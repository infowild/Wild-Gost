# Proxy, local forward, Reverse

These three Add options do different jobs. Do not confuse them with a two-server tunnel.

---

## 1) Single-host Proxy — `2 → 5`

### What is it?

Creates a proxy service on **this one server**. Clients dial this host directly. No second server required.

### Which types exist?

Full list: [14 Proxy types](14-proxy-types.md)

Most common for beginners:

| Type | Client example |
|:---|:---|
| SOCKS5 | `socks5://SERVER_IP:1080` |
| HTTP | `http://SERVER_IP:8080` |
| Shadowsocks | method + password in an SS client |

### Typical steps

1. `2 → 5` Proxy  
2. Pick a type  
3. Set listen port  
4. Answer listener/transport questions if asked  
5. If you pick **MASQUE**, listener becomes **http3** and firewall needs UDP  

### Proxy vs Upstream+Entry

| Situation | Choose |
|:---|:---|
| One VPS; I just want a proxy | Proxy |
| Entry + abroad + panel on abroad | Upstream + Entry |

---

## 2) Local port forward — `2 → 6`

### What is it?

Only remaps a port to another address. Not an international tunnel.

```text
Listen on this server :8080
        │
        ▼
  192.168.1.10:80   (LAN device)
```

### Example uses

- Publish an internal web service through the machine that has a public IP  
- Expose a panel on a different port  

### Steps

1. `2 → 6`  
2. Listen port  
3. Target `IP:port`  
4. TCP or UDP  

---

## 3) Generic Reverse — `2 → 7`

### What is it?

For a device behind NAT/modem that cannot listen on the public internet. It dials a public server and builds a reverse tunnel (tunnel / rtcp / rudp).

### For Iran-focused reverse?

Prefer the dedicated wizard:

```text
2 → 1) Anti-Filter
```

Guide: [04 Anti-Filter](04-antifilter.md)

`2 → 7` is generic/advanced reverse, not a full replacement for Anti-Filter.
