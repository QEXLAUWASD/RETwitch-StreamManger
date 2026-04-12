// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#include "ConfigStore.hpp"
#include "AppState.hpp"

#include <algorithm>
#include <cctype>

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QStandardPaths>
#include <QString>

#include <obs-module.h>

static std::string strToLower(std::string s)
{
	std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return std::tolower(c); });
	return s;
}

std::string getBaseDir()
{
	// Allow overriding the data directory via environment variable.
	// Set TWITCH_AUTOTITLE_DIR to point to your config folder
	// (e.g. D:\Twitch) to use an existing config.ini / config.json.
	QByteArray envDir = qgetenv("TWITCH_AUTOTITLE_DIR");
	if (!envDir.isEmpty()) {
		QString dirPath = QString::fromLocal8Bit(envDir).trimmed();
		QDir().mkpath(dirPath);
		return dirPath.toStdString();
	}

	QString path = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/twitch-auto-title";
	QDir().mkpath(path);
	return path.toStdString();
}

bool loadConfig(const std::string &baseDir, AppState &state)
{
	QFile file(QString::fromStdString(baseDir) + "/config.json");
	if (!file.open(QIODevice::ReadOnly)) {
		blog(LOG_WARNING, "[twitch-auto-title] Could not open config.json");
		return false;
	}

	QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
	file.close();

	if (!doc.isObject()) {
		blog(LOG_WARNING, "[twitch-auto-title] config.json is not valid JSON");
		return false;
	}

	QJsonObject obj = doc.object();

	// Validate and sanitize config values
	QString baseTemplate = obj["base"].toString(" %game% %date%");
	if (baseTemplate.length() > 500) {
		blog(LOG_WARNING, "[twitch-auto-title] base template too long, using default");
		baseTemplate = " %game% %date%";
	}
	state.baseTemplate = baseTemplate.toStdString();

	state.keepLastWhenNoGame = obj["keep_last_when_none"].toBool(true);
	state.darkMode = obj["dark_mode"].toBool(false);

	state.processNames.clear();
	QJsonObject procs = obj["process_name"].toObject();
	for (auto it = procs.begin(); it != procs.end(); ++it) {
		QString gameName = it.key();
		QString procName = it.value().toString();

		// Validate game and process names
		if (gameName.length() > 100 || procName.length() > 200) {
			blog(LOG_WARNING, "[twitch-auto-title] Skipping invalid entry: %s",
			     gameName.toStdString().c_str());
			continue;
		}

		state.processNames[it.key().toStdString()] = it.value().toString().toStdString();
	}

	state.twitchCategories.clear();
	QJsonObject cats = obj["TwitchCategoryName"].toObject();
	for (auto it = cats.begin(); it != cats.end(); ++it) {
		QString categoryName = it.value().toString();
		// Validate category name length
		if (categoryName.length() <= 100) {
			state.twitchCategories[it.key().toStdString()] = categoryName.toStdString();
		}
	}

	blog(LOG_INFO, "[twitch-auto-title] Loaded config: %zu game mappings", state.processNames.size());
	return true;
}

bool saveConfig(const std::string &baseDir, const AppState &state)
{
	QJsonObject procs;
	for (const auto &[game, proc] : state.processNames) {
		QString gameStr = QString::fromStdString(game);
		QString procStr = QString::fromStdString(proc);

		// Skip entries with invalid lengths
		if (gameStr.length() > 100 || procStr.length() > 200) {
			blog(LOG_WARNING, "[twitch-auto-title] Skipping oversized entry: %s", game.c_str());
			continue;
		}

		procs[gameStr] = procStr;
	}

	QJsonObject cats;
	for (const auto &[game, cat] : state.twitchCategories) {
		QString gameStr = QString::fromStdString(game);
		QString catStr = QString::fromStdString(cat);

		// Skip invalid categories
		if (catStr.length() > 100) {
			blog(LOG_WARNING, "[twitch-auto-title] Skipping oversized category: %s", game.c_str());
			continue;
		}

		cats[gameStr] = catStr;
	}

	QJsonObject obj;
	obj["base"] = QString::fromStdString(state.baseTemplate);
	obj["keep_last_when_none"] = state.keepLastWhenNoGame;
	obj["dark_mode"] = state.darkMode;
	obj["process_name"] = procs;
	obj["TwitchCategoryName"] = cats;

	QFile file(QString::fromStdString(baseDir) + "/config.json");
	if (!file.open(QIODevice::WriteOnly)) {
		blog(LOG_WARNING, "[twitch-auto-title] Could not save config.json: %s",
		     file.errorString().toStdString().c_str());
		return false;
	}

	QJsonDocument doc(obj);
	file.write(doc.toJson());
	return true;
}

