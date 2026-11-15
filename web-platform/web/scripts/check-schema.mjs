import fs from 'node:fs'

/** Offline guard: the distributed SQL must cover every field used by the web ORM. */
const sql = fs.readFileSync(new URL('../../../database/schema.sql', import.meta.url), 'utf8')
const prisma = fs.readFileSync(new URL('../prisma/schema.prisma', import.meta.url), 'utf8')
const tables = new Map()
for (const match of sql.matchAll(/CREATE TABLE IF NOT EXISTS `([^`]+)`\s*\(([\s\S]*?)\)\s*(?:ENGINE|DEFAULT CHARACTER)/g)) {
  tables.set(match[1], new Set([...match[2].matchAll(/^\s*`([^`]+)`/gm)].map(field => field[1])))
}
const missingTables = [], missingColumns = []
for (const model of prisma.matchAll(/model\s+(\w+)\s*\{([\s\S]*?)\n\}/g)) {
  const table = model[2].match(/@@map\("([^"]+)"\)/)?.[1] || model[1]
  if (!tables.has(table)) { missingTables.push(table); continue }
  for (const line of model[2].split('\n')) {
    const field = line.match(/^\s*(\w+)\s+(String|Int|BigInt|Float|Decimal|DateTime|Boolean|Bytes)\??(?:\s|$)/)
    if (!field) continue
    const column = line.match(/@map\("([^"]+)"\)/)?.[1] || field[1]
    if (!tables.get(table).has(column)) missingColumns.push(table + '.' + column)
  }
}
const report = { note: 'Static table/column coverage only. Fresh database and runtime tests are also required.', missingTables, missingColumns }
fs.writeFileSync(new URL('../../database-compatibility.json', import.meta.url), JSON.stringify(report, null, 2) + '\n')
console.log(JSON.stringify(report, null, 2))
if (missingTables.length || missingColumns.length) process.exitCode = 1
