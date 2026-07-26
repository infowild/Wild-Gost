# Edit, logs, remove, debugging

Use these menus when a tunnel already exists or when it will not connect.

---

## Quick map

| I want to… | Menu | Notes |
|:---|:---:|:---|
| Change port / upstream / transport | **3** Edit | Edit service or chain |
| Delete one service | **4** Remove | Does not wipe the whole install |
| See what I have | **5** List | Names, addresses, roles |
| Start/stop gost | **6** Service | Like systemctl |
| Find why it fails | **7** Logs | Live logs and Debug |
| Rate limits / API / raw JSON | **8** Advanced | [13](13-edit-advanced.md) |
| Remove Wild GOST from the server | **9** Uninstall | [13](13-edit-advanced.md) |

---

## What can Edit (`3`) change?

Usually:

- Service name and listen address  
- Handler and listener types  
- Metadata such as UDP, BIND, path, tunnel id  
- Auth username/password  
- Forwarder / target  
- In the chain: upstream address, connector, dialer, auth  

If you set handler to **masque**, the script forces listener **http3 + enableDatagrams**.

After important edits, Restart via menu `6`.

---

## How beginners should use Logs (`7`)

1. Open live logs  
2. Trigger one client connection  
3. Read the new lines  

| If you see | Simple meaning |
|:---|:---|
| `timeout` / `i/o timeout` | Cannot reach B; IP, port, firewall |
| `connection refused` | Nothing listening on the target |
| `auth` / authentication | Wrong user/password |
| `unknown handler` | Binary lacks the feature (e.g. masque) |
| `270` with MASQUE | Usually unpatched binary |
| `malformed HTTP` | Client protocol does not match handler |

### Temporary Debug

1. Menu `7` → set log level to Debug  
2. Reproduce once  
3. Switch back to Info (Debug is noisy)

---

## Checklist when it “does not connect”

Go top to bottom:

| # | Question | How to check |
|:---:|:---|:---|
| 1 | Is the service in List? | Menu `5` |
| 2 | Is gost active? | Menu `6` or `systemctl is-active gost` |
| 3 | Firewall correct? | TCP for MWSS · **UDP** for MASQUE |
| 4 | Is B built and up first? | List/Status on B |
| 5 | Matching transport and path? | Edit or List both sides |
| 6 | Client dials **A’s** port? | Not B’s Upstream port |
| 7 | Target correct as seen from B? | Often `127.0.0.1:panel-port` |
| 8 | MASQUE binary patched? | Only for MASQUE scenarios |

---

## Remove vs Uninstall

| | Remove (`4`) | Uninstall (`9`) |
|:---|:---|:---|
| Removes | One service (and maybe its chain) | Almost all of Wild GOST |
| Other config | Stays | `/etc/gost` wiped |
| Binary | Stays | Removed |

Uninstall details: [13](13-edit-advanced.md)
