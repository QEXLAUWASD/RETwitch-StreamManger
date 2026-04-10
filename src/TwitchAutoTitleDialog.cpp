// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2024 LiuLian

#include "TwitchAutoTitleDialog.hpp"

#include <algorithm>
#include <tuple>

#include <QApplication>
#include <QDialogButtonBox>
#include <QFormLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPalette>
#include <QPushButton>
#include <QRegularExpression>
#include <QVBoxLayout>

#include "ConfigStore.hpp"
#include "ProcessMonitor.hpp"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static std::tuple<int, int, int> parseVersion(const QString &tag)
{
	QRegularExpression re(R"((\d+)\.(\d+)\.(\d+))");
	QRegularExpressionMatch m = re.match(tag);
	if (m.hasMatch()) {
		return {m.captured(1).toInt(), m.captured(2).toInt(),
			m.captured(3).toInt()};
	}
	return {0, 0, 0};
}

// ---------------------------------------------------------------------------
// Constructor
// ---------------------------------------------------------------------------

TwitchAutoTitleDialog::TwitchAutoTitleDialog(QWidget *parent)
	: QDialog(parent),
	  twitchClient_("", "", "", this),
	  updatingTwitch_(false)
{
	setWindowTitle("Twitch Auto-Title");
	setMinimumSize(920, 700);
	setWindowFlags(windowFlags() | Qt::WindowMaximizeButtonHint);

	baseDir_ = getBaseDir();
	setupUi();

	ensureCredentials();
	loadConfig(baseDir_, state_);
	loadExcludedProcesses(baseDir_, state_);

	// Hot-reload config.json on external change
	QString configPath =
		QString::fromStdString(baseDir_) + "/config.json";
	configWatcher_.addPath(configPath);
	connect(&configWatcher_, &QFileSystemWatcher::fileChanged, this,
		[this](const QString &) {
			loadConfig(baseDir_, state_);
			refreshMappingsList();
		});

	refreshMappingsList();
	refreshRunningProcessList();

	darkModeCheckbox_->setChecked(state_.darkMode);
	keepLastCheckbox_->setChecked(state_.keepLastWhenNoGame);
	applyTheme();

	connect(&gameMonitorTimer_, &QTimer::timeout, this,
		&TwitchAutoTitleDialog::onGameMonitorTick);
	gameMonitorTimer_.start(5000);

	connect(&uiUpdateTimer_, &QTimer::timeout, this,
		&TwitchAutoTitleDialog::onUiUpdateTick);
	uiUpdateTimer_.start(1000);

	connect(&processRefreshTimer_, &QTimer::timeout, this,
		&TwitchAutoTitleDialog::onProcessRefreshTick);
	processRefreshTimer_.start(60'000);

	QTimer::singleShot(3000, this,
			   &TwitchAutoTitleDialog::checkForUpdate);
}

// ---------------------------------------------------------------------------
// UI setup
// ---------------------------------------------------------------------------

void TwitchAutoTitleDialog::setupUi()
{
	auto *mainLayout = new QVBoxLayout(this);

	// Top bar: dark mode
	auto *topBar = new QHBoxLayout;
	topBar->addStretch();
	darkModeCheckbox_ = new QCheckBox("Dark Mode", this);
	connect(darkModeCheckbox_, &QCheckBox::toggled, this,
		&TwitchAutoTitleDialog::onToggleDarkMode);
	topBar->addWidget(darkModeCheckbox_);
	mainLayout->addLayout(topBar);

	// Current detected game
	mainLayout->addWidget(
		new QLabel("Current Detected Game:", this));
	currentGameLabel_ = new QLabel("Unknown", this);
	QFont boldFont = currentGameLabel_->font();
	boldFont.setBold(true);
	boldFont.setPointSize(boldFont.pointSize() + 1);
	currentGameLabel_->setFont(boldFont);
	mainLayout->addWidget(currentGameLabel_);

	// Configured mappings
	mainLayout->addWidget(
		new QLabel("Configured Game \u2192 Process Mappings:", this));
	mappingsList_ = new QListWidget(this);
	mappingsList_->setFixedHeight(130);
	mainLayout->addWidget(mappingsList_);

	// Mapping action buttons
	auto *btnRow = new QHBoxLayout;
	auto *reloadBtn = new QPushButton("Reload config.json", this);
	auto *removeBtn = new QPushButton("Remove Selected", this);
	auto *exclusionsBtn = new QPushButton("Edit Exclusions", this);
	connect(reloadBtn, &QPushButton::clicked, this,
		&TwitchAutoTitleDialog::onReloadConfig);
	connect(removeBtn, &QPushButton::clicked, this,
		&TwitchAutoTitleDialog::onRemoveSelected);
	connect(exclusionsBtn, &QPushButton::clicked, this,
		&TwitchAutoTitleDialog::onOpenExclusionsEditor);
	btnRow->addWidget(reloadBtn);
	btnRow->addWidget(removeBtn);
	btnRow->addWidget(exclusionsBtn);
	btnRow->addStretch();
	mainLayout->addLayout(btnRow);

	// Add/Update mapping group
	auto *mappingGroup = new QGroupBox("Add / Update Mapping", this);
	auto *mappingGroupLayout = new QHBoxLayout(mappingGroup);

	auto *formLayout = new QFormLayout;
	gameNameEdit_ = new QLineEdit(this);
	categoryEdit_ = new QLineEdit(this);
	formLayout->addRow("Game Name:", gameNameEdit_);
	formLayout->addRow("Twitch Category:", categoryEdit_);
	mappingGroupLayout->addLayout(formLayout);

	auto *procCol = new QVBoxLayout;
	procCol->addWidget(new QLabel("Process (select):", this));
	processListWidget_ = new QListWidget(this);
	processListWidget_->setFixedHeight(110);
	procCol->addWidget(processListWidget_);
	auto *procBtnRow = new QHBoxLayout;
	auto *refreshProcBtn = new QPushButton("Refresh", this);
	auto *autoSelectBtn = new QPushButton("Auto-select match", this);
	connect(refreshProcBtn, &QPushButton::clicked, this,
		&TwitchAutoTitleDialog::onRefreshProcessList);
	connect(autoSelectBtn, &QPushButton::clicked, this,
		&TwitchAutoTitleDialog::onAutoSelectProcess);
	procBtnRow->addWidget(refreshProcBtn);
	procBtnRow->addWidget(autoSelectBtn);
	procCol->addLayout(procBtnRow);
	mappingGroupLayout->addLayout(procCol);

	mainLayout->addWidget(mappingGroup);

	// Custom suffix
	mainLayout->addWidget(new QLabel(
		"Custom Text (will be appended to the end of the title):",
		this));
	customTextEdit_ = new QLineEdit(this);
	mainLayout->addWidget(customTextEdit_);

	// Keep last checkbox
	keepLastCheckbox_ = new QCheckBox(
		"When no game detected, keep last title "
		"(do not switch to Just Chatting)",
		this);
	connect(keepLastCheckbox_, &QCheckBox::toggled, this, [this](bool v) {
		state_.keepLastWhenNoGame = v;
		saveConfig(baseDir_, state_);
	});
	mainLayout->addWidget(keepLastCheckbox_);

	// Action buttons
	auto *actionRow = new QHBoxLayout;
	auto *addUpdateBtn =
		new QPushButton("Add / Update Mapping", this);
	auto *manualUpdateBtn =
		new QPushButton("Manual Update Title/Category", this);
	connect(addUpdateBtn, &QPushButton::clicked, this,
		&TwitchAutoTitleDialog::onAddOrUpdateMapping);
	connect(manualUpdateBtn, &QPushButton::clicked, this,
		&TwitchAutoTitleDialog::onManualUpdate);
	actionRow->addWidget(addUpdateBtn);
	actionRow->addWidget(manualUpdateBtn);
	mainLayout->addLayout(actionRow);

	// Status label
	statusLabel_ = new QLabel("", this);
	mainLayout->addWidget(statusLabel_);
}

// ---------------------------------------------------------------------------
// Credentials setup
// ---------------------------------------------------------------------------

bool TwitchAutoTitleDialog::ensureCredentials()
{
	auto creds = loadCredentials(baseDir_);
	if (creds.isValid()) {
		twitchClient_.setCredentials(creds.clientId,
					     creds.accessToken,
					     creds.streamerId);
		return true;
	}

	QDialog credDialog(this);
	credDialog.setWindowTitle("Twitch Credentials Setup");
	credDialog.setMinimumWidth(420);

	auto *layout = new QFormLayout(&credDialog);
	auto *clientIdEdit = new QLineEdit(&credDialog);
	auto *accessTokenEdit = new QLineEdit(&credDialog);
	accessTokenEdit->setEchoMode(QLineEdit::Password);
	auto *streamerIdEdit = new QLineEdit(&credDialog);

	layout->addRow("Client ID:", clientIdEdit);
	layout->addRow("Access Token:", accessTokenEdit);
	layout->addRow("Streamer ID (User ID):", streamerIdEdit);

	auto *buttons = new QDialogButtonBox(
		QDialogButtonBox::Ok | QDialogButtonBox::Cancel,
		&credDialog);
	layout->addRow(buttons);

	connect(buttons, &QDialogButtonBox::accepted, &credDialog,
		&QDialog::accept);
	connect(buttons, &QDialogButtonBox::rejected, &credDialog,
		&QDialog::reject);

	if (credDialog.exec() != QDialog::Accepted) {
		return false;
	}

	TwitchCredentials newCreds;
	newCreds.clientId =
		clientIdEdit->text().trimmed().toStdString();
	newCreds.accessToken =
		accessTokenEdit->text().trimmed().toStdString();
	newCreds.streamerId =
		streamerIdEdit->text().trimmed().toStdString();

	if (!newCreds.isValid()) {
		return false;
	}

	saveCredentials(baseDir_, newCreds);
	twitchClient_.setCredentials(newCreds.clientId, newCreds.accessToken,
				     newCreds.streamerId);
	return true;
}

// ---------------------------------------------------------------------------
// Slots
// ---------------------------------------------------------------------------

void TwitchAutoTitleDialog::onGameMonitorTick()
{
	if (updatingTwitch_) {
		return;
	}

	auto detected = getCurrentGame(state_);
	state_.currentGame =
		detected.has_value() ? *detected : "Unknown";

	if (detected == lastDetectedGame_) {
		return;
	}

	lastDetectedGame_ = detected;

	if (!detected.has_value() && state_.keepLastWhenNoGame) {
		return;
	}

	doTwitchUpdate(detected.has_value() ? *detected : "Just Chatting");
}

void TwitchAutoTitleDialog::onUiUpdateTick()
{
	currentGameLabel_->setText(
		QString::fromStdString(state_.currentGame));
}

void TwitchAutoTitleDialog::onProcessRefreshTick()
{
	refreshRunningProcessList();
}

void TwitchAutoTitleDialog::onReloadConfig()
{
	loadConfig(baseDir_, state_);
	refreshMappingsList();
	QMessageBox::information(this, "Reloaded", "config.json reloaded.");
}

void TwitchAutoTitleDialog::onRemoveSelected()
{
	auto selected = mappingsList_->selectedItems();
	if (selected.isEmpty()) {
		QMessageBox::information(this, "Select",
					 "Choose a mapping to remove.");
		return;
	}

	QString item = selected[0]->text();
	QString game = item.split("->")[0].trimmed();

	auto choice = QMessageBox::question(
		this, "Confirm",
		QString("Remove mapping for '%1'?").arg(game));
	if (choice != QMessageBox::Yes) {
		return;
	}

	if (removeGame(baseDir_, state_, game.toStdString())) {
		refreshMappingsList();
	} else {
		QMessageBox::critical(this, "Error",
				      "Failed to remove mapping.");
	}
}

void TwitchAutoTitleDialog::onAddOrUpdateMapping()
{
	QString game = gameNameEdit_->text().trimmed();
	QString category = categoryEdit_->text().trimmed();
	auto selected = processListWidget_->selectedItems();

	if (game.isEmpty()) {
		QMessageBox::warning(this, "Missing",
				     "Please provide a Game Name.");
		return;
	}
	if (selected.isEmpty()) {
		QMessageBox::warning(
			this, "Missing",
			"Please select a Process from the list.");
		return;
	}

	QString proc = selected[0]->text().trimmed();
	bool ok = addOrUpdateGame(baseDir_, state_, game.toStdString(),
				  proc.toStdString(),
				  category.toStdString());
	if (ok) {
		gameNameEdit_->clear();
		categoryEdit_->clear();
		refreshMappingsList();
		setStatus(QString("Added/Updated: %1 -> %2")
				  .arg(game)
				  .arg(proc));
	} else {
		setStatus("Failed to add mapping.", "red");
	}
}

void TwitchAutoTitleDialog::onManualUpdate()
{
	auto detected = getCurrentGame(state_);
	state_.currentGame =
		detected.has_value() ? *detected : "Unknown";

	if (!detected.has_value() && state_.keepLastWhenNoGame) {
		setStatus("No game detected; kept last title.", "blue");
		return;
	}

	std::string game =
		detected.has_value() ? *detected : "Just Chatting";
	doTwitchUpdate(game);
	setStatus(QString("Manual update sent for: %1")
			  .arg(QString::fromStdString(game)),
		  "blue");
}

void TwitchAutoTitleDialog::onRefreshProcessList()
{
	refreshRunningProcessList();
}

void TwitchAutoTitleDialog::onAutoSelectProcess()
{
	int bestMatch = -1;
	for (int i = 0; i < processListWidget_->count() && bestMatch < 0;
	     i++) {
		QString item =
			processListWidget_->item(i)->text().toLower();
		for (const auto &[game, proc] : state_.processNames) {
			QString mapped =
				QString::fromStdString(proc).toLower();
			if (item.contains(mapped) ||
			    mapped.contains(item)) {
				bestMatch = i;
				break;
			}
		}
	}

	if (bestMatch >= 0) {
		processListWidget_->clearSelection();
		processListWidget_->setCurrentRow(bestMatch);
		QMessageBox::information(
			this, "Auto-select",
			QString("Selected: %1").arg(
				processListWidget_->item(bestMatch)->text()));
	} else {
		QMessageBox::information(this, "Auto-select",
					 "No likely match found.");
	}
}

void TwitchAutoTitleDialog::onToggleDarkMode(bool checked)
{
	state_.darkMode = checked;
	applyTheme();
	saveConfig(baseDir_, state_);
}

void TwitchAutoTitleDialog::onOpenExclusionsEditor()
{
	// Stop the game monitor while editing exclusions to prevent
	// concurrent state modification.
	gameMonitorTimer_.stop();

	QDialog win(this);
	win.setWindowTitle("Edit Excluded Processes");
	win.setMinimumSize(980, 460);

	auto *mainLayout = new QVBoxLayout(&win);
	auto *colsLayout = new QHBoxLayout;

	// --- Left: excluded names ---
	auto *leftGroup =
		new QGroupBox("Excluded Process Names", &win);
	auto *leftLayout = new QVBoxLayout(leftGroup);
	auto *namesLb = new QListWidget(&win);
	namesLb->setSelectionMode(QAbstractItemView::ExtendedSelection);
	for (const auto &n : state_.excludedNames) {
		namesLb->addItem(QString::fromStdString(n));
	}
	leftLayout->addWidget(namesLb);
	auto *nameEntry = new QLineEdit(&win);
	auto *addNameBtn = new QPushButton("Add", &win);
	auto *addNameRow = new QHBoxLayout;
	addNameRow->addWidget(nameEntry);
	addNameRow->addWidget(addNameBtn);
	leftLayout->addLayout(addNameRow);
	auto *removeNameBtn = new QPushButton("Remove Selected", &win);
	leftLayout->addWidget(removeNameBtn);
	colsLayout->addWidget(leftGroup);

	// --- Middle: running processes ---
	auto *midGroup =
		new QGroupBox("Running Processes (select to add)", &win);
	auto *midLayout = new QVBoxLayout(midGroup);
	auto *runningLb = new QListWidget(&win);
	runningLb->setSelectionMode(QAbstractItemView::ExtendedSelection);

	auto populateRunning = [&]() {
		auto procs = getRunningProcessNames();
		std::sort(procs.begin(), procs.end());
		procs.erase(std::unique(procs.begin(), procs.end()),
			    procs.end());
		runningLb->clear();
		for (const auto &p : procs) {
			if (!isExcludedProcess(p, state_)) {
				runningLb->addItem(
					QString::fromStdString(p));
			}
		}
	};
	populateRunning();

	midLayout->addWidget(runningLb);
	auto *refreshRunBtn = new QPushButton("Refresh", &win);
	auto *addToNamesBtn =
		new QPushButton("Add \u2192 Excluded Names", &win);
	auto *addToPrefixBtn =
		new QPushButton("Add \u2192 Excluded Prefixes", &win);
	midLayout->addWidget(refreshRunBtn);
	midLayout->addWidget(addToNamesBtn);
	midLayout->addWidget(addToPrefixBtn);
	colsLayout->addWidget(midGroup);

	// --- Right: excluded prefixes ---
	auto *rightGroup =
		new QGroupBox("Excluded Prefixes (starts-with)", &win);
	auto *rightLayout = new QVBoxLayout(rightGroup);
	auto *prefixLb = new QListWidget(&win);
	prefixLb->setSelectionMode(QAbstractItemView::ExtendedSelection);
	for (const auto &p : state_.excludedPrefixes) {
		prefixLb->addItem(QString::fromStdString(p));
	}
	rightLayout->addWidget(prefixLb);
	auto *prefixEntry = new QLineEdit(&win);
	auto *addPrefixBtn = new QPushButton("Add", &win);
	auto *addPrefixRow = new QHBoxLayout;
	addPrefixRow->addWidget(prefixEntry);
	addPrefixRow->addWidget(addPrefixBtn);
	rightLayout->addLayout(addPrefixRow);
	auto *removePrefixBtn =
		new QPushButton("Remove Selected", &win);
	rightLayout->addWidget(removePrefixBtn);
	colsLayout->addWidget(rightGroup);

	mainLayout->addLayout(colsLayout);

	// Bottom buttons
	auto *bottomRow = new QHBoxLayout;
	auto *saveBtn = new QPushButton("Save", &win);
	auto *closeBtn = new QPushButton("Close", &win);
	bottomRow->addStretch();
	bottomRow->addWidget(saveBtn);
	bottomRow->addWidget(closeBtn);
	mainLayout->addLayout(bottomRow);

	// Connections
	connect(addNameBtn, &QPushButton::clicked, &win, [&]() {
		QString val = nameEntry->text().trimmed().toLower();
		if (val.isEmpty()) {
			return;
		}
		std::string s = val.toStdString();
		if (!state_.excludedNames.count(s)) {
			state_.excludedNames.insert(s);
			namesLb->addItem(val);
		}
		nameEntry->clear();
	});

	connect(removeNameBtn, &QPushButton::clicked, &win, [&]() {
		for (auto *item : namesLb->selectedItems()) {
			state_.excludedNames.erase(
				item->text().toStdString());
			delete item;
		}
	});

	connect(refreshRunBtn, &QPushButton::clicked, &win,
		populateRunning);

	connect(addToNamesBtn, &QPushButton::clicked, &win, [&]() {
		for (auto *item : runningLb->selectedItems()) {
			QString name = item->text().toLower();
			std::string s = name.toStdString();
			if (!state_.excludedNames.count(s)) {
				state_.excludedNames.insert(s);
				namesLb->addItem(name);
			}
		}
		populateRunning();
	});

	connect(addToPrefixBtn, &QPushButton::clicked, &win, [&]() {
		for (auto *item : runningLb->selectedItems()) {
			QString prefix =
				item->text().split(".")[0].toLower();
			std::string pref = prefix.toStdString();
			if (std::find(state_.excludedPrefixes.begin(),
				      state_.excludedPrefixes.end(),
				      pref) ==
			    state_.excludedPrefixes.end()) {
				state_.excludedPrefixes.push_back(pref);
				prefixLb->addItem(prefix);
			}
		}
		populateRunning();
	});

	connect(addPrefixBtn, &QPushButton::clicked, &win, [&]() {
		QString val = prefixEntry->text().trimmed().toLower();
		if (val.isEmpty()) {
			return;
		}
		std::string pref = val.toStdString();
		if (std::find(state_.excludedPrefixes.begin(),
			      state_.excludedPrefixes.end(),
			      pref) == state_.excludedPrefixes.end()) {
			state_.excludedPrefixes.push_back(pref);
			prefixLb->addItem(val);
		}
		prefixEntry->clear();
	});

	connect(removePrefixBtn, &QPushButton::clicked, &win, [&]() {
		for (auto *item : prefixLb->selectedItems()) {
			std::string pref = item->text().toStdString();
			auto it = std::find(state_.excludedPrefixes.begin(),
					    state_.excludedPrefixes.end(),
					    pref);
			if (it != state_.excludedPrefixes.end()) {
				state_.excludedPrefixes.erase(it);
			}
			delete item;
		}
	});

	connect(saveBtn, &QPushButton::clicked, &win, [&]() {
		saveExcludedProcesses(baseDir_, state_);
		loadExcludedProcesses(baseDir_, state_);
		refreshRunningProcessList();
		QMessageBox::information(&win, "Saved",
					 "Excluded processes saved.");
	});

	connect(closeBtn, &QPushButton::clicked, &win, &QDialog::accept);

	win.exec();

	gameMonitorTimer_.start(5000);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void TwitchAutoTitleDialog::doTwitchUpdate(const std::string &game)
{
	updatingTwitch_ = true;

	std::string category = "Just Chatting";
	if (state_.twitchCategories.count(game)) {
		category = state_.twitchCategories.at(game);
	}

	std::string customText =
		customTextEdit_->text().trimmed().toStdString();
	std::string title = formatTitle(state_.baseTemplate, game);
	if (!customText.empty()) {
		title += " " + customText;
	}

	bool titleOk = twitchClient_.updateStreamTitle(title);
	bool catOk = twitchClient_.updateStreamCategory(category);

	if (!titleOk) {
		setStatus(
			"Title update failed — check credentials / token.",
			"red");
	} else if (!catOk) {
		setStatus(
			QString("Title updated, but category failed: %1")
				.arg(QString::fromStdString(title)),
			"orange");
	} else {
		setStatus(
			QString("Updated: %1").arg(
				QString::fromStdString(title)));
	}

	updatingTwitch_ = false;
}

void TwitchAutoTitleDialog::refreshMappingsList()
{
	mappingsList_->clear();
	for (const auto &[game, proc] : state_.processNames) {
		const std::string &cat =
			state_.twitchCategories.count(game)
				? state_.twitchCategories.at(game)
				: std::string{};
		mappingsList_->addItem(
			QString("%1 -> %2   [Category: %3]")
				.arg(QString::fromStdString(game))
				.arg(QString::fromStdString(proc))
				.arg(QString::fromStdString(cat)));
	}
}

void TwitchAutoTitleDialog::refreshRunningProcessList()
{
	auto procs = getRunningProcessNames();

	procs.erase(std::remove_if(procs.begin(), procs.end(),
				   [this](const std::string &name) {
					   return isExcludedProcess(name,
								    state_);
				   }),
		    procs.end());

	std::sort(procs.begin(), procs.end(),
		  [](const std::string &a, const std::string &b) {
			  std::string la = a, lb = b;
			  std::transform(la.begin(), la.end(), la.begin(),
					 ::tolower);
			  std::transform(lb.begin(), lb.end(), lb.begin(),
					 ::tolower);
			  return la < lb;
		  });
	procs.erase(std::unique(procs.begin(), procs.end()), procs.end());

	processListWidget_->clear();
	for (const auto &name : procs) {
		processListWidget_->addItem(QString::fromStdString(name));
	}
}

void TwitchAutoTitleDialog::setStatus(const QString &text,
				      const QString &color)
{
	statusLabel_->setText(text);
	statusLabel_->setStyleSheet(
		QString("color: %1;").arg(color));
}

void TwitchAutoTitleDialog::applyTheme()
{
	if (!state_.darkMode) {
		setPalette(QApplication::style()->standardPalette());
		return;
	}

	QPalette dark;
	dark.setColor(QPalette::Window, QColor(30, 30, 30));
	dark.setColor(QPalette::WindowText, QColor(212, 212, 212));
	dark.setColor(QPalette::Base, QColor(45, 45, 45));
	dark.setColor(QPalette::AlternateBase, QColor(53, 53, 53));
	dark.setColor(QPalette::Text, QColor(212, 212, 212));
	dark.setColor(QPalette::Button, QColor(60, 60, 60));
	dark.setColor(QPalette::ButtonText, QColor(212, 212, 212));
	dark.setColor(QPalette::Highlight, QColor(38, 79, 120));
	dark.setColor(QPalette::HighlightedText, QColor(212, 212, 212));
	dark.setColor(QPalette::ToolTipBase, QColor(45, 45, 45));
	dark.setColor(QPalette::ToolTipText, QColor(212, 212, 212));
	setPalette(dark);
}

void TwitchAutoTitleDialog::checkForUpdate()
{
	auto *manager = new QNetworkAccessManager(this);
	QNetworkRequest request{
		QUrl(QString("https://api.github.com/repos/%1/"
			     "releases/latest")
			     .arg(kGithubRepo))};
	request.setRawHeader("Accept", "application/vnd.github+json");
	request.setHeader(QNetworkRequest::UserAgentHeader,
			  "twitch-auto-title-obs-plugin");

	QNetworkReply *reply = manager->get(request);
	connect(reply, &QNetworkReply::finished, this,
		[this, reply, manager]() {
			reply->deleteLater();
			manager->deleteLater();

			if (reply->error() != QNetworkReply::NoError) {
				return;
			}

			QJsonDocument doc = QJsonDocument::fromJson(
				reply->readAll());
			QString tag =
				doc.object()["tag_name"].toString();

			auto latest = parseVersion(tag);
			auto current = parseVersion(kAppVersion);

			if (latest > current) {
				QString latestStr =
					QString("%1.%2.%3")
						.arg(std::get<0>(latest))
						.arg(std::get<1>(latest))
						.arg(std::get<2>(latest));
				QMessageBox::information(
					this, "Update Available",
					QString("A new version %1 is available "
						"(current: %2).\n"
						"Visit the GitHub releases "
						"page to download it.")
						.arg(latestStr)
						.arg(kAppVersion));
			}
		});
}
