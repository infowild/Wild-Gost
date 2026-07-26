# Transportها

| # | Preset | لایه |
|:---:|:---|:---|
| 1 | MWSS | TLS + WS + mux |
| 2 | WSS | TLS + WS |
| 3 | TLS | HTTPS-like |
| 4 | uTLS | TLS + fingerprint جعلی |
| 5 | otls | obfs-TLS |
| 6 | KCP | UDP + FEC |
| 7 | QUIC | UDP/QUIC |
| 8 | gRPC | روی TLS |
| 9 | TCP | تست |
| 10 | Advanced | listener/dialer دستی |
| 11 | MASQUE | HTTP/3 · listener=`http3` · dialer=`h3-masque` |

| قانون | |
|:---|:---|
| دو سر تونل | transport یکسان |
| WS/WSS/MWSS | path یکسان |
| SNI/Host | هم‌خوان با دامنه/cert |

| نقش | سمت |
|:---|:---|
| Listener | پذیرنده (مثلاً B Upstream) |
| Dialer | تماس‌گیرنده (مثلاً A Entry) |

MASQUE: B=`http3` (نه `h3`) · A=`h3-masque` + connector `masque`.
