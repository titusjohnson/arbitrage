puts "Setting up game locations..."

# Top 30 US cities arranged geographically on a 6x5 grid
# Grid layout (x: 0-5 West to East, y: 0-4 North to South):
#
#   y=0 (North):  Seattle, Portland, Minneapolis, Detroit, Columbus, Baltimore
#   y=1:          San Francisco, Indianapolis, Denver, Chicago, Philadelphia, New York City
#   y=2 (Middle): Los Angeles, Las Vegas, Phoenix, Albuquerque, Dallas, Washington DC
#   y=3:          San Diego, Boston, El Paso, Austin, Houston, Charlotte
#   y=4 (South):  Nashville, Louisville, San Antonio, Fort Worth, Memphis, Jacksonville
#
# Note: We're simplifying US geography to fit a 6x5 grid.
# West Coast = x:0-1, Mountain/Southwest = x:2-3, Central = x:3-4, East Coast = x:4-5

cities = [
  # Row 0 (North)
  {
    name: "Seattle",
    description: "Rain, coffee, tech bros, and passive-aggressive politeness in perfect harmony.",
    population: 749_000,
    x: 0,
    y: 0,
    tag_names: ["tech_hub", "port_city", "hipster", "coastal", "western"]
  },
  {
    name: "Portland",
    description: "Where the dream of the '90s is alive, along with $18 toast and aggressive sustainability.",
    population: 635_000,
    x: 1,
    y: 0,
    tag_names: ["port_city", "hipster", "art_culture", "coastal", "western"]
  },
  {
    name: "Minneapolis",
    description: "Ten thousand lakes, Minnesota Nice passive aggression, and hotdish that's definitely just casserole.",
    population: 425_000,
    x: 2,
    y: 0,
    tag_names: ["landlocked", "agricultural"]
  },
  {
    name: "Detroit",
    description: "From Motor City to comeback city, now with more artisanal coffee than functioning street lights.",
    population: 639_000,
    x: 3,
    y: 0,
    tag_names: ["manufacturing", "landlocked"]
  },
  {
    name: "Columbus",
    description: "The most average American city, scientifically designed for market testing and mediocrity.",
    population: 906_000,
    x: 4,
    y: 0,
    tag_names: ["college_town", "landlocked"]
  },
  {
    name: "Baltimore",
    description: "Crab cakes, The Wire references, and an inexplicable obsession with Old Bay on everything.",
    population: 569_000,
    x: 5,
    y: 0,
    tag_names: ["port_city", "coastal", "northeastern"]
  },

  # Row 1
  {
    name: "San Francisco",
    description: "A $3,000 studio with a view of someone else's $5,000 studio, disruption not included.",
    population: 808_000,
    x: 0,
    y: 1,
    tag_names: ["tech_hub", "financial_center", "port_city", "wealthy", "hipster", "coastal", "western"]
  },
  {
    name: "Indianapolis",
    description: "Home of the Indy 500, where the most exciting thing is watching cars turn left for hours.",
    population: 882_000,
    x: 1,
    y: 1,
    tag_names: ["manufacturing", "landlocked"]
  },
  {
    name: "Denver",
    description: "Mile high in altitude and prices, where everyone hikes and has strong opinions about craft beer.",
    population: 716_000,
    x: 2,
    y: 1,
    tag_names: ["tech_hub", "hipster", "landlocked", "western"]
  },
  {
    name: "Chicago",
    description: "Where the wind is strong, the pizza is deep, and everyone's a Cubs or Sox fan (no in-between).",
    population: 2_665_000,
    x: 3,
    y: 1,
    tag_names: ["financial_center", "manufacturing", "port_city", "art_culture", "landlocked"]
  },
  {
    name: "Philadelphia",
    description: "Where throwing batteries at Santa is tradition and cheesesteaks are a food group.",
    population: 1_584_000,
    x: 4,
    y: 1,
    tag_names: ["port_city", "art_culture", "coastal", "northeastern"]
  },
  {
    name: "New York City",
    description: "Where a closet costs more than a mansion anywhere else, and pizza rats have better commutes than you.",
    population: 8_336_000,
    x: 5,
    y: 1,
    tag_names: ["financial_center", "port_city", "entertainment", "art_culture", "luxury_market", "wealthy", "tourist_destination", "coastal", "northeastern"]
  },

  # Row 2 (Middle)
  {
    name: "Los Angeles",
    description: "Two hours of traffic to go three miles, but at least you can see celebrities ignoring you.",
    population: 3_822_000,
    x: 0,
    y: 2,
    tag_names: ["entertainment", "tech_hub", "port_city", "luxury_market", "wealthy", "tourist_destination", "coastal", "western"]
  },
  {
    name: "Las Vegas",
    description: "What happens here stays here, except the debt and regrettable tattoos.",
    population: 656_000,
    x: 1,
    y: 2,
    tag_names: ["gambling", "entertainment", "tourist_destination", "landlocked", "western"]
  },
  {
    name: "Phoenix",
    description: "It's a dry heat... that will literally melt your shoes to the pavement in July.",
    population: 1_650_000,
    x: 2,
    y: 2,
    tag_names: ["tech_hub", "landlocked", "western"]
  },
  {
    name: "Albuquerque",
    description: "Breaking Bad tourism and green chile on everything, including your ice cream somehow.",
    population: 564_000,
    x: 3,
    y: 2,
    tag_names: ["tourist_destination", "landlocked", "western"]
  },
  {
    name: "Dallas",
    description: "Cowboys, oil money, and enough hair gel to qualify as a fire hazard.",
    population: 1_304_000,
    x: 4,
    y: 2,
    tag_names: ["financial_center", "manufacturing", "landlocked", "southern"]
  },
  {
    name: "Washington DC",
    description: "Where politicians come to argue about fixing the country while the Metro catches fire.",
    population: 678_000,
    x: 5,
    y: 2,
    tag_names: ["art_culture", "wealthy", "tourist_destination", "coastal", "northeastern"]
  },

  # Row 3
  {
    name: "San Diego",
    description: "Perfect weather year-round, which apparently justifies the insane cost of living.",
    population: 1_387_000,
    x: 0,
    y: 3,
    tag_names: ["tech_hub", "port_city", "tourist_destination", "coastal", "western"]
  },
  {
    name: "Boston",
    description: "Wicked smaht people driving like they've nevah seen a road before, kehd.",
    population: 654_000,
    x: 1,
    y: 3,
    tag_names: ["tech_hub", "financial_center", "college_town", "port_city", "art_culture", "wealthy", "coastal", "northeastern"]
  },
  {
    name: "El Paso",
    description: "So close to Mexico you can get better tacos by just walking across the bridge.",
    population: 678_000,
    x: 2,
    y: 3,
    tag_names: ["landlocked", "western"]
  },
  {
    name: "Austin",
    description: "Keep Austin Weird, but make it unaffordable for the artists who made it weird.",
    population: 974_000,
    x: 3,
    y: 3,
    tag_names: ["tech_hub", "college_town", "entertainment", "hipster", "landlocked", "southern"]
  },
  {
    name: "Houston",
    description: "Everything's bigger in Texas, especially the humidity and the belt buckles.",
    population: 2_314_000,
    x: 4,
    y: 3,
    tag_names: ["port_city", "manufacturing", "coastal", "southern"]
  },
  {
    name: "Charlotte",
    description: "Banking capital of the South, where everyone's either in finance or trying to sell you a time-share.",
    population: 897_000,
    x: 5,
    y: 3,
    tag_names: ["financial_center", "landlocked", "southern"]
  },

  # Row 4 (South)
  {
    name: "Louisville",
    description: "Home of the Derby, bourbon, and people who will correct your pronunciation of Louisville.",
    population: 633_000,
    x: 1,
    y: 4,
    tag_names: ["manufacturing", "landlocked", "southern"]
  },
  {
    name: "San Antonio",
    description: "Remember the Alamo? Because they'll remind you. Every. Single. Day.",
    population: 1_495_000,
    x: 2,
    y: 4,
    tag_names: ["tourist_destination", "landlocked", "southern"]
  },
  {
    name: "Fort Worth",
    description: "Dallas's less pretentious neighbor, where the stockyards smell like authenticity.",
    population: 935_000,
    x: 3,
    y: 4,
    tag_names: ["agricultural", "landlocked", "southern"]
  },
  {
    name: "Memphis",
    description: "Birthplace of rock 'n' roll and BBQ arguments that have ended friendships.",
    population: 621_000,
    x: 4,
    y: 4,
    tag_names: ["entertainment", "port_city", "landlocked", "southern"]
  },
  {
    name: "Nashville",
    description: "Every failed musician's last stop before admitting their parents were right about accounting.",
    population: 689_000,
    x: 0,
    y: 4,
    tag_names: ["entertainment", "tourist_destination", "landlocked", "southern"]
  },
  {
    name: "Jacksonville",
    description: "Florida's largest city by area, because apparently they measured the swamps too.",
    population: 954_000,
    x: 5,
    y: 4,
    tag_names: ["port_city", "coastal", "southern"]
  }
]

