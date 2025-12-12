# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Setting up game resources..."

# Clear existing resources to ensure clean seed
Resource.destroy_all

# EXCEPTIONAL RESOURCES (5 total)
# Ultra-rare, historically significant items worth $50,000 - $500,000+
exceptional_resources = [
  {
    name: "Gutenberg Bible Page",
    description: "Authentic page from the 15th century Gutenberg Bible, one of the first books printed with movable type.",
    base_price_min: 80000,
    base_price_max: 250000,
    price_volatility: 30,
    inventory_size: 1,
    rarity: "exceptional",
    tag_names: ["antique", "collectible", "fragile", "compact", "investment", "european_origin"]
  },
  {
    name: "Pre-Revolution Gold Sovereign",
    description: "Rare imperial Russian gold coin from before the 1917 revolution, highly sought by collectors.",
    base_price_min: 50000,
    base_price_max: 150000,
    price_volatility: 35,
    inventory_size: 1,
    rarity: "exceptional",
    tag_names: ["precious_metal", "collectible", "compact", "investment", "european_origin", "antique"]
  },
  {
    name: "Stradivarius Violin Bow",
    description: "Authentic bow crafted by Antonio Stradivari, portable masterpiece of instrument making.",
    base_price_min: 100000,
    base_price_max: 300000,
    price_volatility: 25,
    inventory_size: 2,
    rarity: "exceptional",
    tag_names: ["antique", "fragile", "artisan", "investment", "european_origin"]
  },
  {
    name: "T206 Honus Wagner Card",
    description: "The 'Mona Lisa' of baseball cards, one of the rarest and most valuable trading cards ever produced.",
    base_price_min: 150000,
    base_price_max: 500000,
    price_volatility: 40,
    inventory_size: 1,
    rarity: "exceptional",
    tag_names: ["collectible", "compact", "fragile", "investment", "antique"]
  },
  {
    name: "Moldavite Crystal",
    description: "Rare tektite formed by ancient meteor impact, found only in the Czech Republic. Deep green gem-quality specimen.",
    base_price_min: 60000,
    base_price_max: 180000,
    price_volatility: 35,
    inventory_size: 1,
    rarity: "exceptional",
    tag_names: ["gemstone", "compact", "fragile", "investment", "european_origin"]
  }
]

# ULTRA RARE RESOURCES (5 total)
# Extremely valuable, hard to find items worth $10,000 - $50,000
ultra_rare_resources = [
  {
    name: "First Edition Darwin's Origin",
    description: "Original 1859 first edition of 'On the Origin of Species', one of science's most important books.",
    base_price_min: 15000,
    base_price_max: 45000,
    price_volatility: 30,
    inventory_size: 2,
    rarity: "ultra_rare",
    tag_names: ["antique", "collectible", "fragile", "investment", "european_origin"]
  },
  {
    name: "Fabergé Egg Fragment",
    description: "Authenticated piece from an Imperial Russian Fabergé egg, ornate and historically significant.",
    base_price_min: 25000,
    base_price_max: 50000,
    price_volatility: 35,
    inventory_size: 1,
    rarity: "ultra_rare",
    tag_names: ["antique", "fragile", "compact", "artisan", "investment", "european_origin"]
  },
  {
    name: "Black Lotus Magic Card",
    description: "Alpha edition Black Lotus from Magic: The Gathering, the most iconic collectible card game card.",
    base_price_min: 30000,
    base_price_max: 50000,
    price_volatility: 40,
    inventory_size: 1,
    rarity: "ultra_rare",
    tag_names: ["collectible", "compact", "fragile", "investment"]
  },
  {
    name: "Jadeite Imperial Jade",
    description: "Top-grade Burmese jadeite in coveted 'imperial green' color, highly prized in Asian markets.",
    base_price_min: 20000,
    base_price_max: 45000,
    price_volatility: 35,
    inventory_size: 1,
    rarity: "ultra_rare",
    tag_names: ["gemstone", "compact", "investment", "asian_origin", "artisan"]
  },
  {
    name: "Pink Star Diamond",
    description: "Flawless fancy vivid pink diamond, among the rarest colored diamonds. Small carat weight.",
    base_price_min: 35000,
    base_price_max: 50000,
    price_volatility: 30,
    inventory_size: 1,
    rarity: "ultra_rare",
    tag_names: ["gemstone", "compact", "investment"]
  }
]

