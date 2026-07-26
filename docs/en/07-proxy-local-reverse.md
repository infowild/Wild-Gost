# Proxy · Forward · Reverse

## Proxy — `2 → 5`

Listen on this host. Types: [14](14-proxy-types.md)

```text
socks5://IP:1080
http://IP:8080
```

MASQUE → listener forced `http3`.

## Local forward — `2 → 6`

```text
:8080 → 192.168.1.10:80
```

Port remap only; not an international tunnel.

## Reverse — `2 → 7`

tunnel / rtcp / rudp for NAT peers.

Iran censorship → **Anti-Filter** (`2 → 1`).
