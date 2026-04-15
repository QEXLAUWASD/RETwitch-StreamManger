// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#include <obs-frontend-api.h>
#include <obs-module.h>

#include <QCoreApplication>
#include <QFileInfo>
#include <QWidget>

#include "TwitchAutoTitleDialog.hpp"

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("twitch-auto-title", "en-US")

MODULE_EXPORT const char *obs_module_description(void)
{
	return "Automatically updates Twitch stream title and category "
	       "based on the detected running game.";
}

static TwitchAutoTitleDialog *dialog = nullptr;

static void openDialog(void *)
{
	if (!dialog) {
		auto *mainWindow = static_cast<QWidget *>(obs_frontend_get_main_window());
		dialog = new TwitchAutoTitleDialog(mainWindow);
	}
	dialog->show();
	dialog->raise();
	dialog->activateWindow();
}

static void onFrontendEvent(enum obs_frontend_event event, void *)
{
	if (event == OBS_FRONTEND_EVENT_FINISHED_LOADING) {
		if (!dialog) {
			auto *mainWindow = static_cast<QWidget *>(obs_frontend_get_main_window());
			dialog = new TwitchAutoTitleDialog(mainWindow);
		}
	}
}

bool obs_module_load(void)
{
	// Register the plugin's own directory so Qt can locate the TLS
	// plugin (tls/qschannelbackend.dll) shipped alongside this DLL.
	const char *binPath = obs_get_module_binary_path(obs_current_module());
	if (binPath) {
		QString pluginDir = QFileInfo(QString::fromUtf8(binPath)).absolutePath();
		QCoreApplication::addLibraryPath(pluginDir);
	}

	obs_frontend_add_tools_menu_item(obs_module_text("TwitchAutoTitle.MenuTitle"), openDialog, nullptr);
	obs_frontend_add_event_callback(onFrontendEvent, nullptr);
	return true;
}

void obs_module_unload(void)
{
	obs_frontend_remove_event_callback(onFrontendEvent, nullptr);
	delete dialog;
	dialog = nullptr;
}
