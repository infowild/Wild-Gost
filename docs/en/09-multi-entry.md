# Multi-entry

Path: `2 → 4`

Several listens on A, or several Server B nodes.

| Field | Value |
|:---|:---|
| Proto | TCP / UDP |
| Connector | relay / socks5 / http — MASQUE forces `masque` |
| Transport | shared preset |
| Locations | name + `IP:port` per B |
| Ports | e.g. `8080,8443` |
| Target | `127.0.0.1:PORT` or one fixed addr |

## Mode

| Mode | Behavior |
|:---|:---|
| Port per location | `listen = PORT + index×offset` — e.g. offset `10000`: US `:8080` · DE `:18080` |
| Shared + selector | shared port · `fifo` / `round` / `rand` |

Build all B upstreams first · matching transport · verify each listen/upstream in List.