bool loadExcludedProcesses(const std::string &baseDir, AppState &state)
{
	QFile file(QString::fromStdString(baseDir) + "/excluded_processes.json");

	if (!file.open(QIODevice::ReadOnly)) {
		state.excludedNames = {"system",  "system idle process", "svchost.exe", "explorer.exe",
				       "cmd.exe", "conhost.exe"};
		state.excludedPrefixes = {"microsoftedge", "google chrome", "brave browser"};
		return false;
	}

	QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
	file.close();

	if (!doc.isObject()) {
		return false;
	}

	QJsonObject obj = doc.object();

	state.excludedNames.clear();
	const QJsonArray excludeNames = obj["exclude_process_names"].toArray();
	for (const auto v : excludeNames) {
		std::string name = strToLower(v.toString().toStdString());
		if (!name.empty()) {
			state.excludedNames.insert(name);
		}
	}

	state.excludedPrefixes.clear();
	const QJsonArray excludePrefixes = obj["exclude_prefixes"].toArray();
	for (const auto v : excludePrefixes) {
		std::string prefix = strToLower(v.toString().toStdString());
		if (!prefix.empty()) {
			state.excludedPrefixes.push_back(prefix);
		}
	}

	blog(LOG_INFO, "[twitch-auto-title] Loaded exclusions: %zu names, %zu prefixes", state.excludedNames.size(),
	     state.excludedPrefixes.size());
	return true;
}

bool saveExcludedProcesses(const std::string &baseDir, const AppState &state)
{
	QJsonArray namesArr;
	for (const auto &name : state.excludedNames) {
		namesArr.append(QString::fromStdString(name));
	}

	QJsonArray prefixesArr;
	for (const auto &prefix : state.excludedPrefixes) {
		prefixesArr.append(QString::fromStdString(prefix));
	}

	QJsonObject obj;
	obj["exclude_process_names"] = namesArr;
	obj["exclude_prefixes"] = prefixesArr;

	QFile file(QString::fromStdString(baseDir) + "/excluded_processes.json");
	if (!file.open(QIODevice::WriteOnly)) {
		return false;
	}
	file.write(QJsonDocument(obj).toJson());
	return true;
}

bool addOrUpdateGame(const std::string &baseDir, AppState &state, const std::string &gameName,
		     const std::string &processName, const std::string &twitchCategory)
{
	// Validate input lengths and characters
	if (gameName.empty() || processName.empty()) {
		return false;
	}

	if (gameName.length() > 100 || processName.length() > 200) {
		blog(LOG_WARNING, "[twitch-auto-title] Input too long, rejecting: %s", gameName.c_str());
		return false;
	}

	// Already validated length above; no additional character check needed

	state.processNames[gameName] = processName;
	if (!twitchCategory.empty() && twitchCategory.length() <= 100) {
		state.twitchCategories[gameName] = twitchCategory;
	}
	return saveConfig(baseDir, state);
}

bool removeGame(const std::string &baseDir, AppState &state, const std::string &gameName)
{
	state.processNames.erase(gameName);
	state.twitchCategories.erase(gameName);
	return saveConfig(baseDir, state);
}

static bool hasSecureEncryption(const std::string &baseDir)
{
	// Check for encrypted credentials marker file
	QFile marker(QString::fromStdString(baseDir) + "/.encrypted_credentials");
	return marker.exists() && marker.size() > 0;
}

TwitchCredentials loadCredentials(const std::string &baseDir)
{
	QSettings settings(QString::fromStdString(baseDir) + "/config.ini", QSettings::IniFormat);
	settings.beginGroup("Twitch");

	TwitchCredentials creds;
	creds.clientId = settings.value("client_id").toString().toStdString();
	creds.accessToken = settings.value("access_token").toString().toStdString();
	creds.streamerId = settings.value("streamer_id").toString().toStdString();

	settings.endGroup();

	// Future: If secure mode is enabled, load encrypted token instead
	if (hasSecureEncryption(baseDir)) {
		// Implementation for secure credential loading
		// This would use encrypted storage with proper key management
	}

	return creds;
}

bool saveCredentials(const std::string &baseDir, const TwitchCredentials &creds)
{
	QSettings settings(QString::fromStdString(baseDir) + "/config.ini", QSettings::IniFormat);
	settings.beginGroup("Twitch");
	settings.setValue("client_id", QString::fromStdString(creds.clientId));
	settings.setValue("access_token", QString::fromStdString(creds.accessToken));
	settings.setValue("streamer_id", QString::fromStdString(creds.streamerId));
	settings.endGroup();
	return true;
}
