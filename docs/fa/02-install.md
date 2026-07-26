# نصب

```bash
sudo wild gost
# 1) Install / Update
```

| # | کانال | نتیجه |
|:---:|:---|:---|
| 1 | Stable | ریلیز پایدار — بدون MASQUE قابل‌اتکا |
| 2 | Nightly | masque ثبت‌شده؛ TCP CONNECT ممکن است باگ داشته باشد |
| 3 | Build patched | سورس + پچ MASQUE — پیشنهادی برای HTTP/3 |
| 4 | Local binary | نصب از مسیر دیسک |

## ایران بدون Go

1. روی خارج: Install → `3`  
2. `scp /usr/local/bin/gost root@IRAN:/tmp/gost-masque-fixed`  
3. روی ایران: Install → `4` → `/tmp/gost-masque-fixed`

حالت Iran برای GitHub از mirror استفاده می‌کند.

**هشدار:** Update با `1` (Stable) باینری پچ‌شده را عوض می‌کند → MASQUE می‌شکند.