# Create or update all locations using find_or_create_by
total_created = 0
total_updated = 0

puts "\nCreating/updating city locations..."

# First pass: Move all existing locations to temporary coordinates to avoid conflicts
cities.each do |attrs|
  location = Location.find_by(name: attrs[:name])
  if location && (location.x != attrs[:x] || location.y != attrs[:y])
    # Move to temporary coordinates (using negative values)
    location.update_columns(x: -location.id, y: -location.id)
  end
end

# Second pass: Update all locations to their final coordinates
cities.each do |attrs|
  location = Location.find_by(name: attrs[:name])
  tag_names = attrs.delete(:tag_names) || []

  if location
    # Update existing location
    location.update!(attrs.except(:name))
    location.tag_names = tag_names
    location.save!
    total_updated += 1
  else
    # Create new location
    location = Location.create!(attrs)
    location.tag_names = tag_names
    location.save!
    total_created += 1
  end

  print "."
end

puts "\n\n✓ Successfully processed #{cities.count} locations!"
puts "  Created: #{total_created}"
puts "  Updated: #{total_updated}" if total_updated > 0

puts "\nGrid layout (West to East, North to South):"
(0..4).each do |y|
  row = []
  (0..5).each do |x|
    loc = Location.find_by(x: x, y: y)
    row << (loc ? loc.name[0..8].ljust(9) : "---".ljust(9))
  end
  puts "  y=#{y}: #{row.join(' | ')}"
end

puts "\n✓ Game locations setup complete!"
