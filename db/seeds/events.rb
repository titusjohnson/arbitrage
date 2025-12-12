puts "Setting up game events..."

# EXCEPTIONAL EVENTS (5 total)
# Legendary historical moments with game-defining impact
exceptional_events = [
  {
    name: "The Great Depression",
    description: "Wall Street just discovered gravity exists. Banks are failing faster than your crypto portfolio in a bear market. Everyone's suddenly very interested in gold while their stocks become fancy wallpaper. Financial centers are in full panic mode—turns out infinite growth wasn't so infinite after all.",
    event_type: "market",
    severity: 5,
    rarity: "exceptional",
    duration: 7,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["investment", "luxury_fashion", "collectible"], match: "any", multiplier: 0.3, description: "Nobody wants your luxury bags when they can't afford bread" },
        { tags: ["precious_metal"], match: "any", multiplier: 3.0, description: "Gold and silver become the only things people trust" },
        { tags: ["antique"], match: "any", multiplier: 0.5, description: "Fire sale on grandma's heirlooms" }
      ],
      availability_modifiers: [
        { tags: ["luxury_fashion"], match: "any", multiplier: 2.5, description: "Desperate wealthy people flooding the market" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["financial_center"], resource: ["investment"] }, match: "any", multiplier: 0.2, description: "Financial centers in absolute chaos" },
        { scoped_tags: { location: ["wealthy"], resource: ["luxury_market"] }, match: "any", multiplier: 0.4, description: "Wealthy neighborhoods liquidating assets" }
      ]
    }
  },
  {
    name: "Hurricane Katrina Devastation",
    description: "Mother Nature just reminded the Gulf Coast who's really in charge. Category 5 winds are redecorating Louisiana without permission. Coastal cities evacuated, ports underwater, and supply chains are now just 'supply.' If you're holding perishables in the South, congratulations on your new paperweights.",
    event_type: "weather",
    severity: 5,
    rarity: "exceptional",
    duration: 6,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "perishable"], match: "all", multiplier: 4.0, description: "Food prices skyrocket as supply vanishes" },
        { tags: ["fragile"], match: "any", multiplier: 2.5, description: "Good luck shipping anything breakable" }
      ],
      availability_modifiers: [
        { tags: ["bulky"], match: "any", multiplier: 0.2, description: "Shipping ground to a halt" },
        { tags: ["perishable"], match: "any", multiplier: 0.3, description: "Supply chains completely disrupted" }
      ]
    },
    location_effects: {
      access_restrictions: [
        { scoped_tags: { location: ["coastal", "southern"] }, match: "all", blocked: true, description: "Southern coastal cities completely inaccessible" },
        { scoped_tags: { location: ["port_city", "southern"] }, match: "all", blocked: true, description: "Gulf ports shut down indefinitely" }
      ]
    }
  },
  {
    name: "Silk Road Seizure",
    description: "The FBI just crashed the internet's favorite anonymous marketplace. Turns out 'crypto is untraceable' was more of a suggestion than a fact. Tech hubs are sweating, digital assets are plummeting, and suddenly everyone's very interested in old-fashioned precious metals again. The blockchain bros are not having a good day.",
    event_type: "political",
    severity: 5,
    rarity: "exceptional",
    duration: 5,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["technology"], match: "any", multiplier: 0.6, description: "Tech sector in crisis mode" },
        { tags: ["precious_metal", "investment"], match: "all", multiplier: 2.2, description: "Flight to traditional safe havens" },
        { tags: ["collectible"], match: "any", multiplier: 1.5, description: "Tangible assets looking pretty good right now" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["tech_hub"], resource: ["technology"] }, match: "any", multiplier: 0.4, description: "Tech hubs panic-selling everything" },
        { scoped_tags: { location: ["financial_center"], resource: ["precious_metal"] }, match: "any", multiplier: 2.5, description: "Financial centers hoarding gold and silver" }
      ]
    }
  },
  {
    name: "The Great Fire",
    description: "A city just learned that wooden buildings and open flames don't mix. Entire cultural districts going up in smoke, priceless antiques becoming literal ashes, and insurance companies discovering what 'act of God' really means. The good news? Collectibles everywhere else just got way more valuable.",
    event_type: "weather",
    severity: 5,
    rarity: "exceptional",
    duration: 6,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["antique", "collectible"], match: "any", multiplier: 2.5, description: "Surviving pieces become instant rarities" },
        { tags: ["fragile"], match: "any", multiplier: 2.0, description: "Anything that survived is worth a fortune" },
        { tags: ["artisan"], match: "any", multiplier: 1.8, description: "Handcrafted items suddenly irreplaceable" }
      ]
    },
    location_effects: {
      access_restrictions: [
        { scoped_tags: { location: ["art_culture"] }, blocked: true, description: "Cultural centers evacuated and burning" }
      ],
      quantity_modifiers: [
        { scoped_tags: { location: ["wealthy"], resource: ["antique"] }, match: "any", multiplier: 0.1, description: "Wealthy collectors' items going up in flames" }
      ]
    }
  },
  {
    name: "Prohibition Era",
    description: "The government just made your favorite vice illegal. Speakeasies are the new normal, bathtub gin is suddenly 'artisanal,' and Al Capone is about to become everyone's favorite businessman. Alcohol prices just went vertical, while tea and coffee merchants are quietly celebrating their unexpected windfall.",
    event_type: "political",
    severity: 5,
    rarity: "exceptional",
    duration: 7,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["alcohol"], match: "any", multiplier: 5.0, description: "Black market prices are insane" },
        { tags: ["food", "consumable"], match: "all", multiplier: 1.5, description: "Alternative beverages booming" }
      ],
      availability_modifiers: [
        { tags: ["alcohol"], match: "any", multiplier: 0.1, description: "Legal markets completely dry" }
      ],
      volatility_modifiers: [
        { tags: ["alcohol"], match: "any", adjustment: 80, description: "Prices wildly unpredictable" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["entertainment"], resource: ["alcohol"] }, match: "any", multiplier: 0.05, description: "Entertainment districts raided" },
        { scoped_tags: { location: ["wealthy"], resource: ["alcohol"] }, match: "any", multiplier: 0.3, description: "Private collections still available... for a price" }
      ]
    }
  }
]

