#!/bin/bash

TARGET=$1
SCAN_TYPE=$2
OUTFILE="your_output_file_here" # Replace with your desired output file path, e.g., "/home/logs/strike_output.txt"
KALI_IP="your_kali_ip_here" # Replace with your KALI IP
KALI_USER="your_kali_user_here" # Replace with your KALI username
SSH_CMD="ssh -o BatchMode=yes -o StrictHostKeyChecking=no $KALI_USER@$KALI_IP"

# === THE INTELLIGENCE KEYS ===
SHODAN_KEY="your_shodan_key_here" # Replace with your actual Shodan API key
VT_KEY="your_vt_key_here" # Replace with your actual VirusTotal API key
ABUSE_KEY="your_abuse_key_here" # Replace with your actual AbuseIPDB API key
GREYNOISE_KEY="your_greynoise_key_here" # Replace with your actual GreyNoise API key


if [ -z "$TARGET" ] || [ -z "$SCAN_TYPE" ]; then
    echo "[-] Error: Missing parameters."
    exit 1
fi

# Clear the old log file
> $OUTFILE

echo "TARGET: $TARGET" >> $OUTFILE
echo "SCAN TYPE: $SCAN_TYPE" >> $OUTFILE

if [ "$SCAN_TYPE" == "ip" ]; then
    echo "[+] Mode: IP INFRASTRUCTURE & THREAT INTEL"
    
    echo "=== IP INTELLIGENCE (GEOLOCATION & ASN) ===" >> $OUTFILE
    $SSH_CMD "curl -s https://ipinfo.io/$TARGET/json" >> $OUTFILE

    echo -e "\n=== SHODAN VULNERABILITY DATABASE ===" >> $OUTFILE
    $SSH_CMD "curl -s 'https://api.shodan.io/shodan/host/$TARGET?key=$SHODAN_KEY' | python3 -c \"
import sys, json
try:
    data = json.load(sys.stdin)
     ports = data.get('ports', 'None')
    vulns = data.get('vulns', 'None detected by Shodan')
    hosts = data.get('hostnames', 'None')
    print(f'Known Open Ports: {ports}')
    print(f'Known Vulnerabilities (CVEs): {vulns}')
    print(f'Hostnames: {hosts}')
except Exception as e:
    print('[-] Target not found in Shodan database.')
\"" >> $OUTFILE
    
    echo -e "\n=== GREYNOISE BACKGROUND NOISE (PROFILER) ===" >> $OUTFILE
    $SSH_CMD "curl -s -H 'Accept: application/json' -H 'key: $GREYNOISE_KEY' https://api.greynoise.io/v3/community/$TARGET | python3 -c \"
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('message') == 'Success':
        cls = data.get('classification', 'Unknown').upper()
        actor = data.get('name', 'Unknown')
        noise = data.get('noise', False)
        riot = data.get('riot', False)
        print(f'Classification: {cls}')
        print(f'Actor Name: {actor}')
        print(f'Is Mass-Scanner (Noise): {noise}')
        print(f'Is Benign Corporate Service (RIOT): {riot}')
    else:
        print('[-] Target not found in GreyNoise dataset.')
except Exception as e:
    print('[-] Error parsing GreyNoise data.')
\"" >> $OUTFILE

    echo -e "\n=== THREATFOX (MALWARE & BOTNET IOCs) ===" >> $OUTFILE
    $SSH_CMD "curl -s -X POST https://threatfox-api.abuse.ch/api/v1/ -d '{\\\"query\\\": \\\"search_ioc\\\", \\\"search_term\\\": \\\"$TARGET\\\"}' | python3 -c \"
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('query_status') == 'ok':
        print('[!] CRITICAL WARNING: Target is a known active threat.')
         malware = data['data'][0].get('malware_printable', 'Unknown Malware Payload')
        print(f'Identified Payload/Botnet: {malware}')
    else:
        print('[+] Target is clear of known ThreatFox botnet IOCs.')
except Exception as e:
    print('[-] Error parsing ThreatFox data.')
\"" >> $OUTFILE

    echo -e "\n=== VIRUSTOTAL REPUTATION ===" >> $OUTFILE
    $SSH_CMD "curl -s --request GET --url https://www.virustotal.com/api/v3/ip_addresses/$TARGET --header 'x-apikey: $VT_KEY' | python3 -c \"
import sys, json
try:
    data = json.load(sys.stdin)
    stats = data['data']['attributes']['last_analysis_stats']
    mal = stats.get('malicious', 0)
    sus = stats.get('suspicious', 0)
    print(f'Malicious Flags: {mal}')
    print(f'Suspicious Flags: {sus}')
except Exception as e:
    print('[-] Error parsing VirusTotal data.')
\"" >> $OUTFILE

    echo -e "\n=== ABUSEIPDB THREAT SCORE ===" >> $OUTFILE
    $SSH_CMD "curl -s -G https://api.abuseipdb.com/api/v2/check --data-urlencode 'ipAddress=$TARGET' -d maxAgeInDays=90 -H 'Key: $ABUSE_KEY' -H 'Accept: application/json' | python3 -c \"
import sys, json
try:
    data = json.load(sys.stdin)['data']
    score = data.get('abuseConfidenceScore', 0)
    reports = data.get('totalReports', 0)
    print(f'Abuse Confidence Score: {score}%')
    print(f'Total Recent Reports: {reports}')
except Exception as e:
    print('[-] Error parsing AbuseIPDB data.')
\"" >> $OUTFILE

    echo -e "\n=== WHOIS REGISTRATION (OWNER PROFILE) ===" >> $OUTFILE
    $SSH_CMD "whois $TARGET | grep -iE 'OrgName|NetName|owner' | head -n 2" >> $OUTFILE

    echo -e "\n=== NMAP HARDWARE PROFILER ===" >> $OUTFILE
    # Removed sudo to prevent password hangs entirely for headless mode
    $SSH_CMD "nmap -F -sV $TARGET 2>/dev/null" >> $OUTFILE

elif [ "$SCAN_TYPE" == "domain" ]; then
    echo "[+] Mode: PUBLIC DOMAIN"
    
    echo "=== NMAP FAST SCAN ===" >> $OUTFILE
    $SSH_CMD "nmap -F -sV $TARGET 2>/dev/null" >> $OUTFILE
    
    echo -e "\n=== WAFW00F (FIREWALL DETECTION) ===" >> $OUTFILE
    $SSH_CMD "wafw00f $TARGET" >> $OUTFILE
    
    echo -e "\n=== DNSRECON (STANDARD) ===" >> $OUTFILE
    $SSH_CMD "dnsrecon -d $TARGET -t std" >> $OUTFILE
fi

# Feed the aggregated multi-tool log to the AI
/your/path/to/ai-recon.sh $OUTFILE