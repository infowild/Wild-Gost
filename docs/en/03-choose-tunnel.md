# Tunnel choice

| Need | Path | Roles |
|:---|:---|:---|
| Filter · hide exit IP | `2 → 1` Anti-Filter | Exit → Iran |
| Client → entry · exit abroad | `2 → 2` then `2 → 3` | B Upstream · A Entry |
| Same over HTTP/3 | MASQUE (transport `11`) | `masque`+`http3` / `h3-masque` |
| Multi port / country | `2 → 4` | Multi-entry |
| Single-host SOCKS/HTTP | `2 → 5` | Proxy |
| Port remap | `2 → 6` | Local forward |

```text
Client → A (Entry) → tunnel → B (Upstream) → target
```

Create **B** first, then **A**.
