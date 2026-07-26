# Anti-Filter

Exit dials Iran. Clients see only the Iran domain/IP.

```text
Client ──SNI──► Iran :443
Exit ──tunnel──► Iran :control → 127.0.0.1:panel@Exit
```

| Step | Where | Path |
|:---:|:---|:---|
| 1 | Iran | `2 → 1 → 1` Iran panel |
| 2 | Abroad | `2 → 1 → 3` Foreign node (same Tunnel ID) |
| 3 | Optional | `2 → 1 → 2` more nodes |

| Rule | Detail |
|:---|:---|
| Routing | Host / SNI — not path |
| Transport | Match both ends (default MWSS) |
| Decoy | usually `:80` |
| State | `/etc/gost/wild-antifilter.json` |
| Raw VLESS | needs TLS; bare inbound unfit for entrypoint |

Doctor: `2 → 1 → 6` · Extras: [12](12-antifilter-extras.md)
