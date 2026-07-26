# Multi-port / multi-location Entry

## What is this menu for?

Path:

```text
2) Add  →  4) Entry multi-port / multi-location
```

Use it on Server A when you want:

- several listen ports, or  
- several Server B destinations (e.g. US and DE)

Instead of running Entry single many times, one wizard builds the group.

---

## Prerequisites

1. Every Server B already has an Upstream  
2. All of them use the same transport you will pick here  
3. For MASQUE: every B is `masque+http3` with UDP open  

---

## What the wizard asks (plain language)

### 1) Group name

A label for the set, e.g. `entry-multi`. Used in names/metadata.

### 2) TCP or UDP

For most panels: **TCP**.

### 3) Connector

| Option | When |
|:---|:---|
| relay | B Upstream is Relay / MWSS style |
| socks5 / http | B uses that handler |
| (automatic) masque | Forced if you pick MASQUE transport |

### 4) Transport preset

Same as single Entry: MWSS, TLS, MASQUE, …  
**11) MASQUE** → connector=`masque`, dialer=`h3-masque`.

### 5) Locations (Server B list)

For each location:

| Field | Example |
|:---|:---|
| Name | `US` |
| Address | `216.x.x.x:2018` |

Add as many as you need.

### 6) Ports

Comma list, for example:

```text
8080,8443
```

These are the base listen ports on A (exact mapping depends on Mode).

### 7) Target

Two common choices:

| Choice | Meaning |
|:---|:---|
| `127.0.0.1:PORT` | Target port on B follows the listen pattern |
| One fixed address | Everything goes to one target, e.g. always `127.0.0.1:8080` |

Remember: Target is as seen from **B**.

### 8) Mode — the key choice

#### Mode 1: Port per location

Each location gets its own listen port.

Simple formula:

```text
listen = base_port + (location_index × offset)
```

Example: base `8080`, offset `10000`, locations US then DE:

| Location | Listen on A |
|:---|:---|
| US (first) | `:8080` |
| DE (second) | `:18080` |

Users change country by changing the port.

#### Mode 2: Shared + selector

Shared listen port(s); pick among B nodes with a strategy:

| Strategy | Behavior |
|:---|:---|
| **fifo** | Prefer the first until it fails |
| **round** | Round-robin |
| **rand** | Random |

---

## After creation

1. Menu `5` List — check each listen and chain  
2. Test each port from a client  
3. If one location dies, check Logs  

---

## Common mistakes

| Mistake | Result |
|:---|:---|
| B has no Upstream yet | dial fail |
| One B on MWSS, another on MASQUE | incompatible |
| Forgot UDP for MASQUE | some locations die |
| Target set to entry IP | wrong destination |

Learn single-tunnel first: [05](05-remote-forward.md) or [06](06-masque.md), then build multi.
