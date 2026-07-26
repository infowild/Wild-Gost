# DNS, TUN, File, Redirect (More menu)

Path:

```text
2) Add  →  8) More
```

These are extra services. You usually do **not** need them for a two-server panel tunnel.

---

## 1) DNS Proxy

### What it does

This host answers DNS for clients and forwards queries to an upstream resolver.

### Common fields

| Field | Example | Meaning |
|:---|:---|:---|
| Listen port | `53` | Standard DNS port |
| Upstream | `udp://8.8.8.8:53` | Plain DNS |
| Upstream | `tls://1.1.1.1:853` | DNS over TLS |
| Listener | dns/udp, tcp, or tls | How this host listens |

### Linux beginner note

Port 53 is often taken by `systemd-resolved`. If bind fails:

- use another port, or  
- free port 53 carefully (sensitive on production hosts)

---

## 2) TUN / TAP / TUNGO

These create virtual network interfaces. The script only writes the GOST service; you must configure OS IP/routes yourself.

| Type | Layer | Simple use |
|:---|:---|:---|
| **TUN** | L3 (IP) | IP-level tunnel interface |
| **TAP** | L2 (Ethernet) | When you need Ethernet frames |
| **TUNGO** | TUN2SOCKS | Send TUN traffic through a proxy/chain |

If you do not know what TUN is, skip this section for now.

---

## 3) File server

Serves a directory over a chosen listener like a static web/file server.

Uses:

- decoy page  
- static file hosting  

The wizard asks for the directory (or uses the default decoy path).

---

## 4) Transparent redirect

| Type | Protocol |
|:---|:---|
| `red` | TCP |
| `redu` | UDP |

### Important

Creating the GOST service is not enough. You must also add **iptables** or **nftables** REDIRECT/TPROXY rules so system traffic reaches the service.

If you are not comfortable with Linux firewalling, skip this for now.

---

## Quick chooser

| I want… | Pick |
|:---|:---|
| DNS for clients | DNS |
| Virtual interface | TUN/TAP/TUNGO |
| Static files/page | File |
| Transparent OS redirect | red/redu + OS rules |
| Two-server panel tunnel | Back to [05](05-remote-forward.md) / [06](06-masque.md) |
