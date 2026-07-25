# Anti-Filter (Iran reverse)

Exit nodes **dial Iran** (reverse). Users only see the Iran domain/IP.

```text
Client ──SNI/Host──► Iran :443 (entrypoint)
                         │
Exit ──tunnel──► Iran :control-port ──► 127.0.0.1:panel on exit
```

## Menu steps

| Step | Where | Path |
|:---|:---|:---|
| 1 | Iran | `2 → 1 → 1` Iran panel |
| 2 | Abroad | `2 → 1 → 3` Foreign node (same Tunnel ID) |
| 3 | Optional | `2 → 1 → 2` more nodes via hostname |

## Simple notes

- Multi-node routing uses **hostname / SNI** (not URL paths)  
- Transport must match both sides (default MWSS)  
- Decoy on `:80` shows a normal page  
- State: `/etc/gost/wild-antifilter.json`  
- Entrypoint is not ideal for raw VLESS without TLS; use TLS+SNI or a plain Entry forward  

Doctor: `2 → 1 → 6`
