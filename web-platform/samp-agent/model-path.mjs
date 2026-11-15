import path from 'node:path'
import fs from 'node:fs'

/** Resolve a model file using the host's path rules. No absolute paths or parent traversal. */
export function resolveModelPath(root, relative, paths = path) {
  if (typeof relative !== 'string' || !relative || /[\x00-\x1f:]/.test(relative)) throw new Error('Invalid model path')
  const parts = relative.replaceAll('\\', '/').split('/')
  if (parts[0] === '' || parts.some(part => part === '..' || part === '')) throw new Error('Path traversal denied')
  const base = paths.resolve(root)
  const result = paths.resolve(base, ...parts)
  const suffix = paths.relative(base, result)
  if (!suffix || suffix === '..' || suffix.startsWith('..' + paths.sep) || paths.isAbsolute(suffix)) throw new Error('Path traversal denied')
  return result
}

/** Reject symlinks below the configured model root, including existing parents of new uploads. */
export function checkedModelPath(root, relative) {
  const resolved = resolveModelPath(root, relative)
  let current = path.resolve(root)
  for (const part of path.relative(current, resolved).split(path.sep)) {
    current = path.join(current, part)
    try { if (fs.lstatSync(current).isSymbolicLink()) throw new Error('Symlink model paths are not allowed') }
    catch (error) { if (error.code !== 'ENOENT') throw error }
  }
  return resolved
}
