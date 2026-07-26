# Transports (anti-DPI and links)

## What is a transport?

Transport is how the tunnel is carried between the two ends.  
Handler says what the service is (e.g. relay); transport says what it rides on (e.g. WebSocket over TLS).

**Beginner golden rule:**

> Both tunnel ends must use the **same transport**.  
> If there is a path (like `/ws`), that must match too.

---

## Common wizard presets

| # | Name | Plain meaning | When to pick |
|:---:|:---|:---|:---|
| 1 | **MWSS** | TLS + WebSocket + multiplexing | Default recommendation for two-server tunnels |
| 2 | WSS | TLS + WebSocket without mux | Simpler WS alternative |
| 3 | TLS | HTTPS-like | When WS is not needed |
| 4 | uTLS | TLS with spoofed client fingerprint | When fingerprinting matters |
| 5 | otls | obfs-TLS | Extra camouflage |
| 6 | KCP | UDP with FEC | Lossy / unstable links |
| 7 | QUIC | UDP/QUIC | HTTP/3-like world |
| 8 | gRPC | over TLS | WS alternative |
| 9 | TCP | no extra crypto dress | Lab testing only |
| 10 | Advanced | pick listener and dialer manually | Only if you know the exact pair |
| 11 | **MASQUE** | HTTP/3 + masque | HTTP/3 tunnel; guide: [06](06-masque.md) |

---

## Listener vs dialer

| Role | Where it sits | Example |
|:---|:---|:---|
| **Listener** | Side that accepts connections | Upstream on Server B |
| **Dialer** | Side that dials out | Entry on Server A |

Most presets configure both for you. **Advanced** lets you pair them manually; a wrong pair means a dead tunnel.

### MASQUE pair (remember this)

| Side | Correct value |
|:---|:---|
| B listener | `http3` (**not** `h3`) |
| A dialer | `h3-masque` |
| connector | `masque` |

---

## Extra fields the wizard may ask

| Field | Plain meaning |
|:---|:---|
| Path | URL path like `/ws` for WebSocket |
| Host / SNI | Domain name seen in TLS |
| Cert / Key | Certificates for TLS listeners |

If you set SNI/Host, keep it consistent with domain and certificate.

---

## Practical starting advice

1. First logic test on a clean network: even **TCP**  
2. Real use: **MWSS**  
3. UDP/HTTP3 goal: **MASQUE** with a patched binary  

The script’s Advanced lists many more listener/dialer types; beginners do not need to memorize them all.
