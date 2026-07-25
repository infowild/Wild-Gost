# تونل دو سرور (MWSS / Relay)

سناریوی کلاسیک Remote Port Forward:

```text
کلاینت --> A:8080 --> MWSS --> B:2018 (Relay) --> 127.0.0.1:8080 (سنایی)
```

## گام ۱ — Server B (خارج)

1. `2 → 2` Upstream  
2. نام (مثلاً `us`)  
3. پورت (مثلاً `2018` یا `443`)  
4. Handler: **Relay**  
5. Transport: **MWSS** (پیشنهادی)  
6. path را یادداشت کن (پیش‌فرض `/ws`)

## گام ۲ — Server A (ایران)

1. `2 → 3` Entry single  
2. Listen = پورتی که کلاینت می‌زند (مثلاً `8080`)  
3. TCP  
4. همان transport (MWSS) + همان path  
5. Upstream = `IP_عمومی_B:پورت`  
6. Target = `127.0.0.1:8080` (سنایی روی B)

## قواعد طلایی

- اول B، بعد A  
- Transport و path دو طرف یکی  
- کلاینت به **پورت A** وصل می‌شود  
- Target روی A آدرس **از دید B** است (معمولاً لوکال روی B)  
- دامنه را چک کن؛ گاهی به سرور اشتباه resolve می‌شود — IP مطمئن‌تر است  

## Multi-port / multi-location

منو `2 → 4`: چند پورت listen یا چند Server B با selector.
