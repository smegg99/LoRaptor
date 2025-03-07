// src/rgb_feedback.cpp
#include "rgb/rgb_feedback.h"
#include "rgb/rgb_action.h"

#ifdef RGB_FEEDBACK_ENABLED

void RGBFeedback::initializeDefaults() {
	defaults[ACTION_IDLE] = {
		1.0f, 0.0f, 0.75f,
		0.75f, 0.0f, 1.0f,
		EFFECT_GRADIENT,
		3000,
		0,
		0.25f,
		INTERP_EXPONENTIAL
	};

	defaults[ACTION_COMM_RECEIVED] = {
		0.0f, 1.0f, 0.75f,
		0.0f, 0.15f, 0.075f,
		EFFECT_BLINK,
		50,
		300,
		1.0f,
		INTERP_SINUSOIDAL
	};

	defaults[ACTION_COMM_TRANSMITTED] = {
		1.0f, 0.5f, 0.0f,
		0.15f, 0.075f, 0.0f,
		EFFECT_BLINK,
		50,
		300,
		1.0f,
		INTERP_SINUSOIDAL
	};

	defaults[ACTION_COMM_DELIVERED] = {
		0.0f, 1.0f, 0.0f,
		0.0f, 0.15f, 0.0f,
		EFFECT_BLINK,
		50,
		200,
		1.0f,
		INTERP_LINEAR
	};

	defaults[ACTION_COMM_CONNECTED] = {
		0.1f, 0.0f, 0.7f,
		0.01f, 0.0f, 0.07f,
		EFFECT_BLINK,
		100,
		1500,
		1.0f,
		INTERP_SINUSOIDAL
	};

	defaults[ACTION_COMM_DISCONNECTED] = {
		1.0f, 0.2f, 0.0f,
		0.0f, 0.0f, 0.0f,
		EFFECT_BLINK,
		100,
		1500,
		1.0f,
		INTERP_SINUSOIDAL
	};

	defaults[ACTION_COMM_WAITING] = {
		0.0f, 0.0f, 1.0f,
		0.0f, 0.5f, 0.8f,
		EFFECT_GRADIENT,
		1000,
		0,
		1.0f,
		INTERP_EXPONENTIAL
	};

	defaults[ACTION_MESH_ACTIVE] = {
		0.1f, 0.0f, 0.7f,
		0.01f, 0.0f, 0.07f,
		EFFECT_GRADIENT,
		500,
		2000,
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
		INTERP_SINUSOIDAL
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
		INTERP_SINUSOIDAL
	};
}

#endif