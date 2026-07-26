# Proxy types (Add → Proxy)

Path: `2 → 5`

All listen on **this server** (unless you attach a separate upstream chain).

| # | Type | Simple use |
|:---:|:---|:---|
| 1 | **SOCKS5** | General proxy; optional UDP/BIND |
| 2 | **SOCKS4** | Older SOCKS |
| 3 | **HTTP** | HTTP proxy; optional UDP-over-TCP |
| 4 | **HTTP2** | HTTP over HTTP/2 |
| 5 | **HTTP3** | HTTP over HTTP/3 |
| 6 | **Relay** | GOST relay (also used in two-server tunnels) |
| 7 | **Shadowsocks** | SS with method + password |
| 8 | **Auto** | Autodetect inbound protocol |
| 9 | **SNI** | Route by SNI |
| 10 | **SSHD** | SSHD-style |
| 11 | **MASQUE** | MASQUE proxy; listener forced to **http3** |
| 12 | **Serial** | Serial / specialty |

After the type, you pick a port and usually a **listener transport** (except MASQUE → fixed http3).

### Client examples

```text
socks5://SERVER:1080
http://SERVER:8080
```

For two-server tunnels prefer **Upstream + Entry**; Proxy is mainly for a single host.
