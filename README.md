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
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
```

یا به صورت دستی:

```bash
curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh -o gost.sh && chmod +x gost.sh && sudo ./gost.sh
```

### نحوه استفاده پس از نصب

پس از اجرای نصب از طریق گزینه اول منو، دستور اختصاصی ثبت می‌شود. از این پس در هر زمان با دستور زیر به پنل مدیریت دسترسی خواهید داشت:

```bash
sudo wild gost
```

### نمای منوی اسکریپت

```text
=============================================
    Wild GOST - Easy Tunnel Management
=============================================
1) Install or Update GOST
2) Add Service / Tunnel (all types)
3) Remove a Service
4) View Services & Config Summary
5) Policies (Bypass / Admission / Limiter / API / Metrics)
6) Manage System Service (Start/Stop/Restart)
7) Logs & Diagnostics
8) Show Raw Config JSON
9) Help / Tunnel usage guide
10) Completely Uninstall GOST
0) Exit
=============================================
```

### ویژگی‌های اسکریپت مدیریت

| ویژگی | توضیح |
|:---|:---|
| 🔧 نصب و بروزرسانی خودکار | شناسایی معماری (amd64, arm64, armv7, 386, …) و دانلود آخرین نسخه پایدار |
| ⚙️ یکپارچه‌سازی با Systemd | سرویس پس‌زمینه با Start / Stop / Restart |
| ➕ انواع تونل تعاملی | پروکسی، Port Forward، تونل دو سرور، Reverse، DNS، Redirect، TUN، File |
| 🛡️ Transport ضد-DPI | TLS / WSS / MWSS (multiplex) برای مسیر بین دو سرور |
| 🔐 احراز هویت | Username/Password برای endpointها |
| 📋 مدیریت JSON با `jq` | ویرایش امن کانفیگ بدون خراب شدن فایل |
| 📜 لاگ و عیب‌یابی | Live log، فیلتر خطا، export، validate کانفیگ |
| 🗑️ حذف کامل | پاکسازی باینری، سرویس، دستورات و کل `/etc/gost` |

---

### 📘 راهنمای کامل تونل‌ها

قبل از هر چیز روی **هر سروری** که استفاده می‌کنید:

```bash
sudo wild gost
# گزینه 1 = Install or Update GOST
```

از این به بعد با همان دستور وارد پنل می‌شوید. در منو، گزینه **۹ = Help** هم راهنمای کوتاه داخل خود اسکریپت است.

#### ۱) کدام نوع تونل را انتخاب کنم؟

| نیاز شما | مسیر منو | توضیح کوتاه |
|:---|:---|:---|
| فقط پروکسی روی یک سرور (SOCKS/HTTP/SS) | `2 → 1` | کلاینت مستقیم به همین سرور وصل می‌شود |
| فوروارد پورت روی همین سرور | `2 → 2` | مثلاً `:8080` به `192.168.1.10:80` |
| **تونل بین دو سرور (رایج‌ترین)** | `2 → 3` | کلاینت → سرور A → سرور B → هدف |
| سرویس پشت NAT / بدون IP عمومی | `2 → 4` | Reverse Tunnel |
| DNS محلی | `2 → 6` | DNS proxy + upstream |
| پروکسی شفاف | `2 → 5` | نیاز به iptables/nftables |
| TUN / VPN-مانند | `2 → 7` | بعد از ساخت، IP/route را خودتان تنظیم کنید |

---

#### ۲) تونل دو سرور (Remote Port Forward) — گام‌به‌گام

این رایج‌ترین سناریو است:

```text
Client  -->  Server A (listen)  -->  Transport  -->  Server B  -->  Target
مثال:     -->  A:8080           -->  MWSS      -->  B:443     -->  127.0.0.1:80
```

**نقش‌ها**

| سرور | نقش | کار |
|:---|:---|:---|
| **Server B** | Upstream / Exit | Relay یا SOCKS5 را گوش می‌دهد؛ هدف معمولاً روی همین شبکه است |
| **Server A** | Entry | پورت عمومی را باز می‌کند و ترافیک را از طریق chain به B می‌فرستد |

**گام ۱ — روی Server B (اول این را بسازید)**

1. `sudo wild gost` → گزینه `2` → گزینه `3` → `2) Server B`
2. پورت مثلاً `443`
3. پروتکل: **Relay** (پیشنهادی)
4. Transport: **4 = MWSS** (پیشنهادی برای ضد-DPI)
5. در صورت نیاز username/password
6. WebSocket path را یادداشت کنید (پیش‌فرض `/ws`)

**گام ۲ — روی Server A**

1. `sudo wild gost` → گزینه `2` → گزینه `3` → `1) Server A`
2. Listen port مثلاً `8080`
3. TCP یا UDP
4. Upstream type = همان Relay
5. **همان Transport** (مثلاً MWSS) و **همان path** (`/ws`)
6. آدرس Server B: `IP_B:443`
7. Target: مثلاً `127.0.0.1:80` (سرویسی که از روی B در دسترس است)

**قواعد طلایی**

- اول B را بسازید، بعد A
- Transport و path دو طرف باید یکی باشد
- برای ضد-DPI ترجیحاً **MWSS + پورت 443**
- فایروال هر دو سرور باید پورت‌ها را باز کند
- تست: کلاینت را به `IP_A:8080` وصل کنید؛ باید به Target روی B برسید

**Transportها (ضد-DPI)**

| گزینه | معنی | توصیه |
|:---|:---|:---|
| Plain TCP | ساده و خام | ریسک شناسایی بالا |
| TLS | رمزنگاری، شبیه HTTPS | خوب |
| WSS | WebSocket روی TLS | بهتر |
| **MWSS** | TLS + WebSocket + multiplex | **پیشنهادی** — چند session روی اتصال کمتر |

---

#### ۳) Reverse Tunnel (پشت NAT)

وقتی سرویس داخل شبکه خصوصی است و IP عمومی ندارد:

```text
Internet --> Public Server (entrypoint)
                ^
                | tunnel
           NAT Client --> Local service (مثلاً 127.0.0.1:80)
