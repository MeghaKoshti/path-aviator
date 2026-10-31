# Who runs Path Aviator and how to reach them, for the policy and contact pages.
# Production sets the real values through ENV. The defaults are deliberately
# obvious placeholders, so an unconfigured deploy can't pass for a reviewed policy.
module Legal
  # Bump this whenever the wording of a policy changes.
  LAST_UPDATED = Date.new(2026, 10, 24)
  JURISDICTION = "Indore, Madhya Pradesh, India".freeze

  def self.owner_name
    ENV["LEGAL_OWNER_NAME"].presence || "[Operator’s legal name]"
  end

  def self.support_email
    ENV["SUPPORT_EMAIL"].presence || "support@example.com"
  end

  def self.configured?
    ENV["LEGAL_OWNER_NAME"].present? && ENV["SUPPORT_EMAIL"].present?
  end
end
