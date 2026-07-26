# انواع Proxy

مسیر: `2 → 5` — listen روی همین هاست.

| # | نوع | کار |
|:---:|:---|:---|
| 1 | SOCKS5 | همه‌کاره · UDP/BIND اختیاری |
| 2 | SOCKS4 | نسخه قدیمی |
| 3 | HTTP | پروکسی HTTP |
| 4 | HTTP2 | روی HTTP/2 |
| 5 | HTTP3 | روی HTTP/3 |
| 6 | Relay | رله GOST |
| 7 | Shadowsocks | method + password |
| 8 | Auto | تشخیص پروتکل ورودی |
| 9 | SNI | مسیریابی SNI |
| 10 | SSHD | شبیه SSHD |
| 11 | MASQUE | listener اجباری `http3` |
| 12 | Serial | سریال |

بعد از نوع: پورت + listener transport (جز MASQUE).

```text
socks5://SERVER:1080
http://SERVER:8080
```

تونل دو سرور → Upstream + Entry؛ Proxy برای تک‌هاست.
