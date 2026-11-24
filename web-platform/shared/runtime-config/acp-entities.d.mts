import type {EntityDefinition} from './entities.mjs';
export const acpEntityTypes:Record<string,EntityDefinition>;
export function assertACPEntityType(type:string):void;
export function assertACPEntityChanges(patches:unknown):void;