# ULTRA RARE EVENTS (5 total)
# Catastrophic disruptions with massive impact
ultra_rare_events = [
  {
    name: "Dot-Com Crash",
    description: "Turns out companies that only sold pet food online weren't worth billions. Who knew? Silicon Valley's champagne budget just became a beer reality. Tech stocks are tanking, venture capitalists are hiding, and suddenly working at a bank doesn't sound so boring anymore.",
    event_type: "market",
    severity: 4,
    rarity: "ultra_rare",
    duration: 5,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["technology"], match: "any", multiplier: 0.4, description: "Tech liquidation sales everywhere" },
        { tags: ["luxury_fashion"], match: "any", multiplier: 0.6, description: "Ex-millionaires selling their Hermès bags" },
        { tags: ["precious_metal"], match: "any", multiplier: 1.7, description: "Gold looking pretty reliable right now" },
        { tags: ["investment", "collectible"], match: "all", multiplier: 1.4, description: "Tangible investments gaining value" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["tech_hub"], resource: ["technology"] }, match: "any", multiplier: 0.3, description: "Fire sales in San Francisco and Seattle" },
        { scoped_tags: { location: ["financial_center"], resource: ["precious_metal"] }, match: "any", multiplier: 2.0, description: "Wall Street buying up safe havens" }
      ]
    }
  },
  {
    name: "Asian Financial Crisis",
    description: "The Thai baht just collapsed and took half of Asia's economy with it. Currency traders are having a really bad day, and anything from Asia is either dirt cheap or completely unavailable. Your jade collection's value just went on a rollercoaster—hope you like volatility.",
    event_type: "market",
    severity: 5,
    rarity: "ultra_rare",
    duration: 6,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["asian_origin"], match: "any", multiplier: 0.5, description: "Asian imports flooding markets at discount prices" },
        { tags: ["gemstone", "investment"], match: "all", multiplier: 0.7, description: "Asian gemstones being liquidated" }
      ],
      volatility_modifiers: [
        { tags: ["asian_origin"], match: "any", adjustment: 60, description: "Extreme price swings on Asian goods" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["port_city"], resource: ["asian_origin"] }, match: "any", multiplier: 2.5, description: "Ports flooded with desperate exports" }
      ]
    }
  },
  {
    name: "Icelandic Volcanic Eruption",
    description: "An unpronounceable volcano just shut down European airspace. Eyjafjallajökull decided to remind everyone that nature doesn't care about your shipping schedule. European goods are stuck on the ground, perishables are perishing, and travel plans are as dead as the ash-covered countryside.",
    event_type: "weather",
    severity: 4,
    rarity: "ultra_rare",
    duration: 5,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["european_origin"], match: "any", multiplier: 2.2, description: "European goods scarce and expensive" },
        { tags: ["perishable"], match: "any", multiplier: 1.8, description: "Anything fresh is rapidly unfreshing" }
      ],
      availability_modifiers: [
        { tags: ["european_origin", "fragile"], match: "all", multiplier: 0.3, description: "Delicate European imports stuck overseas" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["port_city"], resource: ["european_origin"] }, match: "any", multiplier: 0.2, description: "European shipments grounded indefinitely" }
      ]
    }
  },
  {
    name: "Art Heist Panic",
    description: "Someone just walked into a museum and walked out with half a billion in masterpieces. Security cameras caught nothing, guards saw nothing, and the art world is losing its mind. Collectibles markets are paranoid, insurance companies are crying, and suddenly everyone wants their antiques in a vault.",
    event_type: "cultural",
    severity: 4,
    rarity: "ultra_rare",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["antique", "collectible"], match: "any", multiplier: 1.6, description: "Collectibles values surge on scarcity fears" },
        { tags: ["artisan", "investment"], match: "all", multiplier: 1.5, description: "Authenticated pieces worth more than ever" }
      ],
      volatility_modifiers: [
        { tags: ["antique"], match: "any", adjustment: 45, description: "Art markets extremely jittery" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["art_culture", "wealthy"], resource: ["antique"] }, match: "any", multiplier: 2.0, description: "Wealthy collectors panic-buying replacements" }
      ]
    }
  },
  {
    name: "Pandemic Lockdown",
    description: "A novel virus just put the entire world on house arrest. Cities are ghost towns, entertainment venues are closed indefinitely, and toilet paper somehow became currency. Online shopping is king, luxury stores are tumbleweed museums, and your social life now exists exclusively on Zoom.",
    event_type: "political",
    severity: 5,
    rarity: "ultra_rare",
    duration: 6,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["technology"], match: "any", multiplier: 1.6, description: "Everyone panic-buying tech for work-from-home" },
        { tags: ["luxury_fashion"], match: "any", multiplier: 0.5, description: "Who needs designer clothes for video calls?" },
        { tags: ["perishable", "food"], match: "all", multiplier: 2.0, description: "Panic hoarding drives food prices up" }
      ]
    },
    location_effects: {
      access_restrictions: [
        { scoped_tags: { location: ["entertainment", "tourist_destination"] }, match: "any", blocked: true, description: "Entertainment and tourist destinations closed" }
      ]
    }
  }
]

