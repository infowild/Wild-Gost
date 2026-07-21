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
1) Install / Update
2) Add
3) Edit
4) Remove
5) List
6) Service (start/stop/restart)
7) Logs
8) Advanced
9) Uninstall
0) Exit
=============================================
```

**منوی Add (`2`):**

```text
1) Anti-Filter          ← پیشنهادی برای فیلترینگ (ریورس ایران)
2) Upstream (Server B)
3) Entry single (Server A)
4) Entry multi-port / multi-location (Server A)
5) Proxy (SOCKS/HTTP/SS/...)
6) Local port forward
7) Reverse tunnel (generic)
8) More (DNS/TUN/File/Redirect)
0) Back
```

### ویژگی‌های اسکریپت مدیریت

| ویژگی | توضیح |
|:---|:---|
| 🔧 نصب و بروزرسانی خودکار | شناسایی معماری و دانلود آخرین نسخه پایدار |
| ⚙️ یکپارچه‌سازی با Systemd | Start / Stop / Restart |
| 🛡️ **Anti-Filter** | پنل ریورس ایران + نود خارج + چندنود با SNI + سایت فیک |
| ➕ تونل دو سرور | Upstream (B) + Entry تک‌پورت یا Multi-Port/Location |
| 🏷️ نام دلخواه | برای هر کانفیگ / لوکیشن |
| ✏️ Edit | ویرایش سرویس، chain، upstream، target، transport، policies |
| 🛡️ Transport ضد-DPI | MWSS / WSS / TLS / uTLS / otls / KCP / QUIC / gRPC |
| 🎭 Decoy | سایت فیک + probeResist |
| 🔐 احراز هویت | Username/Password |
| 📋 مدیریت JSON با `jq` | ویرایش امن کانفیگ |
| 📜 Logs | Live / Errors / Export / Validate |
| 🗑️ حذف کامل | باینری، سرویس، دستورات و کل `/etc/gost` |

---

### 📘 راهنمای کامل تونل‌ها

قبل از هر چیز روی **هر سروری** که استفاده می‌کنید:

```bash
sudo wild gost
# گزینه 1 = Install / Update
```

از این به بعد با همان دستور وارد پنل می‌شوید. راهنمای کامل در همین README است (دیگر منوی Help داخل اسکریپت نیست).

#### ۰) Anti-Filter — تونل ریورس ضد فیلتر (پیشنهادی)

برای عبور از فیلترینگ ایران: نود خارج به ایران وصل می‌شود (ریورس). کاربر فقط دامنه/IP ایران را می‌بیند؛ IP خارج عمومی نیست.

```text
کاربر ──SNI/Host──► ایران :443 (entrypoint)
                        │
                   ingress (hostname → tunnel id)
                        │
