# Install & update the binary

On **every** server (entry and exit) you must install the `gost` binary once. Without it the menu opens, but tunnels will not work.

## Open install

```bash
sudo wild gost
```

Choose **`1) Install / Update`**.

If the script is not installed yet:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/infowild/Wild-Gost/master/gost.sh)
```

---

## Four install channels — which one?

| # | Name | What you get | Who should use it |
|:---:|:---|:---|:---|
| **1** | Stable | Latest GitHub stable | Normal MWSS / Relay / Proxy — **not** serious MASQUE |
| **2** | Nightly | Pre-release; masque usually registered | Experiments; TCP CONNECT may still fail |
| **3** | Build patched | Builds from source + applies MASQUE patch | **Preferred for MASQUE** (needs Go download) |
| **4** | Local binary | Copies a file already on disk | When the entry server cannot download Go/GitHub well |

### Simple guidance

- Normal MWSS tunnel → **1 Stable** is usually enough.  
- Reliable MASQUE (HTTP/3) → **3** on the exit server; if needed **4** on the entry server.  
- Updating with **1** on a host that had a patched binary replaces the patch and can break MASQUE.

---

## Recommended MASQUE path (entry server cannot download Go)

### On Server B (abroad)

1. Menu → `1` Install  
2. Choose **`3` Build patched**  
3. Wait for the build to finish  

Final binary is usually:

```text
/usr/local/bin/gost
```

### Copy to the entry server

```bash
scp /usr/local/bin/gost root@ENTRY_IP:/tmp/gost-masque-fixed
```

### On Server A (entry)

1. Menu → `1` Install  
2. Choose **`4` Local binary**  
3. Path: `/tmp/gost-masque-fixed`

---

## After a successful install

- `gost -V` prints a version  
- `sudo wild gost` opens the menu  
- systemd unit `gost` exists  

Iran mode uses GitHub mirrors for GitHub URLs.

---

## Common failures

| Problem | Likely cause | Fix |
|:---|:---|:---|
| Go download fails | Filtered/blocked `go.dev` / mirrors | Build abroad + option 4 on entry |
| `unknown handler: masque` | Old/Stable binary | Option 3 or patched 4 |
| MASQUE breaks after Update | Stable overwrote the patch | Reinstall 3 or 4 |

Next: [Which tunnel?](03-choose-tunnel.md)
