# DNS · TUN · File · Redirect

Path: `2 → 8`

## DNS

| Field | Example |
|:---|:---|
| Listen | `53` |
| Upstream | `udp://8.8.8.8:53` · `tls://1.1.1.1:853` |
| Listener | dns/udp · tcp · tls |

May conflict with `systemd-resolved`.

## TUN / TAP / TUNGO

| Type | Layer |
|:---|:---|
| TUN | L3 |
| TAP | L2 |
| TUNGO | TUN → proxy/chain |

Configure OS IP/routes yourself.

## File

Static directory on chosen listener (decoy / files).

## Redirect

`red` (TCP) · `redu` (UDP) — needs separate iptables/nftables REDIRECT/TPROXY.
