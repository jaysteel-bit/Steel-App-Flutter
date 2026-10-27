const {chromium} = require('C:/Users/viole/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{
 const browser = await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const page = await browser.newPage({viewport:{width:1000,height:1000},deviceScaleFactor:1});
 await page.goto('http://127.0.0.1:8787/DOCUMENTATION/verification/reference.html');
 await page.waitForTimeout(5000); await page.evaluate(()=>document.fonts.ready);
 const geom=await page.locator('#profile > div').boundingBox();
 console.log(JSON.stringify({card:geom,portrait:await page.locator('#profile img').boundingBox()}));
 await page.screenshot({path:'DOCUMENTATION/verification/html-desktop.png'});
 await page.locator('#profile > div').screenshot({path:'DOCUMENTATION/verification/html-card.png'});
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
