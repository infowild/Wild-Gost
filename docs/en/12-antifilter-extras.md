# Anti-Filter — extras (Decoy, TLS, Doctor)

Base menu:

```text
2) Add  →  1) Anti-Filter
```

Panel/node build guide: [04](04-antifilter.md)  
This page explains the helper options in full.

---

## Full option map

| # | Option | Plain meaning |
|:---:|:---|:---|
| 1 | Iran panel | On Iran: reverse + entry + decoy + first node |
| 2 | Add node | New node with hostname/SNI and new Tunnel ID |
| 3 | Foreign node | On abroad: dial Iran |
| 4 | Decoy only | Fake site only, without full panel setup |
| 5 | Status | Read `/etc/gost/wild-antifilter.json` |
| 6 | Doctor | Step-by-step diagnostics |
| 7 | TLS cert | Obtain or attach certificates for listeners |

---

## Decoy only (`4`) — fake site

Goal: unauthenticated probes see a “normal” page instead of the real service.

| Wizard mode | Behavior |
|:---|:---|
| File server | Serves static files/page |
| HTTP + probeResist file | Unauthenticated probes get decoy HTML |
| HTTP + probeResist 404 | Unauthenticated probes get 404 |

Usually on port **80**. Files often live at:

```text
/var/www/wild-gost-decoy
```

---

## TLS cert (`7`) — certificates

Without a proper cert, TLS clients may fail and SNI setups are weaker.

| Option | Beginner steps |
|:---|:---|
| **Let's Encrypt + nginx** | Point DNS to the server → nginx on `:80` for ACME → certbot issues cert → copy into `/etc/gost/certs/` → renew hooks installed |
| **Existing paths** | Provide ready `fullchain` and `key` paths |
| **Self-signed** | Quick test; browsers will not trust it |
| **Skip** | No forced TLS for now |

### Port 80 note

If GOST already owns `:80` for decoy, the wizard tries to move decoy to nginx so ACME can work.

After obtaining a cert you can apply it to antifilter listeners (Apply prompt).

---

## Doctor (`6`)

Doctor prints diagnostics such as:

- whether gost is active  
- ports and roles  
- state contents  
- common failure hints  

Copy the output; it helps debugging a lot.

---

## Status (`5`)

Shows the state file: domain, ports, nodes, cert paths after panel creation.

---

## User routing reminders

| Correct | Incorrect |
|:---|:---|
| Separate nodes by Host/SNI (`us.domain.com`) | Expecting a path like `/us` to switch nodes |
| Client with proper TLS + SNI | Raw VLESS without TLS into entrypoint (often `malformed HTTP`) |

If you only want a simple forward to a panel and do not want SNI complexity, use [Entry + Upstream](05-remote-forward.md).
