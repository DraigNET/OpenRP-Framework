import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';import os from 'node:os';import path from 'node:path';import net from 'node:net';import {spawn} from 'node:child_process';import {randomBytes} from 'node:crypto';

async function freePort(){const s=net.createServer();await new Promise(r=>s.listen(0,'127.0.0.1',r));const port=s.address().port;await new Promise(r=>s.close(r));return port;}
async function eventually(fn){for(let i=0;i<50;i++){try{if(await fn())return;}catch{}await new Promise(r=>setTimeout(r,50));}throw Error('Agent did not become ready');}

test('agent HTTP authorization, model uploads and ban persistence',async t=>{
 const folder=fs.mkdtempSync(path.join(os.tmpdir(),'orp-agent-http-')),key=randomBytes(24).toString('hex'),port=await freePort();fs.mkdirSync(path.join(folder,'models'));
 const child=spawn(process.execPath,['index.mjs'],{cwd:new URL('.',import.meta.url),env:{...process.env,SAMP_AGENT_KEY:key,AGENT_BIND:'127.0.0.1',AGENT_PORT:String(port),SAMP_DIR:folder,SAMP_BIN:path.join(folder,'missing-server.exe')},stdio:'ignore'});
 const base='http://127.0.0.1:'+port;
 const request=(url,options={})=>fetch(base+url,{...options,headers:{'x-agent-key':key,...options.headers}});
 try {
  await eventually(async()=>Boolean((await request('/status')).ok));
  await t.test('unauthenticated status and start requests are rejected',async()=>{assert.equal((await fetch(base+'/status')).status,401);assert.equal((await fetch(base+'/start',{method:'POST'})).status,401);assert.equal((await request('/status')).status,200);});
  await t.test('authenticated upload round trips through the public model CDN',async()=>{assert.equal((await request('/upload?path=nested/test.dff',{method:'POST',body:Buffer.from('test model')})).status,200);assert.equal(await(await fetch(base+'/cdn/nested/test.dff')).text(),'test model');});
  await t.test('path traversal cannot upload or delete outside models',async()=>{assert.equal((await request('/upload?path=..%2Foutside.txt',{method:'POST',body:'blocked'})).status,403);assert.equal((await request('/file?path=..%2Foutside.txt',{method:'DELETE'})).status,403);assert.equal(fs.existsSync(path.join(folder,'outside.txt')),false);});
  await t.test('oversized upload leaves no partial file',async()=>{assert.equal((await request('/upload?path=oversize.dff',{method:'POST',body:Buffer.alloc(33*1024*1024)})).status,413);await new Promise(r=>setTimeout(r,200));assert.equal(fs.existsSync(path.join(folder,'models','oversize.dff')),false);});
  await t.test('ban entries use the open.mp disk format and can be removed',async()=>{assert.equal((await request('/bans',{method:'POST',body:JSON.stringify({address:'192.0.2.77',name:'Test_User',reason:'test'})})).status,200);const [entry]=JSON.parse(fs.readFileSync(path.join(folder,'bans.json'),'utf8'));assert.equal(entry.player,'Test_User');assert.match(entry.time,/\+0000$/);assert.equal((await request('/bans?address=192.0.2.77',{method:'DELETE'})).status,200);assert.deepEqual(JSON.parse(fs.readFileSync(path.join(folder,'bans.json'),'utf8')),[]);});
  await t.test('malformed commands are rejected and missing binaries do not set running',async()=>{assert.equal((await request('/cmd',{method:'POST',body:'not json'})).status,400);assert.equal((await(await request('/start',{method:'POST'})).json()).ok,false);assert.equal((await(await request('/status')).json()).running,false);});
  await t.test('authorized file deletion removes only the selected model',async()=>{assert.equal((await request('/file?path=nested/test.dff',{method:'DELETE'})).status,200);assert.equal(fs.existsSync(path.join(folder,'models','nested','test.dff')),false);});
 } finally {
  child.kill();await new Promise(r=>child.exitCode!==null?r():child.once('exit',r));
  const resolved=fs.realpathSync(folder);assert.ok(resolved.startsWith(fs.realpathSync(os.tmpdir())+path.sep));fs.rmSync(folder,{recursive:true,force:true});
 }
});