# RARE RESOURCES (10 total)
# Highly sought-after commodities worth $1,000 - $10,000
rare_resources = [
  {
    name: "Saffron Threads",
    description: "World's most expensive spice by weight, hand-harvested from crocus flowers. Premium grade.",
    base_price_min: 2000,
    base_price_max: 5000,
    price_volatility: 45,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["food", "compact", "perishable", "consumable", "artisan"]
  },
  {
    name: "Matsutake Mushrooms",
    description: "Rare Japanese delicacy mushroom, highly aromatic and prized in high-end cuisine.",
    base_price_min: 1500,
    base_price_max: 4000,
    price_volatility: 60,
    inventory_size: 2,
    rarity: "rare",
    tag_names: ["food", "perishable", "consumable", "asian_origin"]
  },
  {
    name: "Vintage Rolex Daytona",
    description: "Pre-1988 Paul Newman model Rolex Daytona, highly collectible chronograph watch.",
    base_price_min: 5000,
    base_price_max: 10000,
    price_volatility: 35,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["timepiece", "compact", "investment", "antique", "european_origin"]
  },
  {
    name: "Ambergris",
    description: "Rare whale digestive secretion used in luxury perfumes, found floating in ocean or on beaches.",
    base_price_min: 3000,
    base_price_max: 8000,
    price_volatility: 50,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["compact", "fragile"]
  },
  {
    name: "White Truffles",
    description: "Alba white truffles from Italy, the diamond of the kitchen. Extremely seasonal and aromatic.",
    base_price_min: 2500,
    base_price_max: 6000,
    price_volatility: 65,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["food", "perishable", "compact", "consumable", "european_origin"]
  },
  {
    name: "Patek Philippe Watch",
    description: "Vintage Calatrava or Nautilus model from the prestigious Swiss watchmaker.",
    base_price_min: 6000,
    base_price_max: 10000,
    price_volatility: 30,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["timepiece", "compact", "investment", "antique", "european_origin"]
  },
  {
    name: "First Edition Hemingway",
    description: "Signed first edition of a Hemingway novel, authenticated and in excellent condition.",
    base_price_min: 3500,
    base_price_max: 8000,
    price_volatility: 40,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["antique", "collectible", "fragile", "compact", "investment"]
  },
  {
    name: "Rhodium Bars",
    description: "Small bars of rhodium, the rarest and most expensive precious metal, used in catalytic converters.",
    base_price_min: 4000,
    base_price_max: 9000,
    price_volatility: 55,
    inventory_size: 2,
    rarity: "rare",
    tag_names: ["precious_metal", "investment", "compact"]
  },
  {
    name: "Action Comics #1 Reprint",
    description: "Early reprint of the comic that introduced Superman, still valuable to collectors.",
    base_price_min: 2000,
    base_price_max: 5000,
    price_volatility: 45,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["collectible", "compact", "fragile", "antique"]
  },
  {
    name: "Meteorite Fragments",
    description: "Authenticated space rocks with documented fall location, popular with collectors.",
    base_price_min: 1800,
    base_price_max: 4500,
    price_volatility: 50,
    inventory_size: 1,
    rarity: "rare",
    tag_names: ["gemstone", "collectible", "compact", "investment"]
  }
]

