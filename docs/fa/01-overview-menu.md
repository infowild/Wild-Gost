# منو

```bash
sudo wild gost
```

| # | بخش | کار |
|:---:|:---|:---|
| 1 | Install / Update | باینری + اسکریپت |
| 2 | Add | سرویس / تونل جدید |
| 3 | Edit | ویرایش سرویس و chain |
| 4 | Remove | حذف یک سرویس |
| 5 | List | فهرست |
| 6 | Service | start / stop / restart / status |
| 7 | Logs | لاگ · خطا · debug |
| 8 | Advanced | Bypass · Admission · Limiter · API · Metrics · JSON |
| 9 | Uninstall | پاکسازی کامل |
| 0 | Exit | خروج |

## Add (`2`)

| # | گزینه | نقش |
|:---:|:---|:---|
| 1 | Anti-Filter | ریورس ایران · نود خارج dial می‌کند |
| 2 | Upstream | Server B · خروج تونل دو سرور |
| 3 | Entry single | Server A · یک listen |
| 4 | Entry multi | چند پورت / چند B |
| 5 | Proxy | SOCKS / HTTP / SS / … روی همین هاست |
| 6 | Local forward | listen → target محلی |
| 7 | Reverse | tunnel / rtcp / rudp |
| 8 | More | DNS · TUN · File · Redirect |

کانفیگ: `/etc/gost/config.json`
