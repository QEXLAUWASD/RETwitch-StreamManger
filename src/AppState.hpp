// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#pragma once

#include <map>
#include <set>
#include <string>
#include <vector>

inline constexpr const char *kAppVersion = "1.1.1";
inline constexpr const char *kDefaultGithubRepo = "QEXLAUWASD/Twitch-StreamManger";

struct AppState {
	std::map<std::string, std::string> processNames;
	std::map<std::string, std::string> twitchCategories;
	std::string baseTemplate;
	std::string currentGame;
	bool keepLastWhenNoGame;
	bool darkMode;
	std::set<std::string> excludedNames;
	std::vector<std::string> excludedPrefixes;

	AppState() : baseTemplate(" %game% %date%"), currentGame("Unknown"), keepLastWhenNoGame(true), darkMode(false)
	{
	}
};
