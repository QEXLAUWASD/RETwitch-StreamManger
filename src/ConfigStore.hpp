// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#pragma once

#include <string>

#include "AppState.hpp"  // Required for AppState type

struct TwitchCredentials {
	std::string clientId;
	std::string accessToken;
	std::string streamerId;
	std::optional<std::string> encryptedToken;  // Optional encrypted token (future enhancement)

	bool isValid() const { return !clientId.empty() && !accessToken.empty() && !streamerId.empty(); }
};

std::string getBaseDir();

// AppState is forward-declared in AppState.hpp - no need to redeclare here
bool saveConfig(const std::string &baseDir, const AppState &state);

bool loadExcludedProcesses(const std::string &baseDir, AppState &state);
bool saveExcludedProcesses(const std::string &baseDir, const AppState &state);

bool addOrUpdateGame(const std::string &baseDir, AppState &state, const std::string &gameName,
		     const std::string &processName, const std::string &twitchCategory);

bool removeGame(const std::string &baseDir, AppState &state, const std::string &gameName);

TwitchCredentials loadCredentials(const std::string &baseDir);
bool saveCredentials(const std::string &baseDir, const TwitchCredentials &creds);