نود خارج ──MWSS/…──► ایران :8443 (tunnel control) ──rtcp──► 127.0.0.1:Xray
```

| مرحله | مسیر منو | کار |
|:---|:---|:---|
| ۱ | `2 → 1 → 1` Iran panel | دامنه، پورت تونل، entry `:443`، transport، TLS، decoy، نود اول |
| ۲ | روی سرور خارج: `2 → 1 → 3` Foreign node | همان Tunnel ID + آدرس ایران + target لوکال (مثلاً `127.0.0.1:2087`) |
| ۳ | `2 → 1 → 2` Add node | نودهای بیشتر با hostname مثل `de.panel.example.com` |
| — | `2 → 1 → 4` | فقط سایت فیک / probeResist |
| — | `2 → 1 → 5` | وضعیت پنل و لیست نودها |

**نکته‌ها**

- مسیریابی چندنود با **hostname / SNI** است (نه path مثل nginx). برای هر نود یک ساب‌دامین یا Host جدا بگذارید.
- Transport دو طرف (ایران و نود) باید یکی باشد؛ پیش‌فرض **MWSS**.
- Decoy روی `:80` یک صفحهٔ عادی نشان می‌دهد تا پروب‌ها سایت ببینند.
- state در `/etc/gost/wild-antifilter.json` ذخیره می‌شود.

#### ۱) کدام نوع تونل را انتخاب کنم؟

| نیاز شما | مسیر منو | توضیح کوتاه |
|:---|:---|:---|
| **ضد فیلتر / ریورس ایران** | `2 → 1` | Anti-Filter (پیشنهادی) |
| **Upstream روی سرور خارج (B)** | `2 → 2` | Relay/SOCKS برای تونل دو سرور |
| **Entry تک‌پورت روی سرور ایران (A)** | `2 → 3` | کلاینت → A → B → Target |
| **چند پورت / چند لوکیشن روی A** | `2 → 4` | چند listen و چند Server B |
| پروکسی تک‌سروره (SOCKS/HTTP/SS) | `2 → 5` | کلاینت مستقیم به همین سرور |
| فوروارد پورت محلی | `2 → 6` | مثلاً `:8080` → `192.168.1.10:80` |
| Reverse Tunnel عمومی | `2 → 7` | بدون wizard ضد فیلتر |
| DNS / TUN / File / Redirect | `2 → 8` | سایر سرویس‌ها |

---

#### ۲) تونل دو سرور — گام‌به‌گام

```text
Client  -->  Server A (listen)  -->  Transport  -->  Server B  -->  Target
مثال:     -->  A:8080           -->  MWSS      -->  B:443     -->  127.0.0.1:8080
```

**نقش‌ها**

| سرور | نقش | کار |
|:---|:---|:---|
| **Server B** | Upstream / Exit | Relay را گوش می‌دهد؛ هدف معمولاً روی همین ماشین است (مثلاً سنایی) |
| **Server A** | Entry | پورت عمومی را باز می‌کند و ترافیک را از طریق chain به B می‌فرستد |

**گام ۱ — روی Server B (اول این را بسازید)**

1. `sudo wild gost` → `2` → `2) Upstream`
2. یک **نام** بگذارید (مثلاً `US`)
3. پورت مثلاً `443` یا `2018`
4. پروتکل: **Relay**
5. Transport: **1 = MWSS** (یا uTLS / KCP / otls / …)
6. path را یادداشت کنید (پیش‌فرض `/ws`)
7. در صورت نیاز username/password

**گام ۲ — روی Server A (تک‌پورت)**

1. `sudo wild gost` → `2` → `3) Entry single`
2. نام کانفیگ
3. Listen port (همان پورتی که کلاینت به آن وصل می‌شود)
4. TCP یا UDP
5. Connector = Relay + **همان Transport و path**
6. آدرس B: ترجیحاً **IP عمومی** (`IP_B:PORT`) نه دامنه‌ای که به سرور اشتباه می‌خورد
7. Target: مثلاً `127.0.0.1:8080` (inbound سنایی روی B)

**گام ۲ جایگزین — Multi-Port / Multi-Location**

1. `sudo wild gost` → `2` → `4) Entry multi`
2. نام گروه کانفیگ
3. چند Location (نام + `IP:port` هر Server B)
4. لیست پورت‌ها (مثلاً `8080,8443`)
5. حالت:
   - **port per location**: `listen = PORT + (index × offset)` — مثلاً offset `10000` → US=`:8080`، DE=`:18080`
   - **shared + selector**: یک پورت، انتخاب خودکار (`fifo` / `round` / `rand`)

**قواعد طلایی**

- اول B، بعد A
- Transport و path دو طرف یکی باشد
- کلاینت به **پورت listen روی A** وصل می‌شود (نه لزوماً پورت سنایی روی B)
- برای ضد-DPI ترجیحاً **MWSS + پورت 443**
- فایروال هر دو سرور پورت‌ها را باز کند

**Transportها**

| گزینه | معنی | توصیه |
|:---|:---|:---|
| **MWSS** | TLS + WS + multiplex | **پیشنهادی** |
| WSS | WebSocket روی TLS | خوب |
| TLS / uTLS | HTTPS / اثر انگشت کلاینت | خوب / قوی‌تر |
| otls | obfs-TLS | استتار |
| KCP / QUIC | UDP | لینک پرلاس / شبیه HTTP3 |
| gRPC | روی TLS | جایگزین WS |
| TCP | ساده | ریسک شناسایی بالا |

---

#### ۳) Reverse Tunnel عمومی (پشت NAT)

```text
Internet --> Public Server (entrypoint)
                ^
                | tunnel
           NAT Client --> Local service (مثلاً 127.0.0.1:80)
