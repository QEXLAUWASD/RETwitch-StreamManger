// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#include "TwitchClient.hpp"

#include <ctime>

#include <QByteArray>
#include <QEventLoop>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <QUrlQuery>
#include <mutex>
#include <chrono>
#include <thread>

#include <obs-module.h>

TwitchClient::TwitchClient(std::string clientId, std::string accessToken, std::string streamerId, QObject *parent)
	: QObject(parent),
	  clientId_(std::move(clientId)),
	  accessToken_(std::move(accessToken)),
	  streamerId_(std::move(streamerId))
{
}

void TwitchClient::setCredentials(std::string clientId, std::string accessToken, std::string streamerId)
{
	clientId_ = std::move(clientId);
	accessToken_ = std::move(accessToken);
	streamerId_ = std::move(streamerId);
}

bool TwitchClient::hasCredentials() const
{
	return !clientId_.empty() && !accessToken_.empty() && !streamerId_.empty();
}

static void applyHelixHeaders(QNetworkRequest &request, const std::string &clientId, const std::string &accessToken)
{
	request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
	request.setRawHeader("Client-ID", QByteArray::fromStdString(clientId));
	request.setRawHeader("Authorization", "Bearer " + QByteArray::fromStdString(accessToken));
}

static int sendAndWait(QNetworkReply *reply)
{
	QEventLoop loop;
	QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
	loop.exec();

	if (reply->error() != QNetworkReply::NoError) {
		blog(LOG_WARNING, "[twitch-auto-title] Network error: %s", reply->errorString().toUtf8().constData());
	}

	return reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
}

bool TwitchClient::updateStreamTitle(const std::string &title)
{
	if (!hasCredentials()) {
		return false;
	}

	// Rate limiting: prevent excessive API calls
	static std::mutex apiMutex;
	static std::chrono::steady_clock::time_point lastRequestTime;
	static constexpr auto RATE_LIMIT_INTERVAL = std::chrono::seconds(1);

	std::unique_lock<std::mutex> lock(apiMutex, std::defer_lock);
	if (!lock.try_lock()) {
		return false; // Already processing, skip this update
	}

	auto now = std::chrono::steady_clock::now();
	if (now - lastRequestTime < RATE_LIMIT_INTERVAL) {
		std::this_thread::sleep_until(lastRequestTime + RATE_LIMIT_INTERVAL);
	}
	lastRequestTime = now;

	lock.release();

	QUrl url(QString("https://api.twitch.tv/helix/channels"
			 "?broadcaster_id=%1")
			 .arg(QString::fromStdString(streamerId_)));
	QNetworkRequest request{url};
	applyHelixHeaders(request, clientId_, accessToken_);

	QJsonObject payload;
	payload["title"] = QString::fromStdString(title);
	QByteArray body = QJsonDocument(payload).toJson();

	QNetworkReply *reply = networkManager_.sendCustomRequest(request, "PATCH", body);
	int status = sendAndWait(reply);
	QByteArray responseBody = reply->readAll();
	reply->deleteLater();

	if (status == 204) {
		blog(LOG_INFO, "[twitch-auto-title] Title updated: %s", title.c_str());
		return true;
	}
	blog(LOG_WARNING, "[twitch-auto-title] Failed to update title: HTTP %d — %s", status, responseBody.constData());
	return false;
}

bool TwitchClient::updateStreamCategory(const std::string &category)
{
	if (!hasCredentials()) {
		return false;
	}

	// Step 1: find the game_id for the given category name
	QUrl searchUrl("https://api.twitch.tv/helix/games");
	QUrlQuery query;
	query.addQueryItem("name", QString::fromStdString(category));
	searchUrl.setQuery(query);

	QNetworkRequest searchRequest{searchUrl};
	applyHelixHeaders(searchRequest, clientId_, accessToken_);

	QNetworkReply *searchReply = networkManager_.get(searchRequest);
	int searchStatus = sendAndWait(searchReply);
	QByteArray searchBody = searchReply->readAll();
	searchReply->deleteLater();

	if (searchStatus != 200) {
		blog(LOG_WARNING, "[twitch-auto-title] Game search failed: HTTP %d", searchStatus);
		return false;
	}

	QJsonObject root = QJsonDocument::fromJson(searchBody).object();
	if (root.isEmpty()) {
		blog(LOG_WARNING, "[twitch-auto-title] Empty response from game search");
		return false;
	}
	QJsonArray games = root["data"].toArray();

	if (games.isEmpty()) {
		blog(LOG_WARNING, "[twitch-auto-title] Game '%s' not found on Twitch", category.c_str());
		if (category != "Just Chatting") {
			return updateStreamCategory("Just Chatting");
		}
		return false;
	}

	QString gameId = games[0].toObject()["id"].toString();

	// Step 2: PATCH channel with game_id
	QUrl patchUrl(QString("https://api.twitch.tv/helix/channels"
			      "?broadcaster_id=%1")
			      .arg(QString::fromStdString(streamerId_)));
	QNetworkRequest patchRequest{patchUrl};
	applyHelixHeaders(patchRequest, clientId_, accessToken_);

	QJsonObject payload;
	payload["game_id"] = gameId;
	QByteArray patchBody = QJsonDocument(payload).toJson();

	QNetworkReply *patchReply = networkManager_.sendCustomRequest(patchRequest, "PATCH", patchBody);
	int patchStatus = sendAndWait(patchReply);
	QByteArray patchResponseBody = patchReply->readAll();
	patchReply->deleteLater();

	if (patchStatus == 204) {
		blog(LOG_INFO, "[twitch-auto-title] Category updated to: %s", category.c_str());
		return true;
	}
	blog(LOG_WARNING, "[twitch-auto-title] Failed to update category: HTTP %d — %s", patchStatus,
	     patchResponseBody.constData());
	return false;
}

std::string formatTitle(const std::string &titleTemplate, const std::string &game)
{
	std::time_t now = std::time(nullptr);

	std::string result = titleTemplate;

	// Use fixed-size buffer for date to prevent buffer overflow
	constexpr size_t DATE_BUF_SIZE = 11; // YYYY-MM-DD needs 10 chars + null terminator
	std::string dateBuf;
	{
		char buffer[DATE_BUF_SIZE] = {};
		struct tm *localTime = std::localtime(&now);
		if (localTime) {
			std::strftime(buffer, DATE_BUF_SIZE, "%Y-%m-%d", localTime);
			dateBuf = buffer;
		}
	}

	auto replaceAll = [](std::string &str, const std::string &from, const std::string &to) {
		size_t pos = 0;
		while ((pos = str.find(from, pos)) != std::string::npos) {
			str.replace(pos, from.size(), to);
			pos += to.size();
		}
	};

	replaceAll(result, "%game%", game);
	replaceAll(result, "%date%", dateBuf);
	return result;
}
