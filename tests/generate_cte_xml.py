import base64
import json
import requests
import os

# Configuration
API_URL = "http://localhost:9001"
RESOURCE_FILE = r"c:\NFMonitor\src\resources\cteTestData.xml"
OUTPUT_FILE = r"c:\NFMonitor\src\tests\generated_cte.xml"

def main():
    print(f"Reading {RESOURCE_FILE}...")
    try:
        with open(RESOURCE_FILE, "rb") as f:
            xml_content = f.read()
    except FileNotFoundError:
        print(f"Error: File {RESOURCE_FILE} not found.")
        return

    xml_base64 = base64.b64encode(xml_content).decode('utf-8')
    
    # Step 1: Convert XML to JSON (CTeFromXML)
    print("Converting XML to JSON via /cte/cte-from-xml...")
    
    # We need to provide a config object, even if empty or minimal
    config = {
        "Geral": {
            "VersaoDF": 3, # ve400
            "SSLLib": 4, # libOpenSSL
        },
        "WebServices": {
             "UF": "SP",
             "Ambiente": 1, # taHomologacao
        }
    }
    
    payload_from_xml = {
        "xml": xml_base64,
        "config": config
    }
    
    try:
        response = requests.post(f"{API_URL}/cte/cte-from-xml", json=payload_from_xml)
        response.raise_for_status()
        cte_json = response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error calling /cte/cte-from-xml: {e}")
        if response.content:
            print(f"Response content: {response.content.decode('utf-8')}")
        return

    print("Successfully obtained JSON representation of CTe.")
    print(json.dumps(cte_json, indent=2))

    # Step 2: Convert JSON back to XML (CTeToXML)
    print("Converting JSON back to XML via /cte/cte-to-xml...")
    
    # Add config to the payload for CTeToXML
    cte_json["config"] = config
    
    try:
        response = requests.post(f"{API_URL}/cte/cte-to-xml", json=cte_json)
        response.raise_for_status()
        result_json = response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error calling /cte/cte-to-xml: {e}")
        if response.content:
            print(f"Response content: {response.content.decode('utf-8')}")
        return

    if "xml" not in result_json:
        print("Error: 'xml' field not found in response.")
        print(json.dumps(result_json, indent=2))
        return

    generated_xml_base64 = result_json["xml"]
    generated_xml_content = base64.b64decode(generated_xml_base64)

    print(f"Saving generated XML to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, "wb") as f:
        f.write(generated_xml_content)

    print("Done!")
    
    # Optional: Compare contents
    # Note: The generated XML might differ in whitespace or signature, so direct byte comparison might fail.
    # But we can check if it's valid XML.
    print(f"Original size: {len(xml_content)} bytes")
    print(f"Generated size: {len(generated_xml_content)} bytes")

if __name__ == "__main__":
    main()
