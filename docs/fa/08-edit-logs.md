# Edit · Logs · عیب‌یابی

| کار | منو |
|:---|:---|
| ویرایش | `3` |
| حذف یک سرویس | `4` |
| فهرست | `5` |
| Service | `6` |
| Logs / Debug | `7` |
| Advanced | `8` |
| Uninstall | `9` |

جزئیات Edit / Advanced / Uninstall: [13](13-edit-advanced.md)

## چک‌لیست قطعی

| # | چک |
|:---:|:---|
| 1 | سرویس در List |
| 2 | `systemctl is-active gost` |
| 3 | فایروال TCP/UDP درست |
| 4 | B قبل از A بالا است |
| 5 | transport / path / connector یکسان |
| 6 | کلاینت → پورت A (نه پنل روی B) |
| 7 | لاگ: `dial` · `timeout` · `auth` · `270` |

Debug موقت: `7` → Debug → تست → برگردان Info.