```

**گام ۱ — سرور عمومی (Server)**

- منو: `2 → 4 → 1`
- Tunnel port (مثلاً `8421`)
- Entrypoint port (مثلاً `8420`) = پورتی که از اینترنت دیده می‌شود
- Hostname برای ingress (مثلاً `app.example.com`)
- **Tunnel ID (UUID)** را کپی و ذخیره کنید

**گام ۲ — سرور پشت NAT (Client)**

- منو: `2 → 4 → 2`
- همان Tunnel ID
- آدرس سرور عمومی: `IP:8421`
- Target محلی: `127.0.0.1:80`
- `rtcp` برای TCP یا `rudp` برای UDP

دسترسی از بیرون معمولاً از طریق entrypoint سرور عمومی انجام می‌شود.

---

#### ۴) پروکسی تک‌سروره

منو: `2 → 1`

مناسب برای SOCKS5 / HTTP / Relay / Shadowsocks روی همین ماشین.

1. پروتکل را انتخاب کنید
2. پورت listen
3. Transport listener (معمولاً `tcp`؛ برای ضد-DPI: `tls` / `wss` / `mwss`)
4. در صورت نیاز auth
5. اگر می‌خواهید ترافیک از پروکسی دیگری رد شود: Attach upstream chain = `y`

نمونه اتصال کلاینت:

```text
socks5://SERVER_IP:1080
http://SERVER_IP:8080
```

---

#### ۵) Local Port Forward

منو: `2 → 2`

پورت محلی را به یک هدف نگاشت می‌کند:

```text
listen :8080  -->  192.168.1.10:80
```

اگر chain بسازید، فوروارد از طریق پروکسی واسط انجام می‌شود.

---

#### ۶) عیب‌یابی تونل

| کار | مسیر |
|:---|:---|
| لیست سرویس‌ها / Upstream / Target | منو `4` |
| لاگ زنده و خطاها | منو `7` |
| JSON خام | منو `8` |
| Restart سرویس | منو `6` |
| حذف و ساخت مجدد | منو `3` سپس دوباره `2` |

چک‌لیست سریع:

1. سرویس در منو ۴ دیده می‌شود؟
2. در لاگ خطای `dial` / `connect` / `auth` هست؟
3. فایروال پورت را باز کرده؟
4. Transport و path دو سرور یکی است؟
5. روی B اول upstream بالا آمده، بعد A؟

برای جزئیات بیشتر موقتاً Log level را در منو `7` روی **debug** بگذارید، مشکل را بازتولید کنید، بعد دوباره به **info** برگردانید.

---

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
git clone https://github.com/infowild/Wild-Gost.git
cd Wild-Gost/cmd/gost
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
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
```

