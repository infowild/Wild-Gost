# MASQUE tunnel (HTTP/3)

MASQUE carries traffic over **HTTP/3 / QUIC (UDP)**. It supports TCP and UDP; panel scenarios are usually **TCP**.

```text
Client --> A:8080 --> masque + h3-masque --> B:9443/udp (masque+http3) --> 127.0.0.1:8080
```

## Binary requirement

Old stable (`≤3.2.6`) has no masque. For reliable TCP CONNECT:

- Install → **3** (patched build) on the foreign server  
- On Iran if Go download fails → Install → **4** with an `scp`'d binary  

## Step 1 — Server B

1. `2 → 2` Upstream  
2. Handler: **4) MASQUE**  
3. Port e.g. `9443`  
4. Script forces listener **http3** (not `h3`)  

Firewall: allow **UDP** on that port.

## Step 2 — Server A

1. `2 → 3` Entry single  
2. Listen e.g. `8080` / TCP  
3. Transport: **11) MASQUE**  
4. Upstream: `IP_B:9443`  
5. Target: `127.0.0.1:8080`

## Important warnings

| Wrong | Right |
|:---|:---|
| listener `h3` | must be **`http3`** (`h3` is PHT, not MASQUE) |
| unpatched binary | may hit H3 error `270` |
| TCP-only firewall | MASQUE needs **UDP** |

Empty `curl` replies to a panel inbound are normal. Success = `connect-tcp` logs on B.

Security: channel is TLS inside QUIC; feature is still Alpha in GOST. Looks like HTTP/3; not a guaranteed censorship bypass.