# UNCOMMON RESOURCES (20 total)
# Valuable and tradeable items worth $100 - $1,000
uncommon_resources = [
  {
    name: "Cuban Cigars",
    description: "Pre-embargo Cohiba Behike cigars, considered among the finest in the world.",
    base_price_min: 300,
    base_price_max: 900,
    price_volatility: 40,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["consumable", "antique"]
  },
  {
    name: "Vintage Whisky",
    description: "30+ year old single malt Scotch whisky in original bottle, highly collectible.",
    base_price_min: 400,
    base_price_max: 1000,
    price_volatility: 35,
    inventory_size: 3,
    rarity: "uncommon",
    tag_names: ["alcohol", "consumable", "fragile", "antique", "investment", "european_origin"]
  },
  {
    name: "Kopi Luwak Coffee",
    description: "Luxury coffee beans processed through civet digestion, one of world's most expensive coffees.",
    base_price_min: 250,
    base_price_max: 700,
    price_volatility: 45,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["food", "consumable", "perishable", "asian_origin", "artisan"]
  },
  {
    name: "Beluga Caviar",
    description: "Premium Russian sturgeon roe, the most prized type of caviar among connoisseurs.",
    base_price_min: 350,
    base_price_max: 850,
    price_volatility: 50,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["food", "perishable", "consumable", "european_origin"]
  },
  {
    name: "Pokemon First Edition Charizard",
    description: "Shadowless base set first edition Charizard card, highly sought by collectors.",
    base_price_min: 500,
    base_price_max: 1000,
    price_volatility: 55,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["collectible", "compact", "fragile", "investment"]
  },
  {
    name: "Gold Krugerrands",
    description: "South African 1oz gold coins, one of the most traded gold bullion coins worldwide.",
    base_price_min: 600,
    base_price_max: 950,
    price_volatility: 25,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["precious_metal", "compact", "investment"]
  },
  {
    name: "Vintage Cartier Watch",
    description: "Classic Tank or Santos model from Cartier, timeless luxury timepiece.",
    base_price_min: 450,
    base_price_max: 900,
    price_volatility: 30,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["timepiece", "compact", "investment", "antique", "european_origin", "luxury_fashion"]
  },
  {
    name: "Hermès Birkin Bag",
    description: "Mini or small Hermès Birkin in exotic leather, ultra-luxury handbag.",
    base_price_min: 800,
    base_price_max: 1000,
    price_volatility: 35,
    inventory_size: 5,
    rarity: "uncommon",
    tag_names: ["luxury_fashion", "bulky", "artisan", "investment", "european_origin"]
  },
  {
    name: "Swiss Luxury Chocolate",
    description: "To'ak or Amedei limited edition bars, among world's finest and most expensive chocolate.",
    base_price_min: 150,
    base_price_max: 500,
    price_volatility: 40,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["food", "consumable", "perishable", "artisan", "european_origin"]
  },
  {
    name: "Japanese Wagyu Beef",
    description: "A5 grade wagyu, cured and dried for transport. The highest quality beef in the world.",
    base_price_min: 300,
    base_price_max: 750,
    price_volatility: 45,
    inventory_size: 3,
    rarity: "uncommon",
    tag_names: ["food", "perishable", "consumable", "asian_origin", "artisan"]
  },
  {
    name: "Antique Fountain Pens",
    description: "Vintage Montblanc or Parker fountain pens from early 20th century, collectible writing instruments.",
    base_price_min: 200,
    base_price_max: 650,
    price_volatility: 40,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["antique", "collectible", "compact", "artisan", "european_origin"]
  },
  {
    name: "Vintage Camera Lenses",
    description: "Rare Leica or Canon L-series glass from the film era, prized by photographers.",
    base_price_min: 350,
    base_price_max: 800,
    price_volatility: 35,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["technology", "fragile", "antique", "collectible"]
  },
  {
    name: "Ming Dynasty Porcelain",
    description: "Small authenticated Ming dynasty ceramic piece, centuries-old Chinese artistry.",
    base_price_min: 600,
    base_price_max: 1000,
    price_volatility: 45,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["antique", "fragile", "artisan", "investment", "asian_origin"]
  },
  {
    name: "Tibetan Prayer Beads",
    description: "Antique dzi beads from Tibet, believed to bring good fortune and protection.",
    base_price_min: 400,
    base_price_max: 900,
    price_volatility: 50,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["antique", "compact", "artisan", "asian_origin"]
  },
  {
    name: "Vintage Rolex Submariner",
    description: "Pre-1970s Rolex Submariner diving watch, iconic and highly collectible.",
    base_price_min: 700,
    base_price_max: 1000,
    price_volatility: 30,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["timepiece", "compact", "investment", "antique", "european_origin"]
  },
  {
    name: "First Pressing Vinyl",
    description: "Original first pressing vinyl records from Beatles, Dylan, or other legendary artists.",
    base_price_min: 250,
    base_price_max: 700,
    price_volatility: 45,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["collectible", "fragile", "antique"]
  },
  {
    name: "Amber with Inclusions",
    description: "Baltic amber containing prehistoric insect or plant inclusions, millions of years old.",
    base_price_min: 300,
    base_price_max: 750,
    price_volatility: 40,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["gemstone", "compact", "fragile", "antique", "investment", "european_origin"]
  },
  {
    name: "Antique Ivory",
    description: "Pre-ban antique ivory pieces with full provenance documentation, legal to trade.",
    base_price_min: 500,
    base_price_max: 950,
    price_volatility: 55,
    inventory_size: 2,
    rarity: "uncommon",
    tag_names: ["antique", "fragile", "collectible", "investment"]
  },
  {
    name: "Signed Sports Jerseys",
    description: "Game-worn and authenticated jerseys signed by legendary athletes.",
    base_price_min: 350,
    base_price_max: 850,
    price_volatility: 50,
    inventory_size: 4,
    rarity: "uncommon",
    tag_names: ["collectible", "bulky", "antique"]
  },
  {
    name: "Rare Gemstones",
    description: "Alexandrite, padparadscha sapphire, or other rare colored gemstones in small sizes.",
    base_price_min: 450,
    base_price_max: 900,
    price_volatility: 45,
    inventory_size: 1,
    rarity: "uncommon",
    tag_names: ["gemstone", "compact", "investment"]
  }
]

