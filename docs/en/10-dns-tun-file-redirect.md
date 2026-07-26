# DNS, TUN, File, Redirect (More menu)

Path: `2 → 8) More`

## 1) DNS Proxy

- Listen port (default `53`)  
- Upstream e.g. `udp://8.8.8.8:53` or `tls://1.1.1.1:853`  
- Listener: dns/udp, tcp, or tls  

Use when this host should answer DNS and forward queries upstream.

Port 53 may conflict with `systemd-resolved` on Linux.

## 2) TUN / TAP / TUNGO

| Option | Meaning |
|:---|:---|
| **TUN** | Layer-3 interface |
| **TAP** | Layer-2 interface |
| **TUNGO** | TUN2SOCKS — send TUN traffic via proxy/chain |

After creating the service, configure OS IP/routes yourself.

## 3) File server

Serves a directory over the chosen listener — decoy site or static files.

## 4) Transparent redirect

`red` (TCP) or `redu` (UDP).

Needs **iptables/nftables** REDIRECT/TPROXY on the host. Creating the GOST service alone is not enough.