```

برای ضد فیلتر ایران ترجیحاً از **Anti-Filter** (`2 → 1`) استفاده کنید.  
**گام ۱ — سرور عمومی:** `2 → 7 → 1` — Tunnel port، Entrypoint، Hostname؛ **Tunnel ID** را ذخیره کنید  
**گام ۲ — پشت NAT:** `2 → 7 → 2` — همان Tunnel ID، آدرس سرور عمومی، Target محلی (`rtcp`/`rudp`)

---

#### ۴) پروکسی تک‌سروره

منو: `2 → 5`

SOCKS5 / HTTP / Relay / Shadowsocks روی همین ماشین. در صورت نیاز chain بالادستی هم می‌توانید وصل کنید.

```text
socks5://SERVER_IP:1080
http://SERVER_IP:8080
```

---

#### ۵) Local Port Forward

منو: `2 → 6`

```text
listen :8080  -->  192.168.1.10:80
```

---

#### ۶) Edit / حذف / عیب‌یابی

| کار | مسیر |
|:---|:---|
| ویرایش سرویس / upstream / target | منو `3` |
| لیست سرویس‌ها | منو `5` |
| Start / Stop / Restart | منو `6` |
| لاگ زنده و خطاها | منو `7` |
| Limiter / API / JSON خام | منو `8` |
| حذف سرویس | منو `4` |

چک‌لیست:

1. سرویس در List دیده می‌شود؟
2. لاگ خطای `dial` / `timeout` / `auth`؟
3. فایروال باز است؟
4. Transport و path یکی است؟
5. Upstream روی B قبل از A بالا آمده؟
6. کلاینت به پورت **A** وصل است؟

Log level: منو `7` → Debug، مشکل را بازتولید کنید، بعد Info.

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
1) Install / Update
2) Add
3) Edit
4) Remove
5) List
6) Service (start/stop/restart)
7) Logs
8) Advanced
9) Uninstall
0) Exit
=============================================
```

**Add menu (`2`):**

```text
1) Anti-Filter          ← recommended for censorship (Iran reverse)
2) Upstream (Server B)
3) Entry single (Server A)
4) Entry multi-port / multi-location (Server A)
5) Proxy (SOCKS/HTTP/SS/...)
6) Local port forward
7) Reverse tunnel (generic)
8) More (DNS/TUN/File/Redirect)
0) Back
```

### Management Script Features

| Feature | Description |
|:---|:---|
| 🔧 Auto Install & Update | Detects architecture and downloads the latest stable release |
| ⚙️ Systemd Integration | Start / Stop / Restart |
| 🛡️ **Anti-Filter** | Iran reverse panel + foreign node + multi-node SNI + decoy site |
| ➕ Two-server tunnel | Upstream (B) + single or multi-port/location Entry (A) |
| 🏷️ Custom names | Per config / location |
| ✏️ Edit | Service, chain, upstream, target, transport, policies |
| 🛡️ Anti-DPI Transport | MWSS / WSS / TLS / uTLS / otls / KCP / QUIC / gRPC |
| 🎭 Decoy | Fake website + probeResist |
| 🔐 Authentication | Username/password |
| 📋 Safe JSON Config | Edited with `jq` |
| 📜 Logs | Live / Errors / Export / Validate |
| 🗑️ Full Uninstall | Binary, service, commands, and all of `/etc/gost` |

---

### 📘 Complete Tunnel Guide

On **every** server you use:

```bash
sudo wild gost
# Option 1 = Install / Update
```

Full guides live in this README (there is no in-script Help menu anymore).

#### 0) Anti-Filter — reverse tunnel (recommended)

Exit nodes dial Iran (reverse). Users only see the Iran domain/IP; foreign IPs stay private.

```text
Client ──SNI/Host──► Iran :443 (entrypoint)
                         │
                    ingress (hostname → tunnel id)
                         │
Exit node ──MWSS/…──► Iran :8443 (tunnel control) ──rtcp──► 127.0.0.1:Xray
```

| Step | Menu | Action |
|:---|:---|:---|
| 1 | `2 → 1 → 1` Iran panel | Domain, tunnel port, entry `:443`, transport, TLS, decoy, first node |
| 2 | On exit: `2 → 1 → 3` Foreign node | Same Tunnel ID + Iran addr + local target (e.g. `127.0.0.1:2087`) |
| 3 | `2 → 1 → 2` Add node | More nodes via hostname like `de.panel.example.com` |

Multi-node routing uses **hostname / SNI** (not URL path). Transport must match on both sides (default **MWSS**). State: `/etc/gost/wild-antifilter.json`.

#### 1) Which tunnel type should I choose?