# RARE EVENTS (10 total)
# Major historical disruptions
rare_events = [
  {
    name: "Beanie Baby Crash",
    description: "Turns out stuffed animals aren't a viable retirement plan. Who could have seen that coming? The collectibles market just learned what 'speculative bubble' means the hard way. Your rare Princess Diana bear is now worth exactly one regular teddy bear.",
    event_type: "market",
    severity: 3,
    rarity: "rare",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["collectible"], match: "any", multiplier: 0.6, description: "Collectibles credibility shattered" }
      ],
      volatility_modifiers: [
        { tags: ["collectible", "investment"], match: "all", adjustment: 50, description: "Investors very nervous about collectibles" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["entertainment"], resource: ["collectible"] }, match: "any", multiplier: 3.0, description: "Desperate collectors dumping inventory" }
      ]
    }
  },
  {
    name: "Coffee Rust Epidemic",
    description: "A fungus just declared war on coffee plants across Central America. Caffeine addicts worldwide are having a collective meltdown. Prices are spiking faster than your heart rate after that fourth espresso, and baristas are now qualified for hazard pay.",
    event_type: "weather",
    severity: 4,
    rarity: "rare",
    duration: 5,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "consumable"], match: "all", multiplier: 3.0, description: "Coffee prices going absolutely insane" }
      ],
      availability_modifiers: [
        { tags: ["food", "perishable"], match: "all", multiplier: 0.4, description: "Coffee supplies critically low" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["tech_hub", "hipster"], resource: ["food"] }, match: "any", multiplier: 3.5, description: "Coffee-dependent cities in crisis" }
      ]
    }
  },
  {
    name: "Wine Fraud Scandal",
    description: "That $10,000 Bordeaux you bought? Bottled last Tuesday in a New Jersey warehouse. A massive counterfeit wine ring just got busted, and collectors are discovering their cellars are full of expensive vinegar. Trust in the wine market: destroyed. Insurance claims: incoming.",
    event_type: "cultural",
    severity: 3,
    rarity: "rare",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["alcohol"], match: "any", multiplier: 0.7, description: "Wine market credibility tanking" },
        { tags: ["investment", "antique"], match: "all", multiplier: 1.3, description: "Authenticated items gaining premium" }
      ],
      volatility_modifiers: [
        { tags: ["alcohol"], match: "any", adjustment: 55, description: "Wine prices wildly unpredictable" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["wealthy"], resource: ["alcohol"] }, match: "any", multiplier: 0.5, description: "Wealthy wine cellars under suspicion" }
      ]
    }
  },
  {
    name: "Precious Metal Smuggling Ring",
    description: "Customs just broke up an international gold smuggling operation. Ports are locked down, metal shipments are stuck in inspection limbo, and the precious metals market is having an identity crisis. Your gold coins suddenly need a lot more paperwork.",
    event_type: "political",
    severity: 3,
    rarity: "rare",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["precious_metal"], match: "any", multiplier: 1.8, description: "Supply crunch driving prices up" }
      ],
      availability_modifiers: [
        { tags: ["precious_metal", "compact"], match: "all", multiplier: 0.5, description: "Legitimate supplies tangled in red tape" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["port_city"], resource: ["precious_metal"] }, match: "any", multiplier: 0.3, description: "Port cities under heavy scrutiny" }
      ]
    }
  },
  {
    name: "Fashion Week Frenzy",
    description: "Paris, Milan, and New York just set the runways on fire—figuratively, this time. The fashion world is losing its mind over this season's must-haves, and luxury goods are flying off shelves faster than you can say 'limited edition.' Your basic wardrobe just became extremely unfashionable.",
    event_type: "cultural",
    severity: 3,
    rarity: "rare",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["luxury_fashion"], match: "any", multiplier: 2.0, description: "Luxury fashion in peak demand" },
        { tags: ["artisan", "european_origin"], match: "all", multiplier: 1.6, description: "European artisan goods trending hard" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["art_culture", "wealthy"], resource: ["luxury_fashion"] }, match: "any", multiplier: 2.5, description: "Fashion capitals seeing insane markups" }
      ]
    }
  },
  {
    name: "West Coast Port Strike",
    description: "Dock workers just remembered they have leverage. All West Coast ports are at a standstill, container ships are playing parking lot in the Pacific, and your imported goods are enjoying an extended ocean vacation. Supply chains? More like supply pains.",
    event_type: "political",
    severity: 4,
    rarity: "rare",
    duration: 5,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["asian_origin"], match: "any", multiplier: 2.2, description: "Asian imports stuck at sea" },
        { tags: ["bulky"], match: "any", multiplier: 1.8, description: "Large items completely backed up" }
      ],
      availability_modifiers: [
        { tags: ["fragile"], match: "any", multiplier: 0.4, description: "Delicate shipments indefinitely delayed" }
      ]
    },
    location_effects: {
      access_restrictions: [
        { scoped_tags: { location: ["port_city", "western"] }, match: "all", blocked: true, description: "West Coast ports completely shut down" }
      ]
    }
  },
  {
    name: "Diamond Cartel Collapse",
    description: "The diamond industry's price-fixing scheme just got exposed, and it turns out diamonds aren't as rare as DeBeers claimed. Shocking, we know. Gemstone values are plummeting as people realize they've been played for decades. Engagement ring budgets just got a reality check.",
    event_type: "market",
    severity: 3,
    rarity: "rare",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["gemstone"], match: "any", multiplier: 0.6, description: "Diamond bubble bursting spectacularly" },
        { tags: ["investment"], match: "any", multiplier: 1.3, description: "Investors fleeing to real assets" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["wealthy", "financial_center"], resource: ["gemstone"] }, match: "any", multiplier: 0.4, description: "Wealthy panic-selling their rocks" }
      ]
    }
  },
  {
    name: "Truffle Season Boom",
    description: "This year's truffle harvest is legendary. Italian truffle hunters and their dogs are finding white gold everywhere, and high-end restaurants are in a bidding war. If you're holding truffles, you're basically holding edible currency. Act fast before they go bad.",
    event_type: "weather",
    severity: 3,
    rarity: "rare",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "perishable"], match: "all", multiplier: 2.5, description: "Premium perishables in extreme demand" },
        { tags: ["artisan", "european_origin"], match: "all", multiplier: 1.8, description: "European artisan foods having a moment" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["wealthy"], resource: ["food"] }, match: "any", multiplier: 2.0, description: "Rich people buying up all the fancy food" }
      ]
    }
  },
  {
    name: "Vegas Lucky Streak",
    description: "Somebody just broke the house at every major casino on the Strip. High rollers are flooding Vegas, luxury goods are flying off shelves, and there's more gold jewelry changing hands than at a royal wedding. What happens in Vegas... drives markets into a frenzy.",
    event_type: "cultural",
    severity: 3,
    rarity: "rare",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["precious_metal", "luxury_fashion"], match: "any", multiplier: 1.7, description: "Winners buying everything expensive" },
        { tags: ["collectible"], match: "any", multiplier: 1.5, description: "Gamblers feeling lucky on collectibles" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["gambling", "entertainment"], resource: ["luxury_market"] }, match: "any", multiplier: 2.2, description: "Vegas luxury markets going wild" }
      ]
    }
  },
  {
    name: "Sneaker Raffle Madness",
    description: "Limited edition Jordans just dropped, and the sneakerhead community has achieved new levels of obsession. People are camping outside stores, bots are crashing websites, and resale prices are more inflated than the shoes' hype. Welcome to late-stage capitalism, footwear edition.",
    event_type: "cultural",
    severity: 3,
    rarity: "rare",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["luxury_fashion"], match: "any", multiplier: 2.0, description: "Limited edition fashion items spiking" },
        { tags: ["collectible"], match: "any", multiplier: 1.6, description: "Collectible fashion through the roof" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["tech_hub", "entertainment"], resource: ["luxury_fashion"] }, match: "any", multiplier: 2.5, description: "Urban sneaker markets absolutely insane" }
      ]
    }
  }
]

