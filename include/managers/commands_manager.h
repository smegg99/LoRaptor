// include/managers/commands_manager.h
#ifndef COMMANDS_MANAGER_H
#define COMMANDS_MANAGER_H

#include <string>

// Process an incoming command string.
void processCommand(const std::string& cmd);

// Register all available commands.
void registerCommands();

#endif
