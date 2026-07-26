# Wild GOST

<p align="center">
  <strong>Management panel for <a href="https://github.com/go-gost/gost">GOST v3</a></strong><br>
  Install · Tunnel · Proxy · TLS · Logs · Uninstall
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"></a>
  <a href="https://github.com/go-gost/gost"><img src="https://img.shields.io/badge/GOST-v3-green" alt="GOST"></a>
  <a href="docs/README.md"><img src="https://img.shields.io/badge/Docs-14_guides-informational" alt="Docs"></a>
</p>

<p align="center">
  <a href="#english">English</a> ·
  <a href="#فارسی">فارسی</a> ·
  <a href="docs/README.md">Documentation</a>
</p>

---

## فارسی

پنل تعاملی لینوکس برای GOST v3. کانفیگ در `/etc/gost/config.json`.

### نصب سریع

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
```

```bash
sudo wild gost
```

| پیش‌نیاز | |
|:---|:---|
| OS | Linux |
| دسترسی | root |
| ابزار | `curl` یا `wget` · `jq` · `systemctl` |

### معماری‌ها

Wild GOST چند توپولوژی جدا دارد. قبل از ساخت، یکی را انتخاب کن.

#### ۱) دو سرور — فوروارد (Entry → Upstream)

کلاینت به A وصل می‌شود؛ A به B تونل می‌زند؛ B به هدف (مثلاً سنایی) می‌فرستد.  
Transport: MWSS / WSS / TLS / … یا **MASQUE** (UDP).

```text
Client ──► Server A (Entry) ════ tunnel ════► Server B (Upstream) ──► Target
              listen              MWSS/MASQUE         relay/masque      127.0.0.1:port
```

منو: `2 → 2` روی B، بعد `2 → 3` روی A · راهنما: [05](docs/fa/05-remote-forward.md) · [06](docs/fa/06-masque.md)

#### ۲) Anti-Filter — ریورس (خارج → ایران)

نود خارج به ایران dial می‌کند. کلاینت فقط ایران را با SNI/Host می‌بیند.

```text
Client ──SNI──► Iran :443 (entrypoint)
                     │
Abroad node ══tunnel══► Iran :control ──► 127.0.0.1:panel @ Abroad
```

منو: `2 → 1` · راهنما: [04](docs/fa/04-antifilter.md)

#### ۳) Multi-entry — چند پورت / چند لوکیشن

یک Entry روی A به چند Server B وصل می‌شود (پورت جدا یا selector).

```text
                 ┌──► B1 (US)
Client ──► A ────┼──► B2 (DE) ──► Target
                 └──► B3 (...)
