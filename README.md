# Nipe (macOS Silicon Edition)
> **The Invisible Shield: Advanced Tor Network & Security Gateway for macOS (M1/M2/M3)**

Nipe is a security-hardened tool that routes **100% of your system traffic** through the Tor network. Unlike the Tor Browser (which shields only web browsing), Nipe secures your entire operating system, including background apps, updates, and terminal sessions.

**Version**: 0.0.8-hardened
**Architecture**: macOS ARM64 (Silicon)

---

## 🔒 Security Features (God Mode)

Nipe provides a defense-in-depth architecture superior to standard VPNs:

1.  **Kill Switch (Zero-Leak Policy)**
    - Uses macOS Packet Filter (`pfctl`) to strictly **BLOCK** all direct non-Tor traffic. If Tor fails, your internet is cut instantly. No IP leaks ever.

2.  **Stream Isolation (Anti-Correlation)**
    - Configures Tor to use **different anonymous circuits** for every unique destination.
    - *Example*: Browsing `Facebook` and `Google` simultaneously uses two completely different IP addresses, neutralizing correlation attacks.

3.  **Ghost Mode (Automated Rotation)**
    - **Physical Layer**: Automatically sanitizes your Hostname (e.g., to "Printer" or "iPad") on startup.
    - **Network Layer**: Automatically rotates your IP address identity every **60 seconds**.

---

## 🚀 Installation & Usage

### 1. Start Nipe
Activate the shield. This enables the Proxy, Kill Switch, and Ghost Mode.
```bash
sudo perl nipe.pl start
```

### 2. Verify Security
Check if you are anonymous.
```bash
sudo perl nipe.pl status
```

### 3. Spy Dashboard (Real-Time Monitor)
View your live status, current identity, and spoofing details in a hacker-style dashboard.
```bash
sudo perl nipe.pl monitor
```

### 4. Stop Nipe
Disable the shield and return to direct internet connection.
```bash
sudo perl nipe.pl stop
```

### 5. Manual Rotation (Optional)
If you need to change your IP *immediately* without waiting for the 60s auto-timer:
```bash
sudo perl nipe.pl rotate
```

---

## ✅ Compatibility Note (Apple Silicon)
*   **MAC Address Spoofing**: Modern Macs (M1/M2/M3) have a hardware lock on the Wi-Fi card's MAC address. Nipe attempts to spoof this Best-Effort but will likely be rejected by the hardware.
*   **Protection**: Your physical identity is protected via **Hostname Sanitization**, which Nipe strictly enforces.

---

## 📜 Technical Verification
To audit the security yourself:
*   **Kill Switch**: Try `curl ifconfig.me` while Nipe is running. It will timeout (blocked).
*   **Tor Check**: Try `curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip`. It will succeed (proxied).

---
*Maintained by Antigravity Agent*