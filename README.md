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
3. Choose a backend in Settings. If none is available, use the installation prompt or select an existing executable.
4. Start the proxy from the menu bar. Check the active port before connecting another client.

Requires macOS 13 or newer. Release packaging uses an ad-hoc signature and does not notarize the app. macOS may require first-launch confirmation.

## Features

- Automatic backend selection, explicit ciadpi or SpoofDPI selection, and custom executable paths.
- SOCKS5 through ciadpi or HTTP proxy through SpoofDPI.
- Configurable local port, with a free loopback port selected when the requested port is busy.
- Bypass presets and engine-specific packet and DNS settings.
- Managed backend installation and updates from upstream GitHub projects.
- Connectivity diagnostics, speed tests, event logs, and application update checks.
- Optional launch at login, reconnection, hotspot optimization, and VPN-client compatibility.

## Proxy modes

| Mode | What DPI Killer does | What you need |
| --- | --- | --- |
| System proxy | Runs the backend and configures macOS network services to use it | A working backend |
| VPN-client compatibility | Exposes a local upstream proxy; the other client owns routing | A client configured for the displayed proxy type and runtime port |
| Packet Tunnel | Routes through the bundled tunnel extension when available | A build with the extension and the required Network Extension signing and provisioning |

Ordinary proxy builds do not provide Packet Tunnel mode. If the required extension or entitlement is missing, the app uses proxy mode.

For Shadowrocket, enable VPN-client compatibility and choose **Configure Shadowrocket** after installing ciadpi. For other clients, use `127.0.0.1` and the active port shown in DPI Killer, not just the configured preferred port.

## Settings

- **Backend:** choose an engine or executable and manage engine updates. Version checks run automatically when settings open; the refresh icon checks again.
- **Network:** connection and runtime status, bypass presets and packet options, and DNS settings for SpoofDPI, grouped into separate cards.
- **App:** startup, application updates, reconnection, IPv6, VPN-client compatibility, and Packet Tunnel availability.
- **Manual:** extra arguments per engine and a preview of the launch command. Validation catches conflicts with options already managed by the interface.

Use **Save & Restart** to apply settings. Available controls depend on the selected engine.

## Backend installation

ciadpi is built from ByeDPI source in the application's support directory. This requires `cc` and `make`; install Apple's Command Line Tools if they are missing:

```bash
xcode-select --install
```

SpoofDPI is downloaded from a matching upstream macOS release asset. You can also select your own executable in Settings.

## Build from source

Use a Mac with Xcode and the tools required by [build.sh](build.sh):

```bash
git clone https://github.com/iddictive/DPI-Killer.git
cd DPI-Killer
./build.sh
open DPIKiller.app
```

Create a disk image with `./build.sh --dmg`. Application versions and backend versions are independent: updating ciadpi or SpoofDPI does not update DPI Killer itself.

## Troubleshooting

- **No backend found:** install a managed backend or select an executable path.
- **Port differs from settings:** the preferred port was occupied. Use the active runtime port.
- **DNS controls unavailable:** DNS overrides are supported by SpoofDPI, not ciadpi.
- **Connection still fails:** open Connectivity Diagnostics and Event Logs from the menu. Bypass results depend on the network and backend configuration.

Report reproducible problems in [Issues](https://github.com/iddictive/DPI-Killer/issues), including macOS version, app version, backend, and relevant logs with sensitive data removed.

## Uninstall

Review and run the repository's [uninstall script](scripts/uninstall.sh) to remove the app and its associated configuration.

## Русский

DPI Killer управляет локальным прокси для обхода DPI из строки меню macOS. Поддерживает ByeDPI (`ciadpi`, SOCKS5), SpoofDPI (HTTP) и собственный исполняемый файл.

### Начало работы

1. Скачайте DMG из [Releases](https://github.com/iddictive/DPI-Killer/releases/latest) и перенесите приложение в Applications.
2. Выберите или установите движок в настройках.
3. Запустите прокси из строки меню.
4. Для подключения другого клиента используйте `127.0.0.1` и активный порт приложения: он может отличаться от заданного, если тот занят.

Требуется macOS 13 или новее. Сборки имеют ad-hoc подпись без нотариализации Apple; при первом запуске может потребоваться подтверждение macOS.

### Настройки и режимы

В **Backend** выбирается движок и проверяются его обновления. В **Network** собраны подключение, обход DPI и DNS. В **App** находятся запуск, обновления приложения и совместимость с VPN-клиентами. **Manual** позволяет добавить аргументы отдельно для каждого движка. Изменения применяются кнопкой **Save & Restart**.

Системный прокси настраивает сетевые службы macOS. В режиме совместимости маршрутизацией управляет внешний VPN-клиент, а DPI Killer предоставляет локальный прокси. Packet Tunnel требует специальной сборки с расширением и соответствующей подписью; обычная прокси-сборка его не предоставляет.

Для сборки ciadpi нужны `cc` и `make` из Command Line Tools. SpoofDPI загружается из upstream-релиза. DNS-настройки доступны только для SpoofDPI. Для диагностики используйте Connectivity Diagnostics и Event Logs; результат обхода зависит от сети и выбранных параметров.
