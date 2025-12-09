FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.email }
    password_digest { BCrypt::Password.create("password123") }
  end
end
