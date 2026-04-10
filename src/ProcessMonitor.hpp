// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#pragma once

#include <optional>
#include <string>
#include <vector>

struct AppState;

bool isExcludedProcess(const std::string &name, const AppState &state);

std::vector<std::string> getRunningProcessNames();

std::optional<std::string> getCurrentGame(const AppState &state);
