# Anti-Filter — جزئیات بیشتر

منوی پایه: `2 → 1`

| # | گزینه | کار |
|:---:|:---|:---|
| 1 | Iran panel | سرور ایران: reverse + entry + decoy + نود اول |
| 2 | Add node | hostname/SNI جدید → Tunnel ID جدید |
| 3 | Foreign node | سرور خارج به ایران dial می‌کند |
| 4 | Decoy only | فقط سایت فیک |
| 5 | Status | خواندن `/etc/gost/wild-antifilter.json` |
| 6 | Doctor | عیب‌یابی مرحله‌ای |
| 7 | TLS cert | گواهی برای listenerهای GOST |

## Decoy (گزینه ۴)

| حالت | معنی |
|:---|:---|
| File server | صفحه/فایل استاتیک |
| HTTP + probeResist file | پروب بدون auth فایل HTML فیک می‌بیند |
| HTTP + probeResist 404 | پروب کد ۴۰۴ می‌گیرد |

معمولاً روی `:80` تا اسکنر سایت «عادی» ببیند.

## TLS cert (گزینه ۷)

| گزینه ویزارد | کاربرد |
|:---|:---|
| Let's Encrypt + nginx | DNS دامنه → nginx روی `:80` برای ACME → کپی cert به `/etc/gost/certs/` |
| مسیر cert/key موجود | اگر گواهی از قبل داری |
| Self-signed | تست سریع |
| Skip | GOST خودش/بدون TLS اجباری |

اگر GOST قبلاً `:80` را گرفته باشد، decoy به nginx منتقل می‌شود تا ACME کار کند.

## Doctor (گزینه ۶)

وضعیت سرویس، پورت، state، نمونه dialer و نکات رایج را چاپ می‌کند. خروجی را برای دیباگ نگه دار.

## یادآوری مسیریابی کاربر

- چند نود با **Host / SNI** جدا می‌شوند، نه path مثل `/us`  
- VLESS خام بدون TLS به entrypoint معمولاً `malformed HTTP` می‌دهد  
