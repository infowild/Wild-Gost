# MASQUE tunnel (HTTP/3)

## What is MASQUE? (beginner)

MASQUE carries traffic over **HTTP/3**. HTTP/3 uses **QUIC**, and QUIC uses **UDP**.

Unlike MWSS (usually TCP), the firewall must allow **UDP**.

The tunnel logic is still remote port forward:

```text
Client → A:8080 → (masque + h3-masque) → B:9443/UDP → 127.0.0.1:8080
```

| Piece | Meaning |
|:---|:---|
| `masque` | handler/connector type |
| `http3` | B listener type (**not** `h3`) |
| `h3-masque` | A dialer type |

> In GOST, `h3` is something else (PHT). For MASQUE you need `http3`. The script forces this.

---

## Required binary

Old Stable builds (`≤ 3.2.6`) often have no masque at all.  
For reliable TCP CONNECT you need a **patched** binary.

| Server | Recommended action |
|:---|:---|
| Abroad (B) | Install → **3 Build patched** |
| Entry (A) | If Go download fails: `scp` from B → Install → **4** |

Install details: [02](02-install.md)

**Warning:** Do not later Update with Stable; the patch disappears and H3 errors like `270` return.

---

## Step 1 — Server B: MASQUE Upstream

```text
2) Add  →  2) Upstream
```

| Field | Suggested value | Why |
|:---|:---|:---|
| Handler | **4) MASQUE** | MASQUE service |
| Port | e.g. `9443` | Any free UDP port |
| Listener | script sets **http3** | Required |

Firewall on B:

```text
UDP 9443  (or your port) must be open
```

---

## Step 2 — Server A: Entry with MASQUE transport

```text
2) Add  →  3) Entry single
```

| Field | Suggested value |
|:---|:---|
| Listen | e.g. `8080` (TCP for clients) |
| Transport | **11) MASQUE** |
| Upstream | `PUBLIC_IP_B:9443` |
| Target | `127.0.0.1:8080` (panel on B) |

Choosing MASQUE forces connector `masque` and dialer `h3-masque`.

The same works in **Multi-entry** (`2 → 4`) if every B is a MASQUE Upstream.

---

## Common mistakes

| Mistake | Result | Correct |
|:---|:---|:---|
| listener `h3` | wrong/broken tunnel | `http3` |
| TCP-only firewall | no connect | UDP on that port |
| unpatched binary | H3 error `270` | Install 3 or patched 4 |
| Stable after patch | breaks again | avoid Stable for MASQUE |
| Target = entry IP | wrong destination | Target as seen from B |

---

## How do I know it works?

- B logs show something like `connect-tcp`  
- `curl` to a panel port may return empty; normal for VLESS  
- Real client connects to `IP_A:8080`  

If not, use the checklist in [08](08-edit-logs.md).

---

## Security expectations

- Channel is TLS inside QUIC  
- In GOST this capability is still described at Alpha level  
- Traffic looks like HTTP/3; **not a guaranteed censorship bypass**
