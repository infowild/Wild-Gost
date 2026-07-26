# MASQUE

HTTP/3 / QUIC روی **UDP**.

```text
Client → A:8080 → masque+h3-masque → B:9443/udp (masque+http3) → 127.0.0.1:8080
```

## باینری

| وضعیت | کار |
|:---|:---|
| Stable قدیمی | بدون masque |
| پیشنهادی | Install → `3` روی خارج |
| ایران بدون Go | Install → `4` + فایل `scp` |

## B — `2 → 2`

Handler `4) MASQUE` · پورت مثلاً `9443` · listener اجباری **`http3`** · فایروال **UDP**.

## A — `2 → 3`

Listen `8080` TCP · Transport `11) MASQUE` · Upstream `IP_B:9443` · Target `127.0.0.1:8080`.

| غلط | درست |
|:---|:---|
| listener `h3` | **`http3`** (`h3` = PHT) |
| باینری بدون پچ | خطای H3 `270` |
| فقط TCP در فایروال | UDP لازم است |

موفقیت = لاگ `connect-tcp` روی B. جواب خالی `curl` به سنایی طبیعی است.
