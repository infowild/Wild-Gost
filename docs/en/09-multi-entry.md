# Multi-port / multi-location Entry

Menu: `2 → 4) Entry multi-port / multi-location`

Use when Iran needs several listen ports, or several Server B exits (e.g. US + DE).

## What the wizard asks

1. Config **group name**  
2. **TCP or UDP**  
3. **Connector** (relay / socks5 / http) — MASQUE transport forces connector `masque`  
4. **Transport preset**  
5. **Locations:** each Server B name + `IP:port`  
6. **Ports:** comma list, e.g. `8080,8443`  
7. **Target:** `127.0.0.1:PORT` or one custom target for all  
8. **Mode:**

### Mode 1 — port per location

```text
listen = PORT + (index × offset)
Example offset=10000, base 8080:
  US → :8080
  DE → :18080
```

### Mode 2 — shared + selector

Shared listen port(s); pick upstream with:

| Strategy | Meaning |
|:---|:---|
| **fifo** | Prefer first until it fails |
| **round** | Round-robin |
| **rand** | Random |

## Notes

- Build all B upstreams first  
- Same transport on every node  
- Verify each listen/upstream in List  