| Your need | Menu path | Short description |
|:---|:---|:---|
| **Anti-filter / Iran reverse** | `2 → 1` | Anti-Filter (recommended) |
| **Upstream on exit server (B)** | `2 → 2` | Relay/SOCKS for two-server tunnel |
| **Single entry on entry server (A)** | `2 → 3` | Client → A → B → Target |
| **Multi-port / multi-location on A** | `2 → 4` | Several listens and several Server B nodes |
| Single-server proxy (SOCKS/HTTP/SS) | `2 → 5` | Client connects directly to this server |
| Local port forward | `2 → 6` | e.g. `:8080` → `192.168.1.10:80` |
| Generic reverse tunnel | `2 → 7` | Without anti-filter wizard |
| DNS / TUN / File / Redirect | `2 → 8` | Other services |

---

#### 2) Two-server tunnel — step by step

```text
Client  -->  Server A (listen)  -->  Transport  -->  Server B  -->  Target
Example:     -->  A:8080           -->  MWSS      -->  B:443     -->  127.0.0.1:8080
```

**Roles**

| Server | Role | What it does |
|:---|:---|:---|
| **Server B** | Upstream / Exit | Runs Relay; target is usually on this host (e.g. panel inbound) |
| **Server A** | Entry | Opens the public listen port and sends traffic to B via a chain |

**Step 1 — On Server B (create this first)**

1. `sudo wild gost` → `2` → `2) Upstream`
2. Give it a **name** (e.g. `US`)
3. Port e.g. `443` or `2018`
4. Protocol: **Relay**
5. Transport: **1 = MWSS** (or uTLS / KCP / otls / …)
6. Note the WebSocket path (default `/ws`)
7. Optional username/password

**Step 2 — On Server A (single entry)**

1. `sudo wild gost` → `2` → `3) Entry single`
2. Config name
3. Listen port (the port clients connect to)
4. TCP or UDP
5. Connector = Relay + **same transport and path**
6. B address: prefer the **public IP** (`IP_B:PORT`)
7. Target: e.g. `127.0.0.1:8080` (inbound on B)

**Step 2 alternative — Multi-Port / Multi-Location**

1. `sudo wild gost` → `2` → `4) Entry multi`
2. Config group name
3. Add locations (name + each Server B `IP:port`)
4. Ports list (e.g. `8080,8443`)
5. Mode:
   - **port per location**: `listen = PORT + (index × offset)` — e.g. offset `10000` → US=`:8080`, DE=`:18080`
   - **shared + selector**: one listen port; auto pick (`fifo` / `round` / `rand`)

**Golden rules**

- Create B first, then A
- Transport and path must match on both sides
- Clients connect to **A's listen port** (not necessarily B's app port)
- Prefer **MWSS + port 443** for anti-DPI
- Open firewall ports on both servers

**Transports**

| Option | Meaning | Advice |
|:---|:---|:---|
| **MWSS** | TLS + WS + multiplex | **Recommended** |
| WSS | WebSocket over TLS | Good |
| TLS / uTLS | HTTPS / client fingerprint | Good / stronger |
| otls | obfs-TLS | Camouflage |
| KCP / QUIC | UDP | Lossy links / HTTP3-like |
| gRPC | Over TLS | WS alternative |
| TCP | Plain | High detection risk |

---

#### 3) Reverse Tunnel (behind NAT)

```text
Internet --> Public Server (entrypoint)
                ^
                | tunnel
           NAT Client --> Local service (e.g. 127.0.0.1:80)
```

Prefer **Anti-Filter** (`2 → 1`) for Iran censorship.  
**Public server:** `2 → 7 → 1` — tunnel port, entrypoint, hostname; save the **Tunnel ID**  
**NAT client:** `2 → 7 → 2` — same Tunnel ID, public server address, local target (`rtcp`/`rudp`)

---

#### 4) Single-server proxy

Menu: `2 → 5`

SOCKS5 / HTTP / Relay / Shadowsocks on this machine. Optional upstream chain supported.

```text
socks5://SERVER_IP:1080
http://SERVER_IP:8080
```

---

#### 5) Local Port Forward

Menu: `2 → 6`

```text
listen :8080  -->  192.168.1.10:80
```

---

#### 6) Edit / remove / troubleshooting

| Task | Path |
|:---|:---|
| Edit service / upstream / target | Menu `3` |
| List services | Menu `5` |
| Start / Stop / Restart | Menu `6` |
| Live logs and errors | Menu `7` |
| Limiter / API / raw JSON | Menu `8` |
| Remove a service | Menu `4` |

Checklist:

1. Is the service listed?
2. Any `dial` / `timeout` / `auth` errors in logs?
3. Are firewall ports open?
4. Do transport and path match?
5. Is upstream on B up before A?
6. Is the client connecting to **A's** port?

Log level: menu `7` → Debug, reproduce, then Info.

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
