# Two-server tunnel (MWSS / Relay)

## What is this scenario?

Classic remote port forward:

- User connects to **Server A** (often entry/Iran)  
- A sends traffic over an encrypted transport to **Server B** (abroad)  
- B forwards to the target; often `127.0.0.1:8080` = panel on B itself  

```text
Client
   │
   ▼
A:8080  (Entry)
   │  MWSS (e.g. port 2018)
   ▼
B:2018  (Upstream Relay)
   │
   ▼
127.0.0.1:8080  (panel on B)
```

For the HTTP/3 version of the same idea, see [MASQUE](06-masque.md).

---

## Prerequisites

1. Install on A and B ([02](02-install.md)) — Stable is usually enough for MWSS  
2. Panel/target listening on B  
3. Firewall on B allows Upstream port **TCP**  

---

## Step 1 — Server B: Upstream

```text
sudo wild gost  →  2) Add  →  2) Upstream
```

Sample answers:

| Wizard field | Example | Why |
|:---|:---|:---|
| Name | `us` | Label in List |
| Port | `2018` or `443` | Port A will dial |
| Handler | **Relay** | Fits this tunnel |
| Transport | **MWSS** | Good default |
| Path | `/ws` | Must match on A |
| Auth | optional | If set, Entry must match |

Note B’s public IP and port.

---

## Step 2 — Server A: Entry single

```text
sudo wild gost  →  2) Add  →  3) Entry single
```

| Field | Example | Why |
|:---|:---|:---|
| Listen port | `8080` | Port **clients** dial |
| TCP / UDP | TCP | Typical for panels |
| Connector | relay | Must match B’s handler |
| Transport | MWSS | Same as B |
| Path | `/ws` | Same as B |
| Upstream address | `216.x.x.x:2018` | B public IP + Upstream port |
| Target | `127.0.0.1:8080` | Destination **as seen from B** |

### Target mistake everyone makes

Target is not “an address on A”.  
A tells B: “after the tunnel, go here”.  
Panel on B itself → `127.0.0.1:8080` is correct.  
Panel on another host in B’s LAN → use that host’s IP.

---

## Golden rules

1. **B first, then A**  
2. Matching transport and path  
3. Clients dial **A’s port**, not B’s Upstream port  
4. Prefer B’s **public IP** over a domain that may resolve wrong  
5. After build: List + one client test + Logs  

---

## Simple test

1. Point the client to `IP_A:8080`  
2. If it fails:  
   - Is B up?  
   - Is B’s port open on TCP from the internet?  
   - Same path/MWSS?  
   - Do A logs show `dial` / `timeout`?  

Debug guide: [08](08-edit-logs.md)

---

## Several ports or countries?

```text
2 → 4) Entry multi-port / multi-location
```

Guide: [09 Multi-entry](09-multi-entry.md)
