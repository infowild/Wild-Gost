# Anti-Filter

نود خارج به ایران dial می‌کند. کلاینت فقط دامنه/IP ایران را می‌بیند.

```text
Client ──SNI──► Iran :443
Exit ──tunnel──► Iran :control → 127.0.0.1:panel@Exit
```

| گام | کجا | مسیر |
|:---:|:---|:---|
| 1 | ایران | `2 → 1 → 1` Iran panel |
| 2 | خارج | `2 → 1 → 3` Foreign node (همان Tunnel ID) |
| 3 | اختیاری | `2 → 1 → 2` نود بیشتر |

| قانون | جزئیات |
|:---|:---|
| مسیریابی | Host / SNI — نه path |
| Transport | دو طرف یکسان (پیش‌فرض MWSS) |
| Decoy | معمولاً `:80` |
| State | `/etc/gost/wild-antifilter.json` |
| VLESS خام | بدون TLS به entrypoint مناسب نیست |

Doctor: `2 → 1 → 6` · جزئیات: [12](12-antifilter-extras.md)
