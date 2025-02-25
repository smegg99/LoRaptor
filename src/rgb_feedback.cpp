// src/mesh_manager.cpp
#include "rgb_feedback.h"

#ifdef RGB_FEEDBACK_ENABLED

#include <algorithm>
#include <math.h>

#ifdef RGB_FEEDBACK_ENABLED
extern RGBFeedback rgbFeedback;
#endif

RGBFeedback::RGBFeedback() : currentAction(nullptr), actionStartTime(0), idleStartTime(0), lastUpdateTime(0), blinkState(true) {
	defaults[ACTION_IDLE] = {
		1.0f, 0.0f, 0.75f,
		0.75f, 0.0f, 1.0f,
		EFFECT_GRADIENT,
		1000,
		0,
		0.25f,
		INTERP_EXPONENTIAL
	};

	defaults[ACTION_COMM_CONNECTED] = {
		0.3f, 0.0f, 1.0f,
		0.0f, 0.0f, 1.0f,
		EFFECT_BLINK,
		100,
		1500,
		1.0f,
		INTERP_LINEAR
	};

	defaults[ACTION_COMM_DISCONNECTED] = {
		1.0f, 0.8f, 0.0f,
		0.0f, 0.0f, 0.0f,
		EFFECT_BLINK,
		100,
		1500,
		1.0f,
		INTERP_LINEAR
	};

	defaults[ACTION_COMM_WAITING] = {
		0.3f, 0.0f, 1.0f,
		0.0f, 0.6f, 1.0f,
		EFFECT_GRADIENT,
		500,
		0,
		1.0f,
		INTERP_SINUSOIDAL
	};

	defaults[ACTION_MESH_ACTIVE] = {
		0.0f, 1.0f, 0.8f,
		0.0f, 0.2f, 1.0f,
		EFFECT_GRADIENT,
		5000,
		0,
		1.0f,
		INTERP_SINUSOIDAL
	};

	defaults[ACTION_ERROR] = {
		1.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 0.0f,
		EFFECT_BLINK,
		100,
		2000,
		1.0f,
		INTERP_LINEAR
	};

	defaults[ACTION_WARNING] = {
		1.0f, 0.5f, 0.0f,
		1.0f, 0.75f, 0.0f,
		EFFECT_GRADIENT,
		2000,
		0,
		1.0f,
		INTERP_EXPONENTIAL
	};

	defaults[ACTION_SUCCESS] = {
		0.0f, 1.0f, 0.0f,
		0.0f, 1.0f, 0.0f,
		EFFECT_PULSE,
		1000,
		0,
		1.0f,
		INTERP_LINEAR
	};
}

RGBFeedback::~RGBFeedback() {
	if (currentAction != nullptr) {
		delete currentAction;
		currentAction = nullptr;
	}
}

void RGBFeedback::begin() {
	ledcSetup(LEDC_CHANNEL_R, LEDC_FREQUENCY, 8);
	ledcSetup(LEDC_CHANNEL_G, LEDC_FREQUENCY, 8);
	ledcSetup(LEDC_CHANNEL_B, LEDC_FREQUENCY, 8);

	ledcAttachPin(RGB_R_PIN, LEDC_CHANNEL_R);
	ledcAttachPin(RGB_G_PIN, LEDC_CHANNEL_G);
	ledcAttachPin(RGB_B_PIN, LEDC_CHANNEL_B);

	// setAction(ACTION_IDLE);
}

void RGBFeedback::enqueueAction(const RGBAction& action) {
	actionQueue.push_back(action);
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
	currentAction = new RGBAction(action);
	actionStartTime = millis();
	if (action.action == ACTION_IDLE)
		idleStartTime = actionStartTime;
}

void RGBFeedback::setAction(DeviceAction action) {
	if (currentAction != nullptr) {
		delete currentAction;
		currentAction = nullptr;
	}
	DefaultConfig d = defaults[action];
	currentAction = new RGBAction(action,
		d.red, d.green, d.blue,
		d.red2, d.green2, d.blue2,
		d.effect, d.interval, d.duration, 0,
		d.brightness);
	actionStartTime = millis();
	if (action == ACTION_IDLE)
		idleStartTime = actionStartTime;
}

