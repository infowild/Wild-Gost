# Anti-Filter — extras

مسیر: `2 → 1`

| # | گزینه | کار |
|:---:|:---|:---|
| 1 | Iran panel | reverse + entry + decoy + نود اول |
| 2 | Add node | hostname/SNI جدید · Tunnel ID جدید |
| 3 | Foreign node | خارج dial به ایران |
| 4 | Decoy only | فقط سایت فیک |
| 5 | Status | `/etc/gost/wild-antifilter.json` |
| 6 | Doctor | عیب‌یابی |
| 7 | TLS cert | گواهی listener |

## Decoy (`4`)

| حالت | رفتار پروب |
|:---|:---|
| File server | استاتیک |
| HTTP + probeResist file | HTML فیک |
| HTTP + probeResist 404 | 404 |

معمولاً `:80`.

## TLS (`7`)

| گزینه | کار |
|:---|:---|
| Let's Encrypt + nginx | DNS → nginx `:80` ACME → `/etc/gost/certs/` |
| مسیر موجود | cert/key آماده |
| Self-signed | تست |
| Skip | بدون TLS اجباری |

اگر GOST `:80` را گرفته باشد، decoy به nginx منتقل می‌شود.

مسیریابی کاربر: Host/SNI · نه path. VLESS خام بدون TLS → معمولاً `malformed HTTP`.
