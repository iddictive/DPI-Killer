# DPI Killer

<p align="left">
  <img src="assets/banner.png" alt="DPI Killer Banner" width="800">
</p>

<p align="left">
  <a href="#english">English</a> | <a href="#russian">Русский</a>
</p>

---

<a name="english"></a>

## English

DPI Killer runs `ciadpi` or `spoofdpi` from the macOS menu bar and exposes them as a local DPI-bypass proxy.

It wraps the DPI bypass backends behind a menu bar control: start/stop, automatic backend install, runtime port selection, reconnect handling, backend-specific settings, and a VPN-compatible local proxy mode.

## What it does

- Starts and stops the bypass backend from the menu bar.
- Picks `ciadpi` by default when available, with `spoofdpi` as fallback.
- Installs or updates managed backend binaries from the app.
- Uses the right proxy mode for each backend: SOCKS5 for `ciadpi`, HTTP for `spoofdpi`.
- Falls back to another local port when the preferred port is busy.
- Can keep only the local proxy exposed for VPN clients such as Shadowrocket or AdGuard.
- Includes Packet Tunnel / System Extension plumbing for signed builds that can use the VPN path.
- Lets advanced users set TTL, DNS behavior, proxy port, backend flags, and custom binary paths.

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. Move the app to `Applications`.
3. Launch it. The app will set up supported backends when needed.
4. Use `Check for Updates...` from the menu bar app for newer builds.

## VPN client compatibility

To use DPI Killer together with another VPN client:

1. Enable VPN client compatibility in DPI Killer settings.
2. Configure the VPN client to use `127.0.0.1:8080` as its upstream proxy, or use the runtime port shown by DPI Killer if it picked another port.
3. Keep routing in the VPN client and let DPI Killer handle only the local DPI-bypass proxy.

## Uninstall

```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

---

<a name="russian"></a>

## Русский

DPI Killer запускает `ciadpi` или `spoofdpi` из macOS menu bar и поднимает локальный proxy для обхода DPI.

Это Mac-обертка над рабочими DPI-bypass backend-ами: управление start/stop, автоустановка backend-а, выбор свободного runtime-порта, reconnect, настройки под конкретный backend и режим локального proxy для работы рядом с VPN-клиентом.

## Что умеет приложение

- Запуск и остановка backend-а из menu bar.
- `ciadpi` по умолчанию, если он доступен; `spoofdpi` остается fallback.
- Установка и обновление managed backend binaries из приложения.
- Правильный proxy-режим для каждого backend-а: SOCKS5 для `ciadpi`, HTTP для `spoofdpi`.
- Переход на другой локальный порт, если preferred port занят.
- Режим совместимости с VPN-клиентами вроде Shadowrocket или AdGuard.
- Packet Tunnel / System Extension основа для подписанных сборок с VPN path.
- Настройки TTL, DNS, proxy port, backend flags и custom binary path.

## Установка

1. Скачайте последнюю `.dmg` сборку в [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. Перенесите приложение в `Applications`.
3. Запустите его. Приложение поставит поддерживаемые backend-ы, если они нужны.
4. Обновления ставятся через `Check for Updates...` в menu bar.

## Совместимость с VPN-клиентами

Чтобы использовать DPI Killer вместе с другим VPN-клиентом:

1. Включите VPN client compatibility в настройках DPI Killer.
2. Укажите в VPN-клиенте `127.0.0.1:8080` как upstream proxy или используйте runtime port, который показывает DPI Killer, если приложение выбрало другой порт.
3. Оставьте маршрутизацию VPN-клиенту; DPI Killer будет отвечать только за локальный DPI-bypass proxy.

## Удаление

```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

MIT License.
