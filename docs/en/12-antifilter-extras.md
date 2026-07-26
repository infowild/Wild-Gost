# Anti-Filter — extra details

Base menu: `2 → 1`

| # | Option | Job |
|:---:|:---|:---|
| 1 | Iran panel | Iran: reverse + entry + decoy + first node |
| 2 | Add node | New hostname/SNI → new Tunnel ID |
| 3 | Foreign node | Exit dials Iran |
| 4 | Decoy only | Fake site only |
| 5 | Status | Read `/etc/gost/wild-antifilter.json` |
| 6 | Doctor | Step-by-step diagnostics |
| 7 | TLS cert | Certificates for GOST listeners |

## Decoy (option 4)

| Mode | Meaning |
|:---|:---|
| File server | Static page/files |
| HTTP + probeResist file | Unauthenticated probes see decoy HTML |
| HTTP + probeResist 404 | Probes get 404 |

Usually on `:80` so scanners see a “normal” site.

## TLS cert (option 7)

| Wizard choice | Use |
|:---|:---|
| Let's Encrypt + nginx | Point DNS → nginx `:80` ACME → copy certs to `/etc/gost/certs/` |
| Existing cert/key paths | You already have files |
| Self-signed | Quick test |
| Skip | GOST default / no forced TLS |

If GOST already owned `:80`, decoy moves to nginx so ACME can work.

## Doctor (option 6)

Prints service/port/state hints. Keep the output for debugging.

## User routing reminder

- Nodes are split by **Host / SNI**, not paths like `/us`  
- Raw VLESS without TLS into entrypoint often logs `malformed HTTP`  
