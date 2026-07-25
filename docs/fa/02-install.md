# نصب و به‌روزرسانی

روی هر سرور یک‌بار:

```bash
sudo wild gost
# 1) Install / Update
```

## کانال‌های Install

| گزینه | چه چیزی نصب می‌شود؟ | کی استفاده کنیم؟ |
|:---|:---|:---|
| **1 Stable** | آخرین نسخه پایدار GitHub | استفاده عادی بدون MASQUE |
| **2 Nightly** | نسخه شبانه (masque ثبت شده) | تست MASQUE؛ TCP CONNECT ممکن است باگ داشته باشد |
| **3 Build patched** | از سورس + پچ MASQUE TCP | **پیشنهادی برای تونل MASQUE** (نیاز به دانلود Go) |
| **4 Local binary** | فایل آماده روی دیسک | وقتی روی ایران `go.dev` بسته است: باینری را از سرور خارج `scp` کن |

## سرور ایران

اگر گزینه ۳ در دانلود Go شکست خورد:

1. روی سرور **خارج** گزینه ۳ را بزن  
2. باینری را بفرست:

```bash
scp /usr/local/bin/gost root@IP_ایران:/tmp/gost-masque-fixed
```

3. روی ایران: Install → **4** → مسیر `/tmp/gost-masque-fixed`

در حالت Iran، اسکریپت برای GitHub از mirror استفاده می‌کند.

## هشدار

Update با گزینه ۱ (stable) باینری پچ‌شده MASQUE را عوض می‌کند و تونل MASQUE ممکن است بشکند.
