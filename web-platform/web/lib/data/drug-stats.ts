// All grow/cook times derived from task Drugs_OnGrowth[2500]() — one tick every 2.5 seconds.
// Supply point coordinates are SA-MP world coordinates (Vice City map offset applied server-side).

export type DrugVariant = {
  name: string
  supplyCost: number    // $ to buy supply from the cartel NPC (0 = not yet implemented)
  growMins: number      // grow/cook time in minutes (0 = N/A)
  minHaul: number       // min grams per harvest
  maxHaul: number       // max grams per harvest
  stat: string          // key effect value shown in table
}

export type DrugAddiction = {
  ratePerGram: number    // addiction points gained per gram used
  decayPerHour: number   // addiction points lost per hour
  windowHours: number    // hours before withdrawal kicks in
  withdrawalEffects: string[]
}

export type DrugInfo = {
  id: string
  name: string
  colorClass: string      // CSS modifier
  description: string
  consumedBy: string      // how to use in-game
  effectSummary: string[]
  crash?: string          // post-effect downside
  variants: DrugVariant[]
  statLabel: string       // column header for variant stat
  supplyLocation: string  // in-game area description
  supplyNote?: string     // optional extra note about acquiring
  addiction: DrugAddiction
}

export const DRUG_STATS: DrugInfo[] = [
  {
    id: 'weed',
    name: 'Cannabis',
    colorClass: 'drug-weed',
    description: 'A mild stimulant consumed via a rolled blunt. Provides gradual HP recovery while actively smoking. Least addictive of the four drugs and fastest to grow.',
    consumedBy: '/usedrug [slot] [amount], then /blunt to smoke',
    effectSummary: [
      'Heals HP periodically while the /blunt smoking animation is active',
      'Pausing the animation halts the effect — saves the blunt for later',
      'No armour granted and no negative HP effects',
    ],
    variants: [
      { name: 'Maui Waui',       supplyCost: 600,  growMins: 2.5, minHaul: 2.0, maxHaul: 12.5, stat: '+0.50 HP/heal' },
      { name: 'Northern Lights', supplyCost: 800,  growMins: 5,   minHaul: 1.5, maxHaul: 10.0, stat: '+1.00 HP/heal' },
      { name: 'O.G. Kush',       supplyCost: 1000, growMins: 7.5, minHaul: 1.0, maxHaul: 7.5,  stat: '+2.00 HP/heal' },
      { name: 'Purple Kush',     supplyCost: 1200, growMins: 8.3, minHaul: 0.5, maxHaul: 5.0,  stat: '+2.50 HP/heal' },
    ],
    statLabel: 'HP per Heal',
    supplyLocation: 'Escobar International Airport area — marked by a map icon in-game',
    addiction: {
      ratePerGram: 2.5,
      decayPerHour: 4.0,
      windowHours: 6,
      withdrawalEffects: [
        'Irritability and restlessness RP messages every 2 minutes',
        'No stat penalties at any severity level',
      ],
    },
  },
  {
    id: 'cocaine',
    name: 'Cocaine',
    colorClass: 'drug-coke',
    description: 'A powerful stimulant snorted in lines. Triggers an adrenaline rush that boosts outgoing damage for the duration. Requires a coca leaf grow operation to produce.',
    consumedBy: '/usedrug [slot] [amount] — snorted immediately',
    effectSummary: [
      'Flat damage bonus added to all outgoing weapon hits while active',
      'Effect activates instantly on use — no additional action required',
      'Higher grade seeds yield a larger damage bonus and longer duration',
    ],
    variants: [
      { name: 'Sleigh Ride',    supplyCost: 1200, growMins: 25,  minHaul: 2.0, maxHaul: 12.5, stat: '+0.5 flat dmg' },
      { name: 'Blanca Flakes',  supplyCost: 1800, growMins: 50,  minHaul: 1.5, maxHaul: 10.0, stat: '+1.5 flat dmg' },
      { name: 'Gold Dust',      supplyCost: 2400, growMins: 75,  minHaul: 1.0, maxHaul: 7.5,  stat: '+2.5 flat dmg' },
      { name: 'Paradise White', supplyCost: 3000, growMins: 100, minHaul: 0.5, maxHaul: 5.0,  stat: '+3.5 flat dmg' },
    ],
    statLabel: 'Damage Bonus',
    supplyLocation: 'Little Havana area — marked by a map icon in-game',
    addiction: {
      ratePerGram: 8.0,
      decayPerHour: 2.0,
      windowHours: 4,
      withdrawalEffects: [
        'HP drain (1.5–4.5 HP per drain tick) scaling with addiction severity',
        'Screen sway at moderate and severe levels',
        'Nausea and tremor RP messages every 90 seconds',
      ],
    },
  },
  {
    id: 'crack',
    name: 'Crack Cocaine',
    colorClass: 'drug-crack',
    description: 'A rock-form cocaine derivative smoked for an immediate armour boost. The high is intense but HP drains steadily throughout. Most addictive drug with the slowest addiction decay.',
    consumedBy: '/usedrug [slot] [amount] — smoked immediately',
    effectSummary: [
      'Immediately grants armour on use — activates without any follow-up action',
      'HP drains steadily over the entire effect duration',
      'Armour is removed when the effect ends via /stopdrugeffect or natural expiry',
    ],
    variants: [
      { name: 'Moon Rocks',    supplyCost: 1400, growMins: 25,  minHaul: 2.0, maxHaul: 12.5, stat: '+10 armour / −2 HP total' },
      { name: 'Gravel Balls',  supplyCost: 2000, growMins: 50,  minHaul: 1.5, maxHaul: 10.0, stat: '+25 armour / −5 HP total' },
      { name: 'Boulder Cakes', supplyCost: 2800, growMins: 75,  minHaul: 1.0, maxHaul: 7.5,  stat: '+35 armour / −7 HP total' },
      { name: 'Tornado Crack', supplyCost: 3200, growMins: 100, minHaul: 0.5, maxHaul: 5.0,  stat: '+40 armour / −10 HP total' },
    ],
    statLabel: 'Armour Gained / HP Lost',
    supplyLocation: 'Downtown Vice City area — marked by a map icon in-game',
    addiction: {
      ratePerGram: 15.0,
      decayPerHour: 0.8,
      windowHours: 2,
      withdrawalEffects: [
        'Heavy HP drain (2–6 HP per drain tick) scaling with severity',
        'Armour drain at severe addiction level',
        'Drunk walking animation at severe level (30% chance per message tick)',
        'Withdrawal messages every 90 seconds',
      ],
    },
  },
  {
    id: 'meth',
    name: 'Methamphetamine',
    colorClass: 'drug-meth',
    description: 'A potent stimulant smoked in a pipe. Provides sustained HP regeneration and reduces incoming damage for the duration. After the effect ends a crash sets in, temporarily capping HP.',
    consumedBy: '/usedrug [slot] [amount] — smoked immediately',
    effectSummary: [
      'Passive HP regeneration (1 HP every N ticks) throughout the effect',
      'Reduces all incoming weapon damage by a set percentage while active',
      'After the effect expires, HP is capped at 70 HP for the crash duration',
      'Crash ends naturally with a recovery notification',
    ],
    crash: 'HP capped at 70 for 3–6 minutes after the effect ends (scales with grade)',
    variants: [
      { name: 'Shake',       supplyCost: 0, growMins: 0, minHaul: 2.0, maxHaul: 12.5, stat: '15% DR · 30t regen · 3m crash' },
      { name: 'Clear Ice',   supplyCost: 0, growMins: 0, minHaul: 1.5, maxHaul: 10.0, stat: '18% DR · 25t regen · 4m crash' },
      { name: 'Blue Sky',    supplyCost: 0, growMins: 0, minHaul: 1.0, maxHaul: 7.5,  stat: '22% DR · 20t regen · 5m crash' },
      { name: 'Glass Candy', supplyCost: 0, growMins: 0, minHaul: 0.5, maxHaul: 5.0,  stat: '25% DR · 15t regen · 6m crash' },
    ],
    statLabel: 'DR / Regen / Crash',
    supplyLocation: 'Vice Point area — marked by a map icon in-game',
    supplyNote: 'Meth production is currently being developed. Supply points are placed but the cook system is not yet active.',
    addiction: {
      ratePerGram: 10.0,
      decayPerHour: 1.5,
      windowHours: 5,
      withdrawalEffects: [
        'The crash phase (HP cap at 70) acts as a primary downside',
        'Standard withdrawal messages begin after 5 hours without use at 30+ addiction',
      ],
    },
  },
]

export const ADDICTION_THRESHOLDS = [
  { label: 'None',     range: '0 – 29',   color: 'add-none',     effects: 'No withdrawal symptoms' },
  { label: 'Mild',     range: '30 – 59',  color: 'add-mild',     effects: 'Withdrawal messages; mild HP drain on coke/crack' },
  { label: 'Moderate', range: '60 – 79',  color: 'add-moderate', effects: 'Increased HP drain; screen sway on coke/crack' },
  { label: 'Severe',   range: '80 – 100', color: 'add-severe',   effects: 'Max HP/armour drain; drunk walk animation (crack)' },
]

export function formatGrowTime(mins: number): string {
  if (mins === 0) return '—'
  if (mins < 60) return `${mins} min`
  const h = Math.floor(mins / 60)
  const m = Math.round(mins % 60)
  return m === 0 ? `${h}h` : `${h}h ${m}m`
}
