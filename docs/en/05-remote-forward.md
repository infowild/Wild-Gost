# Two-server tunnel (MWSS / Relay)

Classic remote port forward:

```text
Client --> A:8080 --> MWSS --> B:2018 (Relay) --> 127.0.0.1:8080 (panel)
```

## Step 1 — Server B (abroad)

1. `2 → 2` Upstream  
2. Name (e.g. `us`)  
3. Port (e.g. `2018` or `443`)  
4. Handler: **Relay**  
5. Transport: **MWSS** (recommended)  
6. Note the path (default `/ws`)

## Step 2 — Server A (entry)

1. `2 → 3` Entry single  
2. Listen = client port (e.g. `8080`)  
3. TCP  
4. Same transport + path  
5. Upstream = `PUBLIC_IP_B:port`  
6. Target = `127.0.0.1:8080` (panel on B)

## Golden rules

- B first, then A  
- Matching transport/path  
- Clients connect to **A's listen port**  
- Target is as seen **from B**  
- Prefer public IP over a domain that might resolve wrong  

## Multi-port / multi-location

Menu `2 → 4`: several listen ports or several Server B nodes with a selector.
