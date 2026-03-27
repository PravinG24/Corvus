# Corvus
# AI-Augmented Mobile Reconnaissance & C2 Framework

**Pocket-Sized Threat Intelligence. Powered by Tailscale, NVIDIA NIM, and Python.**
---

### ⚠️ LEGAL DISCLAIMER
**This framework was engineered strictly for educational purposes, homelab research, and authorized Red Team engagements.** The author is not responsible for any misuse, unauthorized access, or damage caused by this tool. Never point this infrastructure at a target you do not own or have explicit, written permission to test.

---

## 📖 Overview
**Corvus** is a stealthy, mobile-first Command and Control (C2) and OSINT automation framework. Built to run on headless homelab hardware, it completely decouples the operator from their laptop. 

By routing a Python/Flask orchestrator through an encrypted Tailscale WireGuard mesh, an operator can execute multi-vector reconnaissance strikes directly from a Progressive Web App (PWA) on their smartphone over a 5G network. To eliminate the bottleneck of manual data correlation, the framework pipes asynchronous API telemetry into the **NVIDIA NIM API (Step Flash 3.5)**, utilizing strict prompt engineering to instantly generate formatted, actionable Target Dossiers.

## 🏗️ Architecture & Execution Flow
The infrastructure operates across four primary layers without exposing any inbound ports to the public internet:

`Mobile PWA ➔ 5G Network ➔ Tailscale Mesh (100.x.x.x) ➔ Flask Listener ➔ Bash Subprocess ➔ OSINT APIs ➔ NVIDIA NIM ➔ Target Dossier`

### Core Capabilities:
* **True Stealth (Zero-Config VPN):** The C2 server strictly binds to the Tailscale IP, rendering it invisible to Shodan and local network scanners.
* **Active & Passive Telemetry:** Orchestrates concurrent data pulls from Nmap, Shodan, ThreatFox, VirusTotal, AbuseIPDB, and GreyNoise (filtering out internet background noise).
* **High-Speed AI Synthesis:** Leverages the low-latency NVIDIA NIM API to bypass standard LLM conversational guardrails, formatting raw JSON into an operational intelligence feed in milliseconds.
* **Passwordless Lateral Execution:** Utilizes Ed25519 cryptographic keys to execute bash scripts across internal VMs without hanging on SSH password prompts.
* **Mobile-First Field Console:** A standalone, retro-terminal PWA interface designed for discreet physical red-teaming engagements.

---

## ⚙️ Prerequisites
To deploy this framework, you need:
1. A Linux host (Ubuntu/Debian/Kali) to act as the C2 listener.
2. A free [Tailscale](https://tailscale.com/) account.
3. API Keys for your threat intelligence stack (Shodan, GreyNoise, VirusTotal, ThreatFox).
4. An **NVIDIA NIM API Key** (for the Step Flash 3.5 model).

---

##  Installation & Deployment

### 1. Clone the Repository
git clone [https://github.com/YourUsername/Pierce-C2.git](https://github.com/YourUsername/Pierce-C2.git)
cd Pierce-C2

### 2. Configure Operational Security (API Keys)
mv .env.example .env
nano .env

### Insert your keys:
SHODAN_API_KEY="your_key_here"
GREYNOISE_API_KEY="your_key_here"
NVIDIA_NIM_KEY="your_key_here"
# ...

### 3. Establish the Mesh Network
curl -fsSL [https://tailscale.com/install.sh](https://tailscale.com/install.sh) | sh
sudo tailscale up

### 4. Boot the Listener
pip install -r requirements.txt
python3 app.py

###5. Setup the Mobile Device
 a) Install Tailscale on your iOS/Android device and connect to your Tailnet.

 b) Turn off WiFi (switch to 5G/LTE).

 c) Open your mobile browser and navigate to http://100.x.x.x:5000.

 d) "Add to Home Screen" to install the standalone Field Console PWA.



Technical Challenges Solved
- Resolved a critical pipeline decoupling issue by meticulously realigning the JavaScript fetch() API endpoints and JSON dictionary keys with the Flask backend's extraction logic
- Successfully isolated and ignored benign HTTP "Ghost" errors (e.g., automated browser favicon requests) during headless SSH debugging to identify the true HTTP 200 success codes of the C2 payload execution.
- Strict Payload Validation: Bypassed Flask's strict JSON rejection by forging custom application/json headers in the Vanilla JS frontend.
- Invisible Bash Artifacts: Engineered a Regex scalpel (/^\s+/) within the PWA to strip invisible carriage returns (\r) injected by remote Bash execution, ensuring perfect retro-terminal text alignment.
