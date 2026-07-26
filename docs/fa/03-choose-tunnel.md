# انتخاب تونل

| نیاز | مسیر | نقش |
|:---|:---|:---|
| فیلتر · IP خارج پنهان | `2 → 1` Anti-Filter | نود خارج → ایران |
| کلاینت → ایران · خروج از خارج | `2 → 2` سپس `2 → 3` | B Upstream · A Entry |
| همان روی HTTP/3 | MASQUE (transport `11`) | `masque`+`http3` / `h3-masque` |
| چند پورت / چند کشور | `2 → 4` | Multi-entry |
| SOCKS/HTTP تک‌سرور | `2 → 5` | Proxy |
| جابه‌جایی پورت | `2 → 6` | Local forward |

```text
Client → A (Entry) → tunnel → B (Upstream) → target
```

اول **B**، بعد **A**.
