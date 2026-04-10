// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#pragma once

#include <string>

#include <QNetworkAccessManager>
#include <QObject>

class TwitchClient : public QObject {
	Q_OBJECT

public:
	TwitchClient(std::string clientId, std::string accessToken,
		     std::string streamerId, QObject *parent = nullptr);

	TwitchClient(const TwitchClient &) = delete;
	TwitchClient &operator=(const TwitchClient &) = delete;
	TwitchClient(TwitchClient &&) noexcept = delete;
	TwitchClient &operator=(TwitchClient &&) noexcept = delete;
	~TwitchClient() override = default;

	void setCredentials(std::string clientId, std::string accessToken,
			    std::string streamerId);

	bool hasCredentials() const;
	bool updateStreamTitle(const std::string &title);
	bool updateStreamCategory(const std::string &category);

private:
	std::string clientId_;
	std::string accessToken_;
	std::string streamerId_;
	QNetworkAccessManager networkManager_;
};

std::string formatTitle(const std::string &titleTemplate,
			const std::string &game);
