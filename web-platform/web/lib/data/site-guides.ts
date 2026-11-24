/** Starter player guides. Edit these alongside your server's actual configuration. */
export const siteGuides = {
  "trucking": {
    "title": "Trucking",
    "intro": "Move business supplies from the depot to their destination.",
    "sections": [
      {
        "title": "Take an order",
        "body": "Read /truckerjob for instructions. At the configured depot, drive a supported delivery vehicle and use /loadtruck to take an order."
      },
      {
        "title": "Load and deliver",
        "body": "Press Y to collect a crate, then Y at the rear of the vehicle to load it. Vehicle slots limit the load. Drive to the marked business, take out each crate and carry it to the checkpoint. Press Y to deliver it."
      },
      {
        "title": "Finish or cancel",
        "body": "Each crate delivered earns payment. Use /canceldelivery to abandon the order and clear the cargo."
      }
    ]
  },
  "firms": {
    "title": "Player-run firms",
    "intro": "Register a company, employ other characters and build a working business in game.",
    "sections": [
      {"title":"Register at the administration desk","body":"Earn the registration fee in cash, then visit the configured Administration Building front desk. Use /firmlicense [mechanic/security/lawyer/transit/logistics/media] for a free professional business registration. Used-car and real-estate firms do not need a licence. Register with /firmcreate [field] [abbrev] [name], for example /firmcreate transit CAB Harbor Cab Company. You become the owner after the database accepts the registration."},
      {"title":"Hire and fund your company","body":"Use /firmhelp, /firmmembers and /firminvite [player]. The recipient accepts the invite. /firmrank controls employee roles and /firmduty enables field work. New firms default to 10 members including the owner and 15 vehicles; server configuration can change these defaults. Use /firmbank deposit [amount] to contribute cash; only authorised roles can withdraw."},
      {"title":"Get vehicles and start work","body":"Buy a personal vehicle normally, sit in the driver's seat and use /firmcar assign to transfer it to the company. No free vehicle or reimbursement is created. Mechanics use /mechanic, transit drivers use /fare and the meter, lawyers use /inmates and /defend, media firms use /broadcast, used-car businesses use /usedpool and /usedcar, and real-estate firms use /propertylist and /firmpropertybuy. Logistics uses the normal crate delivery job; it has no separate commodity PDA."},
      {"title":"Manage assets before closing","body":"Use /firmcar release as the owner to return an ordinary firm vehicle to your personal ownership; a personal vehicle slot is required. Withdraw all company funds and release ordinary vehicles before /firmclose. Used-car stock returns to the scrapyard pool and real-estate stock returns to the server under their existing closure rules. A security business registration does not issue police guard or firearms permits."}
    ]
  },
  "dealerships": {
    "title": "Vehicles",
    "intro": "Find the right vehicle for the life you want to build.",
    "sections": [
      {
        "title": "Browse your options",
        "body": "The vehicle catalogue in the player panel lists the available models and storage capacities. Dealership locations, prices and availability are set by the server owner."
      },
      {
        "title": "Look after your vehicle",
        "body": "Check the in-game vehicle commands for ownership, locks and maintenance. A delivery vehicle also has a limited number of crate slots."
      }
    ]
  },
  "real-estate": {
    "title": "Property & businesses",
    "intro": "A home, a storefront or the start of something bigger.",
    "sections": [
      {
        "title": "Find a property",
        "body": "Available houses and businesses are placed by server staff. Check property entrances in game for ownership and purchase information."
      },
      {
        "title": "Make it yours",
        "body": "Use the property and furniture systems to personalise your space. Business types and prices depend on the server configuration."
      }
    ]
  },
  "poker": {
    "title": "Poker",
    "intro": "Meet other characters around the table.",
    "sections": [
      {
        "title": "Find a game",
        "body": "Tables are placed by the server owner. Use the in-game help at an available table to learn the controls and betting rules before joining."
      },
      {
        "title": "Play responsibly",
        "body": "Follow the community rules and table limits. Ask staff if you are unsure how an action works."
      }
    ]
  }
}

