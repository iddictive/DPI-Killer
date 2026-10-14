<p align="center">
  <img src="assets/banner.png" alt="DPI Killer" width="860">
</p>

<h1 align="center">DPI Killer</h1>

<p align="center">Run and manage a local DPI-bypass proxy from the macOS menu bar.</p>

<p align="center">
  <a href="https://github.com/iddictive/DPI-Killer/releases/latest">Download for macOS</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#proxy-modes">Proxy modes</a> ·
  <a href="#build-from-source">Build</a> ·
  <a href="#русский">Русский</a>
</p>

<p align="center">
  <a href="https://github.com/iddictive/DPI-Killer/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/iddictive/DPI-Killer"></a>
  <img alt="macOS 13 or newer" src="https://img.shields.io/badge/macOS-13%2B-333333">
</p>

DPI Killer manages [ByeDPI](https://github.com/hufrea/byedpi) (`ciadpi`) and [SpoofDPI](https://github.com/xvzc/spoofdpi). Start a backend, configure the local proxy, and inspect its status without maintaining terminal sessions. Use the macOS system proxy or connect another client to the loopback proxy.

## Quick start

1. Download the DMG from [Releases](https://github.com/iddictive/DPI-Killer/releases/latest).
2. Move `DPIKiller.app` to Applications and launch it.
3. Choose ciadpi or SpoofDPI in the menu bar or Settings.
4. Start the proxy explicitly from the menu bar. Check the active port before connecting another client.

Requires macOS 13 or newer. Version 4.0.4 uses an Apple development signature; it is not notarized. macOS may require first-launch confirmation. Helper setup requires a native administrator confirmation. Direct mode remains available without installing the helper.

## Features

- Explicit ciadpi or SpoofDPI selection. The app starts stopped, including when launched at login.
- SOCKS5 through ciadpi or HTTP proxy through SpoofDPI.
- Configurable local port, with a free loopback port selected when the requested port is busy.
- Bypass presets and engine-specific packet and DNS settings.
- Managed backend installation and updates from upstream GitHub projects.
- Connectivity diagnostics, speed tests, event logs, and application update checks.
- Optional launch at login, reconnection, and a separate hotspot TTL 65 action.

## Proxy modes

| Mode | What DPI Killer does | What you need |
| --- | --- | --- |
| Local proxy (default) | Runs a loopback proxy without changing macOS proxy settings | A client configured for the displayed proxy type and runtime port |
| System proxy (explicit) | Configures the current network connection after the local backend is ready | An available connection without another active proxy |

The app restores the connection's prior proxy settings when stopped. Temporary loss of internet does not recycle a healthy local backend. Repeated proxy failures trigger recovery only when the direct route works. A real packet-tunnel VPN is not provided by these modes.

The menu's **System settings** selector chooses **Helper** (an installed privileged service for subsequent proxy/TTL changes) or **Direct** (macOS authorization for each privileged operation). The backend itself runs as the current user in both modes. A failed system-proxy operation shows an actionable warning rather than a green active state.

For Shadowrocket, choose **Configure Shadowrocket** after installing ciadpi. For other clients, use `127.0.0.1` and the active port shown in DPI Killer, not just the configured preferred port.

## Settings

- **Backend:** choose an engine and manage engine updates. Version checks run automatically when settings open; the refresh icon checks again.
- **Network:** local port, current mode, explicit system proxy, bypass settings, and DNS settings for SpoofDPI. The separate **Optimize** action sets the macOS TTL to 65 for hotspot use.
- **App:** launch at login, application updates, reconnection, and Shadowrocket setup.
- **Manual:** extra arguments per engine and a preview of the launch command. Validation catches conflicts with options already managed by the interface.

Settings apply automatically. Proxy-only changes keep the backend process; backend arguments restart it once. Invalid changes restore the prior settings and backend. Available controls and preset descriptions depend on the selected engine.

## Backend installation

ciadpi is built from ByeDPI source in the application's support directory. This requires `cc` and `make`; install Apple's Command Line Tools if they are missing:

```bash
xcode-select --install
```

SpoofDPI is downloaded from a matching upstream macOS release asset.

## Build from source

Use a Mac with Xcode and the tools required by [build.sh](build.sh):

```bash
git clone https://github.com/iddictive/DPI-Killer.git
cd DPI-Killer
./build.sh
open .build.noindex/DPIKiller.app
```

Create a disk image with `./build.sh --dmg`. Application versions and backend versions are independent: updating ciadpi or SpoofDPI does not update DPI Killer itself.

For a helper-capable local build, set `DPIKILLER_LOCAL_SIGN_IDENTITY` to an existing Apple signing identity. Unsigned source/CI builds use Direct authorization. Stable releases are created from a clean, committed `main` checkout with `scripts/release.sh <version> <notes-file>` and that signing identity. The script uploads a draft; verify the downloaded DMG and installed application before publishing. CI builds unsigned artifacts for compilation checks and never replaces the signed stable release. The updater preserves a running backend and requires the existing Apple signing team for updates from a signed installation.

## Troubleshooting

- **No backend found:** install a managed backend or select an executable path.
- **Port differs from settings:** the preferred port was occupied. Use the active runtime port.
- **DNS controls unavailable:** DNS overrides are supported by SpoofDPI, not ciadpi.
- **Connection still fails:** open Connectivity Diagnostics and Event Logs from the menu. Bypass results depend on the network and backend configuration.

Report reproducible problems in [Issues](https://github.com/iddictive/DPI-Killer/issues), including macOS version, app version, backend, and relevant logs with sensitive data removed.

## Uninstall

Review and run the repository's [uninstall script](scripts/uninstall.sh) to remove the app and its associated configuration.

## Русский

DPI Killer управляет локальным прокси для обхода DPI из строки меню macOS. Поддерживает ByeDPI (`ciadpi`, SOCKS5) и SpoofDPI (HTTP).

### Начало работы

1. Скачайте DMG из [Releases](https://github.com/iddictive/DPI-Killer/releases/latest) и перенесите приложение в Applications.
2. Выберите или установите движок в настройках.
3. Запустите прокси из строки меню. Само приложение открывается с выключенным прокси.
4. Для подключения другого клиента используйте `127.0.0.1` и активный порт приложения: он может отличаться от заданного, если тот занят.

Требуется macOS 13 или новее. Версия 4.0.4 подписана сертификатом Apple Development без нотариализации; при первом запуске может потребоваться подтверждение macOS. Установка помощника требует подтверждения администратора. Режим **Напрямую** доступен без помощника.

### Настройки и режимы

Движок и способ изменения системных настроек выбираются прямо в меню. В **Backend** также проверяются обновления движков. В **Network** находятся локальный порт, системный прокси, настройки обхода и DNS. Кнопка **Оптимизировать раздачу** отдельно устанавливает TTL 65. В **App** находятся автозапуск, обновления и настройка Shadowrocket. **Manual** позволяет добавить аргументы отдельно для каждого движка. Настройки применяются автоматически; неверные изменения откатываются. Пресеты объясняют параметры выбранного движка.

По умолчанию движок работает только на `127.0.0.1` и не меняет сетевые настройки macOS. Системный прокси меняется только для текущего подключения; прежние значения восстанавливаются при остановке. Чужой активный прокси не перезаписывается. Краткая потеря интернета не останавливает исправный движок. Помощник обслуживает только системные настройки, сам движок работает от обычного пользователя. Настоящего VPN-туннеля в этих режимах нет.

Для сборки ciadpi нужны `cc` и `make` из Command Line Tools. SpoofDPI загружается из upstream-релиза. DNS-настройки доступны только для SpoofDPI. Для диагностики используйте Connectivity Diagnostics и Event Logs; результат обхода зависит от сети и выбранных параметров.
