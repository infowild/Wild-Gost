# DNS، TUN، File، Redirect (منوی More)

مسیر: `2 → 8) More`

## ۱) DNS Proxy

منو داخل More: **DNS**

- پورت listen (پیش‌فرض `53`)  
- Upstream مثلاً `udp://8.8.8.8:53` یا `tls://1.1.1.1:853`  
- Listener: dns/udp یا tcp یا tls  

کاربرد: سرور خودش به کلاینت‌ها DNS بدهد و query را به بالادست بفرستد.

روی لینوکس پورت ۵۳ ممکن است با `systemd-resolved` تداخل داشته باشد.

## ۲) TUN / TAP / TUNGO

| گزینه | یعنی چه؟ |
|:---|:---|
| **TUN** | اینترفیس لایه ۳ (IP) |
| **TAP** | لایه ۲ (Ethernet) |
| **TUNGO** | TUN2SOCKS — ترافیک TUN را به پروکسی/chain بفرست |

بعد از ساخت سرویس باید روی سیستم عامل IP/route را خودت تنظیم کنی؛ اسکریپت فقط سرویس GOST را می‌نویسد.

## ۳) File server

یک پوشه را روی پورت HTTP/HTTPS (با listener انتخابی) سرو می‌کند — برای سایت فیک یا فایل استاتیک.

## ۴) Transparent redirect

`red` (TCP) یا `redu` (UDP).

نیاز به قوانین **iptables/nftables** روی هاست دارد (REDIRECT/TPROXY). فقط ساخت سرویس GOST کافی نیست؛ فایروال سیستم را جدا تنظیم کن.
