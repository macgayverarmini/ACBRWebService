#!/bin/bash
# Quick test: check response from the CTE API by dumping directly to console
cd /home/datalider/workspace/src/resources

# Read the XML and base64 encode it
XML_B64=$(base64 -w0 cteTestData.xml)

# Create a temporary request file to avoid quoting issues
cat > /tmp/cte_request.json << JSONEOF
{
  "xml": "$XML_B64"
}
JSONEOF

# Call the API
RESP=$(curl -s -X POST http://localhost:9002/cte/cte-from-xml \
  -H 'Content-Type: application/json' \
  -d @/tmp/cte_request.json)

echo "Response length: ${#RESP}"
echo "$RESP" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if not d:
    print('EMPTY RESPONSE: {}')
    sys.exit(0)
print('Keys:', sorted(d.keys()))
for k, v in sorted(d.items()):
    if isinstance(v, dict):
        print(f'  {k}: {{...}} keys={sorted(v.keys())[:5]}')
    elif isinstance(v, list):
        print(f'  {k}: [...] len={len(v)}')
    elif isinstance(v, str) and len(v) > 80:
        print(f'  {k}: \"{v[:80]}...\"')
    else:
        print(f'  {k}: {v}')
" 2>&1
