const fs = require('fs');
const path = require('path');

const dir = 'C:\\Users\\macga\\Downloads\\encemissodectedesubcontrataodt530043885510101';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.xml'));

async function testFiles() {
  let successCount = 0;
  let failureCount = 0;
  
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const xmlContent = fs.readFileSync(fullPath);
    const base64 = xmlContent.toString('base64');
    
    let endpoint = '';
    let data = {};
    if (file.startsWith('CTe')) {
      endpoint = 'http://localhost:9002/cte/cte-from-xml';
      data = { config: { Geral: { VersaoDF: 've400' } }, xml: base64 };
    } else if (file.startsWith('NFe')) {
      endpoint = 'http://localhost:9002/nfe/nfe-from-xml';
      data = { config: { Geral: { VersaoDF: 've400' } }, xml: base64 };
    } else {
      console.log(`Skipping unknown prefix: ${file}`);
      continue;
    }

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        body: JSON.stringify(data),
        headers: { 'Content-Type': 'application/json' }
      });
      
      const text = await response.text();
      
      if (!response.ok) {
        console.error(`[FAIL] ${file} - Status: ${response.status} - ${text.substring(0, 100)}`);
        failureCount++;
      } else {
        const json = JSON.parse(text);
        if (Object.keys(json).length === 0) {
          console.error(`[FAIL] ${file} - Returned empty JSON object {}`);
          failureCount++;
        } else {
          // Verify a known property to ensure it's not a generic error object but actually serialized
          // E.g., json.infCTe or json.NFe
          if (file.startsWith('CTe') && !json.infCTe) {
             console.error(`[FAIL] ${file} - Missing infCTe! Keys: ${Object.keys(json).join(',')}`);
             failureCount++;
          } else if (file.startsWith('NFe') && !json.infNFe) {
             console.error(`[FAIL] ${file} - Missing infNFe! Keys: ${Object.keys(json).join(',')}`);
             failureCount++;
          } else {
             // console.log(`[OK] ${file}`);
             successCount++;
          }
        }
      }
    } catch (e) {
      console.error(`[ERROR] ${file} - Request failed: ${e.message}`);
      failureCount++;
    }
  }
  
  console.log(`\nResults: ${successCount} Successes, ${failureCount} Failures.`);
}

testFiles();
