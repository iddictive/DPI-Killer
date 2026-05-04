# DPI Killer⚡️

<p align="left">
  <img src="assets/banner.png" alt="DPI Killer Banner" width="800">
</p>

<p align="left">
  <a href="#english">English</a> • <a href="#russian">Русский</a>
</p>

---

<a name="english"></a>
## English 🇺🇸
### Professional macOS GUI for `ciadpi` / `spoofdpi` — Bypass DPI & Remove Throttling

**DPI Killer** is a lightweight, high-performance macOS application for bypassing DPI censorship, unblocking websites, and reducing throttling. It now prefers the lighter `ciadpi` backend when available, while keeping `spoofdpi` as a fallback.

> Love sharing internet from your phone but hate it when your ISP throttles the speed? Many solutions have been tried over the years. This one is simply convenient for Mac users. If you're on Windows... well, my condolences. 😉

It is a **GoodbyeDPI Mac alternative** that restores access to YouTube and blocked resources without speed loss. No terminal or command line knowledge required.

### Features
- **Control**: Start/stop from Menu Bar.
- **Status**: Visual indicator (🟢/🔴).
- **Backend Selector**: Choose `Auto`, `ciadpi`, `spoofdpi`, or a custom binary path in Settings.
- **Auto-Install**: Builds lightweight `ciadpi` automatically and installs official `spoofdpi` as fallback.
- **Auto-Reconnect**: Restores the backend after connectivity drops when enabled.
- **Proxy-Aware**: Uses `SOCKS5` for `ciadpi` and `HTTP` proxy mode for `spoofdpi`.
- **VPN Foundation**: Includes Packet Tunnel + System Extension scaffolding, activation path, and safe fallback when Apple signing is unavailable.
- **Ultra-Lightweight**: Zero-log silent operation for 0.1% CPU and minimal RAM usage.
- **Clean State**: Automatically kills orphan processes to prevent conflicts.
- **Advanced Settings**: Configure backend, TTL, proxy port, DNS behavior, and manual flags.

### Setup
1. **Download**: Get `.dmg` from [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. **Install**: Drag to `Applications`.
3. **Run**: Opens with auto-setup.
4. **Update**: Use `Check for Updates...` from the menu bar app to install newer builds.

### VPN Compatibility
To use DPI Killer alongside a VPN (like Shadowrocket, AdGuard, etc.):
1. **Disable `Use system-wide proxy`** in DPI Killer Settings.
2. Configure your VPN to use `127.0.0.1:8080` (or your custom port) as the **upstream (parent) proxy**.
3. This allows the VPN to handle routing while DPI Killer handles DPI bypassing.

### Uninstall
```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

---

<a name="russian"></a>
## Русский 🇷🇺
### Нативный GUI для `ciadpi` / `spoofdpi` — Обход DPI и снятие ограничений скорости

**DPI Killer** — лёгкое и производительное приложение для macOS для обхода DPI и снятия ограничений скорости. По умолчанию оно использует более лёгкий `ciadpi`, а `spoofdpi` остаётся совместимым fallback.

> Любите раздавать интернет с телефона, но провайдер режет скорость? Давно было много разных решений, но это — просто удобное для тех, у кого Mac. Для тех, у кого Windows — соболезную. 😉

**Альтернатива GoodbyeDPI для Mac**, возвращает доступ к YouTube и заблокированным ресурсам одним кликом. Работает без терминала.

### Возможности
- **Управление**: Старт/стоп из менюбара.
- **Статус**: Цветной индикатор (🟢/🔴).
- **Выбор backend-а**: В настройках можно выбрать `Авто`, `ciadpi`, `spoofdpi` или свой путь к бинарю.
- **Auto-установка**: Сам соберёт лёгкий `ciadpi` и установит официальный `spoofdpi` как fallback.
- **Авто-реконнект**: Может восстановить backend после пропадания сети.
- **Корректный proxy-режим**: Для `ciadpi` использует `SOCKS5`, для `spoofdpi` — `HTTP` proxy.
- **Основа для VPN/TUN**: В репе уже есть Packet Tunnel, System Extension activation path и безопасный fallback, если Apple signing ещё не готов.
- **Максимальная легкость**: Работает бесшумно без записи логов, потребляя ~0.1% CPU и минимум RAM.
- **Чистый запуск**: Автоматически завершает старые backend-процессы для избежания конфликтов.
- **Расширенные настройки**: Backend, TTL, порт, DNS-поведение и ручные флаги.

### Установка
1. **Скачать**: `.dmg` со страницы [Релизов](https://github.com/iddictive/DPI-Killer/releases).
2. **Установить**: Перетянуть в `Applications`.
3. **Запуск**: Готов к работе сразу.
4. **Обновления**: Новую сборку можно поставить через пункт `Проверить обновления...` в меню приложения.

### Совместимость с VPN
Чтобы использовать DPI Killer вместе с VPN (Shadowrocket, AdGuard и т.д.):
1. **Отключите `Использовать системный прокси`** в настройках DPI Killer.
2. В самом VPN-клиенте укажите `127.0.0.1:8080` (или ваш порт) в качестве **родительского (upstream) прокси**.
3. Таким образом VPN будет отвечать за маршрутизацию, а DPI Killer — за обход DPI.

### Удаление
```bash
curl -sL https://raw.githubusercontent.com/iddictive/DPI-Killer/main/scripts/uninstall.sh | bash
```

---
MIT License.
