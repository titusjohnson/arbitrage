require 'rails_helper'

RSpec.describe EventEffectsService, type: :service do
  let(:game) { create(:game) }
  let(:location) { game.current_location }
  let(:resource) { create(:resource) }
  let(:game_resource) do
    create(:game_resource, game: game, resource: resource)
  end
  let(:service) { described_class.new(game, game_resource) }

  describe '#call' do
    context 'with no active events' do
      it 'returns neutral multipliers' do
        result = service.call

        expect(result[:price_multiplier]).to eq(1.0)
        expect(result[:availability_multiplier]).to eq(1.0)
      end
    end

    context 'with one active event' do
      let!(:event) do
        create(:event, :active, resource_effects: {
          'price_modifiers' => [
            {
              'tags' => ['food'],
              'match' => 'any',
              'multiplier' => 2.0,
              'description' => 'Food prices doubled'
            }
          ]
        })
      end
      let!(:game_event) do
        create(:game_event, game: game, event: event, days_remaining: 3)
      end

      context 'when resource has matching tag' do
        before do
          resource.tag_names = ['food']
          resource.save!
        end

        it 'applies the price modifier' do
          result = service.call

          expect(result[:price_multiplier]).to eq(2.0)
          expect(result[:availability_multiplier]).to eq(1.0)
        end
      end

      context 'when resource does not have matching tag' do
        before do
          resource.tag_names = ['technology']
          resource.save!
        end

        it 'returns neutral multipliers' do
          result = service.call

          expect(result[:price_multiplier]).to eq(1.0)
          expect(result[:availability_multiplier]).to eq(1.0)
        end
      end

      context 'with match type "any"' do
        before do
          event.update!(resource_effects: {
            'price_modifiers' => [
              {
                'tags' => ['food', 'perishable'],
                'match' => 'any',
                'multiplier' => 1.5
              }
            ]
          })
        end

        it 'matches when resource has one of the tags' do
          resource.tag_names = ['food']
          resource.save!

          result = service.call

          expect(result[:price_multiplier]).to eq(1.5)
        end

        it 'matches when resource has multiple matching tags' do
          resource.tag_names = ['food', 'perishable']
          resource.save!

          result = service.call

          expect(result[:price_multiplier]).to eq(1.5)
        end

        it 'does not match when resource has no matching tags' do
          resource.tag_names = ['technology']
          resource.save!

          result = service.call

          expect(result[:price_multiplier]).to eq(1.0)
        end
      end

      context 'with match type "all"' do
        before do
          event.update!(resource_effects: {
            'price_modifiers' => [
              {
                'tags' => ['food', 'perishable'],
                'match' => 'all',
                'multiplier' => 2.5
              }
            ]
          })
        end

        it 'matches when resource has all required tags' do
          resource.tag_names = ['food', 'perishable', 'compact']
          resource.save!

          result = service.call

          expect(result[:price_multiplier]).to eq(2.5)
        end

        it 'does not match when resource is missing one tag' do
          resource.tag_names = ['food']
          resource.save!

          result = service.call

          expect(result[:price_multiplier]).to eq(1.0)
        end
      end
    end

    context 'with multiple active events' do
      let!(:event1) do
        create(:event, :active, resource_effects: {
          'price_modifiers' => [
            {
              'tags' => ['food'],
              'match' => 'any',
              'multiplier' => 2.0
            }
          ]
        })
      end
      let!(:event2) do
        create(:event, :active, resource_effects: {
          'price_modifiers' => [
            {
              'tags' => ['perishable'],
              'match' => 'any',
              'multiplier' => 1.5
            }
          ]
        })
      end
      let!(:game_event1) do
        create(:game_event, game: game, event: event1, days_remaining: 3)
      end
      let!(:game_event2) do
        create(:game_event, game: game, event: event2, days_remaining: 2)
      end

      it 'stacks effects multiplicatively' do
        resource.tag_names = ['food', 'perishable']
        resource.save!

        result = service.call

        # Both events apply: 2.0 * 1.5 = 3.0
        expect(result[:price_multiplier]).to eq(3.0)
      end
    end

    context 'with availability modifiers' do
      let!(:event) do
        create(:event, :active, resource_effects: {
          'availability_modifiers' => [
            {
              'tags' => ['luxury_fashion'],
              'match' => 'any',
              'multiplier' => 0.3,
              'description' => 'Luxury items scarce'
            }
          ]
        })
      end
      let!(:game_event) do
        create(:game_event, game: game, event: event, days_remaining: 3)
      end

      it 'applies availability multiplier' do
        resource.tag_names = ['luxury_fashion']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(1.0)
        expect(result[:availability_multiplier]).to eq(0.3)
      end
    end

    context 'with both price and availability modifiers' do
      let!(:event) do
        create(:event, :active, resource_effects: {
          'price_modifiers' => [
            {
              'tags' => ['food'],
              'match' => 'any',
              'multiplier' => 3.0
            }
          ],
          'availability_modifiers' => [
            {
              'tags' => ['food'],
              'match' => 'any',
              'multiplier' => 0.5
            }
          ]
        })
      end
      let!(:game_event) do
        create(:game_event, game: game, event: event, days_remaining: 3)
      end

      it 'applies both modifiers independently' do
        resource.tag_names = ['food']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(3.0)
        expect(result[:availability_multiplier]).to eq(0.5)
      end
    end

    context 'with location-scoped effects' do
      # Location effects are only applied when a location is provided
      let(:service_with_location) { described_class.new(game, game_resource, location: location) }

      context 'when both location and resource match' do
        let!(:event) do
          create(:event, :active,
            resource_effects: {},
            location_effects: {
              'price_modifiers' => [
                {
                  'scoped_tags' => {
                    'location' => ['port_city'],
                    'resource' => ['food']
                  },
                  'match' => 'any',
                  'multiplier' => 0.5
                }
              ]
            }
          )
        end
        let!(:game_event) do
          create(:game_event, game: game, event: event, days_remaining: 3)
        end

        before do
          location.tag_names = ['port_city']
          location.save!
          resource.tag_names = ['food']
          resource.save!
        end

        it 'applies the location-scoped modifier when location is provided' do
          result = service_with_location.call

          expect(result[:price_multiplier]).to eq(0.5)
        end

        it 'does not apply location-scoped modifier when location is not provided' do
          result = service.call

          expect(result[:price_multiplier]).to eq(1.0)
        end
      end

      context 'when location matches but resource does not' do
        let!(:event) do
          create(:event, :active,
            resource_effects: {},
            location_effects: {
              'price_modifiers' => [
                {
                  'scoped_tags' => {
                    'location' => ['port_city'],
                    'resource' => ['food']
                  },
                  'match' => 'any',
                  'multiplier' => 0.5
                }
              ]
            }
          )
        end
        let!(:game_event) do
          create(:game_event, game: game, event: event, days_remaining: 3)
        end

        before do
          location.tag_names = ['port_city']
          location.save!
          resource.tag_names = ['technology']
          resource.save!
        end

        it 'does not apply the modifier' do
          result = service_with_location.call

          expect(result[:price_multiplier]).to eq(1.0)
        end
      end

      context 'when resource matches but location does not' do
        let!(:event) do
          create(:event, :active,
            resource_effects: {},
            location_effects: {
              'price_modifiers' => [
                {
                  'scoped_tags' => {
                    'location' => ['port_city'],
                    'resource' => ['food']
                  },
                  'match' => 'any',
                  'multiplier' => 0.5
                }
              ]
            }
          )
        end
        let!(:game_event) do
          create(:game_event, game: game, event: event, days_remaining: 3)
        end

        before do
          location.tag_names = ['tech_hub']
          location.save!
          resource.tag_names = ['food']
          resource.save!
        end

        it 'does not apply the modifier' do
          result = service_with_location.call

          expect(result[:price_multiplier]).to eq(1.0)
        end
      end

      context 'with location-only scoped tags' do
        let!(:event) do
          create(:event, :active,
            resource_effects: {},
            location_effects: {
              'price_modifiers' => [
                {
                  'scoped_tags' => {
                    'location' => ['wealthy']
                  },
                  'match' => 'any',
                  'multiplier' => 1.5
                }
              ]
            }
          )
        end
        let!(:game_event) do
          create(:game_event, game: game, event: event, days_remaining: 3)
        end

        before do
          location.tag_names = ['wealthy']
          location.save!
          resource.tag_names = ['food']
          resource.save!
        end

        it 'applies to all resources in matching locations' do
          result = service_with_location.call

          expect(result[:price_multiplier]).to eq(1.5)
        end
      end

      context 'with resource-only scoped tags' do
        let!(:event) do
          create(:event, :active,
            resource_effects: {},
            location_effects: {
              'quantity_modifiers' => [
                {
                  'scoped_tags' => {
                    'resource' => ['perishable']
                  },
                  'match' => 'any',
                  'multiplier' => 0.3
                }
              ]
            }
          )
        end
        let!(:game_event) do
          create(:game_event, game: game, event: event, days_remaining: 3)
        end

        before do
          resource.tag_names = ['perishable']
          resource.save!
        end

        it 'applies to matching resources when location is provided' do
          result = service_with_location.call

          expect(result[:availability_multiplier]).to eq(0.3)
        end
      end
    end

    context 'with expired events' do
      let!(:event) do
        create(:event, :active, resource_effects: {
          'price_modifiers' => [
            {
              'tags' => ['food'],
              'match' => 'any',
              'multiplier' => 2.0
            }
          ]
        })
      end
      let!(:game_event) do
        create(:game_event, game: game, event: event, days_remaining: 0)
      end

      it 'does not apply effects from expired events' do
        resource.tag_names = ['food']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(1.0)
      end
    end

    context 'with multiple modifiers in one event' do
      let!(:event) do
        create(:event, :active, resource_effects: {
          'price_modifiers' => [
            {
              'tags' => ['investment'],
              'match' => 'any',
              'multiplier' => 0.3
            },
            {
              'tags' => ['antique'],
              'match' => 'any',
              'multiplier' => 0.5
            }
          ]
        })
      end
      let!(:game_event) do
        create(:game_event, game: game, event: event, days_remaining: 3)
      end

      it 'applies all matching modifiers from the same event' do
        resource.tag_names = ['investment', 'antique', 'collectible']
        resource.save!

        result = service.call

        # Both modifiers apply: 0.3 * 0.5 = 0.15
        expect(result[:price_multiplier]).to eq(0.15)
      end

      it 'applies only matching modifiers' do
        resource.tag_names = ['antique']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(0.5)
      end
    end

    context 'with complex real-world scenario' do
      let(:service_with_location) { described_class.new(game, game_resource, location: location) }

      # The Great Depression event
      let!(:depression_event) do
        create(:event, :active,
          name: 'The Great Depression',
          resource_effects: {
            'price_modifiers' => [
              {
                'tags' => ['investment', 'luxury_fashion', 'collectible'],
                'match' => 'any',
                'multiplier' => 0.3
              },
              {
                'tags' => ['precious_metal'],
                'match' => 'any',
                'multiplier' => 3.0
              },
              {
                'tags' => ['antique'],
                'match' => 'any',
                'multiplier' => 0.5
              }
            ],
            'availability_modifiers' => [
              {
                'tags' => ['luxury_fashion'],
                'match' => 'any',
                'multiplier' => 2.5
              }
            ]
          },
          location_effects: {
            'price_modifiers' => [
              {
                'scoped_tags' => {
                  'location' => ['financial_center'],
                  'resource' => ['investment']
                },
                'match' => 'any',
                'multiplier' => 0.2
              }
            ]
          }
        )
      end
      let!(:game_event) do
        create(:game_event, game: game, event: depression_event, days_remaining: 5)
      end

      it 'precious metals get 3x price boost' do
        resource.tag_names = ['precious_metal']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(3.0)
        expect(result[:availability_multiplier]).to eq(1.0)
      end

      it 'luxury fashion gets 0.3x price and 2.5x availability' do
        resource.tag_names = ['luxury_fashion']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(0.3)
        expect(result[:availability_multiplier]).to eq(2.5)
      end

      it 'collectible antiques stack both penalties (0.3 * 0.5 = 0.15)' do
        resource.tag_names = ['collectible', 'antique']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(0.15)
      end

      it 'investment items in financial centers get extra penalty' do
        location.tag_names = ['financial_center']
        location.save!
        resource.tag_names = ['investment']
        resource.save!

        result = service_with_location.call

        # 0.3 (investment) * 0.2 (financial center) = 0.06
        expect(result[:price_multiplier]).to eq(0.06)
      end

      it 'unaffected items remain neutral' do
        resource.tag_names = ['food', 'perishable']
        resource.save!

        result = service.call

        expect(result[:price_multiplier]).to eq(1.0)
        expect(result[:availability_multiplier]).to eq(1.0)
      end
    end
  end
end
