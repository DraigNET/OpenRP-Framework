export type EntityField={label:string;min?:number;max?:number;integer?:boolean;text?:boolean;maxLength?:number;allowEmpty?:boolean;default:number|string}
export type EntityDefinition={label:string;table:string;id:string;limit:number;editOnly?:boolean;inGameTools?:string;help?:string;factionField?:string;typeField?:string;squadField?:string;groupLimit?:number;fields:Record<string,EntityField>}
export const entityTypes:Record<string,EntityDefinition>
