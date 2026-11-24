export type SettingDefinition = { key:string;group:string;label:string;type:'integer'|'number'|'text';default:string|number;min?:number;max?:number;maxLength?:number;macro?:string;policy?:string;structuralMacro?:boolean }
export const settings:SettingDefinition[]
export const locationCategories:string[]
export const locations:{key:string;label:string;category:string;x:number;y:number;z:number;angle:number;interior:number;world:number;radius:number;enabled:boolean;gps?:boolean;pickup?:number}[]
export const cargoModels:Record<number,number>
export const squads:{id:number;factionId:number;name:string;roles:number}[]
export function pawnId(key:string):string
