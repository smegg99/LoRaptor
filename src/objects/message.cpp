// src/objects/message.cpp
#include "objects/message.h"

Message::Message(const std::string& content, uint32_t epoch)
	: content(content), epoch(epoch) {
}

Message::Message() : epoch(0) {}

std::string Message::getContent() const {
	return content;
}

uint32_t Message::getEpoch() const {
	return epoch;
}