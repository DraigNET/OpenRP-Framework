import { furnitureCategories } from '@/lib/data/furniture'
import FurnitureCatalogue from './FurnitureCatalogue'

export default function FurniturePricePage() {
  const categories = furnitureCategories()
  return (
    <>
      <div className="ucp-card">
        <h2>Furniture Catalogue</h2>
        <p className="ucp-muted">Browse all purchasable furniture items and their in-game prices.</p>
      </div>
      <FurnitureCatalogue categories={categories} />
    </>
  )
}
