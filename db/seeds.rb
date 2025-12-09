# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a developer account for local development
if ENV["DEVELOPER_EMAIL"].present? && ENV["DEVELOPER_PASSWORD"].present?
  developer = User.find_or_initialize_by(email_address: ENV["DEVELOPER_EMAIL"])

  if developer.new_record?
    developer.password = ENV["DEVELOPER_PASSWORD"]
    developer.password_confirmation = ENV["DEVELOPER_PASSWORD"]
    developer.save!
    puts "✓ Created developer account: #{developer.email_address}"
  else
    # Update password if user already exists
    developer.password = ENV["DEVELOPER_PASSWORD"]
    developer.password_confirmation = ENV["DEVELOPER_PASSWORD"]
    developer.save!
    puts "✓ Updated developer account: #{developer.email_address}"
  end
else
  puts "⚠ Skipping developer account creation - DEVELOPER_EMAIL and DEVELOPER_PASSWORD not set in environment"
end
