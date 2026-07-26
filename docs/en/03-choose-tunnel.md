# Which tunnel should I pick?

Use this page **before** you build anything. Each row links to the full guide.

---

## Beginner decision table

| What do I need? | Open this menu | Full guide |
|:---|:---|:---|
| Bypass filters; hide exit IP; exit dials Iran | `2 → 1` Anti-Filter | [04 Anti-Filter](04-antifilter.md) |
| Client hits entry server; traffic exits abroad (panel on abroad) | `2 → 2` Upstream abroad, then `2 → 3` Entry | [05 MWSS](05-remote-forward.md) |
| Same two-server design over HTTP/3 (UDP) | Same path with **MASQUE** transport | [06 MASQUE](06-masque.md) |
| Several ports or countries (several Server B) | `2 → 4` Entry multi | [09 Multi-entry](09-multi-entry.md) |
| One server only; SOCKS or HTTP | `2 → 5` Proxy | [07](07-proxy-local-reverse.md) and [14](14-proxy-types.md) |
| Only remap a port to another address | `2 → 6` Local forward | [07](07-proxy-local-reverse.md) |
| Device behind NAT must reach a public server | `2 → 7` Reverse (for Iran-focused reverse prefer Anti-Filter) | [07](07-proxy-local-reverse.md) |
| DNS / TUN / file site / transparent redirect | `2 → 8` More | [10](10-dns-tun-file-redirect.md) |

---

## Mental picture of a two-server tunnel

```text
Phone / client
      │
      │  connects to A's public port
      ▼
┌──────────────────┐
│ Server A (Entry) │
│ listens          │
└────────┬─────────┘
         │  encrypted tunnel (MWSS or MASQUE)
         ▼
┌──────────────────┐
│ Server B (Upstream)│
│ exit / panel     │
└────────┬─────────┘
         │
         ▼
   127.0.0.1:8080
   (panel on B)
```

### Words beginners need

| Word | Meaning |
|:---|:---|
| **Entry** | Where the client connects |
| **Upstream** | Exit side of the tunnel |
| **Target** | Final destination after the tunnel; often `127.0.0.1:panel-port` on B |
| **Transport** | How A↔B is carried (MWSS, TLS, MASQUE, …) |
| **Handler** | Service type on the listen side (relay, masque, …) |

---

## Anti-Filter vs Entry+Upstream

| | Anti-Filter | Entry + Upstream |
|:---|:---|:---|
| Control direction | Exit → Iran (reverse) | Entry → abroad (forward) |
| What users see | Usually only Iran domain/IP | Entry address (often Iran) |
| Complexity | Higher (SNI, decoy, Tunnel ID) | Simpler for panel-on-abroad |
| Pick when | Reverse / Iran-centric design | Classic remote port forward |

---

## Correct order of work

1. Install on **both** servers  
2. Build **Server B** first (Upstream or Foreign node)  
3. Build **Server A** second (Entry or Iran panel)  
4. Open the correct firewall ports (TCP or UDP)  
5. Verify with List and Logs  

Wrong choice? Remove that service and rebuild the correct scenario.
