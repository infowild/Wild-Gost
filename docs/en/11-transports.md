# Transports

| # | Preset | Layer |
|:---:|:---|:---|
| 1 | MWSS | TLS + WS + mux |
| 2 | WSS | TLS + WS |
| 3 | TLS | HTTPS-like |
| 4 | uTLS | TLS + spoofed fingerprint |
| 5 | otls | obfs-TLS |
| 6 | KCP | UDP + FEC |
| 7 | QUIC | UDP/QUIC |
| 8 | gRPC | over TLS |
| 9 | TCP | lab only |
| 10 | Advanced | manual listener/dialer |
| 11 | MASQUE | HTTP/3 · listener=`http3` · dialer=`h3-masque` |

| Rule | |
|:---|:---|
| Both ends | same transport |
| WS/WSS/MWSS | same path |
| SNI/Host | match domain/cert |

| Role | Side |
|:---|:---|
| Listener | acceptor (e.g. B Upstream) |
| Dialer | caller (e.g. A Entry) |

MASQUE: B=`http3` (not `h3`) · A=`h3-masque` + connector `masque`.
