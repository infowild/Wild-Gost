# Edit · Advanced · Uninstall

## Edit — `3`

| Field | |
|:---|:---|
| Name / listen | |
| Handler / listener | masque → forced `http3`+`enableDatagrams` |
| Metadata | UDP · BIND · path · tunnel id |
| Auth | |
| Forwarder / target | |
| Chain | upstream · connector · dialer · auth |

## Advanced — `8`

| Option | Action |
|:---|:---|
| Bypass | destination allow/deny |
| Admission | client IP allow/deny |
| Limiter | rate / bandwidth caps |
| API / Metrics | Web API · Prometheus · profiling |
| Log level | info / debug / warn / error |
| Raw JSON | `/etc/gost/config.json` |

## Service — `6` · Logs — `7` · Remove — `4`

`systemctl` for `gost.service` · live logs/validate · delete one service (+ related chain).

## Uninstall — `9`

| Removed | Optional |
|:---|:---|
| Binary · unit · `/etc/gost` · decoy | LE for Wild GOST domains only |
| nginx `wild-gost-*` · certbot hooks | `/usr/local/go` only with `.installed-by-wild-gost` |
| `/tmp` MASQUE/build leftovers | |

System nginx/certbot packages stay.
