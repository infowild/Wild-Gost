# انواع Proxy (منوی Add → Proxy)

مسیر: `2 → 5`

همه روی **همین سرور** listen می‌کنند (مگر chain بالادستی جدا بسازی).

| # | نوع | کاربرد ساده |
|:---:|:---|:---|
| 1 | **SOCKS5** | پروکسی همه‌کاره؛ UDP/BIND اختیاری |
| 2 | **SOCKS4** | نسخه قدیمی‌تر SOCKS |
| 3 | **HTTP** | پروکسی HTTP؛ UDP-over-TCP اختیاری |
| 4 | **HTTP2** | HTTP روی HTTP/2 |
| 5 | **HTTP3** | HTTP روی HTTP/3 |
| 6 | **Relay** | رله GOST (معمولاً برای تونل دو سرور هم استفاده می‌شود) |
| 7 | **Shadowsocks** | SS با method + password |
| 8 | **Auto** | تشخیص خودکار پروتکل ورودی |
| 9 | **SNI** | مسیریابی بر اساس SNI |
| 10 | **SSHD** | شبیه SSHD |
| 11 | **MASQUE** | پروکسی MASQUE؛ listener اجباری **http3** |
| 12 | **Serial** | سریال / خاص |

بعد از انتخاب نوع، پورت و معمولاً **listener transport** را می‌پرسی (جز MASQUE که http3 ثابت است).

### مثال اتصال کلاینت

```text
socks5://SERVER:1080
http://SERVER:8080
```

برای تونل دو سرور معمولاً به‌جای Proxy از **Upstream + Entry** استفاده کن؛ Proxy بیشتر برای «همین یک سرور» است.
