# Proxy, local forward, reverse

## Single-server proxy — `2 → 5`

Create SOCKS5 / HTTP / Shadowsocks / Relay / MASQUE on this host.

```text
socks5://IP:1080
http://IP:8080
```

Choosing MASQUE forces listener **http3**.

## Local port forward — `2 → 6`

```text
listen :8080  -->  192.168.1.10:80
```

Port mapping only — not an international tunnel.

## Generic reverse — `2 → 7`

For NAT devices that dial a public server.

For Iran censorship prefer **Anti-Filter** (`2 → 1`).
