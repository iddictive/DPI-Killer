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

## 🇺🇸 English

> macOS menu bar app for running a local DPI-bypass proxy with `ciadpi` or `spoofdpi`.

DPI Killer keeps the network tool in one compact macOS surface: start or stop the backend, install managed binaries, choose the active engine, inspect logs, and expose the runtime proxy for browser or VPN-client routing.

## What It Handles

- Starts and stops `ciadpi` or `spoofdpi` from the menu bar.
- Uses `ciadpi` by default when available, with `spoofdpi` as fallback.
- Installs and updates managed backend binaries from the app.
- Selects the proxy mode per backend: SOCKS5 for `ciadpi`, HTTP for `spoofdpi`.
- Falls back to another local port when the preferred port is busy.
- Exposes a local proxy mode for VPN clients such as Shadowrocket or AdGuard.
- Includes Packet Tunnel / System Extension plumbing for signed builds that use the VPN path.
- Keeps advanced controls for TTL, DNS, proxy port, backend flags, and custom binary paths.

## Interface Surfaces

- **Menu bar control:** runtime state, start/stop, diagnostics, logs, update check.
- **Settings:** engine selection, managed binary status, network behavior, local proxy options.
- **VPN compatibility:** route traffic in the VPN client while DPI Killer handles only the local bypass proxy.

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. Move the app to `Applications`.
3. Launch it. The app sets up supported backends when needed.
4. Use `Check for Updates...` from the menu bar app for newer builds.

## VPN Client Setup

1. Enable VPN client compatibility in DPI Killer settings.
2. Configure the VPN client to use `127.0.0.1:8080` as its upstream proxy, or use the runtime port shown by DPI Killer if it picked another port.
3. Keep routing in the VPN client. DPI Killer only owns the local DPI-bypass proxy.

## Uninstall

```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

---

<a id="russian"></a>

## 🇷🇺 Русский

> macOS menu bar приложение для локального DPI-bypass proxy на `ciadpi` или `spoofdpi`.

DPI Killer собирает управление сетевым инструментом в компактный macOS-интерфейс: запуск и остановка backend-а, установка managed binaries, выбор движка, просмотр логов и выдача runtime proxy для браузера или VPN-клиента.

## Что умеет приложение

- Запускает и останавливает `ciadpi` или `spoofdpi` из menu bar.
- Использует `ciadpi` по умолчанию, если он доступен; `spoofdpi` остаётся fallback.
- Устанавливает и обновляет managed backend binaries из приложения.
- Выбирает proxy-режим под backend: SOCKS5 для `ciadpi`, HTTP для `spoofdpi`.
- Переходит на другой локальный порт, если preferred port занят.
- Открывает local proxy mode для VPN-клиентов вроде Shadowrocket или AdGuard.
- Содержит Packet Tunnel / System Extension основу для подписанных сборок с VPN path.
- Оставляет продвинутые настройки TTL, DNS, proxy port, backend flags и custom binary path.

## Интерфейс

- **Menu bar:** состояние runtime, start/stop, diagnostics, logs, update check.
- **Settings:** выбор engine, статус managed binaries, сетевое поведение, local proxy options.
- **VPN compatibility:** маршрутизация остаётся в VPN-клиенте, DPI Killer отвечает только за локальный bypass proxy.

## Установка

1. Скачайте последнюю `.dmg` сборку в [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. Перенесите приложение в `Applications`.
3. Запустите его. Приложение поставит поддерживаемые backend-ы, если они нужны.
4. Обновления ставятся через `Check for Updates...` в menu bar.

## Настройка VPN-клиента

1. Включите VPN client compatibility в настройках DPI Killer.
2. Укажите в VPN-клиенте `127.0.0.1:8080` как upstream proxy или используйте runtime port, который показывает DPI Killer.
3. Оставьте маршрутизацию VPN-клиенту. DPI Killer отвечает только за локальный DPI-bypass proxy.

## Удаление

```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

MIT License.
