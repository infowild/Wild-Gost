# Edit · Advanced · Uninstall

## Edit — `3`

| فیلد | |
|:---|:---|
| Name / listen | |
| Handler / listener | masque → اجباری `http3`+`enableDatagrams` |
| Metadata | UDP · BIND · path · tunnel id |
| Auth | |
| Forwarder / target | |
| Chain | upstream · connector · dialer · auth |

## Advanced — `8`

| گزینه | کار |
|:---|:---|
| Bypass | استثنا / whitelist مقصد |
| Admission | allow/deny IP کلاینت |
| Limiter | سقف سرعت / نرخ |
| API / Metrics | Web API · Prometheus · profiling |
| Log level | info / debug / warn / error |
| Raw JSON | `/etc/gost/config.json` |

## Service — `6` · Logs — `7` · Remove — `4`

`systemctl` برای `gost.service` · لاگ زنده/validate · حذف یک سرویس (+ chain مرتبط).

## Uninstall — `9`

| حذف می‌شود | اختیاری |
|:---|:---|
| باینری · unit · `/etc/gost` · decoy | LE فقط دامنه‌های Wild GOST |
| nginx `wild-gost-*` · هوک certbot | `/usr/local/go` فقط با مارکر `.installed-by-wild-gost` |
| `/tmp` MASQUE/build leftovers | |

پکیج سیستم nginx/certbot نمی‌رود.
