# Proxy · Forward · Reverse

## Proxy — `2 → 5`

Listen روی همین هاست. انواع: [14](14-proxy-types.md)

```text
socks5://IP:1080
http://IP:8080
```

MASQUE → listener اجباری `http3`.

## Local forward — `2 → 6`

```text
:8080 → 192.168.1.10:80
```

فقط جابه‌جایی پورت؛ تونل بین‌الملل نیست.

## Reverse — `2 → 7`

tunnel / rtcp / rudp برای پشت NAT.

ضد فیلتر ایران → **Anti-Filter** (`2 → 1`).