void RGBFeedback::update() {
	uint32_t now = millis();
	if (currentAction == nullptr) {
		DefaultConfig idleConfig = defaults[ACTION_IDLE];
		if (idleConfig.effect == EFFECT_PULSE) {
			uint32_t cycle = idleConfig.interval;
			uint32_t elapsed = now - idleStartTime;
			uint32_t timeInCycle = elapsed % cycle;
			float phase = ((float)timeInCycle / (float)cycle) * 6.2831853f;
			uint8_t brightnessVal = (uint8_t)(((sin(phase) + 1.0f) / 2.0f) * 255.0f);
			float factor = (brightnessVal / 255.0f) * idleConfig.brightness;
			setLED((uint8_t)(idleConfig.red * 255.0f * factor),
				(uint8_t)(idleConfig.green * 255.0f * factor),
				(uint8_t)(idleConfig.blue * 255.0f * factor));
		}
		else if (idleConfig.effect == EFFECT_GRADIENT) {
			uint32_t cycle = idleConfig.interval;
			uint32_t elapsed = now - idleStartTime;
			uint32_t timeInCycle = elapsed % cycle;
			float halfCycle = cycle / 2.0f;
			float t;
			if (timeInCycle < halfCycle) {
				t = timeInCycle / halfCycle; // 0 -> 1
			}
			else {
				t = 1.0f - ((timeInCycle - halfCycle) / halfCycle); // 1 -> 0
			}
			float r = idleConfig.red + t * (idleConfig.red2 - idleConfig.red);
			float g = idleConfig.green + t * (idleConfig.green2 - idleConfig.green);
			float b = idleConfig.blue + t * (idleConfig.blue2 - idleConfig.blue);
			float factor = idleConfig.brightness;
			setLED((uint8_t)(r * 255.0f * factor),
				(uint8_t)(g * 255.0f * factor),
				(uint8_t)(b * 255.0f * factor));
		}
		else {
			setLED((uint8_t)(idleConfig.red * 255.0f * idleConfig.brightness),
				(uint8_t)(idleConfig.green * 255.0f * idleConfig.brightness),
				(uint8_t)(idleConfig.blue * 255.0f * idleConfig.brightness));
		}
		return;
	}

	if (currentAction->duration > 0 && now - actionStartTime >= currentAction->duration) {
		delete currentAction;
		currentAction = nullptr;
		return;
	}

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
		uint32_t cycle = currentAction->interval;  // Full cycle period (A -> B -> A)
		uint32_t elapsed = now - actionStartTime;
		uint32_t timeInCycle = elapsed % cycle;
		float t = 0.0f;

		switch (currentAction->interpStyle) {
		case INTERP_LINEAR: {
			float halfCycle = cycle / 2.0f;
			if (timeInCycle < halfCycle)
				t = timeInCycle / halfCycle;          // 0 -> 1
			else
				t = 1.0f - ((timeInCycle - halfCycle) / halfCycle); // 1 -> 0
			break;
		}
		case INTERP_SINUSOIDAL: {
			t = (sin(((float)timeInCycle / cycle) * 6.2831853f - 1.5708f) + 1.0f) / 2.0f;
			break;
		}
		case INTERP_EXPONENTIAL: {
			float halfCycle = cycle / 2.0f;
			if (timeInCycle < halfCycle)
				t = pow(timeInCycle / halfCycle, 2.0f);  // Accelerate
			else
				t = pow((halfCycle - (timeInCycle - halfCycle)) / halfCycle, 2.0f);
			break;
		}
		case INTERP_QUADRATIC: {
			float halfCycle = cycle / 2.0f;
			if (timeInCycle < halfCycle)
				t = pow(timeInCycle / halfCycle, 2.0f); // Quadratic ease-in
			else
				t = 1.0f - pow((timeInCycle - halfCycle) / halfCycle, 2.0f); // Quadratic ease-out
			break;
		}
		case INTERP_CUBIC: {
			float halfCycle = cycle / 2.0f;
			if (timeInCycle < halfCycle)
				t = pow(timeInCycle / halfCycle, 3.0f); // Cubic ease-in
			else
				t = 1.0f - pow((timeInCycle - halfCycle) / halfCycle, 3.0f); // Cubic ease-out
			break;
		}
		default: {
			float halfCycle = cycle / 2.0f;
			if (timeInCycle < halfCycle)
				t = timeInCycle / halfCycle;
			else
				t = 1.0f - ((timeInCycle - halfCycle) / halfCycle);
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
		defaults[action] = { red, green, blue, red2, green2, blue2, effect, interval, duration, brightness };
	}
}

void RGBFeedback::setLED(uint8_t r, uint8_t g, uint8_t b) {
	ledcWrite(LEDC_CHANNEL_R, r);
	ledcWrite(LEDC_CHANNEL_G, g);
	ledcWrite(LEDC_CHANNEL_B, b);
}

void RGBFeedback::startNextAction() {
	if (actionQueue.empty()) return;
	currentAction = new RGBAction(actionQueue.front());
	actionStartTime = millis();
	if (currentAction->action == ACTION_IDLE) {
		idleStartTime = actionStartTime;
	}
	actionQueue.erase(actionQueue.begin());
}

#endif