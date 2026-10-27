const {chromium} = require('C:/Users/viole/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const page=await browser.newPage({viewport:{width:1000,height:1100},deviceScaleFactor:1});
 page.on('console',m=>{if(m.type()==='error') console.log('console:',m.text())});
 page.on('pageerror',e=>console.log('pageerror:',e.message));
 await page.goto('http://127.0.0.1:8790/');
 await page.waitForTimeout(12000);
 await page.screenshot({path:'DOCUMENTATION/verification/flutter-desktop.png'});
 console.log(await page.locator('body').innerText());
 console.log(await page.locator('flt-semantics-placeholder').count());
 await page.locator('flt-semantics-placeholder').evaluateAll(es=>es.forEach(e=>e.click()));
 await page.waitForTimeout(1000);
 console.log((await page.locator('body').innerText()).slice(0,5000));
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