Or manually:

```bash
curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh -o gost.sh && chmod +x gost.sh && sudo ./gost.sh
```

### Usage After Installation

After running the installation (Option 1 in the menu), a system-wide command shortcut is registered. You can open the management panel at any time:

```bash
sudo wild gost
```

### Script Menu Preview

```text
=============================================
    Wild GOST - Easy Tunnel Management
=============================================
1) Install or Update GOST
2) Add Service / Tunnel (all types)
3) Remove a Service
4) View Services & Config Summary
5) Policies (Bypass / Admission / Limiter / API / Metrics)
6) Manage System Service (Start/Stop/Restart)
7) Logs & Diagnostics
8) Show Raw Config JSON
9) Help / Tunnel usage guide
10) Completely Uninstall GOST
0) Exit
=============================================
```

### Management Script Features

| Feature | Description |
|:---|:---|
| 🔧 Auto Install & Update | Detects CPU architecture and downloads the latest stable release |
| ⚙️ Systemd Integration | Background daemon with start / stop / restart |
| ➕ Interactive Tunnel Types | Proxy, port forward, two-server tunnel, reverse, DNS, redirect, TUN, file |
| 🛡️ Anti-DPI Transport | TLS / WSS / MWSS (multiplex) between servers |
| 🔐 Authentication | Username/password per endpoint |
| 📋 Safe JSON Config | Edited with `jq` |
| 📜 Logs & Diagnostics | Live logs, error filter, export, config validation |
| 🗑️ Full Uninstall | Removes binary, service, commands, and all of `/etc/gost` |

---

### 📘 Complete Tunnel Guide

On **every** server you use:

```bash
sudo wild gost
# Option 1 = Install or Update GOST
```

Use the same command later to reopen the panel. Menu **9 = Help** also shows a short in-script guide.

#### 1) Which tunnel type should I choose?

| Your need | Menu path | Short description |
|:---|:---|:---|
| Single-server proxy (SOCKS/HTTP/SS) | `2 → 1` | Client connects directly to this server |
| Local port forward | `2 → 2` | e.g. `:8080` → `192.168.1.10:80` |
| **Two-server tunnel (most common)** | `2 → 3` | Client → Server A → Server B → Target |
| Service behind NAT / no public IP | `2 → 4` | Reverse Tunnel |
| Local DNS | `2 → 6` | DNS proxy + upstream |
| Transparent proxy | `2 → 5` | Needs iptables/nftables |
| TUN / VPN-like | `2 → 7` | After create, configure IP/routes yourself |

---

#### 2) Two-server tunnel (Remote Port Forward) — step by step

This is the most common scenario:

```text
Client  -->  Server A (listen)  -->  Transport  -->  Server B  -->  Target
Example:     -->  A:8080           -->  MWSS      -->  B:443     -->  127.0.0.1:80
```

**Roles**