# UNCOMMON EVENTS (15 total)
# Notable market shifts
uncommon_events = [
  {
    name: "Vintage Watch Expo",
    description: "Horology nerds unite! The annual watch convention just turned the timepiece market into a competitive sport. Collectors are throwing money at anything with gears and a fancy Swiss name.",
    event_type: "cultural",
    severity: 2,
    rarity: "uncommon",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["timepiece"], match: "any", multiplier: 1.6, description: "Watch collectors in bidding wars" },
        { tags: ["antique", "investment"], match: "all", multiplier: 1.4, description: "Vintage collectibles gaining value" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Saffron Harvest",
    description: "The world's most expensive spice by weight just flooded markets. Crocus flowers are being plucked at record rates, and saffron prices are actually affordable for thirty seconds before restaurants buy it all.",
    event_type: "weather",
    severity: 2,
    rarity: "uncommon",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "consumable"], match: "all", multiplier: 0.7, description: "Premium spices temporarily cheaper" }
      ],
      availability_modifiers: [
        { tags: ["artisan"], match: "any", multiplier: 1.8, description: "Artisan foods more available" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Comic-Con Chaos",
    description: "Nerds descend upon the convention center armed with credit cards and poor impulse control. Limited edition comics and collectibles are changing hands faster than Superman in a phone booth.",
    event_type: "cultural",
    severity: 2,
    rarity: "uncommon",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["collectible"], match: "any", multiplier: 1.8, description: "Collectibles markets going ballistic" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["entertainment"], resource: ["collectible"] }, match: "any", multiplier: 2.2, description: "Convention cities seeing massive markup" }
      ]
    }
  },
  {
    name: "Whisky Auction Record",
    description: "A single bottle of Macallan just sold for the price of a house. The whisky world is losing its collective mind, and aged spirits are suddenly better investments than actual stocks.",
    event_type: "market",
    severity: 3,
    rarity: "uncommon",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["alcohol"], match: "any", multiplier: 1.7, description: "Aged spirits market going crazy" },
        { tags: ["investment", "antique"], match: "all", multiplier: 1.5, description: "Vintage collectibles surging" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Tech Conference Season",
    description: "Silicon Valley's annual parade of buzzwords is in full swing. Tech bros are networking, startups are pitching, and gadget prices are fluctuating based on which CEO said what on stage.",
    event_type: "cultural",
    severity: 2,
    rarity: "uncommon",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["technology"], match: "any", multiplier: 1.4, description: "Tech hype driving prices up" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["tech_hub"], resource: ["technology"] }, match: "any", multiplier: 1.8, description: "Tech hubs flooded with new gadgets" }
      ]
    }
  },
  {
    name: "Gemstone Strike",
    description: "Miners just discovered a new deposit of rare gemstones. Geologists are excited, jewelers are scrambling, and your investment-grade gems just got some competition.",
    event_type: "weather",
    severity: 2,
    rarity: "uncommon",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["gemstone"], match: "any", multiplier: 0.8, description: "New supply pushing prices down" }
      ],
      availability_modifiers: [
        { tags: ["gemstone", "investment"], match: "all", multiplier: 1.5, description: "More investment gems on market" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Luxury Import Tariff",
    description: "The government just remembered it can tax expensive foreign stuff. Luxury goods from overseas are about to get a lot pricier, and smugglers are quietly updating their price lists.",
    event_type: "political",
    severity: 3,
    rarity: "uncommon",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["luxury_fashion", "european_origin"], match: "any", multiplier: 1.6, description: "Import duties driving up foreign luxury goods" },
        { tags: ["asian_origin"], match: "any", multiplier: 1.4, description: "Asian imports hit with tariffs" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["port_city"], resource: ["luxury_market"] }, match: "any", multiplier: 1.8, description: "Port cities passing on tariff costs" }
      ]
    }
  },
  {
    name: "Antiques Roadshow Frenzy",
    description: "That show where people discover grandma's attic junk is worth millions just aired a legendary episode. Antique stores are being mobbed by people convinced their trash is treasure.",
    event_type: "cultural",
    severity: 2,
    rarity: "uncommon",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["antique", "collectible"], match: "any", multiplier: 1.5, description: "Antiques suddenly trendy again" }
      ],
      availability_modifiers: [
        { tags: ["antique"], match: "any", multiplier: 2.0, description: "Everyone cleaning out their attics" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Chocolate Festival",
    description: "The annual chocolate festival is turning the town into Willy Wonka's fever dream. Artisan chocolate makers are showing off, and sugar addicts are maxing out credit cards.",
    event_type: "cultural",
    severity: 2,
    rarity: "uncommon",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "consumable"], match: "all", multiplier: 1.4, description: "Premium chocolate in high demand" },
        { tags: ["artisan"], match: "any", multiplier: 1.3, description: "Artisan foods getting premium treatment" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Gold Rush Rumors",
    description: "Someone found a gold nugget the size of their fist, and now everyone thinks they're going to strike it rich. Precious metals are flying off shelves as amateur prospectors gear up.",
    event_type: "market",
    severity: 2,
    rarity: "uncommon",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["precious_metal"], match: "any", multiplier: 1.5, description: "Gold fever driving prices up" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Museum Gala",
    description: "The art world's fanciest party is happening, and wealthy collectors are one-upping each other with increasingly ridiculous purchases. Your artisan and antique items just became status symbols.",
    event_type: "cultural",
    severity: 3,
    rarity: "uncommon",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["antique", "artisan"], match: "any", multiplier: 1.6, description: "Cultural pieces in demand at gala" },
        { tags: ["investment"], match: "any", multiplier: 1.4, description: "Wealthy showing off with investments" }
      ]
    },
    location_effects: {
      price_modifiers: [
        { scoped_tags: { location: ["art_culture", "wealthy"], resource: ["antique"] }, match: "any", multiplier: 2.0, description: "Cultural centers seeing bidding wars" }
      ]
    }
  },
  {
    name: "Electronics Recall",
    description: "A major tech company just discovered their flagship product occasionally catches fire. Recalls are in progress, lawyers are circling, and tech prices are about to get weird.",
    event_type: "political",
    severity: 2,
    rarity: "uncommon",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["technology"], match: "any", multiplier: 0.7, description: "Tech sector losing consumer confidence" }
      ],
      volatility_modifiers: [
        { tags: ["technology"], match: "any", adjustment: 40, description: "Tech prices all over the place" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Caviar Export Ban",
    description: "A major caviar-producing country just banned exports because of 'sustainability concerns.' Translation: they want to keep all the fancy fish eggs for themselves. Prices are about to get stupid.",
    event_type: "political",
    severity: 3,
    rarity: "uncommon",
    duration: 4,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "perishable"], match: "all", multiplier: 2.5, description: "Luxury seafood prices skyrocketing" }
      ],
      availability_modifiers: [
        { tags: ["food", "consumable"], match: "all", multiplier: 0.5, description: "Premium foods suddenly scarce" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Designer Perfume Launch",
    description: "A celebrity just released a signature fragrance, and their fans are convinced they need to smell like their idol. Perfume counters are battlegrounds, and fragrance prices are getting ridiculous.",
    event_type: "cultural",
    severity: 2,
    rarity: "uncommon",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["consumable"], match: "any", multiplier: 1.5, description: "Luxury consumables trending hard" }
      ]
    },
    location_effects: {
      quantity_modifiers: [
        { scoped_tags: { location: ["wealthy"], resource: ["consumable"] }, match: "any", multiplier: 0.6, description: "Wealthy areas selling out of fragrances" }
      ]
    }
  },
  {
    name: "Philately Convention",
    description: "Stamp collectors gather for their annual celebration of tiny adhesive rectangles. Rare stamps are trading hands, and postal history nerds are having the time of their lives.",
    event_type: "cultural",
    severity: 2,
    rarity: "uncommon",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["collectible", "compact"], match: "all", multiplier: 1.6, description: "Small collectibles highly sought after" },
        { tags: ["antique"], match: "any", multiplier: 1.3, description: "Vintage items gaining interest" }
      ]
    },
    location_effects: {}
  }
]

