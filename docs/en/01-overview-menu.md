# What the script menu does

Open the panel:

```bash
sudo wild gost
```

| Option | Meaning |
|:---|:---|
| **1 Install / Update** | Installs or replaces the `gost` binary and management script |
| **2 Add** | Create a new tunnel / service |
| **3 Edit** | Change existing services (port, upstream, transport, …) |
| **4 Remove** | Delete one service |
| **5 List** | Show configured services |
| **6 Service** | Start / Stop / Restart / Status |
| **7 Logs** | Live logs, errors, debug level |
| **8 Advanced** | Bypass, limiter, API, raw JSON |
| **9 Uninstall** | Remove everything (`/etc/gost`, …) |
| **0 Exit** | Quit |

## Add menu (`2`)

| Option | Simple use |
|:---|:---|
| **1 Anti-Filter** | Iran censorship; exit node dials Iran (reverse) |
| **2 Upstream** | On exit server (B): outbound side of a two-server tunnel |
| **3 Entry single** | On entry server (A): one public listen port for clients |
| **4 Entry multi** | Several ports / several countries on A |
| **5 Proxy** | SOCKS/HTTP/SS on this machine |
| **6 Local forward** | This port → another address |
| **7 Reverse** | Generic reverse (no anti-filter wizard) |
| **8 More** | DNS / TUN / file / redirect |

Real config file:

`/etc/gost/config.json`
