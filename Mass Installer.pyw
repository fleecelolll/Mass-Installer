import atexit
import codecs
import ctypes
import json
import os
import re
import shutil
import subprocess
import sys
import traceback
from collections import deque
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional


APP_TITLE = "Mass Installer"
APP_DIR = Path(__file__).resolve().parent
RUNTIME_DIR = APP_DIR / ".runtime"
LOGS_DIR = RUNTIME_DIR / "logs"
ICONS_DIR = APP_DIR / "assets" / "app-icons"
SETUP_LOCK_DIR = RUNTIME_DIR / "setup.lock"
SETUP_MARKER = RUNTIME_DIR / "setup-complete.txt"
VENV_PYTHON = APP_DIR / ".venv" / "Scripts" / "python.exe"
VENV_PYTHONW = APP_DIR / ".venv" / "Scripts" / "pythonw.exe"
EMBEDDED_PYTHON = RUNTIME_DIR / "python" / "python.exe"
EMBEDDED_PYTHONW = RUNTIME_DIR / "python" / "pythonw.exe"
PROFILE_KIND = "fleece.mass-installer.selection"
PROFILE_SCHEMA = 1
OFFICIAL_WINGET_SOURCE_URL = "https://cdn.winget.microsoft.com/cache"
OFFICIAL_WINGET_SOURCE_ID = "Microsoft.Winget.Source_8wekyb3d8bbwe"
OFFICIAL_WINGET_SOURCE_TYPE = "Microsoft.PreIndexed.Package"
WINGET_UPDATE_NOT_APPLICABLE = 0x8A15002B
APP_MUTEX_NAME = r"Local\FleeceMassInstallerApp"
ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]")
APP_MUTEX_HANDLE = None


def show_native_setup_error(message: str):
    if os.name == "nt":
        ctypes.windll.user32.MessageBoxW(None, message, APP_TITLE, 0x10)
    else:
        print(f"{APP_TITLE}: {message}", file=sys.stderr)


def release_app_mutex():
    global APP_MUTEX_HANDLE
    if APP_MUTEX_HANDLE is None or os.name != "nt":
        return
    close_handle = ctypes.windll.kernel32.CloseHandle
    close_handle.argtypes = [ctypes.c_void_p]
    close_handle.restype = ctypes.c_int
    close_handle(APP_MUTEX_HANDLE)
    APP_MUTEX_HANDLE = None


def acquire_app_mutex() -> bool:
    global APP_MUTEX_HANDLE
    if os.name != "nt":
        return True
    kernel32 = ctypes.windll.kernel32
    create_mutex = kernel32.CreateMutexW
    create_mutex.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_wchar_p]
    create_mutex.restype = ctypes.c_void_p
    close_handle = kernel32.CloseHandle
    close_handle.argtypes = [ctypes.c_void_p]
    close_handle.restype = ctypes.c_int
    kernel32.SetLastError(0)
    handle = create_mutex(None, False, APP_MUTEX_NAME)
    if not handle:
        return False
    if kernel32.GetLastError() == 183:
        close_handle(handle)
        return False
    APP_MUTEX_HANDLE = handle
    atexit.register(release_app_mutex)
    return True


def bootstrap_local_python():
    command_mode = any(
        argument in {"--self-test", "--screenshot"} for argument in sys.argv[1:]
    )
    try:
        setup_mode = SETUP_MARKER.read_text(encoding="ascii").strip().lower()
    except (OSError, UnicodeError):
        setup_mode = ""
    configured = {
        "venv": VENV_PYTHON if command_mode else VENV_PYTHONW,
        "embedded": EMBEDDED_PYTHON if command_mode else EMBEDDED_PYTHONW,
    }
    local_python = configured.get(setup_mode)
    if local_python is not None and not local_python.is_file():
        local_python = None
    current = os.path.normcase(os.path.realpath(sys.executable))
    if local_python is None and "--self-test" in sys.argv and sys.flags.isolated:
        setup_candidates = (VENV_PYTHON, EMBEDDED_PYTHON)
        if any(current == os.path.normcase(os.path.realpath(path)) for path in setup_candidates):
            return
    if local_python is None:
        show_native_setup_error(
            "Setup is missing or incomplete.\n\n"
            "Run Installer.bat, let every check finish, then open this file again."
        )
        raise SystemExit(1)

    expected = os.path.normcase(os.path.realpath(local_python))
    if current == expected and sys.flags.isolated:
        return

    try:
        subprocess.Popen(
            [str(local_python), "-I", str(Path(__file__).resolve()), *sys.argv[1:]],
            cwd=str(APP_DIR),
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )
    except OSError:
        show_native_setup_error(
            "The app's private Python could not start.\n\n"
            "Run Installer.bat again to repair the local setup."
        )
        raise SystemExit(1)
    raise SystemExit(0)


if __name__ == "__main__":
    bootstrap_local_python()


try:
    from PySide6.QtCore import (
        QAbstractAnimation,
        QEasingCurve,
        QEvent,
        QPoint,
        QPointF,
        QParallelAnimationGroup,
        QProcess,
        QPropertyAnimation,
        QRect,
        QRectF,
        QTimer,
        Qt,
        QUrl,
        QVariantAnimation,
        Signal,
    )
    from PySide6.QtGui import (
        QCloseEvent,
        QColor,
        QDesktopServices,
        QIcon,
        QMouseEvent,
        QPainter,
        QPen,
    )
    from PySide6.QtWidgets import (
        QApplication,
        QCheckBox,
        QFileDialog,
        QFrame,
        QGraphicsOpacityEffect,
        QGridLayout,
        QHBoxLayout,
        QLabel,
        QLineEdit,
        QMainWindow,
        QMessageBox,
        QPlainTextEdit,
        QProgressBar,
        QPushButton,
        QScrollArea,
        QSizePolicy,
        QStackedWidget,
        QVBoxLayout,
        QWidget,
    )
except Exception:
    if __name__ == "__main__":
        show_native_setup_error(
            "Setup is incomplete and the app window cannot load.\n\n"
            "Run Installer.bat again to repair the local setup."
        )
        raise SystemExit(1)
    raise


@dataclass(frozen=True)
class AppDefinition:
    category: str
    name: str
    package_id: str
    publisher: str
    description: str

    @property
    def searchable_text(self) -> str:
        return " ".join(
            (
                self.category,
                self.name,
                self.package_id,
                self.publisher,
                self.description,
            )
        ).lower()


APP_CATALOG = (
    AppDefinition("Browsers", "Google Chrome", "Google.Chrome", "Google", "Popular Chromium web browser."),
    AppDefinition("Browsers", "Mozilla Firefox", "Mozilla.Firefox", "Mozilla", "Independent, customizable web browser."),
    AppDefinition("Browsers", "Brave", "Brave.Brave", "Brave Software", "Privacy-focused Chromium browser."),
    AppDefinition("Browsers", "Vivaldi", "Vivaldi.Vivaldi", "Vivaldi Technologies", "Highly customizable power-user browser."),
    AppDefinition("Browsers", "Opera", "Opera.Opera", "Opera", "Chromium browser with built-in extras."),
    AppDefinition("Browsers", "Waterfox", "Waterfox.Waterfox", "Waterfox", "Firefox-based privacy browser."),
    AppDefinition("Browsers", "Zen Browser", "Zen-Team.Zen-Browser", "Zen Team", "Modern Firefox-based browser."),
    AppDefinition("Browsers", "Opera GX", "Opera.OperaGX", "Opera Software", "Gaming-focused browser with resource controls."),
    AppDefinition("Browsers", "DuckDuckGo", "DuckDuckGo.DesktopBrowser", "DuckDuckGo", "Privacy-protecting everyday web browser."),
    AppDefinition("Messaging", "Discord", "Discord.Discord", "Discord", "Voice, video, and community chat."),
    AppDefinition("Messaging", "Zoom", "Zoom.Zoom", "Zoom", "Video meetings and calls."),
    AppDefinition("Messaging", "Signal", "OpenWhisperSystems.Signal", "Signal", "Private encrypted messaging."),
    AppDefinition("Messaging", "Telegram", "Telegram.TelegramDesktop", "Telegram", "Cloud messaging desktop client."),
    AppDefinition("Messaging", "Slack", "SlackTechnologies.Slack", "Slack", "Team communication workspace."),
    AppDefinition("Messaging", "Microsoft Teams", "Microsoft.Teams", "Microsoft", "Meetings, chat, and collaboration."),
    AppDefinition("Messaging", "Mozilla Thunderbird", "Mozilla.Thunderbird", "Mozilla", "Email, calendar, and news client."),
    AppDefinition("Messaging", "Element", "Element.Element", "Element", "Secure Matrix messaging desktop client."),
    AppDefinition("Messaging", "Beeper", "Beeper.Beeper", "Beeper Inc.", "Bring multiple chat networks into one app."),
    AppDefinition("Downloads & sharing", "qBittorrent", "qBittorrent.qBittorrent", "The qBittorrent project", "Open-source BitTorrent download client."),
    AppDefinition("Downloads & sharing", "WinSCP", "WinSCP.WinSCP", "Martin Prikryl", "Secure file transfer and remote file manager."),
    AppDefinition("Downloads & sharing", "LocalSend", "LocalSend.LocalSend", "Tien Do Nam", "Private local-network file sharing."),
    AppDefinition("Gaming", "Steam", "Valve.Steam", "Valve", "PC game store and launcher."),
    AppDefinition("Gaming", "Epic Games Launcher", "EpicGames.EpicGamesLauncher", "Epic Games", "Epic game store and launcher."),
    AppDefinition("Gaming", "Ubisoft Connect", "Ubisoft.Connect", "Ubisoft", "Ubisoft games launcher."),
    AppDefinition("Gaming", "EA app", "ElectronicArts.EADesktop", "Electronic Arts", "EA game library and launcher."),
    AppDefinition("Gaming", "Battle.net", "Blizzard.BattleNet", "Blizzard", "Blizzard game launcher."),
    AppDefinition("Gaming", "GOG Galaxy", "GOG.Galaxy", "GOG", "DRM-free game library and launcher."),
    AppDefinition("Gaming", "itch", "ItchIo.Itch", "itch.io", "Indie game store and launcher."),
    AppDefinition("Gaming", "Prism Launcher", "PrismLauncher.PrismLauncher", "Prism Launcher", "Open-source Minecraft launcher."),
    AppDefinition("Gaming", "Playnite", "Playnite.Playnite", "Playnite", "Unified game library manager."),
    AppDefinition("Media", "VLC media player", "VideoLAN.VLC", "VideoLAN", "Flexible video and audio player."),
    AppDefinition("Media", "Spotify", "Spotify.Spotify", "Spotify", "Music streaming desktop app."),
    AppDefinition("Media", "OBS Studio", "OBSProject.OBSStudio", "OBS Project", "Recording and live streaming studio."),
    AppDefinition("Media", "Audacity", "Audacity.Audacity", "Audacity", "Audio recording and editing."),
    AppDefinition("Media", "HandBrake", "HandBrake.HandBrake", "HandBrake", "Video transcoder and compressor."),
    AppDefinition("Media", "foobar2000", "PeterPawlowski.foobar2000", "Peter Pawlowski", "Lightweight advanced music player."),
    AppDefinition("Media", "AIMP", "AIMP.AIMP", "AIMP", "Music player and audio library."),
    AppDefinition("Media", "K-Lite Codec Pack", "CodecGuide.K-LiteCodecPack.Standard", "Codec Guide", "Codecs and Media Player Classic."),
    AppDefinition("Media", "MediaMonkey", "VentisMedia.MediaMonkey.2024", "Ventis Media Inc.", "Organize, tag, and play large media libraries."),
    AppDefinition("Utilities", "7-Zip", "7zip.7zip", "Igor Pavlov", "Fast open-source archive utility."),
    AppDefinition("Utilities", "Microsoft PowerToys", "Microsoft.PowerToys", "Microsoft", "Advanced Windows productivity utilities."),
    AppDefinition("Utilities", "Everything", "voidtools.Everything", "voidtools", "Instant local filename search."),
    AppDefinition("Utilities", "ShareX", "ShareX.ShareX", "ShareX Team", "Screenshot, recording, and sharing tools."),
    AppDefinition("Utilities", "Notepad++", "Notepad++.Notepad++", "Notepad++ Team", "Fast text and source editor."),
    AppDefinition("Utilities", "Rufus", "Rufus.Rufus", "Rufus", "Create bootable USB drives."),
    AppDefinition("Utilities", "WinDirStat", "WinDirStat.WinDirStat", "WinDirStat", "Visual disk usage analyzer."),
    AppDefinition("Utilities", "WizTree", "AntibodySoftware.WizTree", "Antibody Software", "Fast disk space analyzer."),
    AppDefinition("Utilities", "CrystalDiskInfo", "CrystalDewWorld.CrystalDiskInfo", "Crystal Dew World", "Drive health and SMART information."),
    AppDefinition("Utilities", "CPU-Z", "CPUID.CPU-Z", "CPUID", "Processor and hardware information."),
    AppDefinition("Utilities", "HWiNFO", "REALiX.HWiNFO", "REALiX", "Detailed hardware monitoring."),
    AppDefinition("Utilities", "Revo Uninstaller", "RevoUninstaller.RevoUninstaller", "VS Revo Group", "Application removal and leftover cleanup."),
    AppDefinition("Utilities", "WinRAR", "RARLab.WinRAR", "win.rar GmbH", "Trialware archive manager and compression tool."),
    AppDefinition("Utilities", "Process Explorer", "Microsoft.Sysinternals.ProcessExplorer", "Sysinternals", "Advanced Windows process and handle viewer."),
    AppDefinition("Utilities", "CrystalDiskMark", "CrystalDewWorld.CrystalDiskMark", "Crystal Dew World", "Storage drive benchmark utility."),
    AppDefinition("Development", "Visual Studio Code", "Microsoft.VisualStudioCode", "Microsoft", "Extensible source code editor."),
    AppDefinition("Development", "Git", "Git.Git", "Git", "Distributed version control tools."),
    AppDefinition("Development", "GitHub Desktop", "GitHub.GitHubDesktop", "GitHub", "Desktop Git and GitHub client."),
    AppDefinition("Development", "Python 3.14", "Python.Python.3.14", "Python Software Foundation", "Python programming language."),
    AppDefinition("Development", "Node.js LTS", "OpenJS.NodeJS.LTS", "OpenJS Foundation", "Long-term-support JavaScript runtime."),
    AppDefinition("Development", "Postman", "Postman.Postman", "Postman", "API development and testing client."),
    AppDefinition("Development", "JetBrains Toolbox", "JetBrains.Toolbox", "JetBrains", "Install and manage JetBrains IDEs."),
    AppDefinition("Development", "Windows Terminal", "Microsoft.WindowsTerminal", "Microsoft", "Modern command-line terminal."),
    AppDefinition("Development", "Sublime Text 4", "SublimeHQ.SublimeText.4", "Sublime HQ Pty Ltd", "Fast editor for code, markup, and prose."),
    AppDefinition("Documents & cloud", "LibreOffice", "TheDocumentFoundation.LibreOffice", "The Document Foundation", "Free office productivity suite."),
    AppDefinition("Documents & cloud", "SumatraPDF", "SumatraPDF.SumatraPDF", "SumatraPDF", "Lightweight PDF and ebook reader."),
    AppDefinition("Documents & cloud", "Obsidian", "Obsidian.Obsidian", "Obsidian", "Local Markdown notes and knowledge base."),
    AppDefinition("Documents & cloud", "Bitwarden", "Bitwarden.Bitwarden", "Bitwarden", "Open-source password manager."),
    AppDefinition("Documents & cloud", "Dropbox", "Dropbox.Dropbox", "Dropbox", "Cloud file sync client."),
    AppDefinition("Documents & cloud", "Google Drive", "Google.GoogleDrive", "Google", "Google cloud storage sync client."),
    AppDefinition("Documents & cloud", "Microsoft OneDrive", "Microsoft.OneDrive", "Microsoft", "Microsoft cloud storage sync client."),
    AppDefinition("Documents & cloud", "Adobe Acrobat Reader", "Adobe.Acrobat.Reader.64-bit", "Adobe", "View, sign, and annotate PDF documents."),
    AppDefinition("Documents & cloud", "Notion", "Notion.Notion", "Notion Labs, Inc.", "Notes, documents, projects, and workspaces."),
    AppDefinition("Creative", "GIMP", "GIMP.GIMP.3", "GIMP", "Open-source image editor."),
    AppDefinition("Creative", "Krita", "KDE.Krita", "KDE", "Digital painting and illustration."),
    AppDefinition("Creative", "Blender", "BlenderFoundation.Blender", "Blender Foundation", "3D modeling and creation suite."),
    AppDefinition("Creative", "Inkscape", "Inkscape.Inkscape", "Inkscape", "Open-source vector graphics editor."),
    AppDefinition("Creative", "Paint.NET", "dotPDN.PaintDotNet", "dotPDN", "Windows image and photo editor."),
    AppDefinition("Creative", "Kdenlive", "KDE.Kdenlive", "KDE e.V.", "Open-source non-linear video editor."),
)

