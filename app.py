from flask import Flask, render_template, request, jsonify
import subprocess

app = Flask(__name__, template_folder='/path/to/folder')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/fire', methods=['POST'])
def fire():
        # 1. Safely grab the incoming JSON payload
        data = request.json or {}

        # 2. Force the extractions to be raw strings (Sanitization)
        target = str(data.get('target', '')).strip()
        scan_type = str(data.get('type', '')).strip()

        # 3. Validation check
        if not target or not scan_type:
            return jsonify({'output': '[-] Error: Target or Scan Type missing from payload.'})

        try:
            # 4. Fire the weapon (Bash only sees pure text now)
            result = subprocess.run(
                ['/home/pravin/pierce/codes/strike.sh', target, scan_type],
                capture_output=True, text=True, timeout=180
            )
            return jsonify({'output': result.stdout + result.stderr})
        except Exception as e:
            return jsonify({'output': f'[-] Critical System Failure: {str(e)}'})

if __name__ == '__main__':
    # Listen on all network interfaces on port 5000
    app.run(host='your_host_here', port="your_port_here")