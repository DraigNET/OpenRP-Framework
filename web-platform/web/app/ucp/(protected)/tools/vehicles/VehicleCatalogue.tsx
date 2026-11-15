'use client'

import { useState } from 'react'
import type { DealershipVehicle } from '@/lib/data/dealership'

interface Category {
  type: number
  label: string
  vehicles: DealershipVehicle[]
}

export default function VehicleCatalogue({ categories }: { categories: Category[] }) {
  const [activeType, setActiveType] = useState<number | 'all'>('all')
  const [query, setQuery] = useState('')

  const shown = activeType === 'all'
    ? categories
    : categories.filter(c => c.type === activeType)

  const filtered = shown
    .map(c => ({
      ...c,
      vehicles: query
        ? c.vehicles.filter(v => v.name.toLowerCase().includes(query.toLowerCase()) || String(v.model).includes(query))
        : c.vehicles,
    }))
    .filter(c => c.vehicles.length > 0)

  return (
    <>
      <div className="ucp-card" style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <button onClick={() => setActiveType('all')}
            className={`ucp-btn ${activeType === 'all' ? 'ucp-btn-primary' : 'ucp-btn-outline'}`}>
            All
          </button>
          {categories.map(c => (
            <button key={c.type} onClick={() => setActiveType(c.type)}
              className={`ucp-btn ${activeType === c.type ? 'ucp-btn-primary' : 'ucp-btn-outline'}`}>
              {c.label.replace(' Dealership', '')}
            </button>
          ))}
        </div>
        <input
          type="text"
          placeholder="Search vehicle or model ID…"
          value={query}
          onChange={e => setQuery(e.target.value)}
          className="char-text-input"
          style={{ maxWidth: 280, marginLeft: 'auto' }}
        />
      </div>

      {filtered.length === 0 ? (
        <div className="ucp-card"><p className="ucp-muted">No vehicles match your search.</p></div>
      ) : filtered.map(category => (
        <div key={category.type} className="ucp-card" style={{ marginTop: 20 }}>
          <h3>{category.label}</h3>
          <div className="vehicle-grid" style={{ marginTop: 14 }}>
            {category.vehicles.map(v => {
              const discounted = v.newPrice < v.oldPrice
              return (
                <div key={v.model} className="vehicle-card">
                  <div className="vehicle-thumb">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={v.image} alt={v.name} onError={e => { (e.target as HTMLImageElement).style.display = 'none' }} />
                  </div>
                  <div className="vehicle-name">{v.name}</div>
                  <div className="vehicle-meta">Model ID: {v.model}</div>
                  {v.storage > 0 && (
                    <div className="vehicle-meta">
                      <i className="fa-solid fa-boxes-stacked" /> {v.storage} slots
                    </div>
                  )}
                  <div className="vehicle-price">
                    {discounted && (
                      <div style={{ fontSize: 13, color: 'var(--text-2)', textDecoration: 'line-through' }}>
                        ${v.oldPrice.toLocaleString()}
                      </div>
                    )}
                    <div style={{ fontSize: 18, fontWeight: 700, color: '#86efac' }}>
                      ${v.newPrice.toLocaleString()}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      ))}
    </>
  )
}
