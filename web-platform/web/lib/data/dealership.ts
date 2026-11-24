import 'server-only'
import { prisma } from '../prisma'
import baseline from '../../../shared/runtime-config/vehicle-catalog.json'
import { vehicleName, vehicleImage } from './vehicles'

export const DEALERSHIP_TYPES: Record<number, string> = {
  0: 'Budget Dealership',
  1: 'Muscle Dealership',
  2: 'Sports Dealership',
  3: 'Utility Dealership',
  4: 'Bike Dealership',
  5: 'Aircraft Dealership',
  6: 'Boat Dealership',
}

export interface DealershipVehicle {
  model: number
  name: string
  oldPrice: number
  newPrice: number
  image: string
  storage: number
}

// Prices, disabled models and real cargo capacities match the running game.
export async function dealershipInventory():Promise<Record<number,DealershipVehicle[]>> {
  const rows=await prisma.$queryRaw<Array<{model_id:number;cargo_slots:number;catalogue_price:number|null;enabled:number}>>`SELECT model_id,cargo_slots,catalogue_price,enabled FROM runtime_vehicle_models`
  const models=new Map(rows.map(row=>[Number(row.model_id),{cargo_slots:Number(row.cargo_slots),catalogue_price:row.catalogue_price===null?null:Number(row.catalogue_price),enabled:Number(row.enabled)}]))
  const out:Record<number,DealershipVehicle[]>={}
  for(const item of baseline) {
    const row=models.get(item.model)
    if(!row?.enabled || row.catalogue_price===null) continue
    ;(out[item.type]??=[]).push({model:item.model,name:vehicleName(item.model),oldPrice:row.catalogue_price,newPrice:row.catalogue_price,image:vehicleImage(item.model),storage:row.cargo_slots})
  }
  return out
}