CATEGORY_ORDER = (
    "Browsers",
    "Messaging",
    "Downloads & sharing",
    "Gaming",
    "Media",
    "Utilities",
    "Development",
    "Documents & cloud",
    "Creative",
)

MIN_WINGET_VERSION = (1, 6)

APP_BY_ID = {app.package_id: app for app in APP_CATALOG}

ICON_SLUG_BY_PACKAGE = {
    "Google.Chrome": "googlechrome",
    "Mozilla.Firefox": "firefoxbrowser",
    "Brave.Brave": "brave",
    "Vivaldi.Vivaldi": "vivaldi",
    "Opera.Opera": "opera",
    "Zen-Team.Zen-Browser": "zenbrowser",
    "Opera.OperaGX": "operagx",
    "DuckDuckGo.DesktopBrowser": "duckduckgo",
    "Discord.Discord": "discord",
    "Zoom.Zoom": "zoom",
    "OpenWhisperSystems.Signal": "signal",
    "Telegram.TelegramDesktop": "telegram",
    "Mozilla.Thunderbird": "thunderbird",
    "Element.Element": "element",
    "qBittorrent.qBittorrent": "qbittorrent",
    "LocalSend.LocalSend": "localsend",
    "Valve.Steam": "steam",
    "EpicGames.EpicGamesLauncher": "epicgames",
    "Ubisoft.Connect": "ubisoft",
    "ElectronicArts.EADesktop": "ea",
    "Blizzard.BattleNet": "battledotnet",
    "GOG.Galaxy": "gogdotcom",
    "ItchIo.Itch": "itchdotio",
    "VideoLAN.VLC": "vlcmediaplayer",
    "Spotify.Spotify": "spotify",
    "OBSProject.OBSStudio": "obsstudio",
    "Audacity.Audacity": "audacity",
    "PeterPawlowski.foobar2000": "foobar2000",
    "7zip.7zip": "7zip",
    "ShareX.ShareX": "sharex",
    "Notepad++.Notepad++": "notepadplusplus",
    "Git.Git": "git",
    "GitHub.GitHubDesktop": "github",
    "Python.Python.3.14": "python",
    "OpenJS.NodeJS.LTS": "nodedotjs",
    "Postman.Postman": "postman",
    "JetBrains.Toolbox": "jetbrains",
    "SublimeHQ.SublimeText.4": "sublimetext",
    "TheDocumentFoundation.LibreOffice": "libreoffice",
    "Obsidian.Obsidian": "obsidian",
    "Bitwarden.Bitwarden": "bitwarden",
    "Dropbox.Dropbox": "dropbox",
    "Google.GoogleDrive": "googledrive",
    "Notion.Notion": "notion",
    "GIMP.GIMP.3": "gimp",
    "KDE.Krita": "krita",
    "BlenderFoundation.Blender": "blender",
    "Inkscape.Inkscape": "inkscape",
    "KDE.Kdenlive": "kdenlive",
}

ICON_PIXMAP_CACHE = {}


def handle_unhandled_exception(error_type, error, trace):
    try:
        RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
        (RUNTIME_DIR / "error.log").write_text(
            "".join(traceback.format_exception(error_type, error, trace)),
            encoding="utf-8",
        )
    except OSError:
        pass
    show_native_setup_error(
        "The app stopped because of an unexpected error.\n\n"
        "Run Installer.bat again. If it continues, review .runtime\\error.log."
    )
    application = QApplication.instance()
    if application is not None:
        application.quit()


def badge_text(name: str) -> str:
    special = {"7-Zip": "7Z", "Notepad++": "N+", "CPU-Z": "CZ", "Paint.NET": "P."}
    if name in special:
        return special[name]
    words = re.findall(r"[A-Za-z0-9]+", name)
    if not words:
        return "AP"
    if len(words) == 1:
        return words[0][:2].upper()
    return (words[0][0] + words[1][0]).upper()


def app_icon_pixmap(app_definition: AppDefinition):
    slug = ICON_SLUG_BY_PACKAGE.get(app_definition.package_id)
    if slug is None:
        return None
    if slug not in ICON_PIXMAP_CACHE:
        icon_path = ICONS_DIR / f"{slug}.svg"
        icon = QIcon(str(icon_path)) if icon_path.is_file() else QIcon()
        pixmap = icon.pixmap(19, 19)
        ICON_PIXMAP_CACHE[slug] = None if pixmap.isNull() else pixmap
    return ICON_PIXMAP_CACHE[slug]


def make_app_badge(app_definition: AppDefinition) -> QLabel:
    badge = QLabel(badge_text(app_definition.name))
    badge.setObjectName("appBadge")
    badge.setFixedSize(30, 30)
    badge.setAlignment(Qt.AlignCenter)
    pixmap = app_icon_pixmap(app_definition)
    if pixmap is not None:
        badge.setText("")
        badge.setPixmap(pixmap)
    badge.setToolTip(app_definition.name)
    return badge


def validated_profile_packages(payload) -> list[str]:
    if not isinstance(payload, dict):
        raise ValueError("This is not a supported Fleece selection file.")
    schema = payload.get("schema")
    if type(schema) is not int or schema != PROFILE_SCHEMA or payload.get("kind") != PROFILE_KIND:
        raise ValueError("This is not a supported Fleece selection file.")
    packages = payload.get("packages")
    if not isinstance(packages, list) or not all(isinstance(value, str) for value in packages):
        raise ValueError("The package list is invalid.")
    return packages


class TrafficLightButton(QPushButton):
    def __init__(self, color_name: str, tooltip: str, parent=None):
        super().__init__(parent)
        self.setObjectName(color_name)
        self.setToolTip(tooltip)
        self.setFixedSize(13, 13)
        self.setCursor(Qt.PointingHandCursor)


class TitleBar(QFrame):
    def __init__(self, host):
        super().__init__(host)
        self.host = host
        self.drag_offset = QPoint()
        self.setObjectName("titleBar")
        self.setFixedHeight(38)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(14, 0, 14, 0)
        layout.setSpacing(8)

        maximize_button = TrafficLightButton("maximizeDot", "Maximize")
        minimize_button = TrafficLightButton("minimizeDot", "Minimize")
        close_button = TrafficLightButton("closeDot", "Close")
        close_button.clicked.connect(host.close)
        minimize_button.clicked.connect(host.showMinimized)
        maximize_button.clicked.connect(self.toggle_maximized)

        controls = QHBoxLayout()
        controls.setContentsMargins(0, 0, 0, 0)
        controls.setSpacing(8)
        controls.addWidget(maximize_button)
        controls.addWidget(minimize_button)
        controls.addWidget(close_button)
        controls_holder = QWidget()
        controls_holder.setFixedWidth(64)
        controls_holder.setLayout(controls)

        title = QLabel(APP_TITLE)
        title.setObjectName("windowTitle")
        title.setAlignment(Qt.AlignCenter)
        left_spacer = QWidget()
        left_spacer.setFixedWidth(64)

        layout.addWidget(left_spacer)
        layout.addStretch()
        layout.addWidget(title)
        layout.addStretch()
        layout.addWidget(controls_holder)

    def toggle_maximized(self):
        self.host.showNormal() if self.host.isMaximized() else self.host.showMaximized()

    def mouseDoubleClickEvent(self, event: QMouseEvent):
        if event.button() == Qt.LeftButton:
            self.toggle_maximized()
            event.accept()

    def mousePressEvent(self, event: QMouseEvent):
        if event.button() == Qt.LeftButton:
            self.drag_offset = event.globalPosition().toPoint() - self.host.frameGeometry().topLeft()
            event.accept()

    def mouseMoveEvent(self, event: QMouseEvent):
        if event.buttons() & Qt.LeftButton and not self.host.isMaximized():
            self.host.move(event.globalPosition().toPoint() - self.drag_offset)
            event.accept()


