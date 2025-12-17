FactoryBot.define do
  factory :buddy do
    game
    location
    name { Buddy::BUDDY_NAMES.sample }
    hire_cost { 100 }
    hire_day { 1 }
    status { 'idle' }
    target_profit_percent { 25 }
    quantity { 0 }

    trait :holding do
      status { 'holding' }
      resource
      quantity { 5 }
      purchase_price { 100.0 }
    end

    trait :sold do
      status { 'sold' }
      resource
      quantity { 5 }
      purchase_price { 100.0 }
      last_sale_profit { 50.0 }
      last_sale_day { 1 }
    end
  end
end