# COMMON RESOURCES (30 total)
# Basic tradeable goods worth $50 - $500
common_resources = [
  {
    name: "Premium Coffee Beans",
    description: "Jamaican Blue Mountain coffee beans, smooth and highly regarded by coffee enthusiasts.",
    base_price_min: 80,
    base_price_max: 250,
    price_volatility: 50,
    inventory_size: 3,
    rarity: "common",
    tag_names: ["food", "consumable", "perishable"]
  },
  {
    name: "Premium Tobacco",
    description: "High-quality pipe tobacco or premium cigar tobacco leaves.",
    base_price_min: 60,
    base_price_max: 200,
    price_volatility: 45,
    inventory_size: 3,
    rarity: "common",
    tag_names: ["consumable", "perishable"]
  },
  {
    name: "Vanilla Beans",
    description: "Madagascar bourbon vanilla beans, the gold standard for baking and cooking.",
    base_price_min: 100,
    base_price_max: 300,
    price_volatility: 60,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["food", "consumable", "perishable", "artisan"]
  },
  {
    name: "Pure Silk Fabric",
    description: "Chinese or Indian pure silk fabric by the yard, luxurious and versatile.",
    base_price_min: 70,
    base_price_max: 220,
    price_volatility: 40,
    inventory_size: 4,
    rarity: "common",
    tag_names: ["bulky", "artisan", "asian_origin"]
  },
  {
    name: "Luxury Perfume",
    description: "Chanel No. 5 or other prestigious fragrance house perfumes in full bottles.",
    base_price_min: 90,
    base_price_max: 280,
    price_volatility: 35,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["consumable", "fragile", "european_origin"]
  },
  {
    name: "Swiss Watches",
    description: "Entry luxury watches from brands like Tissot, Hamilton, or Longines.",
    base_price_min: 150,
    base_price_max: 450,
    price_volatility: 30,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["timepiece", "compact", "european_origin"]
  },
  {
    name: "Italian Leather Goods",
    description: "Fine Italian leather wallets, belts, and small accessories.",
    base_price_min: 80,
    base_price_max: 300,
    price_volatility: 40,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["luxury_fashion", "artisan", "european_origin"]
  },
  {
    name: "Designer Sunglasses",
    description: "Ray-Ban or Oakley limited edition sunglasses, fashionable and functional.",
    base_price_min: 100,
    base_price_max: 350,
    price_volatility: 45,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["luxury_fashion", "compact", "fragile"]
  },
  {
    name: "Rare Video Games",
    description: "Collectible cartridges like Earthbound, Chrono Trigger, or other sought-after titles.",
    base_price_min: 120,
    base_price_max: 400,
    price_volatility: 55,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["technology", "collectible", "compact"]
  },
  {
    name: "Silver Age Comics",
    description: "Marvel and DC comics from the Silver Age era (1956-1970), key issues in good condition.",
    base_price_min: 90,
    base_price_max: 320,
    price_volatility: 50,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["collectible", "compact", "fragile", "antique"]
  },
  {
    name: "Premium Tea",
    description: "Da Hong Pao or aged Pu-erh tea, highly prized by tea connoisseurs.",
    base_price_min: 75,
    base_price_max: 250,
    price_volatility: 55,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["food", "consumable", "perishable", "asian_origin", "artisan"]
  },
  {
    name: "Artisan Chocolate",
    description: "Valrhona or Amedei chocolate bars, premium cocoa for discerning palates.",
    base_price_min: 50,
    base_price_max: 180,
    price_volatility: 40,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["food", "consumable", "perishable", "artisan"]
  },
  {
    name: "Extra Virgin Olive Oil",
    description: "Estate-bottled extra virgin olive oil from prestigious Mediterranean groves.",
    base_price_min: 60,
    base_price_max: 200,
    price_volatility: 45,
    inventory_size: 4,
    rarity: "common",
    tag_names: ["food", "consumable", "bulky", "artisan", "european_origin"]
  },
  {
    name: "Aged Balsamic Vinegar",
    description: "Traditional balsamic vinegar aged 25+ years from Modena, Italy.",
    base_price_min: 85,
    base_price_max: 280,
    price_volatility: 40,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["food", "consumable", "fragile", "artisan", "european_origin"]
  },
  {
    name: "Champagne",
    description: "Dom Pérignon or Krug champagne bottles, prestigious French sparkling wine.",
    base_price_min: 120,
    base_price_max: 400,
    price_volatility: 35,
    inventory_size: 4,
    rarity: "common",
    tag_names: ["alcohol", "consumable", "fragile", "bulky", "european_origin"]
  },
  {
    name: "Limited Edition Sneakers",
    description: "Rare Nike or Air Jordan releases in deadstock condition, highly sought by sneakerheads.",
    base_price_min: 150,
    base_price_max: 500,
    price_volatility: 60,
    inventory_size: 5,
    rarity: "common",
    tag_names: ["luxury_fashion", "bulky", "collectible"]
  },
  {
    name: "Collectible Playing Cards",
    description: "Antique or limited run Bicycle playing cards, pristine sealed decks.",
    base_price_min: 50,
    base_price_max: 180,
    price_volatility: 50,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["collectible", "compact", "antique"]
  },
  {
    name: "Silver Coins",
    description: "American Silver Eagles or Canadian Silver Maple Leaf coins, pure silver bullion.",
    base_price_min: 100,
    base_price_max: 300,
    price_volatility: 30,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["precious_metal", "compact", "investment"]
  },
  {
    name: "Manuka Honey",
    description: "UMF 20+ Manuka honey from New Zealand, renowned for medicinal properties.",
    base_price_min: 70,
    base_price_max: 220,
    price_volatility: 40,
    inventory_size: 3,
    rarity: "common",
    tag_names: ["food", "consumable", "perishable"]
  },
  {
    name: "Cashmere",
    description: "Pure Mongolian cashmere scarves or small garments, incredibly soft and warm.",
    base_price_min: 90,
    base_price_max: 320,
    price_volatility: 35,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["luxury_fashion", "artisan", "asian_origin"]
  },
  {
    name: "Fine Wine",
    description: "Bordeaux or Burgundy grand cru bottles, highly collectible and age-worthy.",
    base_price_min: 130,
    base_price_max: 450,
    price_volatility: 40,
    inventory_size: 4,
    rarity: "common",
    tag_names: ["alcohol", "consumable", "fragile", "bulky", "investment", "european_origin"]
  },
  {
    name: "Vintage Sunglasses",
    description: "1960s Ray-Ban Wayfarers or Aviators in original condition, retro cool.",
    base_price_min: 80,
    base_price_max: 280,
    price_volatility: 45,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["luxury_fashion", "compact", "fragile", "antique"]
  },
  {
    name: "Antique Pocket Watches",
    description: "Victorian or Edwardian solid gold pocket watches in working condition.",
    base_price_min: 150,
    base_price_max: 480,
    price_volatility: 40,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["timepiece", "compact", "antique", "fragile", "investment", "european_origin"]
  },
  {
    name: "Rare Postage Stamps",
    description: "Early 20th century rare postage stamps in mint condition, philatelist treasures.",
    base_price_min: 100,
    base_price_max: 350,
    price_volatility: 50,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["collectible", "compact", "fragile", "antique"]
  },
  {
    name: "Collectible Coins",
    description: "Morgan silver dollars or other valuable older currency in good condition.",
    base_price_min: 75,
    base_price_max: 250,
    price_volatility: 45,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["collectible", "compact", "antique", "investment"]
  },
  {
    name: "Premium Electronics",
    description: "Latest flagship smartphones or premium headphones, brand new and sealed.",
    base_price_min: 200,
    base_price_max: 500,
    price_volatility: 55,
    inventory_size: 3,
    rarity: "common",
    tag_names: ["technology", "fragile"]
  },
  {
    name: "Pharmaceuticals",
    description: "Insulin, antibiotics, or other essential medications in legal trade scenario.",
    base_price_min: 110,
    base_price_max: 380,
    price_volatility: 50,
    inventory_size: 2,
    rarity: "common",
    tag_names: ["consumable", "perishable", "fragile"]
  },
  {
    name: "Premium Scotch Whisky",
    description: "Macallan 18 or Glenfiddich 21 year old single malt, standard premium offerings.",
    base_price_min: 140,
    base_price_max: 420,
    price_volatility: 35,
    inventory_size: 3,
    rarity: "common",
    tag_names: ["alcohol", "consumable", "fragile", "european_origin"]
  },
  {
    name: "Art Prints",
    description: "Limited edition signed lithographs from known artists, numbered and authenticated.",
    base_price_min: 120,
    base_price_max: 400,
    price_volatility: 45,
    inventory_size: 3,
    rarity: "common",
    tag_names: ["collectible", "fragile", "artisan"]
  },
  {
    name: "Jade Jewelry",
    description: "Nephrite or lower-grade jadeite jewelry pieces, carved pendants and bracelets.",
    base_price_min: 95,
    base_price_max: 330,
    price_volatility: 40,
    inventory_size: 1,
    rarity: "common",
    tag_names: ["gemstone", "compact", "fragile", "artisan", "asian_origin"]
  }
]

