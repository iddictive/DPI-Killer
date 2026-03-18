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
### Professional macOS GUI for `spoofdpi` — Bypass DPI & Remove Throttling

**DPI Killer** is a lightweight, high-performance macOS application built to bypass DPI censorship, unblock websites, and remove ISP throttling.

> Love sharing internet from your phone but hate it when your ISP throttles the speed? Many solutions have been tried over the years. This one is simply convenient for Mac users. If you're on Windows... well, my condolences. 😉

It is a **GoodbyeDPI Mac alternative** that restores access to YouTube and blocked resources without speed loss. No terminal or command line knowledge required.

### Features
- **Control**: Start/stop from Menu Bar.
- **Status**: Visual indicator (🟢/🔴).
- **Auto-Install**: Handles `spoofdpi` dependency via Homebrew.
- **Ultra-Lightweight**: Zero-log silent operation for 0.1% CPU and minimal RAM usage.
- **Clean State**: Automatically kills orphan processes to prevent conflicts.
- **Advanced Settings**: Configure TTL and Window Size values for specialized bypass scenarios.

### Setup
1. **Download**: Get `.dmg` from [Releases](https://github.com/iddictive/DPI-Killer/releases).
2. **Install**: Drag to `Applications`.
3. **Run**: Opens with auto-setup.

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
### Нативный GUI для `spoofdpi` — Обход DPI и снятие ограничений скорости

**DPI Killer** — легкое и производительное приложение для macOS на базе `spoofdpi`, которое обходит блокировки провайдеров (DPI) и убирает замедление трафика. 

> Любите раздавать интернет с телефона, но провайдер режет скорость? Давно было много разных решений, но это — просто удобное для тех, у кого Mac. Для тех, у кого Windows — соболезную. 😉

**Альтернатива GoodbyeDPI для Mac**, возвращает доступ к YouTube и заблокированным ресурсам одним кликом. Работает без терминала.

### Возможности
- **Управление**: Старт/стоп из менюбара.
- **Статус**: Цветной индикатор (🟢/🔴).
- **Auto-установка**: Сам проверит и поставит `spoofdpi`.
- **Максимальная легкость**: Работает бесшумно без записи логов, потребляя ~0.1% CPU и минимум RAM.
- **Чистый запуск**: Автоматически завершает старые процессы `spoofdpi` для избежания конфликтов.
- **Расширенные настройки**: Установка значений TTL и Window Size для специфических сценариев обхода.

### Установка
1. **Скачать**: `.dmg` со страницы [Релизов](https://github.com/iddictive/DPI-Killer/releases).
2. **Установить**: Перетянуть в `Applications`.
3. **Запуск**: Готов к работе сразу.

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
