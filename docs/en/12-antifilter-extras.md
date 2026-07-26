# Anti-Filter — extras

Path: `2 → 1`

| # | Option | Action |
|:---:|:---|:---|
| 1 | Iran panel | reverse + entry + decoy + first node |
| 2 | Add node | new hostname/SNI · new Tunnel ID |
| 3 | Foreign node | exit dials Iran |
| 4 | Decoy only | fake site only |
| 5 | Status | `/etc/gost/wild-antifilter.json` |
| 6 | Doctor | diagnostics |
| 7 | TLS cert | listener certificates |

## Decoy (`4`)

| Mode | Probe sees |
|:---|:---|
| File server | static files |
| HTTP + probeResist file | decoy HTML |
| HTTP + probeResist 404 | 404 |

Usually `:80`.

## TLS (`7`)

| Option | Action |
|:---|:---|
| Let's Encrypt + nginx | DNS → nginx `:80` ACME → `/etc/gost/certs/` |
| Existing paths | ready cert/key |
| Self-signed | quick test |
| Skip | no forced TLS |

If GOST owns `:80`, decoy moves to nginx.

Client routing: Host/SNI · not path. Raw VLESS without TLS → often `malformed HTTP`.
