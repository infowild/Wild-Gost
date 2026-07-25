# Install & update

On every server once:

```bash
sudo wild gost
# 1) Install / Update
```

## Install channels

| Option | What you get | When to use |
|:---|:---|:---|
| **1 Stable** | Latest GitHub stable | Normal use without MASQUE |
| **2 Nightly** | Pre-release (registers masque) | MASQUE experiments; TCP CONNECT may still be buggy |
| **3 Build patched** | Source build + MASQUE TCP fix | **Recommended for MASQUE** (needs Go download) |
| **4 Local binary** | File already on disk | When Iran blocks `go.dev`: `scp` binary from abroad |

## Iranian servers

If option 3 fails downloading Go:

1. Build with option **3** on the **foreign** server  
2. Copy:

```bash
scp /usr/local/bin/gost root@IRAN_IP:/tmp/gost-masque-fixed
```

3. On Iran: Install → **4** → `/tmp/gost-masque-fixed`

Iran mode uses GitHub mirrors for GitHub URLs.

## Warning

Stable update (option 1) can replace a MASQUE-patched binary and break MASQUE tunnels.
