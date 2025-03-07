// include/rgb/rgb_feedback.h
#ifndef RGB_FEEDBACK_H
#define RGB_FEEDBACK_H

#include "config.h"

#ifdef RGB_FEEDBACK_ENABLED

#include <Arduino.h>
#include <vector>
#include "rgb/rgb_action.h"

#define LEDC_TIMER     LEDC_TIMER_0
#define LEDC_MODE      LEDC_SPEED_MODE_MAX
#define LEDC_CHANNEL_R 0
#define LEDC_CHANNEL_G 1
#define LEDC_CHANNEL_B 2
#define LEDC_FREQUENCY 40000   // 40 kHz PWM frequency

class RGBFeedback {
public:
	RGBFeedback();
	~RGBFeedback();

	// Initialize LED PWM channels.
	void begin();

	void initializeDefaults();

	// Enqueue a custom RGBAction.
	void enqueueAction(DeviceAction action);

	// Immediately set an action (clearing queue).
	void setImmediateAction(const RGBAction& action);

	// Set an action using the predefined default configuration.
	void setAction(DeviceAction action);

	// Must be called periodically.
	void update();

	// Update the default configuration for a given action.
	void setFeedbackConfig(DeviceAction action,
		float red, float green, float blue,
		float red2, float green2, float blue2,
		EffectType effect, uint32_t interval, uint32_t duration,
		float brightness);

private:
	struct DefaultConfig {
		float red;
		float green;
		float blue;
		float red2;
		float green2;
		float blue2;
		EffectType effect;
		uint32_t interval;
		uint32_t duration;
		float brightness;
		InterpolationStyle interpStyle;
	};

	DefaultConfig defaults[ACTION_COUNT];
	std::vector<RGBAction> actionQueue;
	
	RGBAction* currentAction;
	RGBAction* pendingAction;
	uint32_t actionStartTime;
	uint32_t idleStartTime;
	uint32_t lastUpdateTime;
	bool blinkState;

	bool inTransition;
	uint32_t transitionStartTime;
	uint32_t transitionDuration;
	float transitionStartR, transitionStartG, transitionStartB;
	float currentLED_R, currentLED_G, currentLED_B;
	// Default fade duration (in milliseconds).
	static const uint32_t DEFAULT_TRANSITION_DURATION = 200;

	// Set LED output. This converts normalized (0.0-1.0) values multiplied by brightness to a duty cycle (0-255).
	void setLED(uint8_t r, uint8_t g, uint8_t b);

	// Start the next action from the queue.
	void startNextAction();

	// Transition from the current LED color to the new action’s starting color.
	void transitionToAction(const RGBAction& newAction, uint32_t fadeDuration = DEFAULT_TRANSITION_DURATION);
};

#endif

#endif