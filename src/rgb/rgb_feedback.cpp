// src/rgb_feedback.cpp
#include "rgb/rgb_feedback.h"
#include <algorithm>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifdef RGB_FEEDBACK_ENABLED
extern RGBFeedback rgbFeedback;
#endif

// Helper: Apply an interpolation curve to t (0.0 to 1.0) based on style.
static inline float applyInterpolation(float t, InterpolationStyle style) {
	switch (style) {
	case INTERP_LINEAR:
		return t;
	case INTERP_SINUSOIDAL:
		// Smooth ease-in-out using sine.
		return (sin((t - 0.5f) * M_PI) + 1.0f) / 2.0f;
	case INTERP_EXPONENTIAL:
		return t * t;
	case INTERP_QUADRATIC:
		return t * t;
	case INTERP_CUBIC:
		return t * t * t;
	default:
		return t;
	}
}

RGBFeedback::RGBFeedback()
	: currentAction(nullptr), pendingAction(nullptr), inTransition(false),
	actionStartTime(0), idleStartTime(0), lastUpdateTime(0), blinkState(true),
	currentLED_R(0), currentLED_G(0), currentLED_B(0) {

	this->initializeDefaults();
}

RGBFeedback::~RGBFeedback() {
	if (currentAction != nullptr) {
		delete currentAction;
		currentAction = nullptr;
	}
	if (pendingAction != nullptr) {
		delete pendingAction;
		pendingAction = nullptr;
	}
}

void RGBFeedback::begin() {
	ledcSetup(LEDC_CHANNEL_R, LEDC_FREQUENCY, 8);
	ledcSetup(LEDC_CHANNEL_G, LEDC_FREQUENCY, 8);
	ledcSetup(LEDC_CHANNEL_B, LEDC_FREQUENCY, 8);

	ledcAttachPin(RGB_R_PIN, LEDC_CHANNEL_R);
	ledcAttachPin(RGB_G_PIN, LEDC_CHANNEL_G);
	ledcAttachPin(RGB_B_PIN, LEDC_CHANNEL_B);
}

void RGBFeedback::enqueueAction(DeviceAction action) {
	if (action == ACTION_IDLE) return;
	DefaultConfig d = defaults[action];
	RGBAction rgbAction(action,
		d.red, d.green, d.blue,
		d.red2, d.green2, d.blue2,
		d.effect, d.interval, d.duration, 0,
		d.brightness, d.interpStyle);
	actionQueue.push_back(rgbAction);
	std::sort(actionQueue.begin(), actionQueue.end(), [] (const RGBAction& a, const RGBAction& b) {
		return a.priority > b.priority;
		});
}

void RGBFeedback::setImmediateAction(const RGBAction& action) {
	actionQueue.clear();
	if (currentAction != nullptr) {
		delete currentAction;
		currentAction = nullptr;
	}
	transitionToAction(action, DEFAULT_TRANSITION_DURATION);
}

void RGBFeedback::setAction(DeviceAction action) {
	DefaultConfig d = defaults[action];
	RGBAction newAction(action,
		d.red, d.green, d.blue,
		d.red2, d.green2, d.blue2,
		d.effect, d.interval, d.duration, 0,
		d.brightness, d.interpStyle);
	transitionToAction(newAction, DEFAULT_TRANSITION_DURATION);
}

// Here we compute the “effective” starting color based on the current action.
// This ensures we start the fade transition from the correct (current) LED state.
void RGBFeedback::transitionToAction(const RGBAction& newAction, uint32_t fadeDuration) {
	uint32_t now = millis();
	float effectiveR, effectiveG, effectiveB;
	if (currentAction != nullptr) {
		switch (currentAction->effect) {
		case EFFECT_BLINK:
			// When blinking, use the "on" color.
			effectiveR = currentAction->red;
			effectiveG = currentAction->green;
			effectiveB = currentAction->blue;
			break;
		case EFFECT_PULSE: {
			uint32_t cycle = currentAction->interval;
			uint32_t elapsed = now - actionStartTime;
			uint32_t timeInCycle = elapsed % cycle;
			float phase = ((float)timeInCycle / cycle) * 6.2831853f;
			uint8_t brightnessVal = (uint8_t)(((sin(phase) + 1.0f) / 2.0f) * 255.0f);
			float factor = (brightnessVal / 255.0f) * currentAction->brightness;
			effectiveR = currentAction->red * factor;
			effectiveG = currentAction->green * factor;
			effectiveB = currentAction->blue * factor;
			break;
		}
		default:
			effectiveR = currentLED_R;
			effectiveG = currentLED_G;
			effectiveB = currentLED_B;
			break;
		}
	}
	else {
		effectiveR = currentLED_R;
		effectiveG = currentLED_G;
		effectiveB = currentLED_B;
	}
	transitionStartR = effectiveR;
	transitionStartG = effectiveG;
	transitionStartB = effectiveB;
	transitionStartTime = now;
	transitionDuration = fadeDuration;
	if (pendingAction != nullptr) {
		delete pendingAction;
	}
	pendingAction = new RGBAction(newAction);
	inTransition = true;
}

