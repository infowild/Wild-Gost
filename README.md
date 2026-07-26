# Wild GOST

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GOST](https://img.shields.io/badge/GOST-v3-green)](https://github.com/go-gost/gost)
[![Docs](https://img.shields.io/badge/Docs-14_guides-informational)](docs/README.md)

[English](#english) · [فارسی](#فارسی) · [Docs](docs/README.md)

Linux menu for [GOST v3](https://github.com/go-gost/gost): install, tunnels, proxy, TLS, logs, uninstall — JSON under `/etc/gost`.

---

## فارسی

### نصب

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
sudo wild gost
```

نیاز: Linux · root · `curl`/`wget` · `jq` · `systemctl`

### منو

| # | بخش | کار |
|:---:|:---|:---|
| 1 | Install / Update | Stable · Nightly · بیلد پچ MASQUE · باینری محلی |
| 2 | Add | Anti-Filter · Upstream · Entry · Multi · Proxy · Forward · Reverse · More |
| 3 | Edit | سرویس و chain |
| 4 | Remove | حذف یک سرویس |
| 5 | List | فهرست سرویس‌ها |
| 6 | Service | start / stop / restart / status |
| 7 | Logs | لاگ زنده · خطا · validate |
| 8 | Advanced | Bypass · Admission · Limiter · API · Metrics · Raw JSON |
| 9 | Uninstall | باینری · `/etc/gost` · decoy · nginx `wild-gost-*` · هوک certbot · اختیاری LE/Go |

### سناریوها

| سناریو | مسیر منو | نقش‌ها |
|:---|:---|:---|
| Anti-Filter | `2 → 1` | ایران = پنل ریورس · خارج = نود · کلاینت با SNI |
| دو سرور (MWSS و مشابه) | `2 → 2` سپس `2 → 3` | B = Upstream · A = Entry → `127.0.0.1:port` |
| دو سرور MASQUE | همان + transport `11` | B: `masque`+`http3` (UDP) · A: `masque`+`h3-masque` |
| چند پورت / چند لوکیشن | `2 → 4` | چند B · پورت جدا یا selector |
| پروکسی تک‌سرور | `2 → 5` | SOCKS / HTTP / SS / Relay / MASQUE / … |
| فوروارد محلی | `2 → 6` | listen → target روی همین هاست |
| Reverse | `2 → 7` | tunnel / rtcp / rudp |
| DNS · TUN · File · Redirect | `2 → 8` | سرویس‌های جانبی |

### کانال نصب (منو `1`)

| گزینه | خروجی |
|:---:|:---|
| 1 Stable | ریلیز پایدار — بدون MASQUE قابل‌اتکا |
| 2 Nightly | masque ثبت‌شده؛ TCP CONNECT ممکن است باگ داشته باشد |
| 3 Build patched | بیلد + پچ MASQUE — پیشنهادی برای تونل HTTP/3 |
| 4 Local binary | نصب از مسیر محلی (مثلاً `/tmp/gost-masque-fixed`) |

Stable روی باینری پچ‌شده = شکست MASQUE.

### Transport

| Preset | لایه |
|:---|:---|
| MWSS | TLS + WebSocket + mux |
| WSS / TLS / uTLS / otls | استتار TLS |
| KCP / QUIC / gRPC | UDP یا gRPC |
| TCP | تست |
| **MASQUE** | HTTP/3 · listener=`http3` (نه `h3`) · dialer=`h3-masque` |

دو سر تونل باید transport یکسان داشته باشند.

### مسیرها

| مسیر | محتوا |
|:---|:---|
| `/usr/local/bin/gost` | باینری |
| `/usr/local/bin/wild` | منو (`wild gost`) |
| `/etc/gost/config.json` | کانفیگ |
| `/etc/gost/wild-antifilter.json` | state پنل Anti-Filter |
| `/var/www/wild-gost-decoy` | decoy |
| `/etc/nginx/.../wild-gost-*.conf` | ACME / decoy nginx |

### آموزش

| # | موضوع |
|:---:|:---|
| [01](docs/fa/01-overview-menu.md) | منو |
| [02](docs/fa/02-install.md) | نصب |
| [03](docs/fa/03-choose-tunnel.md) | انتخاب تونل |
| [04](docs/fa/04-antifilter.md) | Anti-Filter |
| [05](docs/fa/05-remote-forward.md) | MWSS دو سرور |
| [06](docs/fa/06-masque.md) | MASQUE |
| [07](docs/fa/07-proxy-local-reverse.md) | Proxy / Forward / Reverse |
| [08](docs/fa/08-edit-logs.md) | Edit / Logs |
| [09](docs/fa/09-multi-entry.md) | Multi-entry |
| [10](docs/fa/10-dns-tun-file-redirect.md) | DNS / TUN / File / Redirect |
| [11](docs/fa/11-transports.md) | Transportها |
| [12](docs/fa/12-antifilter-extras.md) | decoy / TLS / Doctor |
| [13](docs/fa/13-edit-advanced.md) | Advanced / Uninstall |
| [14](docs/fa/14-proxy-types.md) | انواع Proxy |

فهرست کامل: [docs/README.md](docs/README.md) · هسته: [gost.run](https://gost.run)

---

## English

### Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
sudo wild gost
```

Requires: Linux · root · `curl`/`wget` · `jq` · `systemctl`

### Menu

| # | Section | Action |
|:---:|:---|:---|
| 1 | Install / Update | Stable · Nightly · MASQUE-patched build · local binary |
| 2 | Add | Anti-Filter · Upstream · Entry · Multi · Proxy · Forward · Reverse · More |
| 3 | Edit | Service & chain |
| 4 | Remove | Delete one service |
| 5 | List | List services |
| 6 | Service | start / stop / restart / status |
| 7 | Logs | Live · errors · validate |
| 8 | Advanced | Bypass · Admission · Limiter · API · Metrics · Raw JSON |
| 9 | Uninstall | Binary · `/etc/gost` · decoy · nginx `wild-gost-*` · certbot hooks · optional LE/Go |

### Scenarios

| Scenario | Menu | Roles |
|:---|:---|:---|
| Anti-Filter | `2 → 1` | Iran = reverse panel · abroad = node · client by SNI |
| Two-server (MWSS etc.) | `2 → 2` then `2 → 3` | B = Upstream · A = Entry → `127.0.0.1:port` |
| Two-server MASQUE | same + transport `11` | B: `masque`+`http3` (UDP) · A: `masque`+`h3-masque` |
| Multi port / location | `2 → 4` | Several B · per-port or selector |
| Single-host proxy | `2 → 5` | SOCKS / HTTP / SS / Relay / MASQUE / … |
| Local forward | `2 → 6` | listen → target on this host |
| Reverse | `2 → 7` | tunnel / rtcp / rudp |
| DNS · TUN · File · Redirect | `2 → 8` | Extra services |

### Install channels (menu `1`)

| # | Result |
|:---:|:---|
| 1 Stable | Release build — not reliable for MASQUE |
| 2 Nightly | Registers masque; TCP CONNECT may still fail |
| 3 Build patched | Source + MASQUE patch — preferred for HTTP/3 |
| 4 Local binary | Install from path (e.g. `/tmp/gost-masque-fixed`) |

Stable over a patched binary breaks MASQUE.

### Transports

| Preset | Layer |
|:---|:---|
| MWSS | TLS + WebSocket + mux |
| WSS / TLS / uTLS / otls | TLS camouflage |
| KCP / QUIC / gRPC | UDP or gRPC |
| TCP | Lab only |
| **MASQUE** | HTTP/3 · listener=`http3` (not `h3`) · dialer=`h3-masque` |

Both tunnel ends must share the same transport.

### Paths

| Path | Content |
|:---|:---|
| `/usr/local/bin/gost` | Binary |
| `/usr/local/bin/wild` | Menu (`wild gost`) |
| `/etc/gost/config.json` | Config |
| `/etc/gost/wild-antifilter.json` | Anti-Filter state |
| `/var/www/wild-gost-decoy` | Decoy |
| `/etc/nginx/.../wild-gost-*.conf` | ACME / decoy nginx |

### Docs

| # | Topic |
|:---:|:---|
| [01](docs/en/01-overview-menu.md) | Menu |
| [02](docs/en/02-install.md) | Install |
| [03](docs/en/03-choose-tunnel.md) | Tunnel choice |
| [04](docs/en/04-antifilter.md) | Anti-Filter |
| [05](docs/en/05-remote-forward.md) | Two-server MWSS |
| [06](docs/en/06-masque.md) | MASQUE |
| [07](docs/en/07-proxy-local-reverse.md) | Proxy / Forward / Reverse |
| [08](docs/en/08-edit-logs.md) | Edit / Logs |
| [09](docs/en/09-multi-entry.md) | Multi-entry |
| [10](docs/en/10-dns-tun-file-redirect.md) | DNS / TUN / File / Redirect |
| [11](docs/en/11-transports.md) | Transports |
| [12](docs/en/12-antifilter-extras.md) | decoy / TLS / Doctor |
| [13](docs/en/13-edit-advanced.md) | Advanced / Uninstall |
| [14](docs/en/14-proxy-types.md) | Proxy types |

Index: [docs/README.md](docs/README.md) · Core: [gost.run](https://gost.run)

---

## License

[MIT](LICENSE)
