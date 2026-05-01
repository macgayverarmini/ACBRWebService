import os
import re
import json

TARGET_DIR = r"c:\Users\macga\Documents\issabel_auditoria"

VULN_PATTERNS = [
    # Command injection where variable is concatenated without escapeshellarg
    (r"\b(system|exec|shell_exec|passthru|popen|proc_open)\s*\(\s*.*?\$[a-zA-Z_0-9].*?\)", "Potential Command Injection"),
    # Unsafe eval
    (r"\beval\s*\(\s*.*?\$[a-zA-Z_0-9].*?\)", "Potential Eval Injection"),
    # Unescaped SQL
    (r"\b(mysql_query|pg_query|->query|->exec)\s*\(\s*[\"\'].*?\$_(GET|POST|REQUEST)", "Potential SQL Injection directly from Input"),
    # Path traversal with include/require
    (r"\b(include|require|include_once|require_once)\s*\(\s*.*?\$_(GET|POST|REQUEST)", "Potential Local File Inclusion (LFI)")
]

results = []

def scan_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            # Basic suppression of escapeshellarg/escapeshellcmd cases
            for pattern, desc in VULN_PATTERNS:
                matches = re.finditer(pattern, content, re.IGNORECASE)
                for match in matches:
                    text = match.group(0)
                    if "escapeshellarg" in text or "escapeshellcmd" in text:
                        continue
                    
                    # For command injection, check if it's taking direct GET/POST
                    if desc == "Potential Command Injection" and not ("$_GET" in text or "$_POST" in text or "$_REQUEST" in text):
                        # skip if we only want ones with direct input, but let's just log and filter
                        pass
                    
                    results.append({
                        "file": filepath,
                        "vulnerability": desc,
                        "match": text.strip()
                    })
    except Exception as e:
        pass

for root, _, files in os.walk(TARGET_DIR):
    for f in files:
        if f.endswith('.php') or f.endswith('.sh') or f.endswith('.cgi') or f.endswith('.pl'):
            # Ignore some known noisy folders
            if 'vendor' in root or 'node_modules' in root:
                continue
            scan_file(os.path.join(root, f))

# Further filter the command injection to those that likely contain variables from request
filtered_results = []
for r in results:
    if r['vulnerability'] == 'Potential Command Injection':
       # we only care if the snippet contains variable interpolation like $var or {$_POST ...}
       if "$" not in r["match"]:
           continue
       # We'll output all potentials, but they could be too many.
       # Let's write to a file to analyze
    filtered_results.append(r)

with open(r"c:\NFMonitor\src\scan_results.json", "w") as f:
    json.dump(filtered_results, f, indent=2)

print(f"Found {len(filtered_results)} potential vulnerabilities.")
