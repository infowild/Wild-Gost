# DNS · TUN · File · Redirect

مسیر: `2 → 8`

## DNS

| فیلد | نمونه |
|:---|:---|
| Listen | `53` |
| Upstream | `udp://8.8.8.8:53` · `tls://1.1.1.1:853` |
| Listener | dns/udp · tcp · tls |

ممکن است با `systemd-resolved` تداخل کند.

## TUN / TAP / TUNGO

| نوع | لایه |
|:---|:---|
| TUN | L3 |
| TAP | L2 |
| TUNGO | TUN → proxy/chain |

IP/route را خودت روی OS بگذار.

## File

پوشه استاتیک روی listener انتخابی (decoy / فایل).

## Redirect

`red` (TCP) · `redu` (UDP) — نیاز به iptables/nftables REDIRECT/TPROXY جدا از سرویس GOST.
