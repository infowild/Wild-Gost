# Transportها (ضد-DPI و اتصال)

در ویزارد دو سرور / Anti-Filter معمولاً این preset را می‌بینی:

| # | نام | لایه ساده | توصیه |
|:---:|:---|:---|:---|
| 1 | **MWSS** | TLS + WebSocket + multiplex | پیشنهادی عمومی |
| 2 | WSS | TLS + WebSocket | خوب |
| 3 | TLS | مثل HTTPS | خوب |
| 4 | uTLS | TLS با اثر انگشت کلاینت جعلی | قوی‌تر در برابر fingerprint |
| 5 | otls | obfs-TLS | استتار |
| 6 | KCP | UDP + FEC | لینک پرلاس |
| 7 | QUIC | UDP/QUIC | شبیه HTTP3 |
| 8 | gRPC | روی TLS | جایگزین WS |
| 9 | TCP | بدون رمز | فقط تست |
| 10 | Advanced | listener و dialer جدا | کاربران پیشرفته |
| 11 | **MASQUE** | HTTP/3 + masque | تونل HTTP3؛ listener=`http3` |

## قانون طلایی

- **دو طرف تونل باید یک transport داشته باشند**  
- برای WS/WSS/MWSS مقدار **path** (مثل `/ws`) دو طرف یکی باشد  
- SNI / Host اگر گذاشتی، با دامنه/گواهی هم‌خوان باشد  

## Listener در مقابل Dialer

| نقش | کجا |
|:---|:---|
| **Listener** | سمتی که گوش می‌دهد (مثلاً Upstream روی B) |
| **Dialer** | سمتی که وصل می‌شود (مثلاً Entry روی A) |

در MASQUE:

- B listener = **`http3`** (نه `h3`)  
- A dialer = **`h3-masque`** + connector **`masque`**  

گزینه Advanced همه‌ی انواع listener/dialer اسکریپت (tcp، ws، kcp، ssh، icmp، …) را نشان می‌دهد؛ فقط وقتی می‌دانی چه می‌کنی استفاده کن.
