# Edit · Logs · debug

| Task | Menu |
|:---|:---|
| Edit | `3` |
| Remove one | `4` |
| List | `5` |
| Service | `6` |
| Logs / Debug | `7` |
| Advanced | `8` |
| Uninstall | `9` |

Edit / Advanced / Uninstall detail: [13](13-edit-advanced.md)

## Checklist

| # | Check |
|:---:|:---|
| 1 | Service in List |
| 2 | `systemctl is-active gost` |
| 3 | Firewall TCP/UDP correct |
| 4 | B up before A |
| 5 | Matching transport / path / connector |
| 6 | Client → A's port (not panel on B) |
| 7 | Logs: `dial` · `timeout` · `auth` · `270` |

Temp debug: `7` → Debug → reproduce → back to Info.
