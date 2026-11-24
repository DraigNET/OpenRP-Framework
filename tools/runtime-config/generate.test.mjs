import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,cp,readFile,writeFile,rm,access} from 'node:fs/promises';
import {execFileSync,spawnSync} from 'node:child_process';
import path from 'node:path';
import os from 'node:os';
import {fileURLToPath} from 'node:url';
const source=fileURLToPath(new URL('../../',import.meta.url));

test('baseline generation needs only schema.sql and --check never rewrites stale files',async()=>{
  const root=await mkdtemp(path.join(os.tmpdir(),'orp-schema-generation-'));
  try{
    for(const relative of ['tools/runtime-config','web-platform/shared/runtime-config','gamemodes/config/runtime','database/schema.sql'])await cp(path.join(source,relative),path.join(root,relative),{recursive:true});
    await assert.rejects(access(path.join(root,'database/migrations')));
    await assert.rejects(access(path.join(root,'database/firm-lifecycle.sql')));
    execFileSync(process.execPath,['tools/runtime-config/generate.mjs','--check'],{cwd:root,stdio:'pipe'});
    const schema=await readFile(path.join(root,'database/schema.sql'),'utf8');
    const catalogPath=path.join(root,'web-platform/shared/runtime-config/catalog.mjs');
    const catalog=await readFile(catalogPath,'utf8');
    await writeFile(catalogPath,catalog.replace("Driving licence test fee', 250", "Driving licence test fee', 251"));
    const stale=spawnSync(process.execPath,['tools/runtime-config/generate.mjs','--check'],{cwd:root,encoding:'utf8'});
    assert.equal(stale.status,1);assert.match(stale.stderr,/database\/schema.sql/);
    assert.equal(await readFile(path.join(root,'database/schema.sql'),'utf8'),schema);
    execFileSync(process.execPath,['tools/runtime-config/generate.mjs'],{cwd:root,stdio:'pipe'});
    execFileSync(process.execPath,['tools/runtime-config/generate.mjs','--check'],{cwd:root,stdio:'pipe'});
    await assert.rejects(access(path.join(root,'database/migrations')));
  }finally{await rm(root,{recursive:true,force:true});}
});
