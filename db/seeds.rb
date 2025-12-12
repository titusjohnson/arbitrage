# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create game resources
puts "Setting up game resources..."

# Future: Add resource types for the game here
# Example:
# Resource.find_or_create_by!(name: "Wood") do |r|
#   r.base_price = 100
#   r.description = "Basic building material"
# end

puts "✓ Game resources setup complete"
