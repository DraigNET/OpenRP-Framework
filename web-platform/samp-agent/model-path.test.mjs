import { test } from 'node:test'
import assert from 'node:assert/strict'
import path from 'node:path'
import fs from 'node:fs'
import os from 'node:os'
import { resolveModelPath, checkedModelPath } from './model-path.mjs'

for (const [name, paths, root] of [['Windows', path.win32, 'C:\\server\\models'], ['Linux', path.posix, '/srv/game/models']]) {
  test(name + ': accepts nested model paths', () => {
    assert.equal(resolveModelPath(root, 'skins_faction/1/test.dff', paths), paths.join(root, 'skins_faction', '1', 'test.dff'))
  })
  for (const attack of ['../secrets', '..\\secrets', '/etc/passwd', 'C:\\secret', '//server/share', '', '.', 'folder/../../secret']) {
    test(name + ': rejects ' + JSON.stringify(attack), () => assert.throws(() => resolveModelPath(root, attack, paths)))
  }
}
test('rejects symlinks escaping the model directory', () => {
  const folder = fs.mkdtempSync(path.join(os.tmpdir(), 'orp-model-path-'))
  try {
    fs.mkdirSync(path.join(folder, 'models')); fs.mkdirSync(path.join(folder, 'outside'))
    fs.symlinkSync(path.join(folder, 'outside'), path.join(folder, 'models', 'link'), 'junction')
    assert.throws(() => checkedModelPath(path.join(folder, 'models'), 'link/private.dff'))
  } finally { fs.rmSync(folder, { recursive: true, force: true }) }
})
