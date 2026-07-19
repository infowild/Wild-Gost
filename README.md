# 🚀 Wild GOST (GO Simple Tunnel Manager)

[English Guide](#-english-guide) | [راهنمای فارسی](#-راهنمای-فارسی-persian-guide)

---

## 🇮🇷 راهنمای فارسی (Persian Guide)

پروژه **Wild GOST** یک بسته‌ی بهینه‌سازی‌شده از سرویس محبوب **GOST v3** (یک تونل امنیتی ساده و همه‌کاره نوشته شده در Go) است که به یک اسکریپت نصب آسان و پنل مدیریت تعاملی (منوی رنگی لینوکس) مجهز شده است. با استفاده از این ابزار می‌توانید انواع تونل‌های پروکسی را بدون نیاز به ویرایش دستی فایل‌های تنظیمات، راه‌اندازی و مدیریت کنید.

### ویژگی‌های اسکریپت مدیریت:
- **نصب و بروزرسانی آسان:** شناسایی خودکار معماری سخت‌افزار سرور و دانلود آخرین نسخه رسمی پایدار GOST از گیت‌هاب.
- **یکپارچه‌سازی با سیستم (Systemd):** اجرای خودکار در پس‌زمینه به عنوان سرویس سیستمی و مدیریت چرخه حیات (شروع، توقف، ریستارت و لاگ‌ها).
- **منوی تعاملی افزودن/حذف تونل:** پشتیبانی از پروتکل‌های ورودی **SOCKS5**، **HTTP**، **Relay Server**، **TCP/UDP Port Forwarding** و **Shadowsocks (SS)**.
- **پشتیبانی از زنجیره پروکسی (Upstream Chain):** امکان هدایت اتصالات از میان یک پروکسی بالادستی دیگر به صورت زنجیره‌ای.
- **دسترسی سریع:** امکان باز کردن پنل در هر زمان با زدن دستور اختصاصی `wild gost`.

### ⚡ دستور نصب آسان (Easy Install Command)
برای نصب فوری و راه‌اندازی پنل روی سرور خام لینوکس (توزیع‌های Ubuntu, Debian, CentOS)، دستور زیر را کپی و در ترمینال اجرا کنید:
```bash
curl -fsSL https://raw.githubusercontent.com/infowild338/wild-gost/master/gost.sh -o gost.sh && chmod +x gost.sh && ./gost.sh
```

### نحوه استفاده پس از نصب:
پس از اجرای نصب از طریق گزینه اول منو، فایل‌های مورد نیاز سیستم کپی شده و دستور ثبت می‌شود. از این پس در هر زمان به راحتی با دستور زیر پنل مدیریت را باز کنید:
```bash
sudo wild gost
```

---

## 🇬🇧 English Guide

**Wild GOST** is an optimized distribution of **GOST v3** (GO Simple Tunnel written in Go) equipped with a robust, interactive bash management script for Linux servers. It allows you to easily deploy and manage tunnel endpoints without manually writing JSON/YAML configurations.

### Management Script Features:
- **Auto Install & Update:** Dynamically detects your CPU architecture and downloads the latest stable GOST release.
- **Systemd Service Integration:** Configures a system daemon to run GOST in the background and ensure persistent run-time.
- **Interactive Tunnel Configuration:** Easily add or remove listener endpoints supporting **SOCKS5**, **HTTP**, **Relay**, **TCP/UDP Port Forwarding**, and **Shadowsocks (SS)**.
- **Upstream Forwarding Chains:** Connect tunnels in a forwarding chain using upstream proxy hops.
- **Global Shortcut:** Installs a command shortcut so you can open the console anywhere using the `wild gost` command.

### ⚡ Easy Install Command
To quickly install and launch the script on any Linux server, run the following command:
```bash
curl -fsSL https://raw.githubusercontent.com/infowild338/wild-gost/master/gost.sh -o gost.sh && chmod +x gost.sh && ./gost.sh
```

### How to Use:
After executing the installation (Option 1 in the menu), the script and wrappers will be deployed. You can then open the tunnel management interface at any time by running:
```bash
sudo wild gost
```
