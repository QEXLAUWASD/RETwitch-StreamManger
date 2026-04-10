// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#pragma once

#include <optional>
#include <string>

#include <QCheckBox>
#include <QDialog>
#include <QFileSystemWatcher>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QTimer>

#include "AppState.hpp"
#include "TwitchClient.hpp"

class TwitchAutoTitleDialog : public QDialog {
	Q_OBJECT

public:
	explicit TwitchAutoTitleDialog(QWidget *parent = nullptr);

	TwitchAutoTitleDialog(const TwitchAutoTitleDialog &) = delete;
	TwitchAutoTitleDialog &
	operator=(const TwitchAutoTitleDialog &) = delete;
	TwitchAutoTitleDialog(TwitchAutoTitleDialog &&) noexcept = delete;
	TwitchAutoTitleDialog &
	operator=(TwitchAutoTitleDialog &&) noexcept = delete;
	~TwitchAutoTitleDialog() override = default;

private slots:
	void onGameMonitorTick();
	void onUiUpdateTick();
	void onProcessRefreshTick();
	void onReloadConfig();
	void onRemoveSelected();
	void onAddOrUpdateMapping();
	void onManualUpdate();
	void onRefreshProcessList();
	void onAutoSelectProcess();
	void onToggleDarkMode(bool checked);
	void onOpenExclusionsEditor();

private:
	void setupUi();
	void applyTheme();
	void refreshMappingsList();
	void refreshRunningProcessList();
	void setStatus(const QString &text,
		       const QString &color = "green");
	bool ensureCredentials();
	void checkForUpdate();
	void doTwitchUpdate(const std::string &game);

	AppState state_;
	TwitchClient twitchClient_;
	std::string baseDir_;
	std::optional<std::string> lastDetectedGame_;
	bool updatingTwitch_;

	QTimer gameMonitorTimer_;
	QTimer uiUpdateTimer_;
	QTimer processRefreshTimer_;
	QFileSystemWatcher configWatcher_;

	// UI widgets (non-owning; owned by Qt parent chain)
	QLabel *currentGameLabel_ = nullptr;
	QListWidget *mappingsList_ = nullptr;
	QListWidget *processListWidget_ = nullptr;
	QLineEdit *gameNameEdit_ = nullptr;
	QLineEdit *categoryEdit_ = nullptr;
	QLineEdit *customTextEdit_ = nullptr;
	QCheckBox *keepLastCheckbox_ = nullptr;
	QCheckBox *darkModeCheckbox_ = nullptr;
	QLabel *statusLabel_ = nullptr;
};
