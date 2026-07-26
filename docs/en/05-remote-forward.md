# Two-server tunnel (MWSS)

```text
Client → A:8080 → MWSS → B:2018 (Relay) → 127.0.0.1:8080
```

## B (abroad) — `2 → 2`

| Field | Example |
|:---|:---|
| Handler | Relay |
| Transport | MWSS |
| Port | `2018` / `443` |
| Path | `/ws` (must match) |

## A (entry) — `2 → 3`

| Field | Example |
|:---|:---|
| Listen | `8080` (TCP) |
| Transport / path | same as B |
| Upstream | `IP_B:2018` |
| Target | `127.0.0.1:8080` (as seen from B) |

| Rule | |
|:---|:---|
| Order | B then A |
| Clients | A's port only |
| Address | Prefer public IP over a bad domain |

Multi port/location: `2 → 4` — [09](09-multi-entry.md)
