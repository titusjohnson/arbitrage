---
description: Add schema comments to models, specs, and factories
---

For each model in the app/models directory:

1. Read the current db/schema.rb file to get the table schema
2. For each model file (app/models/*.rb), find the corresponding table in schema.rb
3. Generate a docblock comment showing:
   - Table name
   - All columns with their types, limits, defaults, and null constraints
   - All indexes
   - All foreign keys
4. Add or update this comment at the top of:
   - The model file (app/models/*.rb)
   - The model spec file (spec/models/*_spec.rb)
   - The factory file (spec/factories/*.rb)

Format the comment like this:

```ruby
# == Schema Information
#
# Table name: resources
#
#  id                :integer          not null, primary key
#  name              :string           not null
#  description       :text
#  base_price_min    :decimal(10, 2)   not null
#  base_price_max    :decimal(10, 2)   not null
#  price_volatility  :decimal(5, 2)    default(50.0), not null
#  inventory_size    :integer          default(1), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_resources_on_name  (name) UNIQUE
#
```

If a schema comment already exists, replace it. Make sure to preserve all existing code below the comment.
