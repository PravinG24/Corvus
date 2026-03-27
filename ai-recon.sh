#!/bin/bash

# 1. Define Variables
TARGET_FILE=$1
API_KEY="your_api_key_here" # Replace with your actual API key
ENDPOINT="your_endpoint_here" # Replace with your actual API endpoint, e.g., "https://api.openai.com/v1/chat/completions"
MODEL="your_model_here" # Replace with your actual model name, e.g., "gpt-4-0613"

# 2. Safety Check
if [ -z "$TARGET_FILE" ]; then
    echo "[-] Error: No scan file provided."
    echo "Usage: $0 <path_to_scan_file>"
    exit 1
fi

# 3. Read the raw telemetry from the master trigger text file
SCAN_DATA=$(cat "$TARGET_FILE")

# 4. Define the AI Persona
INSTRUCTIONS="You are the Profiler Engine. I am providing raw network, threat, and hardware telemetry for a target IP. 
Do not write paragraphs. Output a strict, stylized profile dossier using exactly this markdown format:

**[!] TARGET PROFILE GENERATED**
* **OWNER/ENTITY:** (Extract from WHOIS or IPInfo)
* **LOCATION:** (City, Country)
* **HARDWARE/OS:** (Extract from Nmap OS guess or port banners)
* **PRIMARY ROLE:** (Guess based on ports/data e.g., 'Web Server', 'Compromised Botnet Node', 'Residential Gateway')
* **THREAT CLASSIFICATION:** (e.g., BENIGN, SUSPICIOUS, HOSTILE - based on VirusTotal/AbuseIPDB/OTX)

**[SYSTEM VULNERABILITIES]**
(List critical CVEs or dangerous open ports here in 1-2 bullet points)

**[PROFILER NOTES]**
(Write one single, brutal sentence summarizing the target's behavior or risk factor. Example: 'Target is actively brute-forcing SSH networks and belongs to a known Mirai botnet array.')

Here is the raw telemetry:"

# 5. Use Python to build a mathematically perfect JSON payload file.
# This strictly isolates Bash from JSON syntax, guaranteeing zero crashes.
python3 -c '
import sys, json
payload = {
    "model": sys.argv[1],
    "messages": [
        {"role": "system", "content": sys.argv[2]},
        {"role": "user", "content": sys.argv[3]}
    ],
    "temperature": 0.2,
    "max_tokens": 4096
}
with open("/tmp/ai_payload.json", "w") as f:
    json.dump(payload, f)
' "$MODEL" "$INSTRUCTIONS" "$SCAN_DATA"

# 6. Fire the API Request using the safe file, with a 45-second kill switch.
curl -s --max-time 90 -X POST "$ENDPOINT" \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d @"/tmp/ai_payload.json" | python3 -c '
import sys, json
try:
    raw_input = sys.stdin.read()
    data = json.loads(raw_input)
    
    # Attempt to extract ONLY the final formatted output
    content = data.get("choices", [{}])[0].get("message", {}).get("content")
    
    if content:
        # If the dossier exists, print it cleanly.
        print(content)
    else:
        # If the AI choked and returned null, print a stylized ctOS error instead of JSON.
        print("**[!] DIAGNOSTIC OVERRIDE FAILED**")
        print("* **STATUS:** TARGET SECURED OR COGNITIVE LIMIT REACHED.")
        print("* **SYSTEM NOTE:** The AI processed the telemetry but failed to generate the final dossier. This usually indicates a safety guardrail intervention or a token exhaustion event.")
