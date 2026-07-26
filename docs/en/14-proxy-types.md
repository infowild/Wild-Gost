# Proxy types (Add → Proxy)

Path:

```text
2) Add  →  5) Proxy
```

## What does this menu create?

A proxy service that listens on **this server**.  
Clients connect directly to this host’s IP.

If your goal is a two-server tunnel (entry → abroad → panel), use **Upstream + Entry** instead: [05](05-remote-forward.md) / [06](06-masque.md).

---

## Full type table — plain language

| # | Type | Beginner meaning | Example use |
|:---:|:---|:---|:---|
| 1 | **SOCKS5** | General-purpose proxy; widely supported | Browsers/apps via `socks5://IP:1080` |
| 2 | **SOCKS4** | Older SOCKS | Legacy clients |
| 3 | **HTTP** | Classic HTTP proxy | `http://IP:8080` in system/browser proxy settings |
| 4 | **HTTP2** | Same idea over HTTP/2 | When you want h2 carriage |
| 5 | **HTTP3** | Over HTTP/3 | Needs UDP / proper listener |
| 6 | **Relay** | GOST’s own relay | Also common as Upstream in two-server tunnels |
| 7 | **Shadowsocks** | SS with method + password | Shadowsocks clients |
| 8 | **Auto** | Tries to detect inbound protocol | Mixed clients |
| 9 | **SNI** | Routes by SNI | Domain-based routing |
| 10 | **SSHD** | SSHD-style service | Special SSH scenarios |
| 11 | **MASQUE** | MASQUE proxy | Forced `http3` listener · UDP firewall |
| 12 | **Serial** | Serial / specialty | Special hardware cases |

---

## What happens after you pick a type?

The wizard usually asks for:

1. **Listen port** — where clients connect  
2. **Listener / transport** — how it rides on the wire (except MASQUE, which is fixed to `http3`)  
3. Sometimes **auth** — username/password  
4. For Shadowsocks: **method** and **password**  
5. For SOCKS: optional UDP or BIND  

---

## Client connection examples

```text
socks5://203.0.113.10:1080
http://203.0.113.10:8080
```

If you set auth, enter the same credentials in the client.

---

## Beginner security notes

1. Do not leave an open proxy on the internet without auth unless you accept the risk.  
2. Admission in Advanced can limit allowed client IPs.  
3. Limiter caps abusive usage.  
4. A single-host Proxy does not replace Entry+Upstream for two-server filtering setups.

---

## Chooser

| Goal | Go to |
|:---|:---|
| Proxy on one VPS | This page · `2 → 5` |
| Entry + abroad + panel | [05](05-remote-forward.md) or [06](06-masque.md) |
| Multi port/country | [09](09-multi-entry.md) |