```

منو: `2 → 4` · راهنما: [09](docs/fa/09-multi-entry.md)

#### ۴) Proxy تک‌سرور

بدون Server دوم؛ کلاینت مستقیم به همین هاست.

```text
Client ──► Server (SOCKS/HTTP/SS/MASQUE/…) ──► Internet / Target
```

منو: `2 → 5` · راهنما: [14](docs/fa/14-proxy-types.md)

#### ۵) Local forward

فقط جابه‌جایی پورت روی همین ماشین/شبکه.

```text
Client ──► This host :listen ──► IP:port (LAN / local)
```

منو: `2 → 6`

#### ۶) Reverse عمومی

دستگاه پشت NAT به سرور عمومی dial می‌کند (tunnel / rtcp / rudp).  
برای ضد فیلتر ایران ترجیحاً معماری ۲ (Anti-Filter).

```text
Device (NAT) ══reverse dial══► Public server ──► Target
```

منو: `2 → 7`

#### ۷) More — DNS / TUN / File / Redirect

سرویس‌های جانبی روی همین هاست؛ تونل دو سرور نیستند.

منو: `2 → 8` · راهنما: [10](docs/fa/10-dns-tun-file-redirect.md)

| معماری | جهت تونل | چند سرور؟ |
|:---|:---|:---|
| فوروارد Entry→Upstream | A → B | بله |
| Anti-Filter | B → Iran (ریورس) | بله |
| Multi-entry | A → چند B | بله |
| Proxy / Forward / More | — | معمولاً یک هاست |
| Reverse عمومی | دستگاه → سرور عمومی | بله |

### منوی اصلی

| # | بخش | شرح |
|:---:|:---|:---|
| **1** | Install / Update | Stable · Nightly · MASQUE-patched · Local binary |
| **2** | Add | ساخت سرویس و تونل |
| **3** | Edit | ویرایش سرویس و chain |
| **4** | Remove | حذف یک سرویس |
| **5** | List | فهرست سرویس‌ها |
| **6** | Service | start · stop · restart · status |
| **7** | Logs | لاگ زنده · خطا · validate |
| **8** | Advanced | Bypass · Admission · Limiter · API · Metrics · Raw JSON |
| **9** | Uninstall | پاکسازی باینری، کانفیگ، decoy، nginx، هوک‌ها |
| **0** | Exit | خروج |

#### Add → جزئیات

| # | گزینه | کاربرد |
|:---:|:---|:---|
| 1 | **Anti-Filter** | ریورس ایران · SNI · decoy · نود خارج |
| 2 | **Upstream** | Server B — سمت خروج تونل |
| 3 | **Entry** | Server A — listen کلاینت |
| 4 | **Multi** | چند پورت / چند لوکیشن |
| 5 | **Proxy** | SOCKS · HTTP · SS · Relay · MASQUE · … |
| 6 | **Local forward** | listen → target روی همین هاست |
| 7 | **Reverse** | tunnel · rtcp · rudp |
| 8 | **More** | DNS · TUN · File · Redirect |

### سناریوها

| سناریو | مسیر | نکات |
|:---|:---|:---|
| Anti-Filter | `2 → 1` | ایران = پنل · خارج = نود · کلاینت با SNI |
| دو سرور MWSS | `2 → 2` سپس `2 → 3` | اول B، بعد A · path یکسان |
| دو سرور MASQUE | همان + transport `11` | UDP · B:`http3` · A:`h3-masque` |
| Multi-entry | `2 → 4` | پورت جدا یا selector |
| Proxy تک‌سرور | `2 → 5` | بدون تونل دوم |
| Forward محلی | `2 → 6` | فقط remap پورت |
| Reverse | `2 → 7` | پشت NAT |
| DNS / TUN / File | `2 → 8` | سرویس جانبی |

### کانال‌های نصب

| # | کانال | توصیه |
|:---:|:---|:---|
| 1 | **Stable** | استفاده عادی — برای MASQUE مناسب نیست |
| 2 | **Nightly** | masque ثبت‌شده؛ TCP CONNECT ممکن است ناپایدار باشد |
| 3 | **Build patched** | بیلد + پچ MASQUE — مناسب تونل HTTP/3 |
| 4 | **Local binary** | نصب از فایل (مثلاً `scp` از خارج به ایران) |

> Update با Stable روی باینری پچ‌شده، MASQUE را می‌شکند.

### Transport

| Preset | لایه |
|:---|:---|
| **MWSS** | TLS + WebSocket + mux |
| WSS · TLS · uTLS · otls | استتار TLS |
| KCP · QUIC · gRPC | UDP / gRPC |
| TCP | فقط تست |
| **MASQUE** | HTTP/3 · listener `http3` · dialer `h3-masque` |

دو سر تونل = همان transport · برای WS/WSS/MWSS همان path.

### مسیرهای سیستم

| مسیر | نقش |
|:---|:---|
| `/usr/local/bin/gost` | باینری |
| `/usr/local/bin/wild` | ورود به منو |
| `/etc/gost/config.json` | کانفیگ اصلی |
| `/etc/gost/wild-antifilter.json` | state Anti-Filter |
| `/var/www/wild-gost-decoy` | decoy |
| `/etc/nginx/.../wild-gost-*.conf` | ACME / decoy |

### مستندات

| | | |
|:---:|:---|:---|
| [01 منو](docs/fa/01-overview-menu.md) | [02 نصب](docs/fa/02-install.md) | [03 انتخاب تونل](docs/fa/03-choose-tunnel.md) |
| [04 Anti-Filter](docs/fa/04-antifilter.md) | [05 MWSS](docs/fa/05-remote-forward.md) | [06 MASQUE](docs/fa/06-masque.md) |
| [07 Proxy / Reverse](docs/fa/07-proxy-local-reverse.md) | [08 Edit / Logs](docs/fa/08-edit-logs.md) | [09 Multi-entry](docs/fa/09-multi-entry.md) |
| [10 DNS / TUN](docs/fa/10-dns-tun-file-redirect.md) | [11 Transport](docs/fa/11-transports.md) | [12 Decoy / TLS](docs/fa/12-antifilter-extras.md) |
| [13 Advanced](docs/fa/13-edit-advanced.md) | [14 انواع Proxy](docs/fa/14-proxy-types.md) | [فهرست](docs/README.md) |

هستهٔ پروتکل‌ها: [gost.run](https://gost.run)

---

## English

Interactive Linux panel for GOST v3. Config lives in `/etc/gost/config.json`.

### Quick install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
```

