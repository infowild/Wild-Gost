# 🚀 Wild GOST (GO Simple Tunnel Manager)

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8?logo=go)](https://go.dev)
[![GOST](https://img.shields.io/badge/Based_on-GOST_v3-green)](https://github.com/go-gost/gost)

[English Guide](#-english-guide) | [راهنمای فارسی](#-راهنمای-فارسی)

---

## 🇮🇷 راهنمای فارسی

پروژه **Wild GOST** یک بسته‌ی بهینه‌سازی‌شده از سرویس محبوب **[GOST v3](https://github.com/go-gost/gost)** (یک تونل امنیتی همه‌کاره نوشته شده در Go) است که به یک **اسکریپت نصب آسان** و **پنل مدیریت تعاملی** (منوی رنگی لینوکس) مجهز شده است. با استفاده از این ابزار می‌توانید انواع تونل‌های پروکسی را بدون نیاز به ویرایش دستی فایل‌های تنظیمات، راه‌اندازی و مدیریت کنید.

### ⚡ دستور نصب آسان

برای نصب فوری و راه‌اندازی پنل روی سرور خام لینوکس (Ubuntu, Debian, CentOS)، دستور زیر را کپی و در ترمینال اجرا کنید:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild338/wild-gost/master/gost.sh)
```

یا به صورت دستی:

```bash
curl -fsSL https://raw.githubusercontent.com/infowild338/wild-gost/master/gost.sh -o gost.sh && chmod +x gost.sh && sudo ./gost.sh
```

### نحوه استفاده پس از نصب

پس از اجرای نصب از طریق گزینه اول منو، دستور اختصاصی ثبت می‌شود. از این پس در هر زمان با دستور زیر به پنل مدیریت دسترسی خواهید داشت:

```bash
sudo wild gost
```

### نمای منوی اسکریپت

```text
=============================================
      اسکریپت مدیریت آسان و تونل‌زنی GOST
=============================================
وضعیت نرم‌افزار: نصب شده و فعال (Running)
---------------------------------------------
1) نصب یا بروزرسانی GOST (آخرین نسخه)
2) افزودن یک تونل جدید
3) حذف یک تونل موجود
4) مشاهده لیست تونل‌های فعال
5) مدیریت سرویس سیستم (Start / Stop / Restart / Logs)
6) حذف کامل GOST از روی سرور
7) خروج
---------------------------------------------
```

### ویژگی‌های اسکریپت مدیریت

| ویژگی | توضیح |
|:---|:---|
| 🔧 نصب و بروزرسانی خودکار | شناسایی خودکار معماری سخت‌افزار سرور (amd64, arm64, armv7, 386) و دانلود آخرین نسخه پایدار |
| ⚙️ یکپارچه‌سازی با Systemd | اجرای خودکار در پس‌زمینه به عنوان سرویس سیستمی با قابلیت شروع، توقف، ریستارت و مشاهده لاگ |
| ➕ افزودن تونل تعاملی | پشتیبانی از SOCKS5، HTTP، Relay، TCP/UDP Port Forwarding و Shadowsocks |
| 🔗 زنجیره پروکسی بالادستی | امکان هدایت ترافیک از میان پروکسی‌های واسط به صورت زنجیره‌ای |
| 🔐 احراز هویت | تعریف نام کاربری و رمز عبور برای هر تونل |
| 📋 مدیریت کانفیگ JSON | ویرایش امن تنظیمات با ابزار `jq` بدون خطر خرابی ساختار فایل |
| 🗑️ حذف کامل | پاکسازی کامل شامل باینری، سرویس، دستورات و فایل‌های تنظیمات |

### ویژگی‌های اصلی هسته GOST

این پروژه بر پایه هسته قدرتمند GOST v3 ساخته شده و از تمام قابلیت‌های آن بهره‌مند است:

- [x] [گوش دادن روی چندین پورت](https://gost.run/getting-started/quick-start/)
- [x] [زنجیره فوروارد چندسطحی](https://gost.run/concepts/chain/)
- [x] پشتیبانی از پروتکل‌های متنوع
- [x] [فوروارد پورت TCP/UDP](https://gost.run/tutorials/port-forwarding/)
- [x] [پروکسی معکوس (Reverse Proxy)](https://gost.run/tutorials/reverse-proxy/) و [تونل](https://gost.run/tutorials/reverse-proxy-tunnel/)
- [x] [پروکسی شفاف TCP/UDP (Transparent Proxy)](https://gost.run/tutorials/redirect/)
- [x] [سرور و پروکسی DNS](https://gost.run/tutorials/dns/) (پشتیبانی از DoT و DoH)
- [x] [دستگاه TUN/TAP](https://gost.run/tutorials/tuntap/) و [TUN2SOCKS](https://gost.run/tutorials/tungo/)
- [x] [تعادل بار (Load Balancing)](https://gost.run/concepts/selector/)
- [x] [کنترل مسیریابی (Bypass)](https://gost.run/concepts/bypass/)
- [x] [کنترل دسترسی (Admission)](https://gost.run/concepts/admission/)
- [x] [محدودکننده پهنای باند و نرخ](https://gost.run/concepts/limiter/)
- [x] [سیستم پلاگین](https://gost.run/concepts/plugin/)
- [x] [متریک‌های Prometheus](https://gost.run/tutorials/metrics/)
- [x] [پیکربندی داینامیک](https://gost.run/tutorials/api/config/)
- [x] [Web API](https://gost.run/tutorials/api/overview/)

### نمای کلی معماری

![Overview](https://gost.run/images/overview.png)

سه حالت اصلی استفاده از GOST به عنوان تونل وجود دارد:

#### پروکسی مستقیم (Forward Proxy)
به عنوان سرویس پروکسی برای دسترسی به شبکه. می‌توان از چندین پروتکل به صورت ترکیبی برای ساخت زنجیره فوروارد استفاده کرد.

![Proxy](https://gost.run/images/proxy.png)

#### فوروارد پورت (Port Forwarding)
نگاشت پورت یک سرویس به پورت سرویس دیگر. امکان استفاده از زنجیره پروتکل‌ها برای هدایت ترافیک.

![Forward](https://gost.run/images/forward.png)

#### پروکسی معکوس (Reverse Proxy)
استفاده از تونل و نفوذ به شبکه داخلی برای دسترسی عمومی به سرویس‌های پشت NAT یا فایروال.

![Reverse Proxy](https://gost.run/images/reverse-proxy.png)

### جدول پروتکل‌های پشتیبانی شده

| لایه انتقال (Transport) | لایه پروکسی (Proxy) | شبکه و VPN |
|:---|:---|:---|
| TCP / UDP | HTTP / HTTP2 / HTTP3 | TUN / TAP Device |
| TLS / mTLS | SOCKS4 / SOCKS5 | TUN2SOCKS |
| WebSocket (WS/WSS) | Shadowsocks (SS) | Transparent Proxy |
| KCP | SSH / SSHD | DNS Proxy (DoT, DoH) |
| QUIC / WebTransport | Relay | MASQUE |
| gRPC | SNI Proxy | ICMP Tunnel |
| DTLS | File Server | Serial Port |

### روش‌های جایگزین نصب

#### Docker
```bash
docker run --rm gogost/gost -V
```

#### کامپایل از سورس
```bash
git clone https://github.com/infowild338/wild-gost.git
cd wild-gost/cmd/gost
go build
```

### پشتیبانی و منابع

| منبع | لینک |
|:---|:---|
| 📖 مستندات کامل (Wiki) | [gost.run](https://gost.run) |
| 🎬 آموزش ویدیویی (YouTube) | [@gost-tunnel](https://www.youtube.com/@gost-tunnel) |
| 💬 گروه تلگرام | [t.me/gogost](https://t.me/gogost) |
| 📧 گروه گفتگوی گوگل | [go-gost](https://groups.google.com/d/forum/go-gost) |
| 🖥️ ابزار GUI | [gostctl](https://github.com/go-gost/gostctl) |
| 🌐 رابط وب (WebUI) | [gost-ui](https://github.com/go-gost/gost-ui) |

---

## 🇬🇧 English Guide

**Wild GOST** is an optimized distribution of **[GOST v3](https://github.com/go-gost/gost)** (GO Simple Tunnel — a versatile security tunnel written in Go) equipped with a robust, **interactive bash management script** for Linux servers. It allows you to easily deploy and manage tunnel endpoints without manually writing JSON/YAML configurations.

### ⚡ Easy Install Command

To quickly install and launch on any Linux server (Ubuntu, Debian, CentOS), run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild338/wild-gost/master/gost.sh)
```

