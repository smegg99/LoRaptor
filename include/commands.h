// include/commands.h
#ifndef COMMANDS_H
#define COMMANDS_H

#include <string>

// Process an incoming command string.
void processCommand(const std::string& cmd);

// Register all available commands.
void registerCommands();

#endif