```bash
sudo wild gost
```

| Requirement | |
|:---|:---|
| OS | Linux |
| Access | root |
| Tools | `curl` or `wget` · `jq` · `systemctl` |

### Architectures

Wild GOST has several distinct topologies. Pick one before you build.

#### 1) Two-server forward (Entry → Upstream)

Client dials A; A tunnels to B; B forwards to the target (e.g. panel).  
Transport: MWSS / WSS / TLS / … or **MASQUE** (UDP).

```text
Client ──► Server A (Entry) ════ tunnel ════► Server B (Upstream) ──► Target
              listen              MWSS/MASQUE         relay/masque      127.0.0.1:port
```

Menu: `2 → 2` on B, then `2 → 3` on A · Docs: [05](docs/en/05-remote-forward.md) · [06](docs/en/06-masque.md)

#### 2) Anti-Filter reverse (abroad → Iran)

Abroad node dials Iran. Clients only see Iran via SNI/Host.

```text
Client ──SNI──► Iran :443 (entrypoint)
                     │
Abroad node ══tunnel══► Iran :control ──► 127.0.0.1:panel @ Abroad
```

Menu: `2 → 1` · Docs: [04](docs/en/04-antifilter.md)

#### 3) Multi-entry — multi-port / multi-location

One Entry on A reaches several Server B nodes (per-port or selector).

```text
                 ┌──► B1 (US)
Client ──► A ────┼──► B2 (DE) ──► Target
                 └──► B3 (...)
```

Menu: `2 → 4` · Docs: [09](docs/en/09-multi-entry.md)

#### 4) Single-host Proxy

No second server; client dials this host directly.

```text
Client ──► Server (SOCKS/HTTP/SS/MASQUE/…) ──► Internet / Target
```

Menu: `2 → 5` · Docs: [14](docs/en/14-proxy-types.md)

#### 5) Local forward

Port remap on the same machine/LAN only.

```text
Client ──► This host :listen ──► IP:port (LAN / local)
```

Menu: `2 → 6`

#### 6) Generic Reverse

NAT device dials a public server (tunnel / rtcp / rudp).  
For Iran-focused reverse, prefer architecture 2 (Anti-Filter).

```text
Device (NAT) ══reverse dial══► Public server ──► Target
```

Menu: `2 → 7`

#### 7) More — DNS / TUN / File / Redirect

Side services on this host; not two-server tunnels.

Menu: `2 → 8` · Docs: [10](docs/en/10-dns-tun-file-redirect.md)

| Architecture | Tunnel direction | Multi-server? |
|:---|:---|:---|
| Forward Entry→Upstream | A → B | Yes |
| Anti-Filter | B → Iran (reverse) | Yes |
| Multi-entry | A → several B | Yes |
| Proxy / Forward / More | — | Usually one host |
| Generic Reverse | device → public server | Yes |

### Main menu

