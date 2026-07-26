# MASQUE

HTTP/3 / QUIC over **UDP**.

```text
Client → A:8080 → masque+h3-masque → B:9443/udp (masque+http3) → 127.0.0.1:8080
```

## Binary

| Case | Action |
|:---|:---|
| Old stable | No masque |
| Preferred | Install → `3` on abroad |
| Iran without Go | Install → `4` + `scp`'d file |

## B — `2 → 2`

Handler `4) MASQUE` · port e.g. `9443` · listener forced **`http3`** · firewall **UDP**.

## A — `2 → 3`

Listen `8080` TCP · Transport `11) MASQUE` · Upstream `IP_B:9443` · Target `127.0.0.1:8080`.

| Wrong | Right |
|:---|:---|
| listener `h3` | **`http3`** (`h3` = PHT) |
| unpatched binary | H3 error `270` |
| TCP-only firewall | UDP required |

Success = `connect-tcp` on B. Empty `curl` to a panel inbound is normal.
