# Removes email addresses and phone numbers from text a learner pastes (a job
# post), so recruiters' contact details are never stored or sent to the LLM.
#
#   PiiScrubber.call("Mail hr@acme.in or call +91 98765 43210")
#   # => "Mail [email removed] or call [phone removed]"
module PiiScrubber
  EMAIL = /[\w.%+-]+@[a-z0-9-]+(?:\.[a-z0-9-]+)*\.[a-z]{2,}/i
  # A run of digits with the usual separators. Whether it is a phone number is
  # decided by counting digits (see phone?), so "2023-2024" or "3-5 years" stay.
  PHONE_LIKE = /(?<![\w+])\+?\(?\d[\d\s().\/-]{6,}\d(?!\w)/

  def self.call(text)
    return text if text.blank?

    text.gsub(EMAIL, "[email removed]").gsub(PHONE_LIKE) { |match| phone?(match) ? "[phone removed]" : match }
  end

  # 10-15 digits covers Indian mobiles (98765 43210), landlines with an STD
  # code (0731-2345678) and international numbers; a leading + makes 8-9 enough.
  def self.phone?(match)
    digits = match.count("0-9")
    digits.between?(10, 15) || (match.start_with?("+") && digits >= 8)
  end
end
