const { chromium } = require('C:/Users/viole/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
 const context=await browser.newContext({viewport:{width:1000,height:1100},deviceScaleFactor:1,acceptDownloads:true,serviceWorkers:'block'});
 const page=await context.newPage(); const errors=[];
 page.on('pageerror', e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error') errors.push(m.text())});
 async function load(url){await page.goto(url); await page.waitForSelector('flt-semantics-placeholder',{timeout:60000}); await page.locator('flt-semantics-placeholder').evaluateAll(es=>es.forEach(e=>e.click()));await page.waitForTimeout(500);}
 await load('http://127.0.0.1:8790/');
 await page.getByText('Alexis Rivera',{exact:true}).waitFor();
 await page.getByRole('button',{name:'Identity & permissions',exact:true}).click();
 await page.getByRole('button',{name:'Close',exact:true}).waitFor({timeout:30000});
 const security=await page.locator('body').innerText();await page.screenshot({path:'DOCUMENTATION/verification/flutter-security.png'});
 assert(security.includes('Replay blocked: true'));
 const firstId=security.match(/steel:[0-9a-f-]{36}/)[0];
 await page.getByRole('button',{name:'Close',exact:true}).click();
 await page.getByRole('button',{name:'Lock preview',exact:true}).click();
 await page.getByText('Tap to Connect',{exact:true}).waitFor();
 await page.screenshot({path:'DOCUMENTATION/verification/flutter-locked.png'});
 await page.getByRole('button',{name:'Reveal Profile',exact:true}).click();
 await page.waitForTimeout(900);
 const dl=page.waitForEvent('download');
 await page.getByRole('button',{name:'Add to Contacts',exact:true}).click();
 const download=await dl; await download.saveAs('DOCUMENTATION/verification/contact.vcf');
 const vcf=fs.readFileSync('DOCUMENTATION/verification/contact.vcf','utf8');
 assert(vcf.startsWith('BEGIN:VCARD')); assert(!vcf.includes('EMAIL:')); assert(!vcf.includes('TEL:'));
 await page.getByRole('button',{name:'Edit profile',exact:true}).click();
 console.log('Editor:',(await page.locator('body').innerText()).slice(0,1500));
 console.log('Inputs:', await page.locator('input').count());
 const inputs=page.locator('input');
 for(const [i,v] of ['Jay Test','Builder | NYC','jay.test','https://www.linkedin.com/in/jay-test/','+15551234567','private@example.test'].entries()) await inputs.nth(i).fill(v);
 await page.getByRole('button',{name:'Save profile',exact:true}).click();
 await page.getByText('Jay Test',{exact:true}).waitFor();
 await load('http://127.0.0.1:8790/');
 await page.getByText('Jay Test',{exact:true}).waitFor();
 await page.getByRole('button',{name:'Identity & permissions',exact:true}).click();
 await page.getByRole('button',{name:'Close',exact:true}).waitFor();
 assert((await page.locator('body').innerText()).includes(firstId));
 await page.getByRole('button',{name:'Close',exact:true}).click();
 await load('http://127.0.0.1:8790/#/public');
 const publicText=await page.locator('body').innerText();
 assert(!publicText.includes('private@example.test')); assert(!publicText.includes('+15551234567')); assert(!publicText.includes('Edit profile'));
 // Prevent real external navigation while checking configured URL dispatch.
 await context.route('https://www.instagram.com/**',r=>r.fulfill({body:'URL dispatch verified'}));
 const popup=context.waitForEvent('page');
 await page.getByText('@jay.test',{exact:true}).click();
 const social=await popup; await social.waitForLoadState(); assert.equal(social.url(),'https://www.instagram.com/jay.test/');await social.close();
 // Reset presentation fixture only in the test browser's isolated storage.
 await page.evaluate(()=>{for(let i=localStorage.length-1;i>=0;i--){const k=localStorage.key(i);if(k.includes('steel.digital-profile'))localStorage.removeItem(k)}});
 await load('http://127.0.0.1:8790/');
 await page.screenshot({path:'DOCUMENTATION/verification/flutter-desktop.png'});
 console.log('Name bounds:',await page.getByText('Alexis Rivera',{exact:true}).boundingBox());
 await page.screenshot({path:'DOCUMENTATION/verification/flutter-card.png',clip:{x:341,y:325,width:318,height:566}});
 for(const width of [390,320]){
  await page.setViewportSize({width,height:844});await page.waitForTimeout(700);
  await page.screenshot({path:`DOCUMENTATION/verification/flutter-phone-${width}.png`});
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
 }
 assert.equal(errors.length,0,JSON.stringify(errors));
 console.log('PASS: web secure identity persists; signed read/replay; edit/reload; guest filtering; vCard download; configured social URL; lock/reveal; 390px/320px. No browser errors.');
 fs.writeFileSync('DOCUMENTATION/verification/browser-results.txt','PASS\n'+security+'\n'+publicText+'\n'+JSON.stringify(errors));
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});


