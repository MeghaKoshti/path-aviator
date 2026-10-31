# Read-only catalog of plans loaded from config/plans.yml.
#
#   Plan.find(:pro).price_cents(currency: :inr, interval: :year) # => 149900
#   Plan.find(:free).monthly_generations                        # => 3
#   Plan.find(:pro).includes?(:certificates)                     # => true
class Plan
  CURRENCIES = %i[inr usd].freeze
  INTERVALS = %i[month year].freeze

  attr_reader :key, :name, :monthly_generations, :features

  def self.all
    @all ||= YAML.load_file(Rails.root.join("config/plans.yml")).map do |key, attrs|
      new(key: key.to_sym, **attrs.symbolize_keys)
    end.freeze
  end

  def self.find(key)
    all.find { |plan| plan.key == key.to_sym } or raise KeyError, "Unknown plan: #{key}"
  end

  def self.free = find(:free)
  def self.pro = find(:pro)

  def initialize(key:, name:, monthly_generations:, prices: {}, features: [])
    @key = key
    @name = name
    @monthly_generations = monthly_generations
    @prices = prices.to_h.deep_symbolize_keys
    @features = features.map(&:to_sym).freeze
  end

  def free? = key == :free
  def paid? = !free?

  def includes?(feature) = features.include?(feature.to_sym)

  # Price in paise/cents, or nil when the plan has no price (Free).
  def price_cents(currency:, interval:)
    @prices.dig(currency.to_sym, interval.to_sym)
  end
end
