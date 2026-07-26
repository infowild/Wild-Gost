# What the script menu does

After install, open the panel:

```bash
sudo wild gost
```

This is a text menu on Linux. Instead of editing JSON by hand, you answer questions and the script writes the real config:

```text
/etc/gost/config.json
```

It also manages the `gost` systemd service.

---

## Main menu (0–9)

| # | Name | Meaning | When to use |
|:---:|:---|:---|:---|
| **1** | Install / Update | Installs/replaces the `gost` binary and management script | First time on each server, or when changing version |
| **2** | Add | Creates a new service / tunnel | Anti-Filter, Upstream, Entry, Proxy, … |
| **3** | Edit | Changes existing items (port, upstream, transport, auth, …) | Fix mistakes or update settings |
| **4** | Remove | Deletes **one** service | Remove a tunnel without wiping the install |
| **5** | List | Shows current services | See names, ports, roles |
| **6** | Service | Start / Stop / Restart / Status | Control the `gost` engine |
| **7** | Logs | Live logs, errors, Debug, config validate | When connections fail |
| **8** | Advanced | Bypass, Admission, Limiter, API, Metrics, raw JSON | Limits and advanced ops |
| **9** | Uninstall | Removes almost everything Wild GOST related | Full wipe |
| **0** | Exit | Leave the menu | Done |

---

## Add menu (`2`) — the important part

| # | Name | Beginner meaning | Typical server |
|:---:|:---|:---|:---|
| **1** | Anti-Filter | Reverse model: exit dials Iran; users only see Iran | Iran = panel · abroad = node |
| **2** | Upstream | Exit side of a two-server tunnel (Server B) | Abroad |
| **3** | Entry single | Entry side; one client listen port (Server A) | Often Iran |
| **4** | Entry multi | Several ports or countries on one Entry | Often Iran |
| **5** | Proxy | SOCKS / HTTP / Shadowsocks / … on **this** host | Any single host |
| **6** | Local forward | Remap a port (e.g. `:8080` → an internal IP) | Same machine/LAN |
| **7** | Reverse | Generic reverse (tunnel / rtcp / rudp) | Host behind NAT |
| **8** | More | DNS, TUN/TAP, static files, transparent redirect | Special cases |

---

## Two roles: A and B

Classic two-server tunnel:

```text
Client  -->  Server A (Entry)  -->  tunnel  -->  Server B (Upstream)  -->  target
```

- **A (Entry):** where the user connects  
- **B (Upstream):** where traffic exits / where the panel listens  

**Beginner rule:** always build **B first**, then **A**.

---

## Suggested next steps

1. [Install](02-install.md)  
2. [Which tunnel?](03-choose-tunnel.md)  
3. Pick a scenario: [Anti-Filter](04-antifilter.md) · [MWSS](05-remote-forward.md) · [MASQUE](06-masque.md)
