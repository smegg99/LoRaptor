// include/commands.h
#ifndef COMMANDS_H
#define COMMANDS_H

#include <Arduino.h>

// Process an incoming command string.
void processCommand(const String& cmd);

// Register all available commands.
void registerCommands();

#endif
