# Edit, Advanced, Uninstall

## Edit — menu `3`

Typical fields you can change:

- Name / listen address  
- Handler and listener types  
- Metadata (UDP, BIND, path, tunnel id, …)  
- Auth  
- Forwarder / target  
- Chain: upstream address, connector, dialer, auth  

Setting handler to **masque** forces listener **http3 + enableDatagrams**.

## Advanced — menu `8`

| Option | Meaning |
|:---|:---|
| **Bypass** | Skip (or only allow) some destinations |
| **Admission** | Allow/deny client IPs |
| **Limiter** | Bandwidth / rate caps |
| **API / Metrics** | Web API, Prometheus, profiling |
| **Log level** | info / debug / warn / error |
| **Raw JSON** | Full `/etc/gost/config.json` |

A limiter will intentionally slow traffic — check here if things feel capped.

## Service — menu `6`

Start / Stop / Restart / Status via `gost.service`.

## Logs — menu `7`

Live tail, errors, export, config validate, log level.

## Remove — menu `4`

Deletes one service; related chain may be removed too.

## Uninstall — menu `9`

Broader cleanup:

- Binary and unit  
- `/etc/gost`  
- Decoy  
- nginx sites prefixed `wild-gost-*`  
- Related certbot hooks  
- MASQUE/build leftovers under `/tmp` (`gost-masque-fixed`, `gost-build`, `x-build`)  
- Optional: Let's Encrypt certs **only for detected Wild GOST domains** (not every file under certs)  
- Optional: `/usr/local/go` **only if** marked `.installed-by-wild-gost`  

System packages nginx/certbot are left installed by default.
