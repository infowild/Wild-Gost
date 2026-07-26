# Entry چند پورت / چند لوکیشن

منو: `2 → 4) Entry multi-port / multi-location`

وقتی روی ایران چند پورت می‌خواهی، یا چند Server B (مثلاً US و DE) داری.

## چه می‌پرسد؟

1. **نام گروه** کانفیگ  
2. **TCP یا UDP**  
3. **Connector** (relay / socks5 / http) — اگر transport را MASQUE بگیری، connector اجباری masque می‌شود  
4. **Transport preset** (MWSS، MASQUE، …)  
5. **Locations:** برای هر Server B یک نام + `IP:port`  
6. **Ports:** لیست با ویرگول، مثل `8080,8443`  
7. **Target:**  
   - `127.0.0.1:PORT` (پورت listen = پورت هدف روی B)  
   - یا یک target ثابت برای همه  
8. **Mode:**

### حالت ۱ — port per location

هر لوکیشن پورت listen جدا می‌گیرد:

```text
listen = PORT + (index × offset)
مثال offset=10000 و پورت پایه 8080:
  US → :8080
  DE → :18080
```

### حالت ۲ — shared + selector

یک (یا چند) پورت مشترک؛ بین لوکیشن‌ها با استراتژی انتخاب:

| استراتژی | معنی ساده |
|:---|:---|
| **fifo** | اولی تا خراب نشود |
| **round** | نوبتی |
| **rand** | تصادفی |

## نکات

- اول همه Upstreamهای B را بساز  
- Transport همه نودها یکی باشد  
- در List هر سرویس listen و upstream را چک کن  
