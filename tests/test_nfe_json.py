import requests
import base64

xml_content = '<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe Id="NFe123" versao="4.00"><ide><cUF>35</cUF></ide></infNFe></NFe>'
xml_b64 = base64.b64encode(xml_content.encode('utf-8')).decode('utf-8')

try:
    response = requests.post("http://localhost:9002/nfe/nfe-from-xml", json={"xml": xml_b64})
    print("NFe JSON:", response.text)
except Exception as e:
    print("Error:", e)
