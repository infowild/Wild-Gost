# Proxy types

Path: `2 → 5` — listen on this host.

| # | Type | Role |
|:---:|:---|:---|
| 1 | SOCKS5 | general · optional UDP/BIND |
| 2 | SOCKS4 | legacy |
| 3 | HTTP | HTTP proxy |
| 4 | HTTP2 | over HTTP/2 |
| 5 | HTTP3 | over HTTP/3 |
| 6 | Relay | GOST relay |
| 7 | Shadowsocks | method + password |
| 8 | Auto | detect inbound |
| 9 | SNI | SNI routing |
| 10 | SSHD | SSHD-style |
| 11 | MASQUE | listener forced `http3` |
| 12 | Serial | serial |

Then: port + listener transport (except MASQUE).

```text
socks5://SERVER:1080
http://SERVER:8080
```

Two-server tunnels → Upstream + Entry; Proxy is for single-host.
