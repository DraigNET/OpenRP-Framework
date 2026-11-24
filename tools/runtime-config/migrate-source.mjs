// Idempotent migration of configuration macros. Structural array limits are
// deliberately excluded; their owning modules require an explicit count refactor.
import fs from 'node:fs';
import path from 'node:path';
import { settings, pawnId } from '../../web-platform/shared/runtime-config/catalog.mjs';
const id = pawnId;
const macros = new Map(settings.filter(s=>s.macro&&!s.structuralMacro).map(s=>[s.macro,`${s.type==='number'&&!s.integerMacro?'Runtime_Float':'Runtime_Int'}(${id(s.key)})`]));
for (const [prefix,key] of Object.entries({SERVER_DMV:'dmv',CHOPSHOP:'chopshop',TRUCKER_DEPOT:'trucker_depot',ADMIN_JAIL_POS:'admin_jail',SCRAPYARD_POS:'scrapyard_land',SCRAPYARD_BOAT_POS:'scrapyard_boat',SCRAPYARD_AIR_POS:'scrapyard_air',ADV_POS:'advert_agency',LS_GYM_EXT:'gym_ls',SF_GYM_EXT:'gym_sf',LV_GYM_EXT:'gym_lv',GANTON_GYM_EXT:'gym_ganton',BEACH_GYM_EXT:'gym_beach'})) for (const axis of ['X','Y','Z']) macros.set(prefix+'_'+axis,`RuntimeLocations[RT_LOC_${key.toUpperCase()}][RLOC_${axis}]`);
macros.set('ADMIN_JAIL_POS_INT','RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_INTERIOR]');
macros.set('ADMIN_JAIL_WORLD','RuntimeLocations[RT_LOC_ADMIN_JAIL][RLOC_WORLD]');
function walk(dir) { for(const item of fs.readdirSync(dir,{withFileTypes:true})) { const file=path.join(dir,item.name);if(item.isDirectory()){if(file.includes(path.join('config','runtime')))continue;walk(file);}else if(file.endsWith('.pwn')){const original=fs.readFileSync(file,'utf8');const result=original.replace(/^(\s*#define\s+)([A-Z][A-Z0-9_]*)([^\r\n]*)/gm,(line,prefix,name)=>macros.has(name)?`${prefix}${name} (${macros.get(name)}) // Cached database setting; edit through ACP.`:line);if(result!==original)fs.writeFileSync(file,result);} } }
// GPS initializers must remain constant expressions. Runtime rebuild fills these
// entries from the authoritative service records after the snapshot is loaded.
const gps='gamemodes/gps/data.pwn';let source=fs.readFileSync(gps,'utf8');source=source.replace(/new GPS\s*\[\s*\]/,'new GPS [256]');source=source.replace(/new GPS[\s\S]*?\n\}\s*;/,block=>block.replace(/\b(?:ADV_POS|CHOPSHOP)_[XYZ]\b/g,'0.0'));fs.writeFileSync(gps,source);
walk('gamemodes');
console.log(`Connected ${macros.size} scalar/location macros to the runtime cache.`);