class ChevronButton(QPushButton):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._chevron_progress = 0.0
        self._chevron_animation = QVariantAnimation(self)
        self._chevron_animation.setDuration(120)
        self._chevron_animation.setEasingCurve(QEasingCurve.OutCubic)
        self._chevron_animation.valueChanged.connect(self._set_chevron_progress)

    def _set_chevron_progress(self, value):
        self._chevron_progress = float(value)
        self.update()

    def set_expanded(self, expanded: bool):
        target = 1.0 if expanded else 0.0
        self._chevron_animation.stop()
        self._chevron_animation.setStartValue(self._chevron_progress)
        self._chevron_animation.setEndValue(target)
        self._chevron_animation.start()

    def paintEvent(self, event):
        super().paintEvent(event)
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setPen(QPen(Qt.white, 1.4))
        x = self.width() - 20
        y = self.height() // 2 - 1
        edge_y = y - 2 + 4 * self._chevron_progress
        center_y = y + 2 - 4 * self._chevron_progress
        painter.drawLine(QPointF(x - 4, edge_y), QPointF(x, center_y))
        painter.drawLine(QPointF(x, center_y), QPointF(x + 4, edge_y))


class AnimatedDropdown(QWidget):
    changed = Signal(str)

    @staticmethod
    def display_text(value: str) -> str:
        return value.replace("&", "&&")

    def __init__(self, items, current_index=0, parent=None):
        super().__init__(parent)
        self.items = list(items)
        self._current = self.items[current_index]
        self._animation = None
        self._popup_direction = 1
        self.option_buttons = []
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        self.button = ChevronButton(self.display_text(self._current))
        self.button.setAccessibleName(self._current)
        self.button.setObjectName("dropdownButton")
        self.button.setMinimumHeight(38)
        self.button.clicked.connect(self.toggle_popup)
        layout.addWidget(self.button)

        self.popup = QFrame(None, Qt.Tool | Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint)
        self.popup.setObjectName("dropdownPopup")
        self.popup.setAttribute(Qt.WA_TranslucentBackground)
        outer = QVBoxLayout(self.popup)
        outer.setContentsMargins(0, 0, 0, 0)
        surface = QFrame()
        surface.setObjectName("dropdownSurface")
        surface_layout = QVBoxLayout(surface)
        surface_layout.setContentsMargins(5, 5, 5, 5)
        surface_layout.setSpacing(2)
        for item in self.items:
            option = QPushButton(self.display_text(item))
            option.setAccessibleName(item)
            option.setObjectName("dropdownOption")
            option.setMinimumHeight(32)
            option.clicked.connect(lambda checked=False, value=item: self.select(value))
            surface_layout.addWidget(option)
            self.option_buttons.append(option)
        outer.addWidget(surface)
        self.opacity_effect = QGraphicsOpacityEffect(self.popup)
        self.popup.setGraphicsEffect(self.opacity_effect)

    def currentText(self):
        return self._current

    def select(self, value):
        if value not in self.items:
            return
        self._current = value
        self.button.setText(self.display_text(value))
        self.button.setAccessibleName(value)
        self.changed.emit(value)
        self.hide_popup()

    def toggle_popup(self):
        self.hide_popup() if self.popup.isVisible() else self.show_popup()

    def show_popup(self):
        self._stop_popup_animation()
        popup_height = len(self.items) * 34 + 12
        popup_width = self.width()
        top_left = self.mapToGlobal(QPoint(0, 0))
        below_y = top_left.y() + self.height() + 4
        screen = QApplication.screenAt(top_left)
        available = screen.availableGeometry() if screen else QRect()
        final_y = below_y
        start_y = final_y - 8
        if available and below_y + popup_height > available.bottom():
            final_y = top_left.y() - popup_height - 4
            start_y = final_y + 8
            self._popup_direction = -1
        else:
            self._popup_direction = 1
        final_x = top_left.x()
        if available and final_x + popup_width > available.right():
            final_x = available.right() - popup_width
        final_x = max(available.left(), final_x) if available else final_x
        end_rect = QRect(final_x, final_y, popup_width, popup_height)
        start_rect = QRect(final_x, start_y, popup_width, popup_height)
        QApplication.instance().installEventFilter(self)
        self.popup.setGeometry(start_rect)
        self.opacity_effect.setOpacity(0.0)
        self.popup.show()
        self.popup.raise_()
        self.button.set_expanded(True)
        geometry = QPropertyAnimation(self.popup, b"geometry")
        geometry.setDuration(150)
        geometry.setStartValue(start_rect)
        geometry.setEndValue(end_rect)
        geometry.setEasingCurve(QEasingCurve.OutCubic)
        opacity = QPropertyAnimation(self.opacity_effect, b"opacity")
        opacity.setDuration(150)
        opacity.setStartValue(0.0)
        opacity.setEndValue(1.0)
        opacity.setEasingCurve(QEasingCurve.OutCubic)
        group = QParallelAnimationGroup()
        group.addAnimation(geometry)
        group.addAnimation(opacity)
        self._animation = group
        group.finished.connect(lambda current=group: self._popup_animation_finished(current, False))
        group.start()
        try:
            selected_index = self.items.index(self._current)
        except ValueError:
            selected_index = 0
        self.option_buttons[selected_index].setFocus(Qt.PopupFocusReason)

    def hide_popup(self):
        if not self.popup.isVisible():
            return
        self._stop_popup_animation()
        QApplication.instance().removeEventFilter(self)
        current = self.popup.geometry()
        end_rect = QRect(
            current.x(),
            current.y() - (5 * self._popup_direction),
            current.width(),
            current.height(),
        )
        geometry = QPropertyAnimation(self.popup, b"geometry")
        geometry.setDuration(100)
        geometry.setStartValue(current)
        geometry.setEndValue(end_rect)
        geometry.setEasingCurve(QEasingCurve.InCubic)
        opacity = QPropertyAnimation(self.opacity_effect, b"opacity")
        opacity.setDuration(100)
        opacity.setStartValue(self.opacity_effect.opacity())
        opacity.setEndValue(0.0)
        opacity.setEasingCurve(QEasingCurve.InCubic)
        group = QParallelAnimationGroup()
        group.addAnimation(geometry)
        group.addAnimation(opacity)
        self._animation = group
        self.button.set_expanded(False)
        group.finished.connect(lambda current=group: self._popup_animation_finished(current, True))
        group.start()

    def _stop_popup_animation(self):
        if self._animation is None:
            return
        animation = self._animation
        self._animation = None
        animation.stop()
        animation.deleteLater()

    def _popup_animation_finished(self, animation, hide_after: bool):
        if self._animation is animation:
            self._animation = None
        if hide_after:
            self.popup.hide()
            self.button.setFocus(Qt.PopupFocusReason)
        animation.deleteLater()

    def eventFilter(self, watched, event):
        if self.popup.isVisible() and event.type() == QEvent.MouseButtonPress:
            position = event.globalPosition().toPoint()
            popup_rect = self.popup.frameGeometry()
            button_rect = QRect(self.button.mapToGlobal(QPoint(0, 0)), self.button.size())
            if not popup_rect.contains(position) and not button_rect.contains(position):
                self.hide_popup()
        elif self.popup.isVisible() and event.type() in {QEvent.ApplicationDeactivate, QEvent.WindowDeactivate}:
            self.hide_popup()
        elif self.popup.isVisible() and event.type() == QEvent.KeyPress and event.key() == Qt.Key_Escape:
            self.hide_popup()
            return True
        return super().eventFilter(watched, event)


class SmoothScrollArea(QScrollArea):
    """A scroll area with short, retargetable wheel animations."""

    def __init__(self, parent=None):
        super().__init__(parent)
        bar = self.verticalScrollBar()
        bar.setSingleStep(32)
        self._scroll_target = float(bar.value())
        self._scroll_animation = QPropertyAnimation(bar, b"value", self)
        self._scroll_animation.setEasingCurve(QEasingCurve.OutCubic)
        self._scroll_animation.finished.connect(self._sync_scroll_target)
        bar.sliderPressed.connect(self._stop_and_sync_scroll)
        bar.actionTriggered.connect(self._stop_and_sync_scroll)
        bar.rangeChanged.connect(self._stop_and_sync_scroll)

    def _sync_scroll_target(self, *args):
        self._scroll_target = float(self.verticalScrollBar().value())

    def _stop_and_sync_scroll(self, *args):
        self._scroll_animation.stop()
        self._sync_scroll_target()

    def scroll_to_top(self):
        self._scroll_animation.stop()
        bar = self.verticalScrollBar()
        bar.setValue(bar.minimum())
        self._sync_scroll_target()

    def wheelEvent(self, event):
        bar = self.verticalScrollBar()
        if bar.maximum() <= bar.minimum():
            super().wheelEvent(event)
            return

        if event.phase() == Qt.ScrollPhase.ScrollBegin:
            self._stop_and_sync_scroll()
        pixel_y = event.pixelDelta().y()
        angle_y = event.angleDelta().y()
        if pixel_y:
            # Precision touchpads already provide smooth, high-frequency movement.
            self._stop_and_sync_scroll()
            super().wheelEvent(event)
            self._sync_scroll_target()
            return
        if angle_y:
            lines = QApplication.wheelScrollLines()
            distance = bar.pageStep() if lines < 0 else max(1, lines or 3) * bar.singleStep()
            offset = -(angle_y / 120.0) * distance
            duration = 170
        else:
            if event.phase() == Qt.ScrollPhase.ScrollEnd:
                event.accept()
            else:
                super().wheelEvent(event)
            return

        current = float(bar.value())
        running = self._scroll_animation.state() == QAbstractAnimation.State.Running
        pending = self._scroll_target - current
        base = self._scroll_target if running and pending * offset >= 0 else current
        target = max(float(bar.minimum()), min(float(bar.maximum()), base + offset))
        if running and abs(target - self._scroll_target) < 0.5:
            event.accept()
            return
        if abs(target - current) < 0.5:
            self._sync_scroll_target()
            event.ignore()
            return

        self._scroll_animation.stop()
        self._scroll_animation.setDuration(duration)
        self._scroll_animation.setStartValue(bar.value())
        self._scroll_animation.setEndValue(round(target))
        self._scroll_target = target
        self._scroll_animation.start()
        event.accept()


