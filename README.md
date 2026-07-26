# Wild GOST (GO Simple Tunnel Manager)

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8?logo=go)](https://go.dev)
[![GOST](https://img.shields.io/badge/Based_on-GOST_v3-green)](https://github.com/go-gost/gost)

[English](#-english) · [فارسی](#-فارسی) · **[Tutorials / آموزش‌ها](docs/README.md)**

Interactive Linux menu for [GOST v3](https://github.com/go-gost/gost): install, build tunnels, edit config, logs, uninstall — without hand-editing JSON most of the time.

---

## فارسی

### نصب سریع

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
```

بعد از نصب:

```bash
sudo wild gost
```

### منوی اصلی

```text
1) Install / Update
2) Add
3) Edit
4) Remove
5) List
6) Service
7) Logs
8) Advanced
9) Uninstall
0) Exit
```

**Add (`2`):** Anti-Filter · Upstream (B) · Entry (A) · Multi · Proxy · Local forward · Reverse · More

### قابلیت‌ها (خلاصه)

| مورد | توضیح |
|:---|:---|
| نصب | Stable / Nightly / بیلد پچ MASQUE / باینری محلی |
| Anti-Filter | ریورس ایران + نود خارج + SNI + decoy |
| تونل دو سرور | Upstream + Entry (تک یا چند پورت/لوکیشن) |
| MASQUE | HTTP/3 روی UDP — handler `masque` + listener `http3` |
| Transport | MWSS / WSS / TLS / uTLS / otls / KCP / QUIC / gRPC / **MASQUE** |
| Edit / Logs / Uninstall | ویرایش کامل، لاگ، پاکسازی `/etc/gost` |

### آموزش (فایل‌های جدا — README شلوغ نمی‌شود)

همه آموزش‌های فارسی اینجا هستند:

**→ [docs/README.md](docs/README.md)** (۱۴ موضوع، فایل جدا)

پوشش: منو · نصب · انتخاب تونل · Anti-Filter · MWSS · MASQUE · پروکسی · Multi-entry · DNS/TUN/File · Transportها · decoy/TLS/Doctor · Edit/Advanced · انواع Proxy

### هسته GOST

این پنل روی هسته رسمی GOST v3 سوار است (chain، reverse، DNS، TUN، limiter، …). جزئیات پروتکل‌ها: [gost.run](https://gost.run).

---

## English

### Quick install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
```

Then:

```bash
sudo wild gost
```

### Main menu

```text
1) Install / Update
2) Add
3) Edit
4) Remove
5) List
6) Service
7) Logs
8) Advanced
9) Uninstall
0) Exit
```

**Add (`2`):** Anti-Filter · Upstream (B) · Entry (A) · Multi · Proxy · Local forward · Reverse · More

### Features (short)

| Item | Notes |
|:---|:---|
| Install | Stable / Nightly / MASQUE-patched build / local binary |
| Anti-Filter | Iran reverse + foreign node + SNI + decoy |
| Two-server | Upstream + Entry (single or multi port/location) |
| MASQUE | HTTP/3 over UDP — `masque` + listener `http3` |
| Transports | MWSS / WSS / TLS / uTLS / otls / KCP / QUIC / gRPC / **MASQUE** |
| Ops | Full Edit, Logs, uninstall of `/etc/gost` |

### Tutorials (separate pages)

**→ [docs/README.md](docs/README.md)** (14 topics, one file each)

Covers: menu · install · tunnel choice · Anti-Filter · MWSS · MASQUE · proxy · multi-entry · DNS/TUN/File · transports · decoy/TLS/Doctor · Edit/Advanced · proxy types

### GOST core

Wild GOST wraps official GOST v3. Protocol details: [gost.run](https://gost.run).

---

## License

See [LICENSE](LICENSE).
