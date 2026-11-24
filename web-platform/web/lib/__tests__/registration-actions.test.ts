import {describe,it,expect} from 'vitest'
import {readFileSync} from 'node:fs'
import ts from 'typescript'

describe('public registration server-action boundary',()=>{
  it('exports registration only, without an account-ID session-token helper',()=>{
    const source=ts.createSourceFile('actions.ts',readFileSync('app/ucp/register/actions.ts','utf8'),ts.ScriptTarget.Latest,true)
    const functions=source.statements.filter(ts.isFunctionDeclaration).filter(statement=>statement.modifiers?.some(modifier=>modifier.kind===ts.SyntaxKind.ExportKeyword)).map(statement=>statement.name?.text)
    expect(functions).toEqual(['registerAction'])
  })
})
