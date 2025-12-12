# Location Tag System

Location tags interact with resource tags to create dynamic pricing events and gameplay modifiers.

## Location Tag Categories

### Economic/Industry Tags (what the city produces/specializes in)
- `tech_hub` - Technology center (affects: technology resources)
- `financial_center` - Banking/finance hub (affects: precious_metal, investment resources)
- `manufacturing` - Industrial production (affects: technology, luxury_fashion when strikes occur)
- `port_city` - Major shipping/trade hub (affects: all imports, bulky items)
- `agricultural` - Food production region (affects: food, perishable resources)
- `entertainment` - Media/entertainment industry (affects: collectible resources)
- `luxury_market` - High-end consumer goods (affects: luxury_fashion, timepiece, artisan)
- `art_culture` - Museums, galleries, art scene (affects: collectible, antique, artisan)
- `gambling` - Casino/gaming industry (affects: alcohol, luxury_fashion)

### Demographic/Cultural Tags (who lives there and what they buy)
- `wealthy` - High income population (increases demand for: investment, luxury_fashion, timepiece)
- `tourist_destination` - Major tourism (increases demand for: collectible, artisan, food)
- `college_town` - University presence (increases demand for: technology, consumable)
- `hipster` - Trendy/artisanal culture (increases demand for: artisan, food, collectible)
- `conservative` - Traditional values (affects: alcohol, certain collectibles)

### Geographic Tags (affects shipping and availability)
- `coastal` - Ocean access (better prices on: imports, perishable from overseas)
- `landlocked` - No ocean access (worse prices on: imports)
- `southern` - Southern US region (affects: food preferences)
- `western` - Western US region (affects: resource availability)
- `northeastern` - Northeastern US region (affects: antique, european_origin availability)

## Tag-to-Resource Interactions

### Events that could trigger based on tags:
- **Warehouse Strike** in `manufacturing` city → `luxury_fashion` prices increase
- **Port Shutdown** in `port_city` → All `bulky` items and imports increase
- **Tech Boom** in `tech_hub` → `technology` resources demand increases
- **Festival** in `tourist_destination` → `collectible`, `artisan`, `food` demand spikes
- **Market Crash** in `financial_center` → `investment` resources drop
- **Drought** in `agricultural` region → `food` and `perishable` prices spike
- **Gallery Opening** in `art_culture` city → `antique` and `collectible` demand increases
- **University Homecoming** in `college_town` → `alcohol`, `consumable` demand spikes

## Example City Tagging:
- **New York City**: `financial_center`, `port_city`, `art_culture`, `wealthy`, `tourist_destination`, `coastal`, `northeastern`
- **Los Angeles**: `entertainment`, `port_city`, `tech_hub`, `wealthy`, `tourist_destination`, `coastal`, `western`
- **Las Vegas**: `gambling`, `entertainment`, `tourist_destination`, `western`
- **San Francisco**: `tech_hub`, `financial_center`, `port_city`, `wealthy`, `hipster`, `coastal`, `western`
- **Nashville**: `entertainment`, `tourist_destination`, `southern`
