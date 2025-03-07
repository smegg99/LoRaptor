// src/rgb/rgb_feedback.cpp
#include "rgb/rgb_feedback.h"
#include <algorithm>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifdef RGB_FEEDBACK_ENABLED
extern RGBFeedback rgbFeedback;
#endif

// Apply an interpolation curve to t (0.0 to 1.0) based on style.
static inline float applyInterpolation(float t, InterpolationStyle style) {
	switch (style) {
	case INTERP_LINEAR:
		return t;
	case INTERP_SINUSOIDAL:
		return (sin((t - 0.5f) * M_PI) + 1.0f) / 2.0f;
	case INTERP_EXPONENTIAL:
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
	if (currentAction) {
		delete currentAction;
	}
	if (pendingAction) {
		delete pendingAction;
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
	if (currentAction) {
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

// Transition from the current color to the new action’s target,
// preserving the current LED state. For idle actions, we preserve the idle phase.
void RGBFeedback::transitionToAction(const RGBAction& newAction, uint32_t fadeDuration) {
	uint32_t now = millis();
	float effectiveR, effectiveG, effectiveB;
	if (currentAction) {
		switch (currentAction->effect) {
		case EFFECT_BLINK:
			effectiveR = currentAction->red;
			effectiveG = currentAction->green;
			effectiveB = currentAction->blue;
			break;
		case EFFECT_PULSE: {
			uint32_t cycle = currentAction->interval;
			uint32_t elapsed = now - actionStartTime;
			uint32_t timeInCycle = elapsed % cycle;
			float phase = ((float)timeInCycle / cycle) * 6.2831853f;
			float factor = ((sin(phase) + 1.0f) / 2.0f) * currentAction->brightness;
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

	if (newAction.action == ACTION_IDLE) {
		if (!(currentAction && currentAction->action == ACTION_IDLE) && idleStartTime != 0) {
			// Continue with the previously saved idleStartTime.
		}
		else {
			idleStartTime = now;
		}
	}

	transitionStartTime = now;
	transitionDuration = fadeDuration;
	if (pendingAction) {
		delete pendingAction;
	}
	pendingAction = new RGBAction(newAction);
	inTransition = true;
}

void RGBFeedback::update() {
	uint32_t now = millis();

	if (inTransition) {
		uint32_t elapsed = now - transitionStartTime;
		float t = (elapsed < transitionDuration) ? ((float)elapsed / transitionDuration) : 1.0f;
		t = applyInterpolation(t, pendingAction->interpStyle);

		float r = transitionStartR + t * (pendingAction->red - transitionStartR);
		float g = transitionStartG + t * (pendingAction->green - transitionStartG);
		float b = transitionStartB + t * (pendingAction->blue - transitionStartB);
		float factor = pendingAction->brightness;
		setLED((uint8_t)(r * 255.0f * factor),
			(uint8_t)(g * 255.0f * factor),
			(uint8_t)(b * 255.0f * factor));

		if (t >= 1.0f) {
			if (currentAction) delete currentAction;
			currentAction = pendingAction;
			pendingAction = nullptr;
			inTransition = false;
			actionStartTime = now;
			if (currentAction->action == ACTION_IDLE && idleStartTime == 0) {
				idleStartTime = now;
			}
		}
		return;
	}

	if (currentAction && currentAction->action == ACTION_IDLE && !actionQueue.empty()) {
		startNextAction();
		return;
	}

	// If there is no current action or if the current action's duration has expired, process queued actions.
	if (!currentAction || (currentAction->duration > 0 && now - actionStartTime >= currentAction->duration)) {
		if (!actionQueue.empty()) {
			RGBAction nextAction = actionQueue.front();
			actionQueue.erase(actionQueue.begin());
			transitionToAction(nextAction, DEFAULT_TRANSITION_DURATION);
		}
		else if (!currentAction || currentAction->action != ACTION_IDLE) {
			// No queued actions: default to idle.
			DefaultConfig idleConfig = defaults[ACTION_IDLE];
			RGBAction idleAction(ACTION_IDLE,
				idleConfig.red, idleConfig.green, idleConfig.blue,
				idleConfig.red2, idleConfig.green2, idleConfig.blue2,
				idleConfig.effect, idleConfig.interval, idleConfig.duration, 0,
				idleConfig.brightness, idleConfig.interpStyle);
			transitionToAction(idleAction, DEFAULT_TRANSITION_DURATION);
		}
		if (currentAction) {
			delete currentAction;
			currentAction = nullptr;
		}
		return;
	}

	float factor = currentAction->brightness;
	switch (currentAction->effect) {
	case EFFECT_SOLID:
		setLED((uint8_t)(currentAction->red * 255.0f * factor),
			(uint8_t)(currentAction->green * 255.0f * factor),
			(uint8_t)(currentAction->blue * 255.0f * factor));
		break;
	case EFFECT_BLINK:
		if (now - lastUpdateTime >= currentAction->interval) {
			blinkState = !blinkState;
			lastUpdateTime = now;
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
	case EFFECT_PULSE: {
		uint32_t cycle = currentAction->interval;
		uint32_t elapsed = now - actionStartTime;
		uint32_t timeInCycle = elapsed % cycle;
		float phase = ((float)timeInCycle / cycle) * 6.2831853f;
		float brightnessVal = (sin(phase) + 1.0f) / 2.0f;
		setLED((uint8_t)(currentAction->red * 255.0f * factor * brightnessVal),
			(uint8_t)(currentAction->green * 255.0f * factor * brightnessVal),
			(uint8_t)(currentAction->blue * 255.0f * factor * brightnessVal));
		break;
	}
	case EFFECT_GRADIENT: {
		// For idle animations, preserve the previous phase.
		uint32_t baseTime = (currentAction->action == ACTION_IDLE) ? idleStartTime : actionStartTime;
		uint32_t elapsed = now - baseTime;
		uint32_t cycle = currentAction->interval;
		uint32_t timeInCycle = elapsed % cycle;
		float t = 0.0f;
		switch (currentAction->interpStyle) {
		case INTERP_LINEAR:
			t = (timeInCycle < cycle / 2.0f) ?
				((float)timeInCycle / (cycle / 2.0f)) :
				(1.0f - ((timeInCycle - cycle / 2.0f) / (cycle / 2.0f)));
			break;
		case INTERP_SINUSOIDAL:
			t = (sin(((float)timeInCycle / cycle) * 6.2831853f - 1.5708f) + 1.0f) / 2.0f;
			break;
		case INTERP_EXPONENTIAL:
			t = (timeInCycle < cycle / 2.0f) ?
				pow((float)timeInCycle / (cycle / 2.0f), 2.0f) :
				pow((cycle - timeInCycle) / (cycle / 2.0f), 2.0f);
			break;
		case INTERP_QUADRATIC:
			t = (timeInCycle < cycle / 2.0f) ?
				pow((float)timeInCycle / (cycle / 2.0f), 2.0f) :
				1.0f - pow((timeInCycle - cycle / 2.0f) / (cycle / 2.0f), 2.0f);
			break;
		case INTERP_CUBIC:
			t = (timeInCycle < cycle / 2.0f) ?
				pow((float)timeInCycle / (cycle / 2.0f), 3.0f) :
				1.0f - pow((timeInCycle - cycle / 2.0f) / (cycle / 2.0f), 3.0f);
			break;
		default:
			t = (timeInCycle < cycle / 2.0f) ?
				((float)timeInCycle / (cycle / 2.0f)) :
				(1.0f - ((timeInCycle - cycle / 2.0f) / (cycle / 2.0f)));
			break;
		}
		float r = currentAction->red + t * (currentAction->red2 - currentAction->red);
		float g = currentAction->green + t * (currentAction->green2 - currentAction->green);
		float b = currentAction->blue + t * (currentAction->blue2 - currentAction->blue);
		setLED((uint8_t)(r * 255.0f * factor),
			(uint8_t)(g * 255.0f * factor),
			(uint8_t)(b * 255.0f * factor));
		break;
	}
	default:
		break;
	}
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