# Helper method to create resources with tags
def create_resource_with_tags(attrs)
  tag_names = attrs.delete(:tag_names) || []
  resource = Resource.create!(attrs)
  resource.tag_names = tag_names
  resource.save!
  resource
end

# Create all resources
total_created = 0

puts "\nCreating Exceptional resources (5)..."
exceptional_resources.each do |attrs|
  create_resource_with_tags(attrs)
  total_created += 1
  print "."
end

puts "\n\nCreating Ultra Rare resources (5)..."
ultra_rare_resources.each do |attrs|
  create_resource_with_tags(attrs)
  total_created += 1
  print "."
end

puts "\n\nCreating Rare resources (10)..."
rare_resources.each do |attrs|
  create_resource_with_tags(attrs)
  total_created += 1
  print "."
end

puts "\n\nCreating Uncommon resources (20)..."
uncommon_resources.each do |attrs|
  create_resource_with_tags(attrs)
  total_created += 1
  print "."
end

puts "\n\nCreating Common resources (30)..."
common_resources.each do |attrs|
  create_resource_with_tags(attrs)
  total_created += 1
  print "."
end

puts "\n\n✓ Successfully created #{total_created} resources!"
puts "\nBreakdown by rarity:"
puts "  Exceptional: #{Resource.exceptional.count}"
puts "  Ultra Rare: #{Resource.ultra_rare.count}"
puts "  Rare: #{Resource.rare.count}"
puts "  Uncommon: #{Resource.uncommon.count}"
puts "  Common: #{Resource.common.count}"
puts "\n✓ Game resources setup complete!"