class AnimatedCheckBox(QCheckBox):
    """A fully custom rounded checkbox with a smooth fill and drawn tick."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setTristate(False)
        self.setCursor(Qt.PointingHandCursor)
        self.setFocusPolicy(Qt.StrongFocus)
        self.setFixedSize(22, 22)
        self._progress = 0.0
        self._hovered = False
        self._animation = QVariantAnimation(self)
        self._animation.setEasingCurve(QEasingCurve.OutCubic)
        self._animation.valueChanged.connect(self._set_progress)
        self.toggled.connect(self._animate_state)

    @staticmethod
    def _mix(first: QColor, second: QColor, amount: float) -> QColor:
        amount = max(0.0, min(1.0, amount))
        return QColor.fromRgbF(
            first.redF() + (second.redF() - first.redF()) * amount,
            first.greenF() + (second.greenF() - first.greenF()) * amount,
            first.blueF() + (second.blueF() - first.blueF()) * amount,
            first.alphaF() + (second.alphaF() - first.alphaF()) * amount,
        )

    def _set_progress(self, value):
        self._progress = float(value)
        self.update()

    def _animate_state(self, checked: bool):
        target = 1.0 if checked else 0.0
        self._animation.stop()
        self._animation.setStartValue(self._progress)
        self._animation.setEndValue(target)
        self._animation.setDuration(round(125 + 55 * abs(target - self._progress)))
        self._animation.start()

    def enterEvent(self, event):
        self._hovered = True
        self.update()
        super().enterEvent(event)

    def leaveEvent(self, event):
        self._hovered = False
        self.update()
        super().leaveEvent(event)

    def focusInEvent(self, event):
        self.update()
        super().focusInEvent(event)

    def focusOutEvent(self, event):
        self.update()
        super().focusOutEvent(event)

    @staticmethod
    def _point_between(start: QPointF, end: QPointF, amount: float) -> QPointF:
        return QPointF(
            start.x() + (end.x() - start.x()) * amount,
            start.y() + (end.y() - start.y()) * amount,
        )

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        if not self.isEnabled():
            painter.setOpacity(0.45)

        if self.hasFocus():
            focus_pen = QPen(QColor("#9a9a9a"), 1.0)
            painter.setPen(focus_pen)
            painter.setBrush(Qt.NoBrush)
            painter.drawRoundedRect(QRectF(0.75, 0.75, 20.5, 20.5), 6.5, 6.5)

        progress = max(0.0, min(1.0, self._progress))
        unchecked_fill = QColor("#111111" if self._hovered else "#0b0b0b")
        unchecked_border = QColor("#737373" if self._hovered else "#484848")
        fill = self._mix(unchecked_fill, QColor("#ffffff"), progress)
        border = self._mix(unchecked_border, QColor("#ffffff"), progress)
        indicator = QRectF(2.0, 2.0, 18.0, 18.0)
        painter.setPen(QPen(border, 1.15))
        painter.setBrush(fill)
        painter.drawRoundedRect(indicator, 5.5, 5.5)

        tick_progress = max(0.0, min(1.0, (progress - 0.28) / 0.72))
        if tick_progress <= 0.0:
            return
        first = QPointF(6.0, 10.8)
        middle = QPointF(9.2, 13.7)
        last = QPointF(15.8, 6.5)
        tick_pen = QPen(QColor("#101010"), 2.0)
        tick_pen.setCapStyle(Qt.RoundCap)
        tick_pen.setJoinStyle(Qt.RoundJoin)
        painter.setPen(tick_pen)
        first_share = 0.36
        if tick_progress < first_share:
            painter.drawLine(first, self._point_between(first, middle, tick_progress / first_share))
        else:
            painter.drawLine(first, middle)
            painter.drawLine(
                middle,
                self._point_between(middle, last, (tick_progress - first_share) / (1.0 - first_share)),
            )


class ElidedLabel(QLabel):
    """A single-line label that keeps narrow layouts readable."""

    def __init__(self, text: str, parent=None):
        super().__init__(parent)
        self.full_text = text
        self.setToolTip(text)
        self.setSizePolicy(QSizePolicy.Ignored, QSizePolicy.Preferred)
        self._update_elision()

    def _update_elision(self):
        width = max(0, self.contentsRect().width())
        elided = self.fontMetrics().elidedText(self.full_text, Qt.ElideRight, width)
        if self.text() != elided:
            self.setText(elided)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        self._update_elision()

    def changeEvent(self, event):
        super().changeEvent(event)
        if event.type() == QEvent.FontChange:
            self._update_elision()


class AppRow(QFrame):
    toggled = Signal(str, bool)

    def __init__(self, app_definition: AppDefinition, parent=None):
        super().__init__(parent)
        self.app_definition = app_definition
        self.setObjectName("appRow")
        self.setProperty("selected", False)
        self.setCursor(Qt.PointingHandCursor)
        self.setToolTip(f"{app_definition.publisher}\n{app_definition.package_id}")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(9, 7, 9, 7)
        layout.setSpacing(9)
        badge = make_app_badge(app_definition)
        text_column = QVBoxLayout()
        text_column.setContentsMargins(0, 0, 0, 0)
        text_column.setSpacing(1)
        name = ElidedLabel(app_definition.name)
        name.setObjectName("appName")
        detail = ElidedLabel(app_definition.description)
        detail.setObjectName("appDescription")
        detail.setWordWrap(False)
        text_column.addWidget(name)
        text_column.addWidget(detail)
        self.checkbox = AnimatedCheckBox()
        self.checkbox.setAccessibleName(f"Select {app_definition.name}")
        self.checkbox.toggled.connect(self._state_changed)
        layout.addWidget(badge)
        layout.addLayout(text_column, 1)
        layout.addWidget(self.checkbox)

    def _state_changed(self, checked: bool):
        self.setProperty("selected", checked)
        self.style().unpolish(self)
        self.style().polish(self)
        self.toggled.emit(self.app_definition.package_id, checked)

    def isChecked(self):
        return self.checkbox.isChecked()

    def setChecked(self, checked: bool):
        self.checkbox.setChecked(checked)

    def mouseReleaseEvent(self, event: QMouseEvent):
        if event.button() == Qt.LeftButton and self.isEnabled():
            self.checkbox.setFocus(Qt.MouseFocusReason)
            self.checkbox.toggle()
            event.accept()
            return
        super().mouseReleaseEvent(event)


class CategoryCard(QFrame):
    toggle_requested = Signal(str)

    def __init__(self, category: str, rows: list[AppRow], parent=None):
        super().__init__(parent)
        self.category = category
        self.rows = rows
        self.setObjectName("categoryCard")
        layout = QVBoxLayout(self)
        layout.setContentsMargins(11, 10, 11, 11)
        layout.setSpacing(4)
        header = QHBoxLayout()
        title = QLabel(category)
        title.setObjectName("categoryTitle")
        self.count_label = QLabel(str(len(rows)))
        self.count_label.setObjectName("categoryCount")
        self.toggle_button = QPushButton("select all")
        self.toggle_button.setObjectName("tiny")
        self.toggle_button.clicked.connect(lambda: self.toggle_requested.emit(category))
        header.addWidget(title)
        header.addWidget(self.count_label)
        header.addStretch()
        header.addWidget(self.toggle_button)
        layout.addLayout(header)
        self.apps_grid = QGridLayout()
        self.apps_grid.setContentsMargins(0, 0, 0, 0)
        self.apps_grid.setHorizontalSpacing(8)
        self.apps_grid.setVerticalSpacing(4)
        for column in range(3):
            self.apps_grid.setColumnStretch(column, 1)
        layout.addLayout(self.apps_grid)
        self._visible_package_ids = None
        self.reflow(rows)

    def reflow(self, visible_rows):
        visible_rows = list(visible_rows)
        visible_package_ids = tuple(row.app_definition.package_id for row in visible_rows)
        if visible_package_ids == self._visible_package_ids:
            return
        self._visible_package_ids = visible_package_ids
        while self.apps_grid.count():
            self.apps_grid.takeAt(0)
        for index, row in enumerate(visible_rows):
            self.apps_grid.addWidget(row, index // 3, index % 3)

    def update_state(self, selected: int, visible: int, selected_visible: int):
        if visible < len(self.rows):
            self.count_label.setText(
                f"{selected_visible}/{visible} shown" if selected_visible else f"{visible} shown"
            )
            self.toggle_button.setText(
                "clear shown" if visible and selected_visible == visible else "select shown"
            )
        else:
            self.count_label.setText(f"{selected}/{len(self.rows)}" if selected else str(visible))
            self.toggle_button.setText("clear" if selected == len(self.rows) else "select all")
        self.toggle_button.setEnabled(visible > 0)


class ReviewRow(QFrame):
    remove_requested = Signal(str)

    def __init__(self, app_definition: AppDefinition, parent=None):
        super().__init__(parent)
        self.setObjectName("reviewRow")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(11, 8, 11, 8)
        layout.setSpacing(10)
        badge = make_app_badge(app_definition)
        text_column = QVBoxLayout()
        text_column.setSpacing(1)
        name = ElidedLabel(app_definition.name)
        name.setObjectName("appName")
        metadata = ElidedLabel(f"{app_definition.publisher}  ·  {app_definition.package_id}")
        metadata.setObjectName("appDescription")
        text_column.addWidget(name)
        text_column.addWidget(metadata)
        remove = QPushButton("Remove")
        remove.setObjectName("small")
        remove.clicked.connect(lambda: self.remove_requested.emit(app_definition.package_id))
        layout.addWidget(badge)
        layout.addLayout(text_column, 1)
        layout.addWidget(remove)


class QueueRow(QFrame):
    def __init__(self, app_definition: AppDefinition, parent=None):
        super().__init__(parent)
        self.setObjectName("queueRow")
        layout = QHBoxLayout(self)
        layout.setContentsMargins(11, 8, 11, 8)
        layout.setSpacing(10)
        badge = make_app_badge(app_definition)
        text_column = QVBoxLayout()
        text_column.setSpacing(1)
        name = ElidedLabel(app_definition.name)
        name.setObjectName("appName")
        package_id = ElidedLabel(app_definition.package_id)
        package_id.setObjectName("appDescription")
        text_column.addWidget(name)
        text_column.addWidget(package_id)
        self.status = QLabel("Waiting")
        self.status.setObjectName("queueStatus")
        self.status.setProperty("state", "waiting")
        self.status.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
        layout.addWidget(badge)
        layout.addLayout(text_column, 1)
        layout.addWidget(self.status)

    def set_status(self, text: str, state: str):
        self.status.setText(text)
        self.status.setProperty("state", state)
        self.status.style().unpolish(self.status)
        self.status.style().polish(self.status)


class MassInstaller(QMainWindow):
    SELECT_PAGE = 0
    REVIEW_PAGE = 1
    INSTALL_PAGE = 2
    RESULTS_PAGE = 3

    def __init__(self):
        super().__init__()
        self.setWindowTitle(APP_TITLE)
        self.setWindowFlags(Qt.Window | Qt.FramelessWindowHint)
        self.setAttribute(Qt.WA_TranslucentBackground)
        screen = QApplication.primaryScreen()
        available = screen.availableGeometry() if screen is not None else QRect(0, 0, 1120, 760)
        usable_width = max(1, available.width() - 32)
        usable_height = max(1, available.height() - 32)
        self.resize(min(1120, usable_width), min(760, usable_height))
        self.setMinimumSize(min(1010, usable_width), min(640, usable_height))

        self.selected_ids: set[str] = set()
        self.selection_batching = False
        self.app_rows: dict[str, AppRow] = {}
        self.category_cards: dict[str, CategoryCard] = {}
        self.review_rows: dict[str, ReviewRow] = {}
        self.queue_rows: dict[str, QueueRow] = {}
        self.results: dict[str, tuple[str, str]] = {}
        self.failed_ids: list[str] = []
        self.install_queue: deque[AppDefinition] = deque()
        self.current_app: Optional[AppDefinition] = None
        self.process: Optional[QProcess] = None
        self.process_decoder = None
        self.process_line_buffer = ""
        self.current_output_lines: list[str] = []
        self.install_active = False
        self.stop_after_current = False
        self.force_stopping = False
        self.total_jobs = 0
        self.completed_jobs = 0
        self.session_log_path: Optional[Path] = None
        self.winget_path = self.find_winget()
        self.winget_ready = False
        self.winget_version = "checking"
        self.winget_supports_no_progress = False
        self.preflight_process: Optional[QProcess] = None
        self.preflight_stage = ""
        self.preflight_version_candidate = ""
        self.page_animation = None
        self.page_animation_widget = None

        self.preflight_timer = QTimer(self)
        self.preflight_timer.setSingleShot(True)
        self.preflight_timer.timeout.connect(self.preflight_timed_out)
        self.next_install_timer = QTimer(self)
        self.next_install_timer.setSingleShot(True)
        self.next_install_timer.timeout.connect(self.start_next_install)

        try:
            RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
            LOGS_DIR.mkdir(parents=True, exist_ok=True)
        except OSError:
            pass

        self.apply_style()
        self.build_ui()
        self.update_selection_ui()
        if "--self-test" not in sys.argv:
            QTimer.singleShot(0, self.start_winget_preflight)

    @staticmethod
    def find_winget() -> Optional[Path]:
        if os.name == "nt":
            local_data = os.environ.get("LOCALAPPDATA")
            if not local_data:
                return None
            candidate = Path(local_data) / "Microsoft" / "WindowsApps" / "winget.exe"
            return candidate if candidate.is_file() else None
        located = shutil.which("winget")
        if located:
            return Path(located)
        return None

    def apply_style(self):
        QApplication.instance().setStyleSheet(
            """
            QWidget { color: #f5f5f5; font-family: "Segoe UI"; font-size: 13px; }
            QFrame#windowFrame { background: #070707; border: 1px solid #252525; border-radius: 14px; }
            QFrame#titleBar { background: #070707; border: none; border-bottom: 1px solid #1c1c1c; border-top-left-radius: 14px; border-top-right-radius: 14px; }
            QLabel#windowTitle { color: #bdbdbd; font-size: 12px; font-weight: 600; }
            QPushButton#closeDot, QPushButton#minimizeDot, QPushButton#maximizeDot { border: none; border-radius: 6px; min-height: 13px; max-height: 13px; min-width: 13px; max-width: 13px; padding: 0; }
            QPushButton#closeDot { background: #ff5f57; }
            QPushButton#minimizeDot { background: #febc2e; }
            QPushButton#maximizeDot { background: #28c840; }
            QPushButton#closeDot:hover, QPushButton#minimizeDot:hover, QPushButton#maximizeDot:hover { border: 1px solid rgba(0, 0, 0, 90); }
            QFrame#panel { background: #0d0d0d; border: 1px solid #242424; border-radius: 14px; }
            QLabel#pageHeading { color: #ffffff; font-size: 20px; font-weight: 650; }
            QLabel#pageDescription, QLabel#note { color: #858585; font-size: 11px; }
            QLabel#label { color: #b8b8b8; font-size: 12px; font-weight: 600; }
            QLabel#status { color: #8b8b8b; font-size: 12px; }
            QLabel#step { color: #777777; font-size: 11px; font-weight: 600; padding: 0 3px; }
            QLabel#step[active="true"] { color: #ffffff; }
            QLabel#stepSeparator { color: #333333; font-size: 11px; }
            QLineEdit { background: #0a0a0a; border: 1px solid #292929; border-radius: 10px; min-height: 38px; padding: 0 12px; selection-background-color: #ffffff; selection-color: #000000; }
            QLineEdit:focus { border-color: #ffffff; }
            QPushButton { background: #151515; border: 1px solid #2b2b2b; border-radius: 10px; min-height: 38px; padding: 0 14px; font-weight: 600; }
            QPushButton:hover { background: #1d1d1d; border-color: #3a3a3a; }
            QPushButton:pressed { background: #101010; }
            QPushButton:focus { border-color: #8a8a8a; }
            QPushButton:disabled { color: #555555; background: #101010; border-color: #1e1e1e; }
            QPushButton#primary { background: #ffffff; color: #000000; border: none; min-height: 42px; }
            QPushButton#primary:hover { background: #e7e7e7; }
            QPushButton#primary:focus { border: 2px solid #8a8a8a; }
            QPushButton#primary:disabled { background: #3b3b3b; color: #777777; }
            QPushButton#small { min-height: 28px; max-height: 28px; border-radius: 8px; padding: 0 10px; color: #bdbdbd; font-size: 11px; }
            QPushButton#tiny { min-height: 23px; max-height: 23px; border-radius: 7px; padding: 0 8px; color: #8e8e8e; font-size: 10px; }
            QPushButton#dropdownButton { background: #0a0a0a; border: 1px solid #292929; border-radius: 10px; min-height: 38px; padding: 0 38px 0 12px; text-align: left; font-weight: 500; }
            QPushButton#dropdownButton:hover { background: #101010; border-color: #3b3b3b; }
            QFrame#dropdownSurface { background: #111111; border: 1px solid #303030; border-radius: 11px; }
            QPushButton#dropdownOption { background: transparent; border: none; border-radius: 7px; min-height: 32px; padding: 0 10px; text-align: left; font-weight: 500; }
            QPushButton#dropdownOption:hover { background: #242424; }
            QScrollArea { background: transparent; border: none; }
            QScrollArea > QWidget > QWidget { background: transparent; }
            QFrame#categoryCard { background: #0a0a0a; border: 1px solid #242424; border-radius: 12px; }
            QLabel#categoryTitle { color: #e7e7e7; font-size: 13px; font-weight: 650; }
            QLabel#categoryCount { color: #7a7a7a; font-size: 11px; }
            QLabel#emptyState { color: #858585; font-size: 12px; padding: 36px; }
            QFrame#appRow { background: transparent; border: 1px solid transparent; border-radius: 9px; }
            QFrame#appRow:hover { background: #121212; border-color: #222222; }
            QFrame#appRow[selected="true"] { background: #171717; border-color: #3b3b3b; }
            QLabel#appBadge { background: #1b1b1b; color: #bfbfbf; border: 1px solid #303030; border-radius: 8px; font-size: 10px; font-weight: 700; }
            QLabel#appName { color: #e4e4e4; font-size: 12px; font-weight: 600; }
            QLabel#appDescription { color: #858585; font-size: 11px; }
            QFrame#selectionBar, QFrame#infoBar { background: #0a0a0a; border: 1px solid #242424; border-radius: 11px; }
            QLabel#selectedCount { color: #d5d5d5; font-size: 12px; font-weight: 600; }
            QFrame#reviewRow, QFrame#queueRow { background: #0a0a0a; border: 1px solid #242424; border-radius: 10px; }
            QLabel#queueStatus { color: #838383; font-size: 11px; font-weight: 600; }
            QLabel#queueStatus[state="installing"] { color: #ffffff; }
            QLabel#queueStatus[state="installed"] { color: #bdbdbd; }
            QLabel#queueStatus[state="current"] { color: #8d8d8d; }
            QLabel#queueStatus[state="failed"] { color: #ff7b73; }
            QLabel#queueStatus[state="cancelled"] { color: #777777; }
            QPlainTextEdit { background: #090909; color: #c8c8c8; border: 1px solid #242424; border-radius: 10px; padding: 8px; font-family: "Cascadia Mono", "Consolas"; font-size: 11px; selection-background-color: #ffffff; selection-color: #000000; }
            QProgressBar { background: #121212; border: none; border-radius: 3px; min-height: 6px; max-height: 6px; }
            QProgressBar::chunk { background: #ffffff; border-radius: 3px; }
            QScrollBar:vertical { width: 8px; background: transparent; }
            QScrollBar::handle:vertical { background: #333333; border-radius: 4px; min-height: 24px; }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }
            QToolTip { color: #ededed; background: #161616; border: 1px solid #333333; padding: 5px; }
            """
        )

    def build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        outer = QVBoxLayout(central)
        outer.setContentsMargins(0, 0, 0, 0)
        window_frame = QFrame()
        window_frame.setObjectName("windowFrame")
        outer.addWidget(window_frame)
        window_layout = QVBoxLayout(window_frame)
        window_layout.setContentsMargins(0, 0, 0, 0)
        window_layout.setSpacing(0)
        title_bar = TitleBar(self)
        window_layout.addWidget(title_bar)
        content = QWidget()
        window_layout.addWidget(content, 1)
        page = QVBoxLayout(content)
        page.setContentsMargins(22, 18, 22, 18)
        page.setSpacing(0)
        panel = QFrame()
        panel.setObjectName("panel")
        page.addWidget(panel, 1)
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(18, 14, 18, 16)
        panel_layout.setSpacing(10)
        panel_layout.addLayout(self.build_step_bar())
        self.stack = QStackedWidget()
        self.stack.addWidget(self.build_select_page())
        self.stack.addWidget(self.build_review_page())
        self.stack.addWidget(self.build_install_page())
        self.stack.addWidget(self.build_results_page())
        self.page_effects = {}
        for index in range(self.stack.count()):
            widget = self.stack.widget(index)
            effect = QGraphicsOpacityEffect(widget)
            effect.setOpacity(1.0)
            widget.setGraphicsEffect(effect)
            self.page_effects[index] = effect
        panel_layout.addWidget(self.stack, 1)
        self.set_page(self.SELECT_PAGE)

    def build_step_bar(self):
        bar = QHBoxLayout()
        bar.setSpacing(4)
        self.step_labels = []
        for index, text in enumerate(("01 select", "02 review", "03 install", "04 results")):
            label = QLabel(text)
            label.setObjectName("step")
            self.step_labels.append(label)
            bar.addWidget(label)
            if index < 3:
                separator = QLabel("/")
                separator.setObjectName("stepSeparator")
                bar.addWidget(separator)
        bar.addStretch()
        self.preflight_label = QLabel("checking WinGet...")
        self.preflight_label.setObjectName("status")
        bar.addWidget(self.preflight_label)
        return bar

    def heading_block(self, title: str, description: str):
        block = QVBoxLayout()
        block.setSpacing(2)
        heading = QLabel(title)
        heading.setObjectName("pageHeading")
        detail = QLabel(description)
        detail.setObjectName("pageDescription")
        detail.setWordWrap(True)
        block.addWidget(heading)
        block.addWidget(detail)
        return block

    def build_select_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)
        layout.addLayout(self.heading_block("Pick the apps you want", "Choose as many as you need. Nothing installs until you review the full list."))
        filter_row = QHBoxLayout()
        filter_row.setSpacing(8)
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText(f"Search {len(APP_CATALOG)} apps")
        self.search_input.setClearButtonEnabled(True)
        self.search_input.textChanged.connect(self.filter_catalog)
        self.category_filter = AnimatedDropdown(["All categories", *CATEGORY_ORDER])
        self.category_filter.setFixedWidth(190)
        self.category_filter.changed.connect(self.filter_catalog)
        filter_row.addWidget(self.search_input, 1)
        filter_row.addWidget(self.category_filter)
        layout.addLayout(filter_row)

        self.catalog_scroll = SmoothScrollArea()
        self.catalog_scroll.setWidgetResizable(True)
        self.catalog_scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        catalog_widget = QWidget()
        catalog_layout = QVBoxLayout(catalog_widget)
        catalog_layout.setContentsMargins(0, 0, 4, 0)
        catalog_layout.setSpacing(10)
        apps_by_category = {category: [] for category in CATEGORY_ORDER}
        for app_definition in APP_CATALOG:
            row = AppRow(app_definition)
            row.toggled.connect(self.app_toggled)
            self.app_rows[app_definition.package_id] = row
            apps_by_category[app_definition.category].append(row)
        for category in CATEGORY_ORDER:
            card = CategoryCard(category, apps_by_category[category])
            card.toggle_requested.connect(self.toggle_category)
            self.category_cards[category] = card
            catalog_layout.addWidget(card)
        self.no_results_label = QLabel("No apps match this search.")
        self.no_results_label.setObjectName("emptyState")
        self.no_results_label.setAlignment(Qt.AlignCenter)
        self.no_results_label.hide()
        catalog_layout.addWidget(self.no_results_label)
        catalog_layout.addStretch()
        self.catalog_scroll.setWidget(catalog_widget)
        layout.addWidget(self.catalog_scroll, 1)

        selection_bar = QFrame()
        selection_bar.setObjectName("selectionBar")
        bottom = QHBoxLayout(selection_bar)
        bottom.setContentsMargins(11, 8, 8, 8)
        bottom.setSpacing(7)
        self.selected_label = QLabel("0 apps selected")
        self.selected_label.setObjectName("selectedCount")
        load_button = QPushButton("Load selection")
        load_button.setObjectName("small")
        load_button.clicked.connect(self.load_profile)
        self.save_button = QPushButton("Save selection")
        self.save_button.setObjectName("small")
        self.save_button.clicked.connect(self.save_profile)
        self.clear_button = QPushButton("Clear")
        self.clear_button.setObjectName("small")
        self.clear_button.clicked.connect(self.clear_selection)
        self.review_button = QPushButton("Review selection")
        self.review_button.setObjectName("primary")
        self.review_button.setFixedWidth(190)
        self.review_button.clicked.connect(self.show_review)
        bottom.addWidget(self.selected_label)
        bottom.addStretch()
        bottom.addWidget(load_button)
        bottom.addWidget(self.save_button)
        bottom.addWidget(self.clear_button)
        bottom.addWidget(self.review_button)
        layout.addWidget(selection_bar)
        return page

    def build_review_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)
        layout.addLayout(self.heading_block("Review your selection", "Selected apps install one at a time from the curated WinGet source."))
        self.review_scroll = SmoothScrollArea()
        self.review_scroll.setWidgetResizable(True)
        self.review_scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        layout.addWidget(self.review_scroll, 1)
        info = QFrame()
        info.setObjectName("infoBar")
        info_layout = QVBoxLayout(info)
        info_layout.setContentsMargins(11, 9, 11, 9)
        info_layout.setSpacing(2)
        self.review_status = QLabel("Checking WinGet...")
        self.review_status.setObjectName("selectedCount")
        agreement = QLabel("Install uses publisher defaults, accepts required WinGet source/package agreements, may show Windows permission prompts, and never requests an automatic restart.")
        agreement.setObjectName("note")
        agreement.setWordWrap(True)
        info_layout.addWidget(self.review_status)
        info_layout.addWidget(agreement)
        layout.addWidget(info)
        actions = QHBoxLayout()
        actions.setSpacing(8)
        back = QPushButton("Back")
        back.clicked.connect(lambda: self.set_page(self.SELECT_PAGE))
        save = QPushButton("Save selection")
        save.clicked.connect(self.save_profile)
        self.install_button = QPushButton("Install selected apps")
        self.install_button.setObjectName("primary")
        self.install_button.setFixedWidth(230)
        self.install_button.clicked.connect(self.start_installation)
        actions.addWidget(back)
        actions.addWidget(save)
        actions.addStretch()
        actions.addWidget(self.install_button)
        layout.addLayout(actions)
        return page

    def build_install_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)
        layout.addLayout(self.heading_block("Installing your apps", "Keep this window open. Windows or an individual publisher may ask for permission."))
        self.overall_progress = QProgressBar()
        self.overall_progress.setTextVisible(False)
        self.overall_progress.setRange(0, 1)
        self.overall_progress.setValue(0)
        self.progress_animation = QPropertyAnimation(self.overall_progress, b"value", self)
        self.progress_animation.setDuration(180)
        self.progress_animation.setEasingCurve(QEasingCurve.OutCubic)
        layout.addWidget(self.overall_progress)
        install_header = QHBoxLayout()
        self.install_status = QLabel("Preparing...")
        self.install_status.setObjectName("status")
        install_header.addWidget(self.install_status)
        install_header.addStretch()
        self.stop_button = QPushButton("Stop after current app")
        self.stop_button.setObjectName("small")
        self.stop_button.clicked.connect(self.request_stop_after_current)
        install_header.addWidget(self.stop_button)
        layout.addLayout(install_header)
        self.install_scroll = SmoothScrollArea()
        self.install_scroll.setWidgetResizable(True)
        self.install_scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        layout.addWidget(self.install_scroll, 1)
        log_header = QHBoxLayout()
        log_label = QLabel("Log")
        log_label.setObjectName("label")
        log_header.addWidget(log_label)
        log_header.addStretch()
        layout.addLayout(log_header)
        self.install_log = QPlainTextEdit()
        self.install_log.setReadOnly(True)
        self.install_log.document().setMaximumBlockCount(1500)
        self.install_log.setPlaceholderText("No activity")
        self.install_log.setMinimumHeight(100)
        self.install_log.setMaximumHeight(120)
        layout.addWidget(self.install_log)
        return page

    def build_results_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)
        results_heading_layout = self.heading_block("Installation results", "Your results will appear here.")
        self.results_heading = results_heading_layout.itemAt(0).widget()
        self.results_description = results_heading_layout.itemAt(1).widget()
        layout.addLayout(results_heading_layout)
        self.results_scroll = SmoothScrollArea()
        self.results_scroll.setWidgetResizable(True)
        self.results_scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        layout.addWidget(self.results_scroll, 1)
        actions = QHBoxLayout()
        actions.setSpacing(8)
        back = QPushButton("Back to apps")
        back.clicked.connect(self.back_to_catalog)
        open_log = QPushButton("Open local log")
        open_log.clicked.connect(self.open_session_log)
        self.retry_button = QPushButton("Review failed apps")
        self.retry_button.setObjectName("primary")
        self.retry_button.setFixedWidth(210)
        self.retry_button.clicked.connect(self.results_primary_action)
        actions.addWidget(back)
        actions.addWidget(open_log)
        actions.addStretch()
        actions.addWidget(self.retry_button)
        layout.addLayout(actions)
        return page

    def set_page(self, index: int):
        changed = self.stack.currentIndex() != index
        if self.page_animation is not None:
            animation = self.page_animation
            self.page_animation = None
            animation.stop()
            animation.deleteLater()
        if self.page_animation_widget is not None:
            self.page_effects[self.page_animation_widget].setOpacity(1.0)
            self.page_animation_widget = None
        self.stack.setCurrentIndex(index)
        if changed and self.isVisible():
            effect = self.page_effects[index]
            effect.setOpacity(0.35)
            animation = QPropertyAnimation(effect, b"opacity", self)
            animation.setDuration(145)
            animation.setStartValue(0.35)
            animation.setEndValue(1.0)
            animation.setEasingCurve(QEasingCurve.OutCubic)
            animation.finished.connect(lambda current=animation: self.page_animation_finished(current))
            self.page_animation = animation
            self.page_animation_widget = index
            animation.start()
        for label_index, label in enumerate(self.step_labels):
            label.setProperty("active", label_index == index)
            label.style().unpolish(label)
            label.style().polish(label)
        focus_targets = {
            self.SELECT_PAGE: self.search_input,
            self.REVIEW_PAGE: self.install_button,
            self.INSTALL_PAGE: self.stop_button,
            self.RESULTS_PAGE: self.retry_button,
        }
        QTimer.singleShot(0, lambda target=focus_targets[index]: target.setFocus(Qt.OtherFocusReason))

    def page_animation_finished(self, animation):
        if self.page_animation is animation:
            self.page_animation = None
            if self.page_animation_widget is not None:
                self.page_effects[self.page_animation_widget].setOpacity(1.0)
                self.page_animation_widget = None
        animation.deleteLater()

    def app_toggled(self, package_id: str, checked: bool):
        if checked:
            self.selected_ids.add(package_id)
        else:
            self.selected_ids.discard(package_id)
        if not self.selection_batching:
            self.update_selection_ui()

    def update_selection_ui(self):
        count = len(self.selected_ids)
        self.selected_label.setText(f"{count} app{'s' if count != 1 else ''} selected")
        self.review_button.setEnabled(count > 0)
        self.save_button.setEnabled(count > 0)
        self.clear_button.setEnabled(count > 0)
        for category, card in self.category_cards.items():
            rows = card.rows
            selected = sum(row.isChecked() for row in rows)
            # isVisible() is false while the page or window itself is hidden.
            # isHidden() reflects whether filtering hid the individual row.
            visible_rows = [row for row in rows if not row.isHidden()]
            selected_visible = sum(row.isChecked() for row in visible_rows)
            card.update_state(selected, len(visible_rows), selected_visible)

    def set_selected_ids(self, package_ids):
        allowed = set(package_ids) & set(APP_BY_ID)
        self.selection_batching = True
        try:
            for package_id, row in self.app_rows.items():
                row.setChecked(package_id in allowed)
        finally:
            self.selection_batching = False
        self.selected_ids = allowed
        self.update_selection_ui()

    def clear_selection(self):
        self.set_selected_ids(set())

    def toggle_category(self, category: str):
        package_ids = {
            row.app_definition.package_id
            for row in self.category_cards[category].rows
            if not row.isHidden()
        }
        if not package_ids:
            return
        if package_ids <= self.selected_ids:
            updated = self.selected_ids - package_ids
        else:
            updated = self.selected_ids | package_ids
        self.set_selected_ids(updated)

    def filter_catalog(self, value=None):
        term = self.search_input.text().strip().lower()
        selected_category = self.category_filter.currentText()
        visible_categories = 0
        for category, card in self.category_cards.items():
            category_visible = selected_category in {"All categories", category}
            visible_rows = []
            for row in card.rows:
                matches_text = not term or term in row.app_definition.searchable_text
                visible = category_visible and matches_text
                if visible and row.isHidden():
                    row.show()
                elif not visible and not row.isHidden():
                    row.hide()
                if visible:
                    visible_rows.append(row)
            card.reflow(visible_rows)
            card.setVisible(bool(visible_rows))
            visible_categories += int(bool(visible_rows))
        self.no_results_label.setVisible(visible_categories == 0)
        self.catalog_scroll.scroll_to_top()
        self.update_selection_ui()

    def ordered_selection(self) -> list[AppDefinition]:
        return [app for app in APP_CATALOG if app.package_id in self.selected_ids]

    def profile_payload(self):
        return {
            "schema": PROFILE_SCHEMA,
            "kind": PROFILE_KIND,
            "packages": [app.package_id for app in self.ordered_selection()],
        }

    def save_profile(self):
        if not self.selected_ids:
            return
        filename, _ = QFileDialog.getSaveFileName(
            self,
            "Save Fleece Selection",
            str(APP_DIR / "my-apps.fleecepack"),
            "Fleece selection (*.fleecepack);;JSON files (*.json)",
        )
        if not filename:
            return
        path = Path(filename)
        if not path.suffix:
            path = path.with_suffix(".fleecepack")
        try:
            path.write_text(json.dumps(self.profile_payload(), indent=2) + "\n", encoding="utf-8")
        except OSError as error:
            QMessageBox.warning(self, "Could not save", f"The selection could not be saved.\n\n{error}")

    def load_profile(self):
        filename, _ = QFileDialog.getOpenFileName(
            self,
            "Load Fleece Selection",
            str(APP_DIR),
            "Fleece selection (*.fleecepack *.json);;All files (*.*)",
        )
        if not filename:
            return
        path = Path(filename)
        try:
            with path.open("rb") as handle:
                profile_bytes = handle.read(128 * 1024 + 1)
            if len(profile_bytes) > 128 * 1024:
                raise ValueError("The selection file is too large.")
            payload = json.loads(profile_bytes.decode("utf-8"))
            packages = validated_profile_packages(payload)
        except (OSError, UnicodeError, json.JSONDecodeError, ValueError, RecursionError) as error:
            QMessageBox.warning(self, "Could not load", str(error))
            return
        known = set(packages) & set(APP_BY_ID)
        unknown = len(set(packages) - set(APP_BY_ID))
        if not known:
            QMessageBox.warning(self, "No supported apps", "The file did not contain any apps from the approved catalog.")
            return
        self.set_selected_ids(known)
        if unknown:
            QMessageBox.information(self, "Selection loaded", f"Loaded {len(known)} apps. Ignored {unknown} unknown package entr{'y' if unknown == 1 else 'ies'}.")

    def show_review(self):
        if not self.selected_ids:
            return
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 4, 0)
        layout.setSpacing(7)
        self.review_layout = layout
        self.review_rows = {}
        for app_definition in self.ordered_selection():
            row = ReviewRow(app_definition)
            row.remove_requested.connect(self.remove_from_review)
            self.review_rows[app_definition.package_id] = row
            layout.addWidget(row)
        layout.addStretch()
        old = self.review_scroll.takeWidget()
        if old is not None:
            old.deleteLater()
        self.review_scroll.setWidget(container)
        self.refresh_review_status()
        self.set_page(self.REVIEW_PAGE)

    def remove_from_review(self, package_id: str):
        self.app_rows[package_id].setChecked(False)
        row = self.review_rows.pop(package_id, None)
        if row is not None:
            self.review_layout.removeWidget(row)
            row.deleteLater()
        if not self.selected_ids:
            self.set_page(self.SELECT_PAGE)
            return
        self.refresh_review_status()

    def start_winget_preflight(self):
        if self.winget_path is None:
            self.finish_winget_preflight(False, "not found")
            return
        self.preflight_version_candidate = ""
        self.start_preflight_command(["--version"], "version")

    def start_preflight_command(self, arguments: list[str], stage: str):
        if self.preflight_process is not None:
            return
        self.preflight_process = QProcess(self)
        self.preflight_stage = stage
        self.preflight_process.setProcessChannelMode(QProcess.MergedChannels)
        self.preflight_process.finished.connect(self.preflight_finished)
        self.preflight_process.errorOccurred.connect(self.preflight_error)
        self.preflight_process.start(str(self.winget_path), arguments)
        self.preflight_timer.start(10_000)

    def preflight_finished(self, exit_code, exit_status):
        process = self.preflight_process
        if process is None:
            return
        self.preflight_timer.stop()
        output = bytes(process.readAllStandardOutput()).decode("utf-8", errors="replace").strip()
        stage = self.preflight_stage
        self.preflight_process = None
        self.preflight_stage = ""
        process.deleteLater()
        if exit_code != 0 or not output:
            self.finish_winget_preflight(False, output or f"exit {exit_code}")
            return
        if stage == "version":
            self.preflight_version_candidate = output
            self.start_preflight_command(
                ["source", "export", "winget", "--disable-interactivity"],
                "source",
            )
            return
        if stage == "source" and self.is_official_winget_source(output):
            self.finish_winget_preflight(True, self.preflight_version_candidate)
            return
        self.finish_winget_preflight(False, "official source unavailable")

    def preflight_error(self, error):
        process = self.preflight_process
        if process is None:
            return
        self.preflight_timer.stop()
        self.preflight_process = None
        self.preflight_stage = ""
        if process.state() != QProcess.NotRunning:
            process.kill()
        process.deleteLater()
        detail = "could not start" if error == QProcess.FailedToStart else "preflight failed"
        self.finish_winget_preflight(False, detail)

    def preflight_timed_out(self):
        process = self.preflight_process
        if process is None:
            return
        self.preflight_process = None
        self.preflight_stage = ""
        if process.state() != QProcess.NotRunning:
            process.kill()
        process.deleteLater()
        self.finish_winget_preflight(False, "preflight timed out")

    @staticmethod
    def is_official_winget_source(output: str) -> bool:
        try:
            payload = json.loads(output.lstrip("\ufeff"))
        except (json.JSONDecodeError, RecursionError):
            return False
        if not isinstance(payload, dict):
            return False
        trust_levels = payload.get("TrustLevel")
        return (
            payload.get("Name") == "winget"
            and str(payload.get("Arg", "")).rstrip("/").casefold()
            == OFFICIAL_WINGET_SOURCE_URL.casefold()
            and payload.get("Data") == OFFICIAL_WINGET_SOURCE_ID
            and payload.get("Identifier") == OFFICIAL_WINGET_SOURCE_ID
            and payload.get("Type") == OFFICIAL_WINGET_SOURCE_TYPE
            and isinstance(trust_levels, list)
            and any(value == "Trusted" for value in trust_levels)
        )

    def finish_winget_preflight(self, ready: bool, version: str):
        self.winget_version = version
        self.winget_supports_no_progress = False
        match = re.search(r"(\d+)\.(\d+)", version)
        if match:
            major, minor = (int(value) for value in match.groups())
            self.winget_supports_no_progress = (major, minor) >= (1, 29)
            if ready and (major, minor) < MIN_WINGET_VERSION:
                ready = False
                self.preflight_label.setText("Update WinGet")
            else:
                self.preflight_label.setText(f"WinGet {version}" if ready else "WinGet unavailable")
        else:
            ready = False
            self.preflight_label.setText("WinGet unavailable")
        self.winget_ready = ready
        self.refresh_review_status()

    def refresh_review_status(self):
        if not hasattr(self, "review_status"):
            return
        count = len(self.selected_ids)
        if self.winget_ready:
            self.review_status.setText(f"Ready to install {count} app{'s' if count != 1 else ''} with WinGet {self.winget_version}.")
        elif self.winget_version == "checking":
            self.review_status.setText("Checking WinGet and its official source...")
        else:
            self.review_status.setText("WinGet is unavailable. Update Microsoft App Installer, then reopen this tool.")
        self.install_button.setText(f"Install {count} app{'s' if count != 1 else ''}")
        self.install_button.setEnabled(count > 0 and self.winget_ready and not self.install_active)

    def build_winget_arguments(self, app_definition: AppDefinition) -> list[str]:
        arguments = [
            "install",
            "--id",
            app_definition.package_id,
            "--exact",
            "--source",
            "winget",
            "--silent",
            "--disable-interactivity",
            "--accept-source-agreements",
            "--accept-package-agreements",
        ]
        if self.winget_supports_no_progress:
            arguments.append("--no-progress")
        return arguments

    def start_installation(self):
        if self.install_active or not self.selected_ids:
            return
        if not self.winget_ready or self.winget_path is None:
            QMessageBox.warning(self, "WinGet unavailable", "Mass Installer needs WinGet from Microsoft App Installer. Update App Installer and try again.")
            return
        self.install_queue = deque(self.ordered_selection())
        self.total_jobs = len(self.install_queue)
        self.completed_jobs = 0
        self.results = {}
        self.failed_ids = []
        self.current_app = None
        self.install_active = True
        self.stop_after_current = False
        self.force_stopping = False
        self.next_install_timer.stop()
        self.stop_button.setEnabled(True)
        self.stop_button.setText("Stop after current app")
        self.install_log.clear()
        self.progress_animation.stop()
        self.overall_progress.setRange(0, self.total_jobs)
        self.overall_progress.setValue(0)
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")[:-3]
        self.session_log_path = LOGS_DIR / f"install-{timestamp}.log"
        try:
            LOGS_DIR.mkdir(parents=True, exist_ok=True)
            self.session_log_path.write_text(
                f"Fleece Mass Installer session\nStarted: {datetime.now().isoformat(timespec='seconds')}\nPackages: {self.total_jobs}\n\n",
                encoding="utf-8",
            )
        except OSError:
            self.session_log_path = None
        self.populate_install_queue()
        self.set_page(self.INSTALL_PAGE)
        self.append_install_log(f"Starting {self.total_jobs} selected apps.")
        self.next_install_timer.start(100)

    def populate_install_queue(self):
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 4, 0)
        layout.setSpacing(7)
        self.queue_rows = {}
        for app_definition in self.install_queue:
            row = QueueRow(app_definition)
            self.queue_rows[app_definition.package_id] = row
            layout.addWidget(row)
        layout.addStretch()
        old = self.install_scroll.takeWidget()
        if old is not None:
            old.deleteLater()
        self.install_scroll.setWidget(container)

    def start_next_install(self):
        if not self.install_active or self.process is not None or self.current_app is not None:
            return
        if self.stop_after_current:
            self.cancel_remaining_queue()
            self.finish_installation()
            return
        if not self.install_queue:
            self.finish_installation()
            return
        self.current_app = self.install_queue.popleft()
        self.force_stopping = False
        self.current_output_lines = []
        self.process_decoder = codecs.getincrementaldecoder("utf-8")(errors="replace")
        self.process_line_buffer = ""
        row = self.queue_rows[self.current_app.package_id]
        row.set_status("Installing", "installing")
        self.install_status.setText(f"Installing {self.current_app.name}  ·  {self.completed_jobs + 1} of {self.total_jobs}")
        self.append_install_log(f"{self.current_app.name}: starting {self.current_app.package_id}")
        self.process = QProcess(self)
        self.process.setProcessChannelMode(QProcess.MergedChannels)
        self.process.readyReadStandardOutput.connect(self.read_install_output)
        self.process.finished.connect(self.install_process_finished)
        self.process.errorOccurred.connect(self.install_process_error)
        self.process.start(str(self.winget_path), self.build_winget_arguments(self.current_app))

    def read_install_output(self):
        if self.process is None or self.process_decoder is None:
            return
        data = bytes(self.process.readAllStandardOutput())
        if data:
            self.consume_install_text(self.process_decoder.decode(data), final=False)

    def consume_install_text(self, text: str, final: bool):
        self.process_line_buffer += text.replace("\r\n", "\n").replace("\r", "\n")
        parts = self.process_line_buffer.split("\n")
        self.process_line_buffer = "" if final else parts.pop()
        log_messages = []
        for raw_line in parts:
            line = ANSI_RE.sub("", raw_line).replace("\x08", "").strip()
            if not line:
                continue
            progress_characters = sum(character in "█▓▒░-\\|/" for character in line)
            if progress_characters > max(8, len(line) // 2):
                continue
            self.current_output_lines.append(line)
            if self.current_app is not None:
                log_messages.append(f"{self.current_app.name}: {line}")
        if len(self.current_output_lines) > 300:
            del self.current_output_lines[:-300]
        self.append_install_log_lines(log_messages)

    def install_process_finished(self, exit_code, exit_status):
        if self.process is None or self.current_app is None:
            return
        self.read_install_output()
        if self.process_decoder is not None:
            self.consume_install_text(self.process_decoder.decode(b"", final=True), final=True)
        output = "\n".join(self.current_output_lines)
        state, label = self.classify_install_result(exit_code, output, self.force_stopping)
        self.complete_current(state, label)

    @classmethod
    def classify_install_result(
        cls,
        exit_code: int,
        output: str,
        force_stopping: bool = False,
    ) -> tuple[str, str]:
        lowered = output.lower()
        current_patterns = (
            "no available upgrade found",
            "no newer package versions are available",
            "no applicable upgrade found",
        )
        unsigned_exit_code = exit_code & 0xFFFFFFFF
        restart_positive = re.search(
            r"\b(?:restart|reboot)\b.{0,40}\b(?:required|needed|recommended)\b"
            r"|\b(?:requires?|needs?|recommends?)\b.{0,40}\b(?:restart|reboot)\b",
            lowered,
        )
        restart_negative = re.search(
            r"\b(?:no|without)\b.{0,24}\b(?:restart|reboot)\b"
            r"|\b(?:restart|reboot)\b.{0,24}\b(?:not required|not needed|unnecessary)\b",
            lowered,
        )
        restart_needed = bool(restart_positive and not restart_negative)
        if force_stopping:
            return "failed", "Emergency stop requested"
        elif unsigned_exit_code == WINGET_UPDATE_NOT_APPLICABLE or (
            exit_code == 0 and any(pattern in lowered for pattern in current_patterns)
        ):
            return "current", "Already current"
        elif exit_code == 0:
            return (
                "installed",
                "Installed · restart may be needed" if restart_needed else "Installed",
            )
        return "failed", cls.failure_label(exit_code, lowered)

    def install_process_error(self, error):
        if error == QProcess.FailedToStart and self.current_app is not None:
            self.append_install_log(f"{self.current_app.name}: WinGet could not start.")
            self.complete_current("failed", "WinGet could not start")

    @staticmethod
    def failure_label(exit_code: int, output: str) -> str:
        if "cancel" in output or "declined" in output:
            return "Permission declined"
        if "another installation is already in progress" in output:
            return "Another installer is busy"
        if "no applicable installer" in output:
            return "Not compatible with this PC"
        if "blocked by policy" in output:
            return "Blocked by Windows policy"
        unsigned = exit_code & 0xFFFFFFFF
        return f"Failed · 0x{unsigned:08X}"

    def complete_current(self, state: str, label: str):
        if self.current_app is None:
            return
        app_definition = self.current_app
        self.results[app_definition.package_id] = (state, label)
        if state == "failed":
            self.failed_ids.append(app_definition.package_id)
        row = self.queue_rows.get(app_definition.package_id)
        if row is not None:
            row.set_status(label, state)
        self.append_install_log(f"{app_definition.name}: {label}")
        self.completed_jobs += 1
        self.progress_animation.stop()
        self.progress_animation.setStartValue(self.overall_progress.value())
        self.progress_animation.setEndValue(self.completed_jobs)
        self.progress_animation.start()
        process = self.process
        self.process = None
        self.current_app = None
        self.process_decoder = None
        self.process_line_buffer = ""
        self.force_stopping = False
        if process is not None:
            process.deleteLater()
        if self.stop_after_current:
            self.cancel_remaining_queue()
            self.finish_installation()
        else:
            self.next_install_timer.start(120)

    def request_stop_after_current(self):
        if not self.install_active:
            return
        if self.stop_after_current:
            self.confirm_emergency_stop()
            return
        self.stop_after_current = True
        self.stop_button.setText("Emergency force stop…")
        self.install_status.setText("The active installer will finish safely; remaining apps will be cancelled.")
        self.append_install_log("Stop requested. The current installer will not be force-closed.")
        if self.current_app is None:
            self.stop_button.setEnabled(False)
            self.cancel_remaining_queue()
            self.finish_installation()

    def confirm_emergency_stop(self):
        process = self.process
        if process is None or process.state() == QProcess.NotRunning:
            return
        answer = QMessageBox.warning(
            self,
            "Emergency force stop",
            "Use this only if WinGet or the publisher installer is frozen.\n\n"
            "Force stopping can leave the current app partly installed, and a publisher installer may continue separately.\n\n"
            "Force stop WinGet now?",
            QMessageBox.Yes | QMessageBox.Cancel,
            QMessageBox.Cancel,
        )
        if answer != QMessageBox.Yes:
            return
        if (
            not self.install_active
            or self.process is not process
            or process.state() == QProcess.NotRunning
        ):
            return
        self.force_stopping = True
        self.stop_button.setEnabled(False)
        self.stop_button.setText("Force stopping WinGet…")
        self.install_status.setText("Emergency stop requested; waiting for WinGet to close.")
        self.append_install_log("Emergency force stop requested for the active WinGet process.")
        process.kill()

    def cancel_remaining_queue(self):
        for app_definition in self.install_queue:
            self.results[app_definition.package_id] = ("cancelled", "Cancelled")
            row = self.queue_rows.get(app_definition.package_id)
            if row is not None:
                row.set_status("Cancelled", "cancelled")
            self.completed_jobs += 1
        self.install_queue.clear()
        self.progress_animation.stop()
        self.overall_progress.setValue(self.completed_jobs)

    def finish_installation(self):
        if not self.install_active:
            return
        self.next_install_timer.stop()
        self.install_active = False
        self.stop_button.setEnabled(False)
        self.install_status.setText("Finished")
        self.append_install_log("Session finished. Mass Installer did not request a restart.")
        self.populate_results()
        self.refresh_review_status()
        self.set_page(self.RESULTS_PAGE)

    def populate_results(self):
        installed = sum(state == "installed" for state, label in self.results.values())
        current = sum(state == "current" for state, label in self.results.values())
        failed = sum(state == "failed" for state, label in self.results.values())
        cancelled = sum(state == "cancelled" for state, label in self.results.values())
        if failed:
            heading = "Installation finished with issues"
        elif cancelled:
            heading = "Installation stopped"
        else:
            heading = "Installation complete"
        self.results_heading.setText(heading)
        summary_parts = [f"{installed} installed", f"{current} already current"]
        if failed:
            summary_parts.append(f"{failed} failed")
        if cancelled:
            summary_parts.append(f"{cancelled} cancelled")
        self.results_description.setText("  ·  ".join(summary_parts) + ". No restart was requested by Fleece.")
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 4, 0)
        layout.setSpacing(7)
        for app_definition in APP_CATALOG:
            if app_definition.package_id not in self.results:
                continue
            state, label = self.results[app_definition.package_id]
            row = QueueRow(app_definition)
            row.set_status(label, state)
            layout.addWidget(row)
        layout.addStretch()
        old = self.results_scroll.takeWidget()
        if old is not None:
            old.deleteLater()
        self.results_scroll.setWidget(container)
        self.retry_button.setText("Review failed apps" if self.failed_ids else "Install more apps")
        self.retry_button.setEnabled(True)

    def append_install_log(self, message: str):
        self.append_install_log_lines([message])

    def append_install_log_lines(self, messages):
        cleaned_messages = []
        for message in messages:
            cleaned = str(message).strip()
            if cleaned:
                cleaned_messages.append(cleaned)
        if not cleaned_messages:
            return
        timestamp = datetime.now().strftime("%H:%M:%S")
        lines = [f"[{timestamp}] {message}" for message in cleaned_messages]
        text = "\n".join(lines)
        self.install_log.appendPlainText(text)
        if self.session_log_path is not None:
            try:
                with self.session_log_path.open("a", encoding="utf-8") as handle:
                    handle.write(text + "\n")
            except OSError:
                self.session_log_path = None

    def open_session_log(self):
        if self.session_log_path is not None and self.session_log_path.is_file():
            QDesktopServices.openUrl(QUrl.fromLocalFile(str(self.session_log_path)))
        else:
            QMessageBox.information(self, "No local log", "No session log is available for this run.")

    def retry_failed(self):
        if not self.failed_ids:
            return
        self.set_selected_ids(self.failed_ids)
        self.show_review()

    def results_primary_action(self):
        if self.failed_ids:
            self.retry_failed()
        else:
            self.set_selected_ids(set())
            self.back_to_catalog()

    def back_to_catalog(self):
        self.set_page(self.SELECT_PAGE)

    def closeEvent(self, event: QCloseEvent):
        self.category_filter.hide_popup()
        if self.install_active:
            QMessageBox.information(
                self,
                "Installation in progress",
                "For safety, Mass Installer will stay open until the active publisher installer finishes.\n\n"
                "Use 'Stop after current app' to cancel the remaining queue. If it is truly frozen, that button then offers a separately confirmed emergency force stop.",
            )
            if self.install_active:
                event.ignore()
            else:
                event.accept()
            return
        event.accept()


def run_self_test(application: QApplication) -> int:
    window = MassInstaller()
    assert len(APP_CATALOG) == 78
    added_package_ids = {
        "Mozilla.Thunderbird",
        "Element.Element",
        "Beeper.Beeper",
        "qBittorrent.qBittorrent",
        "WinSCP.WinSCP",
        "LocalSend.LocalSend",
        "RARLab.WinRAR",
        "Microsoft.Sysinternals.ProcessExplorer",
        "CrystalDewWorld.CrystalDiskMark",
    }
    assert added_package_ids <= set(APP_BY_ID)
    assert all(
        sum(item.category == category for item in APP_CATALOG) % 3 == 0
        for category in CATEGORY_ORDER
    )
    package_ids = [item.package_id for item in APP_CATALOG]
    assert len(package_ids) == len(set(package_ids))
    assert len(ICON_SLUG_BY_PACKAGE) == 49
    assert set(ICON_SLUG_BY_PACKAGE).issubset(package_ids)
    assert all((ICONS_DIR / f"{slug}.svg").is_file() for slug in ICON_SLUG_BY_PACKAGE.values())
    assert all(app_icon_pixmap(APP_BY_ID[package_id]) is not None for package_id in ICON_SLUG_BY_PACKAGE)
    assert not any(
        re.search(
            r"\btor(?:\s+browser)?\b",
            " ".join((item.category, item.name, item.package_id, item.publisher, item.description)),
            re.IGNORECASE,
        )
        for item in APP_CATALOG
    )
    assert tuple(dict.fromkeys(item.category for item in APP_CATALOG)) == CATEGORY_ORDER
    for invalid_profile in (None, [], "not an object"):
        try:
            validated_profile_packages(invalid_profile)
        except ValueError:
            pass
        else:
            raise AssertionError("Invalid profile root was accepted")
    try:
        validated_profile_packages(
            {"schema": True, "kind": PROFILE_KIND, "packages": ["Google.Chrome"]}
        )
    except ValueError:
        pass
    else:
        raise AssertionError("Boolean profile schema was accepted")
    official_source = json.dumps(
        {
            "Arg": OFFICIAL_WINGET_SOURCE_URL,
            "Data": OFFICIAL_WINGET_SOURCE_ID,
            "Identifier": OFFICIAL_WINGET_SOURCE_ID,
            "Name": "winget",
            "TrustLevel": ["Trusted", "StoreOrigin"],
            "Type": OFFICIAL_WINGET_SOURCE_TYPE,
        }
    )
    assert window.is_official_winget_source(official_source)
    assert not window.is_official_winget_source(
        official_source.replace("cdn.winget.microsoft.com", "example.invalid")
    )
    window.clear_selection()
    window.search_input.setText("Google Chrome")
    visible_ids = {
        row.app_definition.package_id for row in window.category_cards["Browsers"].rows if not row.isHidden()
    }
    assert visible_ids == {"Google.Chrome"}
    window.toggle_category("Browsers")
    assert window.selected_ids == {"Google.Chrome"}
    window.search_input.clear()
    sample_ids = {APP_CATALOG[0].package_id, APP_CATALOG[13].package_id, APP_CATALOG[30].package_id}
    window.set_selected_ids(sample_ids)
    assert window.selected_ids == sample_ids
    assert all(window.app_rows[package_id].isChecked() for package_id in sample_ids)
    assert window.profile_payload()["packages"]
    window.finish_winget_preflight(True, "v1.5.0")
    assert not window.winget_ready
    window.finish_winget_preflight(True, "v1.29.0")
    assert window.winget_ready and window.winget_supports_no_progress
    arguments = window.build_winget_arguments(APP_CATALOG[0])
    assert arguments[:3] == ["install", "--id", APP_CATALOG[0].package_id]
    assert "--exact" in arguments and "--source" in arguments
    assert "--ignore-security-hash" not in arguments and "--allow-reboot" not in arguments
    assert window.classify_install_result(-1978335189, "") == ("current", "Already current")
    assert window.classify_install_result(0, "No restart required.") == ("installed", "Installed")
    assert window.classify_install_result(0, "A restart is required.") == (
        "installed",
        "Installed · restart may be needed",
    )
    assert window.classify_install_result(5, "Operation cancelled")[0] == "failed"
    window.show_review()
    assert window.stack.currentIndex() == MassInstaller.REVIEW_PAGE
    window.close()
    application.processEvents()
    print(
        "Mass Installer self-test passed: catalog, icons, filters, profiles, official source, "
        "selection, review, result classification, and safe command construction."
    )
    return 0


def screenshot_path_from_arguments() -> Optional[Path]:
    if "--screenshot" not in sys.argv:
        return None
    index = sys.argv.index("--screenshot")
    if index + 1 >= len(sys.argv):
        return APP_DIR / "Mass Installer.png"
    return Path(sys.argv[index + 1]).expanduser().resolve()


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    else:
        if not acquire_app_mutex():
            show_native_setup_error("Mass Installer is already open.")
            raise SystemExit(1)
        if SETUP_LOCK_DIR.is_dir():
            show_native_setup_error(
                "Mass Installer setup is currently running.\n\n"
                "Let Installer.bat finish, then open the app again."
            )
            raise SystemExit(1)
    sys.excepthook = sys.__excepthook__ if "--self-test" in sys.argv else handle_unhandled_exception
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    if "--self-test" in sys.argv:
        raise SystemExit(run_self_test(app))
    window = MassInstaller()
    window.show()
    screenshot_path = screenshot_path_from_arguments()
    if screenshot_path is not None:
        def save_screenshot():
            screenshot_path.parent.mkdir(parents=True, exist_ok=True)
            success = window.grab().save(str(screenshot_path), "PNG")
            print(f"Screenshot saved: {screenshot_path}" if success else "Screenshot failed")
            app.quit()
        QTimer.singleShot(900, save_screenshot)
    sys.exit(app.exec())
