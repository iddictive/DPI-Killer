# DPI Killer

<p align="center">
  <img src="https://cdn.jsdelivr.net/gh/iddictive/DPI-Killer@main/assets/banner.png" alt="DPI Killer banner" width="860">
</p>

<p align="center">
  <a href="#english">English</a> • <a href="#russian">Русский</a>
</p>

## Interface Snapshot

<p align="center">
  <img src="https://cdn.jsdelivr.net/gh/iddictive/DPI-Killer@main/assets/interface-network.png" alt="DPI Killer network settings interface" width="860">
</p>

---

<a id="english"></a>

## English

> macOS menu bar controller for local DPI-bypass backends: `ciadpi` / ByeDPI and SpoofDPI.

This README reflects the current GitHub release line, including `v3.0.74` published on July 9, 2026.

DPI Killer starts a local backend on `127.0.0.1`, tracks its runtime state from the menu bar, and exposes the resulting proxy either through macOS system proxy settings or as a local upstream for another client. It is primarily a local proxy controller; Packet Tunnel VPN mode is available only in builds that include the tunnel extension and are signed with the required Network Extension entitlement.

## What The Current App Does

- Selects the backend automatically, or lets you choose `ciadpi`, SpoofDPI, or a custom binary path.
- Uses `ciadpi` / ByeDPI as the preferred managed backend when available.
- Uses SOCKS5 for `ciadpi` and HTTP proxy mode for SpoofDPI.
- Starts the backend on the configured local port, then falls back to another free loopback port if that port is busy.
- Can apply macOS system proxy settings when system proxy mode is enabled.
- Can keep only the local proxy exposed for VPN clients such as Shadowrocket.
- Includes a Shadowrocket helper that opens a SOCKS5 import URL when `ciadpi` is available.
- Checks, installs, and updates managed backend binaries from their upstream GitHub projects.
- Provides runtime diagnostics, a speed test window, event logs, and manual update checks.

## Settings

- **Backend:** automatic, `ciadpi`, SpoofDPI, or custom executable path.
- **Network:** local port, active proxy mode, system proxy behavior, hotspot optimization status.
- **Bypass:** TTL, HTTPS split mode, packet disorder/fake packet options, and presets.
- **DNS:** SpoofDPI DNS settings, including UDP, system DNS, or DNS-over-HTTPS mode.
- **App:** launch at login, app update checks/downloads, IPv6 toggle, auto-reconnect, VPN client compatibility, and Packet Tunnel mode availability.
- **Manual:** extra per-engine arguments with validation against options already managed by the UI.

## Managed Backends

- `ciadpi` is installed to the app support directory by downloading the ByeDPI source from `hufrea/byedpi` and building it locally when `cc` and `make` are available.
- SpoofDPI is installed to the app support directory from the latest matching `xvzc/spoofdpi` macOS release asset.
- If neither managed backend can be installed, choose a custom executable path in Settings.

## VPN And Proxy Modes

- **System proxy mode:** DPI Killer runs the backend and configures macOS network services to use it.
- **VPN client compatibility:** DPI Killer does not own routing; another client can use `127.0.0.1:<runtime-port>` as its upstream proxy.
- **Packet Tunnel mode:** available only when the app bundle contains the tunnel extension and the bundle is signed/provisioned for Network Extension. If that is not true, the app falls back to proxy mode.

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. Move `DPIKiller.app` to `Applications`.
3. Launch the app.
4. If no backend is available, use the install prompt or install/select a backend manually in Settings.

## VPN Client Setup

1. Enable **VPN client compatibility** in DPI Killer settings.
2. Use the runtime port shown by DPI Killer, usually `127.0.0.1:8080` unless the app selected a fallback port.
3. Keep routing rules in the VPN client. DPI Killer only provides the local upstream proxy in this mode.
4. For Shadowrocket, use **Configure Shadowrocket** after `ciadpi` is installed.

## Uninstall

```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

MIT License.

---

<a id="russian"></a>

## Русский

> macOS menu bar контроллер для локальных DPI-bypass backend-ов: `ciadpi` / ByeDPI и SpoofDPI.

Этот README синхронизирован с текущей линейкой GitHub-релизов, включая `v3.0.74` от 9 июля 2026.

DPI Killer запускает локальный backend на `127.0.0.1`, показывает его runtime-состояние в menu bar и отдаёт получившийся proxy либо через системные proxy-настройки macOS, либо как локальный upstream для другого клиента. Основной режим приложения — local proxy controller; Packet Tunnel VPN доступен только в сборках, где встроено tunnel extension и есть подпись с нужным Network Extension entitlement.

## Что реально делает текущая версия

- Выбирает backend автоматически или позволяет выбрать `ciadpi`, SpoofDPI либо custom binary path.
- Предпочитает managed `ciadpi` / ByeDPI, если он доступен.
- Использует SOCKS5 для `ciadpi` и HTTP proxy mode для SpoofDPI.
- Запускает backend на заданном локальном порту и выбирает другой свободный loopback-порт, если порт занят.
- Может включать системный proxy macOS, если включён system proxy mode.
- Может оставлять только локальный proxy для VPN-клиентов вроде Shadowrocket.
- Содержит helper для Shadowrocket: при наличии `ciadpi` открывает SOCKS5 import URL.
- Проверяет, устанавливает и обновляет managed backend binaries из upstream GitHub-проектов.
- Даёт diagnostics, speed test, event logs и ручную проверку обновлений приложения.

## Настройки

- **Backend:** automatic, `ciadpi`, SpoofDPI или custom executable path.
- **Network:** local port, активный proxy mode, поведение system proxy, статус hotspot optimization.
- **Bypass:** TTL, HTTPS split mode, packet disorder/fake packet options и presets.
- **DNS:** DNS-настройки SpoofDPI: UDP, system DNS или DNS-over-HTTPS.
- **App:** launch at login, проверки/скачивание обновлений, IPv6 toggle, auto-reconnect, VPN client compatibility и доступность Packet Tunnel.
- **Manual:** дополнительные аргументы отдельно для каждого engine с проверкой конфликтов с параметрами, которыми уже управляет UI.

## Managed backends

- `ciadpi` ставится в app support directory: приложение скачивает исходники ByeDPI из `hufrea/byedpi` и собирает бинарник локально, если доступны `cc` и `make`.
- SpoofDPI ставится в app support directory из подходящего macOS asset последнего release `xvzc/spoofdpi`.
- Если managed backend-и не установились, выберите custom executable path в Settings.

## VPN и proxy modes

- **System proxy mode:** DPI Killer запускает backend и прописывает его в network services macOS.
- **VPN client compatibility:** DPI Killer не управляет маршрутизацией; другой клиент может использовать `127.0.0.1:<runtime-port>` как upstream proxy.
- **Packet Tunnel mode:** работает только если app bundle содержит tunnel extension и подписан/provisioned под Network Extension. Если условия не выполнены, приложение откатывается в proxy mode.

## Установка

1. Скачайте последнюю `.dmg` сборку в [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. Перенесите `DPIKiller.app` в `Applications`.
3. Запустите приложение.
4. Если backend недоступен, используйте install prompt или установите/выберите backend вручную в Settings.

## Настройка VPN-клиента

1. Включите **VPN client compatibility** в настройках DPI Killer.
2. Используйте runtime port, который показывает DPI Killer: обычно `127.0.0.1:8080`, если приложение не выбрало fallback port.
3. Оставьте routing rules в VPN-клиенте. В этом режиме DPI Killer даёт только локальный upstream proxy.
4. Для Shadowrocket используйте **Configure Shadowrocket** после установки `ciadpi`.

## Удаление

```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

MIT License.
