# Transports (anti-DPI & links)

Common wizard presets:

| # | Name | Simple layer | Advice |
|:---:|:---|:---|:---|
| 1 | **MWSS** | TLS + WebSocket + mux | General recommended |
| 2 | WSS | TLS + WebSocket | Good |
| 3 | TLS | HTTPS-like | Good |
| 4 | uTLS | TLS with spoofed client fingerprint | Stronger vs fingerprinting |
| 5 | otls | obfs-TLS | Camouflage |
| 6 | KCP | UDP + FEC | Lossy links |
| 7 | QUIC | UDP/QUIC | HTTP3-like |
| 8 | gRPC | Over TLS | WS alternative |
| 9 | TCP | No encryption | Testing only |
| 10 | Advanced | Separate listener + dialer | Experts |
| 11 | **MASQUE** | HTTP/3 + masque | HTTP3 tunnel; listener=`http3` |

## Golden rule

- **Both ends must use the same transport**  
- For WS/WSS/MWSS keep the same **path**  
- SNI/Host must match cert/domain when set  

## Listener vs dialer

| Role | Where |
|:---|:---|
| **Listener** | Side that accepts connections (e.g. Upstream on B) |
| **Dialer** | Side that dials out (e.g. Entry on A) |

MASQUE:

- B listener = **`http3`** (not `h3`)  
- A dialer = **`h3-masque`** + connector **`masque`**  

Advanced exposes every listener/dialer type in the script — use only when you know the pair.
