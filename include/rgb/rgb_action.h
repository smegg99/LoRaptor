// include/rgb/rgb_action.h
#ifndef RGB_ACTION_H
#define RGB_ACTION_H

#include <Arduino.h>

enum EffectType {
	EFFECT_SOLID,
	EFFECT_BLINK,
	EFFECT_PULSE,
	EFFECT_GRADIENT
};

enum DeviceAction {
	ACTION_IDLE,
	ACTION_COMM_RECEIVED,
	ACTION_COMM_TRANSMITTED,
	ACTION_COMM_CONNECTED,
	ACTION_COMM_DISCONNECTED,
	ACTION_COMM_WAITING,
	ACTION_MESH_ACTIVE,
	ACTION_ERROR,
	ACTION_WARNING,
	ACTION_SUCCESS,
	ACTION_COUNT  // Total number of actions.
};

enum InterpolationStyle {
	INTERP_LINEAR,
	INTERP_SINUSOIDAL,
	INTERP_EXPONENTIAL,
	INTERP_QUADRATIC,
	INTERP_CUBIC
};

// RGBAction represents one LED feedback action.
class RGBAction {
public:
	DeviceAction action;
	float red;
	float green;
	float blue;
	float red2;
	float green2;
	float blue2;
	EffectType effect;
	uint32_t interval;              // Cycle period in ms.
	uint32_t duration;              // Duration in ms (0 = indefinite).
	uint8_t priority;               // Higher value = higher urgency.
	float brightness;               // Normalized (0.0 to 1.0).
	InterpolationStyle interpStyle; // Interpolation style for gradient effects.

	RGBAction(DeviceAction action,
		float red, float green, float blue,
		float red2, float green2, float blue2,
		EffectType effect, uint32_t interval, uint32_t duration,
		uint8_t priority, float brightness,
		InterpolationStyle interpStyle = INTERP_LINEAR)
		: action(action),
		red(red), green(green), blue(blue),
		red2(red2), green2(green2), blue2(blue2),
		effect(effect),
		interval(interval),
		duration(duration),
		priority(priority),
		brightness(brightness),
		interpStyle(interpStyle) {
	}
};

#endif
