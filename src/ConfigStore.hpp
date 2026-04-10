// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#pragma once

#include <string>

struct AppState;

struct TwitchCredentials {
	std::string clientId;
	std::string accessToken;
	std::string streamerId;

	bool isValid() const
	{
		return !clientId.empty() && !accessToken.empty() &&
		       !streamerId.empty();
	}
};

std::string getBaseDir();

bool loadConfig(const std::string &baseDir, AppState &state);
bool saveConfig(const std::string &baseDir, const AppState &state);

bool loadExcludedProcesses(const std::string &baseDir, AppState &state);
bool saveExcludedProcesses(const std::string &baseDir,
			   const AppState &state);

bool addOrUpdateGame(const std::string &baseDir, AppState &state,
		     const std::string &gameName,
		     const std::string &processName,
		     const std::string &twitchCategory);

bool removeGame(const std::string &baseDir, AppState &state,
		const std::string &gameName);

TwitchCredentials loadCredentials(const std::string &baseDir);
bool saveCredentials(const std::string &baseDir,
		     const TwitchCredentials &creds);
