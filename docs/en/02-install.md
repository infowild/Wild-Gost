# Install

```bash
sudo wild gost
# 1) Install / Update
```

| # | Channel | Result |
|:---:|:---|:---|
| 1 | Stable | Release — not reliable for MASQUE |
| 2 | Nightly | Registers masque; TCP CONNECT may fail |
| 3 | Build patched | Source + MASQUE patch — preferred for HTTP/3 |
| 4 | Local binary | Install from disk path |

## Iran without Go

1. Abroad: Install → `3`  
2. `scp /usr/local/bin/gost root@IRAN:/tmp/gost-masque-fixed`  
3. Iran: Install → `4` → `/tmp/gost-masque-fixed`

Iran mode uses GitHub mirrors.

**Warning:** Update via `1` (Stable) replaces a patched binary → MASQUE breaks.
