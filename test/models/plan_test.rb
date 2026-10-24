require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "loads free and pro from config/plans.yml" do
    assert_equal %i[free pro], Plan.all.map(&:key)
    assert Plan.free.free?
    assert Plan.pro.paid?
  end

  test "free plan allows three generations a month and has no price" do
    assert_equal 3, Plan.free.monthly_generations
    assert_nil Plan.free.price_cents(currency: :inr, interval: :month)
  end

  test "pro prices are stored in the smallest currency unit" do
    assert_equal 19_900, Plan.pro.price_cents(currency: :inr, interval: :month)
    assert_equal 149_900, Plan.pro.price_cents(currency: "inr", interval: "year")
    assert_equal 600, Plan.pro.price_cents(currency: :usd, interval: :month)
    assert_equal 4_800, Plan.pro.price_cents(currency: :usd, interval: :year)
  end

  test "feature checks" do
    assert Plan.pro.includes?(:certificates)
    assert_not Plan.free.includes?(:certificates)
    assert Plan.free.includes?("data_export")
  end

  test "unknown plan raises" do
    assert_raises(KeyError) { Plan.find(:enterprise) }
  end
end