void RGBFeedback::update() {
	uint32_t now = millis();

	// Process any ongoing fade transition.
	if (inTransition) {
		uint32_t elapsed = now - transitionStartTime;
		float t = (elapsed < transitionDuration) ? ((float)elapsed / transitionDuration) : 1.0f;
		// Apply interpolation for smoother easing.
		t = applyInterpolation(t, pendingAction->interpStyle);

		float targetR = pendingAction->red;
		float targetG = pendingAction->green;
		float targetB = pendingAction->blue;
		float r = transitionStartR + t * (targetR - transitionStartR);
		float g = transitionStartG + t * (targetG - transitionStartG);
		float b = transitionStartB + t * (targetB - transitionStartB);
		float factor = pendingAction->brightness;
		setLED((uint8_t)(r * 255.0f * factor),
			(uint8_t)(g * 255.0f * factor),
			(uint8_t)(b * 255.0f * factor));
		if (t >= 1.0f) {
			// Transition complete.
			currentAction = pendingAction;
			pendingAction = nullptr;
			inTransition = false;
			actionStartTime = now;
			if (currentAction->action == ACTION_IDLE) {
				idleStartTime = now;
			}
		}
		return;
	}

	// Process queued actions, expiration of current action, etc.
	if (!actionQueue.empty() && currentAction &&
		(currentAction->action == ACTION_IDLE || currentAction->duration == 0)) {
		startNextAction();
		return;
	}

	if (currentAction && (currentAction->duration > 0 && now - actionStartTime >= currentAction->duration)) {
		if (!actionQueue.empty()) {
			RGBAction nextAction = actionQueue.front();
			actionQueue.erase(actionQueue.begin());
			transitionToAction(nextAction, DEFAULT_TRANSITION_DURATION);
		}
		else {
			if (currentAction->action != ACTION_IDLE) {
				DefaultConfig idleConfig = defaults[ACTION_IDLE];
				RGBAction idleAction(ACTION_IDLE,
					idleConfig.red, idleConfig.green, idleConfig.blue,
					idleConfig.red2, idleConfig.green2, idleConfig.blue2,
					idleConfig.effect, idleConfig.interval, idleConfig.duration, 0,
					idleConfig.brightness, idleConfig.interpStyle);
				transitionToAction(idleAction, DEFAULT_TRANSITION_DURATION);
			}
		}
		delete currentAction;
		currentAction = nullptr;
		return;
	}

	if (!currentAction) {
		if (!actionQueue.empty()) {
			startNextAction();
			return;
		}
		else {
			DefaultConfig idleConfig = defaults[ACTION_IDLE];
			RGBAction idleAction(ACTION_IDLE,
				idleConfig.red, idleConfig.green, idleConfig.blue,
				idleConfig.red2, idleConfig.green2, idleConfig.blue2,
				idleConfig.effect, idleConfig.interval, idleConfig.duration, 0,
				idleConfig.brightness, idleConfig.interpStyle);
			transitionToAction(idleAction, DEFAULT_TRANSITION_DURATION);
			return;
		}
	}

	// Process the current action’s effect.
	switch (currentAction->effect) {
	case EFFECT_SOLID: {
		float factor = currentAction->brightness;
		setLED((uint8_t)(currentAction->red * 255.0f * factor),
			(uint8_t)(currentAction->green * 255.0f * factor),
			(uint8_t)(currentAction->blue * 255.0f * factor));
		break;
	}
	case EFFECT_BLINK: {
		if (now - lastUpdateTime >= currentAction->interval) {
			blinkState = !blinkState;
			lastUpdateTime = now;
			float factor = currentAction->brightness;
			if (blinkState) {
				setLED((uint8_t)(currentAction->red * 255.0f * factor),
					(uint8_t)(currentAction->green * 255.0f * factor),
					(uint8_t)(currentAction->blue * 255.0f * factor));
			}
			else {
				setLED(0, 0, 0);
			}
		}
		break;
	}
	case EFFECT_PULSE: {
		uint32_t cycle = currentAction->interval;
		uint32_t elapsed = now - actionStartTime;
		uint32_t timeInCycle = elapsed % cycle;
		float phase = ((float)timeInCycle / (float)cycle) * 6.2831853f;
		uint8_t brightnessVal = (uint8_t)(((sin(phase) + 1.0f) / 2.0f) * 255.0f);
		float factor = (brightnessVal / 255.0f) * currentAction->brightness;
		setLED((uint8_t)(currentAction->red * 255.0f * factor),
			(uint8_t)(currentAction->green * 255.0f * factor),
			(uint8_t)(currentAction->blue * 255.0f * factor));
		break;
	}
	case EFFECT_GRADIENT: {
		uint32_t cycle = currentAction->interval;
		uint32_t elapsed = now - actionStartTime;
		uint32_t timeInCycle = elapsed % cycle;
		float t = 0.0f;
		switch (currentAction->interpStyle) {
		case INTERP_LINEAR: {
			float halfCycle = cycle / 2.0f;
			t = (timeInCycle < halfCycle) ? (timeInCycle / halfCycle) :
				(1.0f - ((timeInCycle - halfCycle) / halfCycle));
			break;
		}
		case INTERP_SINUSOIDAL: {
			t = (sin(((float)timeInCycle / cycle) * 6.2831853f - 1.5708f) + 1.0f) / 2.0f;
			break;
		}
		case INTERP_EXPONENTIAL: {
			float halfCycle = cycle / 2.0f;
			t = (timeInCycle < halfCycle) ? pow(timeInCycle / halfCycle, 2.0f) :
				pow((halfCycle - (timeInCycle - halfCycle)) / halfCycle, 2.0f);
			break;
		}
		case INTERP_QUADRATIC: {
			float halfCycle = cycle / 2.0f;
			t = (timeInCycle < halfCycle) ? pow(timeInCycle / halfCycle, 2.0f) :
				1.0f - pow((timeInCycle - halfCycle) / halfCycle, 2.0f);
			break;
		}
		case INTERP_CUBIC: {
			float halfCycle = cycle / 2.0f;
			t = (timeInCycle < halfCycle) ? pow(timeInCycle / halfCycle, 3.0f) :
				1.0f - pow((timeInCycle - halfCycle) / halfCycle, 3.0f);
			break;
		}
		default: {
			float halfCycle = cycle / 2.0f;
			t = (timeInCycle < halfCycle) ? (timeInCycle / halfCycle) :
				(1.0f - ((timeInCycle - halfCycle) / halfCycle));
			break;
		}
		}
		float r = currentAction->red + t * (currentAction->red2 - currentAction->red);
		float g = currentAction->green + t * (currentAction->green2 - currentAction->green);
		float b = currentAction->blue + t * (currentAction->blue2 - currentAction->blue);
		float factor = currentAction->brightness;
		setLED((uint8_t)(r * 255.0f * factor),
			(uint8_t)(g * 255.0f * factor),
			(uint8_t)(b * 255.0f * factor));
		break;
	}
	default:
		break;
	}
}

void RGBFeedback::setFeedbackConfig(DeviceAction action,
	float red, float green, float blue,
	float red2, float green2, float blue2,
	EffectType effect, uint32_t interval, uint32_t duration,
	float brightness) {
	if (action < ACTION_COUNT) {
		defaults[action] = { red, green, blue, red2, green2, blue2, effect, interval, duration, brightness, INTERP_LINEAR };
	}
}

void RGBFeedback::setLED(uint8_t r, uint8_t g, uint8_t b) {
	ledcWrite(LEDC_CHANNEL_R, r);
	ledcWrite(LEDC_CHANNEL_G, g);
	ledcWrite(LEDC_CHANNEL_B, b);
	currentLED_R = r / 255.0f;
	currentLED_G = g / 255.0f;
	currentLED_B = b / 255.0f;
}

void RGBFeedback::startNextAction() {
	while (!actionQueue.empty() && actionQueue.front().action == ACTION_IDLE) {
		actionQueue.erase(actionQueue.begin());
	}
	if (actionQueue.empty()) return;
	RGBAction nextAction = actionQueue.front();
	actionQueue.erase(actionQueue.begin());
	transitionToAction(nextAction, DEFAULT_TRANSITION_DURATION);
}
