import { dealershipInventory, DEALERSHIP_TYPES } from '@/lib/data/dealership'
import VehicleCatalogue from './VehicleCatalogue'

export default function VehicleCataloguePage() {
  const inventory = dealershipInventory()
  // Serialise to plain object keyed by type with its label
  const categories = Object.entries(inventory).map(([type, vehicles]) => ({
    type: Number(type),
    label: DEALERSHIP_TYPES[Number(type)] ?? `Dealership ${type}`,
    vehicles,
  })).sort((a, b) => a.type - b.type)

  return (
    <>
      <div className="ucp-card">
        <h2>Vehicle Catalogue</h2>
        <p className="ucp-muted">Browse all available vehicles by dealership. Prices are shown for reference.</p>
      </div>
      <VehicleCatalogue categories={categories} />
    </>
  )
}
