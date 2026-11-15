'use client'

import { useState, useMemo } from 'react'
import { furnitureImage } from '@/lib/data/furniture'
import type { FurnitureCategory } from '@/lib/data/furniture'

export default function FurnitureCatalogue({ categories }: { categories: FurnitureCategory[] }) {
  const [activeCat, setActiveCat] = useState(categories[0]?.name ?? '')
  const [query, setQuery] = useState('')

  const category = categories.find(c => c.name === activeCat) ?? categories[0]

  const subcategories = useMemo(() => {
    const q = query.toLowerCase()
    if (!q) return category?.subcategories ?? []
    return (category?.subcategories ?? []).map(sub => ({
      ...sub,
      items: sub.items.filter(i => i.name.toLowerCase().includes(q) || String(i.modelId).includes(q)),
    })).filter(sub => sub.items.length > 0)
  }, [category, query])

  return (
    <>
      {/* Tab bar + search */}
      <div className="ucp-card" style={{ padding: '12px 16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', flex: 1 }}>
            {categories.map(c => (
              <button
                key={c.name}
                onClick={() => { setActiveCat(c.name); setQuery('') }}
                className={`ucp-btn ${activeCat === c.name ? 'ucp-btn-primary' : 'ucp-btn-outline'}`}
                style={{ fontSize: 13 }}
              >
                {c.name}
              </button>
            ))}
          </div>
          <input
            type="text"
            placeholder="Search item or model ID…"
            value={query}
            onChange={e => setQuery(e.target.value)}
            className="char-text-input"
            style={{ width: 240, flexShrink: 0 }}
          />
        </div>
      </div>

      {/* Content */}
      {subcategories.length === 0 ? (
        <div className="ucp-card"><p className="ucp-muted">No items match your search.</p></div>
      ) : (
        <div className="ucp-card" style={{ marginTop: 16 }}>
          {subcategories.map(sub => (
            <div key={sub.name} style={{ marginBottom: 28 }}>
              <h4 style={{ marginBottom: 10, color: 'var(--text-2)', fontSize: 12, textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                {sub.name}
              </h4>
              <div className="vehicle-grid">
                {sub.items.map((item, idx) => (
                  <div key={`${item.modelId}-${idx}`} className="vehicle-card">
                    <div className="vehicle-thumb">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={furnitureImage(item.modelId)}
                        alt={item.name}
                        onError={e => { (e.target as HTMLImageElement).style.display = 'none' }}
                      />
                    </div>
                    <div className="vehicle-name">{item.name}</div>
                    <div className="vehicle-meta">Model ID: {item.modelId}</div>
                    <div className="vehicle-price">
                      <div style={{ fontSize: 18, fontWeight: 700, color: '#86efac' }}>
                        ${item.price.toLocaleString()}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  )
}
