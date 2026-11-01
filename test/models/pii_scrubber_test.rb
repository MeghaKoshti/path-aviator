require "test_helper"

class PiiScrubberTest < ActiveSupport::TestCase
  def scrub(text) = PiiScrubber.call(text)

  test "removes email addresses" do
    assert_equal "Send your CV to [email removed] or [email removed].",
                 scrub("Send your CV to careers@acme.co.in or Priya.Nair+jobs@mail.example.com.")
  end

  test "removes Indian and international phone numbers in common formats" do
    [
      "+91 98765 43210", "+91-98765-43210", "9876543210", "098765 43210", "0731-2345678",
      "(0731) 234 5678", "+1 (415) 555-0132", "+44 20 7946 0958", "+65 6123 4567"
    ].each do |number|
      assert_equal "Call [phone removed] today", scrub("Call #{number} today"), number
    end
  end

  test "keeps numbers that are part of the job itself" do
    text = "3-5 years of Rails 7.1, 2023-2024 projects, CTC 12,00,000-18,00,000 per year, 40 hours a week, PIN 452001, ISO 27001."

    assert_equal text, scrub(text)
  end

  test "leaves blank text alone" do
    assert_nil scrub(nil)
    assert_equal "", scrub("")
  end
end