Or manually:

```bash
curl -fsSL https://raw.githubusercontent.com/infowild338/wild-gost/master/gost.sh -o gost.sh && chmod +x gost.sh && sudo ./gost.sh
```

### Usage After Installation

After running the installation (Option 1 in the menu), a system-wide command shortcut is registered. You can open the management panel at any time:

```bash
sudo wild gost
```

### Script Menu Preview

```text
=============================================
      GOST Easy Tunnel Management Script
=============================================
Software Status: Installed & Active (Running)
---------------------------------------------
1) Install or Update GOST (Latest Version)
2) Add a New Tunnel
3) Remove an Existing Tunnel
4) View Active Tunnels List
5) Manage System Service (Start / Stop / Restart / Logs)
6) Completely Uninstall GOST
7) Exit
---------------------------------------------
```

### Management Script Features

| Feature | Description |
|:---|:---|
| 🔧 Auto Install & Update | Detects CPU architecture (amd64, arm64, armv7, 386) and downloads the latest stable release |
| ⚙️ Systemd Integration | Runs as a background daemon with start, stop, restart, and log viewing capabilities |
| ➕ Interactive Tunnel Setup | Supports SOCKS5, HTTP, Relay, TCP/UDP Port Forwarding, and Shadowsocks |
| 🔗 Upstream Forwarding Chain | Route traffic through upstream proxy hops in a multi-hop chain |
| 🔐 Authentication | Set username/password for each tunnel endpoint |
| 📋 JSON Config Management | Safe configuration editing using `jq` to prevent file corruption |
| 🗑️ Full Uninstall | Clean removal of binary, service, commands, and config files |