| # | Section | Description |
|:---:|:---|:---|
| **1** | Install / Update | Stable · Nightly · MASQUE-patched · Local binary |
| **2** | Add | Create services and tunnels |
| **3** | Edit | Edit service & chain |
| **4** | Remove | Delete one service |
| **5** | List | List services |
| **6** | Service | start · stop · restart · status |
| **7** | Logs | Live · errors · validate |
| **8** | Advanced | Bypass · Admission · Limiter · API · Metrics · Raw JSON |
| **9** | Uninstall | Wipe binary, config, decoy, nginx, hooks |
| **0** | Exit | Quit |

#### Add → detail

| # | Option | Use |
|:---:|:---|:---|
| 1 | **Anti-Filter** | Iran reverse · SNI · decoy · foreign node |
| 2 | **Upstream** | Server B — tunnel egress |
| 3 | **Entry** | Server A — client listen |
| 4 | **Multi** | Multi-port / multi-location |
| 5 | **Proxy** | SOCKS · HTTP · SS · Relay · MASQUE · … |
| 6 | **Local forward** | listen → target on this host |
| 7 | **Reverse** | tunnel · rtcp · rudp |
| 8 | **More** | DNS · TUN · File · Redirect |

### Scenarios

| Scenario | Path | Notes |
|:---|:---|:---|
| Anti-Filter | `2 → 1` | Iran = panel · abroad = node · client via SNI |
| Two-server MWSS | `2 → 2` then `2 → 3` | B first, then A · matching path |
| Two-server MASQUE | same + transport `11` | UDP · B:`http3` · A:`h3-masque` |
| Multi-entry | `2 → 4` | Per-port or selector |
| Single-host proxy | `2 → 5` | No second hop |
| Local forward | `2 → 6` | Port remap only |
| Reverse | `2 → 7` | Behind NAT |
| DNS / TUN / File | `2 → 8` | Extra services |

### Install channels

| # | Channel | Guidance |
|:---:|:---|:---|
| 1 | **Stable** | Everyday use — not suitable for MASQUE |
| 2 | **Nightly** | Registers masque; TCP CONNECT may be unstable |
| 3 | **Build patched** | Source + MASQUE patch — preferred for HTTP/3 |
| 4 | **Local binary** | Install from file (e.g. `scp` abroad → Iran) |

> Updating with Stable over a patched binary breaks MASQUE.

### Transports

| Preset | Layer |
|:---|:---|
| **MWSS** | TLS + WebSocket + mux |
| WSS · TLS · uTLS · otls | TLS camouflage |
| KCP · QUIC · gRPC | UDP / gRPC |
| TCP | Lab only |
| **MASQUE** | HTTP/3 · listener `http3` · dialer `h3-masque` |

Both ends share the same transport · WS/WSS/MWSS share the same path.

### System paths

| Path | Role |
|:---|:---|
| `/usr/local/bin/gost` | Binary |
| `/usr/local/bin/wild` | Menu entry |
| `/etc/gost/config.json` | Main config |
| `/etc/gost/wild-antifilter.json` | Anti-Filter state |
| `/var/www/wild-gost-decoy` | Decoy |
| `/etc/nginx/.../wild-gost-*.conf` | ACME / decoy |

### Documentation

| | | |
|:---:|:---|:---|
| [01 Menu](docs/en/01-overview-menu.md) | [02 Install](docs/en/02-install.md) | [03 Tunnel choice](docs/en/03-choose-tunnel.md) |
| [04 Anti-Filter](docs/en/04-antifilter.md) | [05 MWSS](docs/en/05-remote-forward.md) | [06 MASQUE](docs/en/06-masque.md) |
| [07 Proxy / Reverse](docs/en/07-proxy-local-reverse.md) | [08 Edit / Logs](docs/en/08-edit-logs.md) | [09 Multi-entry](docs/en/09-multi-entry.md) |
| [10 DNS / TUN](docs/en/10-dns-tun-file-redirect.md) | [11 Transports](docs/en/11-transports.md) | [12 Decoy / TLS](docs/en/12-antifilter-extras.md) |
| [13 Advanced](docs/en/13-edit-advanced.md) | [14 Proxy types](docs/en/14-proxy-types.md) | [Index](docs/README.md) |

Protocol reference: [gost.run](https://gost.run)

---

## License

Released under the [MIT License](LICENSE).
