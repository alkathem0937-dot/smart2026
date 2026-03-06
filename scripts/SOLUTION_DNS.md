# 🔧 حل مشكلة DNS للاتصال بـ Ollama

## المشكلة
```
Error: pull model manifest: Get "https://registry.ollama.ai/v2/library/qwen/manifests/7b-chat": 
dial tcp: lookup registry.ollama.ai: no such host
```

## الحلول

### الحل 1: إصلاح DNS (الأسهل)

**شغّل السكربت:**
```powershell
cd E:\smartjudi2\scripts
.\fix_dns.ps1
```

**أو يدوياً:**
1. افتح PowerShell كمسؤول (Run as Administrator)
2. شغّل:
```powershell
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex -ServerAddresses "8.8.8.8", "8.8.4.4"
```

### الحل 2: استخدام DNS يدوياً في hosts file

1. افتح `C:\Windows\System32\drivers\etc\hosts` كمسؤول
2. أضف:
```
104.21.0.0 registry.ollama.ai
```

### الحل 3: استخدام VPN

إذا كان هناك قيود على الشبكة، استخدم VPN.

### الحل 4: الانتظار

إذا كانت المشكلة مؤقتة، انتظر قليلاً ثم حاول مرة أخرى.

---

## بعد إصلاح DNS

```bash
# أضف Ollama إلى PATH أولاً
$env:PATH += ";$env:LOCALAPPDATA\Programs\Ollama"

# ثم حاول تحميل النموذج
ollama pull qwen:7b-chat
```

---

## إذا استمرت المشكلة

1. **تحقق من Firewall:** تأكد من أن Firewall لا يحجب Ollama
2. **تحقق من Proxy:** إذا كنت تستخدم Proxy، تأكد من إعداداته
3. **جرب شبكة أخرى:** WiFi مختلف أو Hotspot من الهاتف
4. **اتصل بالدعم:** إذا كانت المشكلة في مزود الإنترنت
