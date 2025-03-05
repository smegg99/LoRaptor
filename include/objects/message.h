// include/objects/message.h
#ifndef MESSAGE_H
#define MESSAGE_H

#include <string>
#include <cstdint>
#include "config.h"

class Message {
public:
	Message(const std::string& content, uint32_t epoch);
	Message();
	
	std::string getContent() const;
	uint32_t getEpoch() const;
private:
	std::string content;
	uint32_t epoch;
};

#endif