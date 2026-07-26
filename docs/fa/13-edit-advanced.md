# Edit، Advanced، Uninstall

## Edit — منو `3`

معمولاً می‌توانی این‌ها را عوض کنی:

- نام / آدرس listen  
- نوع handler و listener  
- metadata (مثل UDP، BIND، path، tunnel id)  
- auth  
- forwarder / target  
- chain: آدرس upstream، connector، dialer، auth  

اگر handler را **masque** کنی، listener به **http3 + enableDatagrams** اجبار می‌شود.

## Advanced — منو `8`

| گزینه | معنی ساده |
|:---|:---|
| **Bypass** | بعضی مقصدها از پروکسی رد نشوند (یا برعکس در whitelist) |
| **Admission** | اجازه/مسدود کردن IP کلاینت |
| **Limiter** | سقف سرعت / نرخ اتصال |
| **API / Metrics** | Web API، Prometheus، profiling |
| **Log level** | info / debug / warn / error |
| **Raw JSON** | دیدن کل `/etc/gost/config.json` |

Limiter اگر ست شود عمداً سرعت را کم می‌کند؛ اگر کندی دیدی اینجا را چک کن.

## Service — منو `6`

Start / Stop / Restart / Status همان `systemctl` برای `gost.service`.

## Logs — منو `7`

لاگ زنده، فیلتر خطا، خروجی فایل، validate کانفیگ، تغییر سطح لاگ.

## Remove — منو `4`

یک سرویس را پاک می‌کند؛ در صورت وجود، chain مرتبط هم ممکن است حذف شود.

## Uninstall — منو `9`

پاکسازی کامل‌تر:

- باینری و unit  
- `/etc/gost`  
- decoy  
- سایت‌های nginx با پیشوند `wild-gost-*`  
- هوک‌های certbot مرتبط  
- اختیاری: گواهی Let's Encrypt  

پکیج سیستم nginx/certbot را به‌طور پیش‌فرض حذف نمی‌کند.
