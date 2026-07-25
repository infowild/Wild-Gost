# Which tunnel should I pick?

| Need | Use | One-line meaning |
|:---|:---|:---|
| Bypass filters; hide exit IP | **Anti-Filter** (`2 → 1`) | Exit dials Iran |
| Client hits Iran; exit + panel on abroad | **Entry + Upstream** (`2 → 3` / `2 → 2`) | Classic two-server forward |
| Same, but over HTTP/3 (UDP) | **MASQUE** | MASQUE upstream + MASQUE entry |
| One server SOCKS/HTTP | **Proxy** (`2 → 5`) | Simplest |
| Just move a port | **Local forward** (`2 → 6`) | e.g. `:8080` → LAN host |
| Several countries / ports on Iran | **Entry multi** (`2 → 4`) | Multiple B or listens |

## Two roles in a two-server tunnel

```text
Client  -->  Server A (entry)  -->  tunnel  -->  Server B (upstream)  -->  target (e.g. panel)
```

- **A:** where users connect  
- **B:** where traffic exits / panel listens  

Always create **B first**, then **A**.
