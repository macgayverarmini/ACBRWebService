const fs = require('fs');
const path = require('path');

const dir = 'C:\\Users\\macga\\Downloads\\encemissodectedesubcontrataodt530043885510101';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.xml'));

async function testRoundTrip() {
  let successCount = 0;
  let failureCount = 0;
  
  for (const file of files) {
    if (!file.startsWith('CTe')) {
       continue; // Only testing CTe for now
    }
    const fullPath = path.join(dir, file);
    const xmlContent = fs.readFileSync(fullPath);
    const base64 = xmlContent.toString('base64');
    
    // STEP 1: XML -> JSON
    const dataFromXML = { config: { Geral: { VersaoDF: 've400' } }, xml: base64 };
    let jsonResp;
    try {
      const resp1 = await fetch('http://localhost:9002/cte/cte-from-xml', {
        method: 'POST', body: JSON.stringify(dataFromXML), headers: { 'Content-Type': 'application/json' }
      });
      if (!resp1.ok) throw new Error(`cte-from-xml failed: ${resp1.status}`);
      jsonResp = await resp1.json();
    } catch (e) {
      console.error(`[FAIL] ${file} - Step 1 (XML->JSON) error: ${e.message}`);
      failureCount++;
      continue;
    }

    // STEP 2: JSON -> ACBr -> XML
    const dataToXML = { config: { Geral: { VersaoDF: 've400' } }, cte: jsonResp };
    try {
      const resp2 = await fetch('http://localhost:9002/cte/cte-to-xml', {
        method: 'POST', body: JSON.stringify(dataToXML), headers: { 'Content-Type': 'application/json' }
      });
      if (!resp2.ok) throw new Error(`cte-to-xml failed: ${resp2.status}`);
      const resultJson = await resp2.json();
      
      if (!resultJson.xml) {
         console.error(`[FAIL] ${file} - Step 2 (JSON->XML) returned no XML! Resp: ${JSON.stringify(resultJson).substring(0,100)}`);
         failureCount++;
         continue;
      }
      
      const reconstructedXml = Buffer.from(resultJson.xml, 'base64').toString('utf8');
      
      // We successfully reconstructed an XML. Let's do a basic size check or tag check.
      if (reconstructedXml.includes('<CTe')) {
         successCount++;
      } else {
         console.error(`[FAIL] ${file} - Reconstructed XML is missing <CTe> tag.`);
         failureCount++;
      }

    } catch (e) {
      console.error(`[FAIL] ${file} - Step 2 (JSON->XML) error: ${e.message}`);
      failureCount++;
    }
  }
  
  console.log(`\nRoundTrip Results (CTe): ${successCount} Successes, ${failureCount} Failures.`);
}

testRoundTrip();
