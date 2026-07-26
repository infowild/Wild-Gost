# Edit, Advanced, Uninstall

This page covers maintenance menus in detail. Day-to-day debugging: [08](08-edit-logs.md)

---

## Edit — menu `3`

After picking a service you can change:

| Group | Examples |
|:---|:---|
| Identity | Service name, listen address |
| Types | Handler, listener |
| Metadata | UDP, BIND, path, tunnel id, … |
| Security | Auth user/password |
| Destination | Forwarder / target |
| Chain | Upstream address, connector, dialer, auth |

### Special MASQUE behavior in Edit

Setting handler to `masque` forces the listener to:

- type `http3`  
- `enableDatagrams`

After important changes: menu `6` → Restart.

---

## Advanced — menu `8`

| Option | Beginner meaning | When you need it |
|:---|:---|:---|
| **Bypass** | Some destinations skip the proxy / or only some are allowed | Exceptions for specific sites/IPs |
| **Admission** | Allow or deny client IPs that may connect | Restrict who can use the server |
| **Limiter** | Cap speed or connection rate | Stop abuse — if everything feels slow, check here |
| **API / Metrics** | Web API, Prometheus, profiling | Advanced monitoring |
| **Log level** | info / debug / warn / error | Same idea as Logs menu |
| **Raw JSON** | View full `/etc/gost/config.json` | See exactly what the script wrote |

A wrong Advanced setting can make a tunnel “work but feel broken”. Limiter is the first suspect for unexpected slowness.

---

## Service — menu `6`

systemd controls for `gost.service`:

- Start  
- Stop  
- Restart  
- Status  

Rough equivalents:

```bash
systemctl status gost
systemctl restart gost
```

---

## Logs — menu `7`

- Live follow  
- Error filter  
- Export to file  
- Validate config  
- Change log level  

---

## Remove — menu `4`

Deletes one service from the config. If a chain belongs only to that service, the chain may be removed too.

Other services and the binary stay.

---

## Uninstall — menu `9`

Fuller cleanup of Wild GOST from the host.

### Removed by default

| Item | Where |
|:---|:---|
| Binary and menu commands | `gost` · `wild` · `gost-manage.sh` |
| Config and state | entire `/etc/gost` |
| Decoy | `/var/www/wild-gost-decoy` |
| Script nginx sites | `wild-gost-*.conf` |
| Certbot hooks | `wild-gost-reload.sh` · `wild-gost-sync-certs.sh` |
| Build leftovers | `/tmp/gost-masque-fixed` · `/tmp/gost-build` · `/tmp/x-build` and similar |

### Optional questions during Uninstall

| Question | Default | Meaning |
|:---|:---|:---|
| Delete Let's Encrypt certs? | Usually No | Only domains detected as Wild GOST — not every cert on the server |
| Delete `/usr/local/go`? | Usually No | Only if marked `.installed-by-wild-gost` |

System packages like `nginx` and `certbot` are left installed; they may be used elsewhere.

### After Uninstall

The menu exits because the script was removed from PATH. Reinstall with the curl command from the README.