# COMMON EVENTS (15 total)
# Minor market fluctuations
common_events = [
  {
    name: "Weekend Farmers Market",
    description: "Local farmers brought their A-game this week. Fresh produce, artisan goods, and people paying $12 for organic kale they could grow in their backyard.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "artisan"], match: "any", multiplier: 1.2, description: "Fresh artisan foods slightly pricier" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Rainy Day Sales",
    description: "Weather's terrible, so retailers are slashing prices to get people in the door. Your loss is literally their gain... wait, that's not how that saying goes.",
    event_type: "weather",
    severity: 1,
    rarity: "common",
    duration: 1,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["luxury_fashion"], match: "any", multiplier: 0.85, description: "Retail discounts to drive foot traffic" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Artisan Coffee Promotion",
    description: "Local coffee shops are competing for 'best pour-over' bragging rights. Premium beans are flowing, and caffeine addicts are in heaven.",
    event_type: "market",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "consumable"], match: "all", multiplier: 1.15, description: "Premium coffee beans in demand" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Neighborhood Garage Sales",
    description: "Entire suburbs are cleaning out their garages. One person's junk is another person's treasure, and everyone's convinced they're on the treasure side of that equation.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["collectible", "antique"], match: "any", multiplier: 0.9, description: "Market flooded with random old stuff" }
      ],
      availability_modifiers: [
        { tags: ["collectible"], match: "any", multiplier: 1.6, description: "More garage sale finds available" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Jewelry Store Anniversary",
    description: "A local jewelry store is celebrating decades in business by marking up diamonds and calling it a 'sale.' People are actually falling for it.",
    event_type: "market",
    severity: 1,
    rarity: "common",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["gemstone", "precious_metal"], match: "any", multiplier: 1.1, description: "'Anniversary pricing' (aka regular prices)" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Flea Market Weekend",
    description: "The monthly flea market is back, and treasure hunters are ready to haggle over everything. Bring cash, bring patience, bring your poker face.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["antique", "collectible"], match: "any", multiplier: 0.95, description: "Flea market bargaining in full effect" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Summer Heat Wave",
    description: "It's hot enough to fry an egg on the sidewalk. Perishables are perishing faster than usual, and everyone's AC bill just doubled.",
    event_type: "weather",
    severity: 2,
    rarity: "common",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["perishable"], match: "any", multiplier: 1.3, description: "Heat affecting perishable goods" }
      ],
      availability_modifiers: [
        { tags: ["perishable", "food"], match: "all", multiplier: 0.8, description: "Spoilage reducing available supply" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Independent Bookstore Fair",
    description: "Book lovers unite for a celebration of the printed word. First editions are changing hands, and literary nerds are in their element.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["antique", "collectible"], match: "all", multiplier: 1.25, description: "Rare books getting premium attention" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Wine Tasting Circuit",
    description: "Local wineries are showing off their latest vintages. Wine snobs are swirling, sniffing, and pretending they can taste the terroir.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["alcohol"], match: "any", multiplier: 1.2, description: "Wine tourism driving up prices" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Electronics Clearance",
    description: "Last year's model is this year's discount. Tech stores are clearing inventory, and bargain hunters are circling like sharks.",
    event_type: "market",
    severity: 1,
    rarity: "common",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["technology"], match: "any", multiplier: 0.8, description: "Last season's tech on clearance" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Holiday Shopping Season",
    description: "The annual ritual of buying stuff people don't need with money they don't have. Retailers love it, wallets hate it.",
    event_type: "cultural",
    severity: 2,
    rarity: "common",
    duration: 3,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["luxury_fashion", "consumable"], match: "any", multiplier: 1.3, description: "Holiday markup in full swing" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Organic Produce Bounty",
    description: "Farmers markets are overflowing with organic everything. Hipsters and health nuts are fighting over heirloom tomatoes.",
    event_type: "weather",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "perishable"], match: "all", multiplier: 0.9, description: "Abundant harvest lowering prices" }
      ],
      availability_modifiers: [
        { tags: ["food", "artisan"], match: "any", multiplier: 1.4, description: "More artisan foods available" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Numismatic Show",
    description: "Coin collectors gather to geek out over small metal circles. Rare coins are trading, and everyone's brought their magnifying glasses.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["collectible", "compact"], match: "all", multiplier: 1.3, description: "Coin collecting enthusiasm up" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Community Yard Sale Day",
    description: "Neighborhoods coordinate the ultimate treasure hunt. Someone's vintage lamp could be your next living room centerpiece.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 1,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["collectible"], match: "any", multiplier: 0.85, description: "Yard sale bargains everywhere" }
      ],
      availability_modifiers: [
        { tags: ["bulky"], match: "any", multiplier: 1.5, description: "People offloading big items" }
      ]
    },
    location_effects: {}
  },
  {
    name: "Tea Ceremony Exhibition",
    description: "Traditional tea ceremonies are being demonstrated, and tea enthusiasts are taking notes. Premium loose leaf is moving fast.",
    event_type: "cultural",
    severity: 1,
    rarity: "common",
    duration: 2,
    day_start: nil,
    active: false,
    resource_effects: {
      price_modifiers: [
        { tags: ["food", "consumable"], match: "all", multiplier: 1.2, description: "Premium tea getting attention" },
        { tags: ["asian_origin"], match: "any", multiplier: 1.15, description: "Asian goods trending" }
      ]
    },
    location_effects: {}
  }
]

