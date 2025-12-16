module DifficultyConfiguration
  extend ActiveSupport::Concern

  DIFFICULTIES = {
    street_peddler: {
      display_name: "Street Peddler",
      description: "Start small, dream big. Perfect for learning the ropes.",
      starting_cash: 5_000,
      wealth_target: 25_000,
      day_target: 30,
      order: 1
    },
    antique_dealer: {
      display_name: "Antique Dealer",
      description: "Your shop is established. Now make it legendary.",
      starting_cash: 35_000,
      wealth_target: 500_000,
      day_target: 180,
      order: 2
    },
    tycoon: {
      display_name: "Tycoon",
      description: "Build an empire. Only the relentless succeed.",
      starting_cash: 100_000,
      wealth_target: 10_000_000,
      day_target: 365,
      order: 3
    }
  }.freeze

  class_methods do
    def difficulty_options
      DIFFICULTIES.keys
    end

    def difficulty_config(level)
      DIFFICULTIES[level.to_sym]
    end

    def difficulties_for_display
      DIFFICULTIES.sort_by { |_, config| config[:order] }
    end
  end
end
