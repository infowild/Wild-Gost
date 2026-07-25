# Edit، لاگ، حذف، عیب‌یابی

| کار | منو |
|:---|:---|
| ویرایش سرویس / chain / target | `3` Edit |
| لیست | `5` List |
| Start/Stop/Restart | `6` Service |
| لاگ زنده / خطا / Debug | `7` Logs |
| Limiter / API / JSON | `8` Advanced |
| حذف یک سرویس | `4` Remove |
| پاک کردن کل نصب | `9` Uninstall |

## چک‌لیست سریع وقتی وصل نمی‌شود

1. سرویس در List هست؟  
2. `systemctl is-active gost` = active؟  
3. فایروال پورت را باز کرده؟ (TCP یا UDP درست؟)  
4. روی تونل دو سرور: اول B بالا است؟  
5. Transport / path / نوع connector یکی است؟  
6. کلاینت به پورت **A** وصل است نه پورت سنایی روی B؟  
7. لاگ: `dial` / `timeout` / `auth` / `270`؟  

Debug موقت: منو `7` → سطح Debug → مشکل را تکرار کن → برگردان Info.
