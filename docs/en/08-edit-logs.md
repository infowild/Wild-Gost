# Edit, logs, remove, debugging

| Task | Menu |
|:---|:---|
| Edit service / chain / target | `3` Edit |
| List | `5` List |
| Start/Stop/Restart | `6` Service |
| Live logs / errors / Debug | `7` Logs |
| Limiter / API / JSON | `8` Advanced |
| Remove one service | `4` Remove |
| Wipe installation | `9` Uninstall |

## Quick checklist when it does not connect

1. Service visible in List?  
2. `systemctl is-active gost` = active?  
3. Firewall open (correct TCP vs UDP)?  
4. Two-server: is B up first?  
5. Matching transport / path / connector?  
6. Client hits **A's** port, not B's panel port?  
7. Logs show `dial` / `timeout` / `auth` / `270`?  

Temporary debug: menu `7` → Debug → reproduce → set Info again.
