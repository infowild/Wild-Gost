# Edit، Advanced، Uninstall

این صفحه جزئیات منوهای نگهداری را می‌گوید. عیب‌یابی روزمره: [08](08-edit-logs.md)

---

## Edit — منو `3`

بعد از انتخاب سرویس می‌توانی فیلدها را عوض کنی:

| گروه | مثال‌ها |
|:---|:---|
| هویت | نام سرویس، آدرس listen |
| نوع | handler، listener |
| metadata | UDP، BIND، path، tunnel id، … |
| امنیت | auth کاربر/رمز |
| مقصد | forwarder / target |
| chain | آدرس upstream، connector، dialer، auth |

### رفتار خاص MASQUE در Edit

اگر handler را `masque` کنی، اسکریپت listener را به این‌ها اجبار می‌کند:

- نوع `http3`  
- `enableDatagrams`

بعد از تغییرات مهم: منو `6` → Restart.

---

## Advanced — منو `8`

| گزینه | برای مبتدی یعنی چه؟ | کی لازم است؟ |
|:---|:---|:---|
| **Bypass** | بعضی مقصدها از پروکسی رد شوند / یا فقط بعضی مجاز باشند | استثنا گذاشتن برای سایت/IP خاص |
| **Admission** | اجازه یا ممنوعیت IP کلاینت‌هایی که وصل می‌شوند | محدود کردن دسترسی به سرور |
| **Limiter** | سقف سرعت یا تعداد اتصال | جلوگیری از مصرف بی‌رویه — اگر همه چیز کند شد اینجا را چک کن |
| **API / Metrics** | API وب، Prometheus، profiling | مانیتورینگ پیشرفته |
| **Log level** | info / debug / warn / error | مثل منوی Logs |
| **Raw JSON** | کل `/etc/gost/config.json` را ببین | وقتی می‌خواهی دقیق ببینی اسکریپت چه نوشته |

اگر چیزی را در Advanced اشتباه ست کنی، ممکن است تونل «کار کند ولی کند/قطع» به نظر برسد؛ Limiter اولین مظنون است.

---

## Service — منو `6`

همان کنترل systemd برای واحد `gost.service`:

- Start  
- Stop  
- Restart  
- Status  

معادل تقریبی:

```bash
systemctl status gost
systemctl restart gost
```

---

## Logs — منو `7`

- دنبال کردن لاگ زنده  
- فیلتر خطا  
- خروجی به فایل  
- validate کردن کانفیگ  
- تغییر سطح لاگ  

---

## Remove — منو `4`

یک سرویس را از کانفیگ حذف می‌کند. اگر chain فقط مال همان سرویس باشد، ممکن است chain هم پاک شود.

بقیهٔ سرویس‌ها و باینری می‌مانند.

---

## Uninstall — منو `9`

پاکسازی کامل‌تر Wild GOST از سرور.

### به‌طور پیش‌فرض حذف می‌شود

| مورد | مسیر/نشانه |
|:---|:---|
| باینری و دستور منو | `gost` · `wild` · `gost-manage.sh` |
| کانفیگ و state | کل `/etc/gost` |
| decoy | `/var/www/wild-gost-decoy` |
| سایت‌های nginx اسکریپت | `wild-gost-*.conf` |
| هوک‌های certbot | `wild-gost-reload.sh` · `wild-gost-sync-certs.sh` |
| فایل‌های موقت بیلد | `/tmp/gost-masque-fixed` · `/tmp/gost-build` · `/tmp/x-build` و مشابه |

### سؤال‌های اختیاری هنگام Uninstall

| سؤال | پیش‌فرض | توضیح |
|:---|:---|:---|
| پاک کردن گواهی Let's Encrypt؟ | معمولاً No | فقط دامنه‌هایی که اسکریپت به‌عنوان Wild GOST تشخیص دهد، نه هر cert روی سرور |
| پاک کردن `/usr/local/go`؟ | معمولاً No | فقط اگر با مارکر `.installed-by-wild-gost` نصب شده باشد |

پکیج‌های سیستم مثل خود `nginx` و `certbot` را حذف نمی‌کند، چون ممکن است جای دیگر استفاده شوند.

### بعد از Uninstall

منو بسته می‌شود (`exit`) چون خود اسکریپت از PATH پاک شده. برای نصب دوباره از دستور curl اول README استفاده کن.
