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

**→ [docs/README.md](docs/README.md)**

| موضوع | لینک |
|:---|:---|
| منوی اسکریپت | [docs/fa/01-overview-menu.md](docs/fa/01-overview-menu.md) |
| نصب | [docs/fa/02-install.md](docs/fa/02-install.md) |
| انتخاب نوع تونل | [docs/fa/03-choose-tunnel.md](docs/fa/03-choose-tunnel.md) |
| Anti-Filter | [docs/fa/04-antifilter.md](docs/fa/04-antifilter.md) |
| تونل MWSS دو سرور | [docs/fa/05-remote-forward.md](docs/fa/05-remote-forward.md) |
| تونل MASQUE | [docs/fa/06-masque.md](docs/fa/06-masque.md) |
| پروکسی / فوروارد / Reverse | [docs/fa/07-proxy-local-reverse.md](docs/fa/07-proxy-local-reverse.md) |
| Edit و عیب‌یابی | [docs/fa/08-edit-logs.md](docs/fa/08-edit-logs.md) |

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

**→ [docs/README.md](docs/README.md)**

| Topic | Link |
|:---|:---|
| Menu overview | [docs/en/01-overview-menu.md](docs/en/01-overview-menu.md) |
| Install | [docs/en/02-install.md](docs/en/02-install.md) |
| Choosing a tunnel | [docs/en/03-choose-tunnel.md](docs/en/03-choose-tunnel.md) |
| Anti-Filter | [docs/en/04-antifilter.md](docs/en/04-antifilter.md) |
| Two-server MWSS | [docs/en/05-remote-forward.md](docs/en/05-remote-forward.md) |
| MASQUE | [docs/en/06-masque.md](docs/en/06-masque.md) |
| Proxy / forward / reverse | [docs/en/07-proxy-local-reverse.md](docs/en/07-proxy-local-reverse.md) |
| Edit & debugging | [docs/en/08-edit-logs.md](docs/en/08-edit-logs.md) |

### GOST core

Wild GOST wraps official GOST v3. Protocol details: [gost.run](https://gost.run).

---

## License

See [LICENSE](LICENSE).
