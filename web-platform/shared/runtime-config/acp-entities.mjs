// ACP exposes only missing editors. Existing in-game tools keep ownership of
// placement and lifecycle operations; their journal/reload safety remains shared.
import {entityTypes} from './entities.mjs';
import {ConfigurationError} from './validation.mjs';
export const acpEntityTypes=Object.fromEntries(Object.entries(entityTypes).filter(([,value])=>!value.inGameTools));
export function assertACPEntityType(type) {
 if(!Object.hasOwn(acpEntityTypes,type))throw new ConfigurationError(Object.hasOwn(entityTypes,type)&&entityTypes[type].inGameTools?'Use the in-game editor: '+entityTypes[type].inGameTools:'Unknown ACP entity family.');
}
export function assertACPEntityChanges(patches) {
 if(Array.isArray(patches))for(const patch of patches)assertACPEntityType(patch?.type);
}