| Server | Role | What it does |
|:---|:---|:---|
| **Server B** | Upstream / Exit | Runs Relay or SOCKS5; target is usually on this network |
| **Server A** | Entry | Opens the public listen port and sends traffic to B via a chain |

**Step 1 — On Server B (create this first)**

1. `sudo wild gost` → `2` → `3` → `2) Server B`
2. Port e.g. `443`
3. Protocol: **Relay** (recommended)
4. Transport: **4 = MWSS** (recommended for anti-DPI)
5. Optional username/password
6. Note the WebSocket path (default `/ws`)

**Step 2 — On Server A**

1. `sudo wild gost` → `2` → `3` → `1) Server A`
2. Listen port e.g. `8080`
3. TCP or UDP
4. Upstream type = same Relay
5. **Same transport** (e.g. MWSS) and **same path** (`/ws`)
6. Server B address: `IP_B:443`
7. Target: e.g. `127.0.0.1:80` (reachable from B)

**Golden rules**

- Build B first, then A
- Transport and path must match on both sides
- Prefer **MWSS + port 443** for anti-DPI
- Open firewall ports on both servers
- Test: connect a client to `IP_A:8080`; it should reach Target on B

**Transports (anti-DPI)**

| Option | Meaning | Advice |
|:---|:---|:---|
| Plain TCP | Simple / raw | High DPI risk |
| TLS | Encrypted, HTTPS-like | Good |
| WSS | WebSocket over TLS | Better |
| **MWSS** | TLS + WebSocket + multiplex | **Recommended** — fewer connections |

---

#### 3) Reverse Tunnel (behind NAT)

Use when the service is on a private network with no public IP:

```text
Internet --> Public Server (entrypoint)
                ^
                | tunnel
           NAT Client --> Local service (e.g. 127.0.0.1:80)
```

**Step 1 — Public server (Server)**

- Menu: `2 → 4 → 1`
- Tunnel port (e.g. `8421`)
- Entrypoint port (e.g. `8420`) = public-facing port
- Ingress hostname (e.g. `app.example.com`)
- Copy and save the **Tunnel ID (UUID)**

**Step 2 — NAT server (Client)**

- Menu: `2 → 4 → 2`
- Same Tunnel ID
- Public server address: `IP:8421`
- Local target: `127.0.0.1:80`
- `rtcp` for TCP or `rudp` for UDP

External access is usually through the public server entrypoint.

---

#### 4) Single-server proxy

Menu: `2 → 1`

Good for SOCKS5 / HTTP / Relay / Shadowsocks on this machine.

1. Choose protocol
2. Listen port
3. Listener transport (usually `tcp`; for anti-DPI: `tls` / `wss` / `mwss`)
4. Optional auth
5. To route via another proxy: Attach upstream chain = `y`

Client examples:

```text
socks5://SERVER_IP:1080
http://SERVER_IP:8080
```

---

#### 5) Local Port Forward

Menu: `2 → 2`

Maps a local listen port to a target:

```text
listen :8080  -->  192.168.1.10:80
```

If you attach a chain, forwarding goes through an upstream proxy.

---

#### 6) Tunnel troubleshooting

| Task | Path |
|:---|:---|
| List services / Upstream / Target | Menu `4` |
| Live logs and errors | Menu `7` |
| Raw JSON | Menu `8` |
| Restart service | Menu `6` |
| Remove and recreate | Menu `3`, then `2` again |

Quick checklist:

1. Is the service listed in menu 4?
2. Any `dial` / `connect` / `auth` errors in logs?
3. Are firewall ports open?
4. Do transport and path match on both servers?
5. Is upstream on B up before A?

For more detail, temporarily set log level to **debug** in menu `7`, reproduce the issue, then switch back to **info**.

---

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
- [x] [Admission Control](https://gost.run/en/concepts/admission/)
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
git clone https://github.com/infowild/Wild-Gost.git
cd Wild-Gost/cmd/gost
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