# Helper method to create or update events
def create_or_update_event(attrs)
  event = Event.find_or_initialize_by(name: attrs[:name])
  was_new = event.new_record?
  event.update!(attrs)
  was_new
end

# Create or update all events
total_created = 0
total_updated = 0

puts "\nCreating/updating Exceptional events (5)..."
exceptional_events.each do |attrs|
  if create_or_update_event(attrs)
    total_created += 1
  else
    total_updated += 1
  end
  print "."
end

puts "\n\nCreating/updating Ultra Rare events (5)..."
ultra_rare_events.each do |attrs|
  if create_or_update_event(attrs)
    total_created += 1
  else
    total_updated += 1
  end
  print "."
end

puts "\n\nCreating/updating Rare events (10)..."
rare_events.each do |attrs|
  if create_or_update_event(attrs)
    total_created += 1
  else
    total_updated += 1
  end
  print "."
end

puts "\n\nCreating/updating Uncommon events (15)..."
uncommon_events.each do |attrs|
  if create_or_update_event(attrs)
    total_created += 1
  else
    total_updated += 1
  end
  print "."
end

puts "\n\nCreating/updating Common events (15)..."
common_events.each do |attrs|
  if create_or_update_event(attrs)
    total_created += 1
  else
    total_updated += 1
  end
  print "."
end

puts "\n\n✓ Successfully processed #{total_created + total_updated} events!"
puts "  Created: #{total_created}"
puts "  Updated: #{total_updated}" if total_updated > 0

puts "\nBreakdown by rarity:"
puts "  Exceptional: #{Event.by_rarity('exceptional').count}"
puts "  Ultra Rare: #{Event.by_rarity('ultra_rare').count}"
puts "  Rare: #{Event.by_rarity('rare').count}"
puts "  Uncommon: #{Event.by_rarity('uncommon').count}"
puts "  Common: #{Event.by_rarity('common').count}"

puts "\nBreakdown by type:"
puts "  Market: #{Event.by_type('market').count}"
puts "  Weather: #{Event.by_type('weather').count}"
puts "  Political: #{Event.by_type('political').count}"
puts "  Cultural: #{Event.by_type('cultural').count}"

puts "\n✓ Game events setup complete!"
