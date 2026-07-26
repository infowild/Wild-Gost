# Anti-Filter (Iran reverse)

## What is this scenario?

In the normal model, clients dial the exit server. In **Anti-Filter** it is reversed:

- The **abroad** server dials **Iran** (reverse)  
- Users only see the Iran domain/IP  
- Multi-node routing uses **Hostname / SNI**, not paths like `/us`

```text
User
  │  SNI / Host  (e.g. us.example.com)
  ▼
Iran :443   ←  user entrypoint
  │
  ├── optional decoy on :80
  │
  └── tunnel control port
        ▲
        │  abroad node dials in
        │
     Abroad server  ──►  127.0.0.1:panel-port on abroad
```

Panel state file:

```text
/etc/gost/wild-antifilter.json
```

---

## Prerequisites

- Domain DNS pointing to the Iran IP (usually needed for TLS/SNI)  
- Install on Iran and abroad  
- Firewall open for control + entry ports on Iran  

---

## Step 1 — Iran: Iran panel

```text
2) Add  →  1) Anti-Filter  →  1) Iran panel
```

Typical questions:

| Question | Beginner meaning |
|:---|:---|
| Domain | Domain users/SNI will use |
| Tunnel control port | Port the abroad node dials |
| Entry port | Usually 443 for users |
| Transport | Tunnel dress Iran↔abroad (often MWSS) |
| Decoy on 80? | Fake page for probes |
| First node | Name + hostname/SNI + target on abroad |

At the end you get a **Tunnel ID** and notes for the abroad node. Save them.

---

## Step 2 — Abroad: Foreign node

```text
2) Add  →  1) Anti-Filter  →  3) Foreign node
```

| Field | Meaning |
|:---|:---|
| Iran address | `IRAN_IP:control_port` |
| Tunnel ID | Same value created on Iran |
| Transport / path | Must match the Iran panel |
| Target | Usually `127.0.0.1:panel-port` on this abroad host |

---

## Step 3 — More nodes (optional)

On Iran:

```text
2 → 1 → 2) Add node to panel
```

Each node gets its own hostname, e.g.:

- `us.example.com`  
- `de.example.com`  

Users switch nodes by changing SNI/Host, not by changing a URL path.

---

## Other Anti-Filter options

| # | Action |
|:---:|:---|
| 4 | Decoy only |
| 5 | Status — read state file |
| 6 | Doctor — step diagnostics |
| 7 | TLS cert — Let's Encrypt / self-signed / manual paths |

Details: [12 Anti-Filter extras](12-antifilter-extras.md)

---

## Beginner rules

1. Transport must match on both sides.  
2. For WS/WSS/MWSS, **path** must match.  
3. Raw VLESS without TLS into the entrypoint usually fails (`malformed HTTP`). Use TLS+SNI, or a plain Entry forward ([05](05-remote-forward.md)).  
4. When unsure, run Doctor and read the output.

---

## Quick checks after build

| Check | How |
|:---|:---|
| Services exist? | Menu `5` List |
| gost active? | Menu `6` or `systemctl is-active gost` |
| Abroad node connected? | Logs on both sides |
| SNI correct? | Client must use that node hostname |
