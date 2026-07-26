# Multi-entry

مسیر: `2 → 4`

چند listen روی A، یا چند Server B.

| فیلد | مقدار |
|:---|:---|
| Proto | TCP / UDP |
| Connector | relay / socks5 / http — با MASQUE → اجباری `masque` |
| Transport | preset مشترک همه نودها |
| Locations | نام + `IP:port` هر B |
| Ports | مثلاً `8080,8443` |
| Target | `127.0.0.1:PORT` یا یک آدرس ثابت |

## Mode

| Mode | رفتار |
|:---|:---|
| Port per location | `listen = PORT + index×offset` — مثال offset `10000`: US `:8080` · DE `:18080` |
| Shared + selector | پورت مشترک · `fifo` / `round` / `rand` |

اول همه Upstreamهای B · transport یکسان · در List هر listen/upstream را چک کن.
