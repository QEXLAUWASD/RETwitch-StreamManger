// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#include "ProcessMonitor.hpp"
#include "AppState.hpp"

#include <algorithm>
#include <cctype>

#ifdef _WIN32
#include <windows.h>
#include <psapi.h>
#endif

static std::string strToLower(std::string s)
{
	std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return std::tolower(c); });
	return s;
}

bool isExcludedProcess(const std::string &name, const AppState &state)
{
	std::string lower = strToLower(name);

	if (state.excludedNames.count(lower) > 0) {
		return true;
	}

	for (const auto &prefix : state.excludedPrefixes) {
		if (lower.rfind(prefix, 0) == 0) {
			return true;
		}
	}

	return false;
}

std::vector<std::string> getRunningProcessNames()
{
	std::vector<std::string> names;

#ifdef _WIN32
	DWORD processIds[2048] = {};
	DWORD bytesReturned = 0;

	if (!EnumProcesses(processIds, sizeof(processIds), &bytesReturned)) {
		return names;
	}

	DWORD numProcesses = bytesReturned / sizeof(DWORD);
	names.reserve(numProcesses);

	for (DWORD i = 0; i < numProcesses; i++) {
		if (processIds[i] == 0) {
			continue;
		}

		HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processIds[i]);
		if (!hProcess) {
			continue;
		}

		CHAR fullPath[MAX_PATH] = {};
		DWORD size = MAX_PATH;
		if (QueryFullProcessImageNameA(hProcess, 0, fullPath, &size)) {
			const char *baseName = strrchr(fullPath, '\\');
			names.emplace_back(baseName ? baseName + 1 : fullPath);
		}

		CloseHandle(hProcess);
	}
#endif

	return names;
}

std::optional<std::string> getCurrentGame(const AppState &state)
{
	std::vector<std::string> running = getRunningProcessNames();

	for (const auto &proc : running) {
		if (isExcludedProcess(proc, state)) {
			continue;
		}

		std::string procLower = strToLower(proc);

		for (const auto &[game, mappedProc] : state.processNames) {
			if (strToLower(mappedProc) == procLower) {
				return game;
			}
		}
	}

	return std::nullopt;
}