### Core GOST Features

This project is built on the powerful GOST v3 engine and inherits all of its capabilities:

- [x] [Multi-port Listening](https://gost.run/en/getting-started/quick-start/)
- [x] [Multi-level Forwarding Chain](https://gost.run/en/concepts/chain/)
- [x] Rich Protocol Support
- [x] [TCP/UDP Port Forwarding](https://gost.run/en/tutorials/port-forwarding/)
- [x] [Reverse Proxy](https://gost.run/en/tutorials/reverse-proxy/) and [Tunnel](https://gost.run/en/tutorials/reverse-proxy-tunnel/)
- [x] [TCP/UDP Transparent Proxy](https://gost.run/en/tutorials/redirect/)
- [x] DNS [Resolver](https://gost.run/en/concepts/resolver/) and [Proxy](https://gost.run/en/tutorials/dns/) (DoT, DoH)
- [x] [TUN/TAP Device](https://gost.run/en/tutorials/tuntap/) and [TUN2SOCKS](https://gost.run/en/tutorials/tungo/)
- [x] [Load Balancing](https://gost.run/en/concepts/selector/)
- [x] [Routing Control (Bypass)](https://gost.run/en/concepts/bypass/)
- [x] [Admission Control](https://gost.run/en/concepts/limiter/)
- [x] [Bandwidth / Rate Limiter](https://gost.run/en/concepts/limiter/)
- [x] [Plugin System](https://gost.run/en/concepts/plugin/)
- [x] [Prometheus Metrics](https://gost.run/en/tutorials/metrics/)
- [x] [Dynamic Configuration](https://gost.run/en/tutorials/api/config/)
- [x] [Web API](https://gost.run/en/tutorials/api/overview/)

### Architecture Overview

![Overview](https://gost.run/images/overview.png)

There are three main ways to use GOST as a tunnel:

#### Forward Proxy
Acts as a proxy service for network access. Multiple protocols can be combined to form a forwarding chain.

![Proxy](https://gost.run/images/proxy.png)

#### Port Forwarding
Maps the port of one service to another. Supports protocol chaining for traffic forwarding.

![Forward](https://gost.run/images/forward.png)

#### Reverse Proxy
Uses tunnel and intranet penetration to expose local services behind NAT or firewall to the public network.

![Reverse Proxy](https://gost.run/images/reverse-proxy.png)

### Supported Protocols

| Transport Layer | Proxy Layer | Network & VPN |
|:---|:---|:---|
| TCP / UDP | HTTP / HTTP2 / HTTP3 | TUN / TAP Device |
| TLS / mTLS | SOCKS4 / SOCKS5 | TUN2SOCKS |
| WebSocket (WS/WSS) | Shadowsocks (SS) | Transparent Proxy |
| KCP | SSH / SSHD | DNS Proxy (DoT, DoH) |
| QUIC / WebTransport | Relay | MASQUE |
| gRPC | SNI Proxy | ICMP Tunnel |
| DTLS | File Server | Serial Port |

### Alternative Installation Methods

#### Docker
```bash
docker run --rm gogost/gost -V
```

#### Build from Source
```bash
git clone https://github.com/infowild338/wild-gost.git
cd wild-gost/cmd/gost
go build
```

### Support & Resources

| Resource | Link |
|:---|:---|
| 📖 Full Documentation (Wiki) | [gost.run](https://gost.run/en/) |
| 🎬 Video Tutorials (YouTube) | [@gost-tunnel](https://www.youtube.com/@gost-tunnel) |
| 💬 Telegram Group | [t.me/gogost](https://t.me/gogost) |
| 📧 Google Discussion Group | [go-gost](https://groups.google.com/d/forum/go-gost) |
| 🖥️ GUI Tool | [gostctl](https://github.com/go-gost/gostctl) |
| 🌐 Web Interface (WebUI) | [gost-ui](https://github.com/go-gost/gost-ui) |

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).
