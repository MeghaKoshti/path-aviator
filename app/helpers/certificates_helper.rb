module CertificatesHelper
  # LinkedIn's documented "Add to profile" link, which pre-fills the
  # Licenses & certifications form: https://addtoprofile.linkedin.com
  # organizationId (a LinkedIn page) and organizationName can't be combined.
  def linkedin_add_to_profile_url(learning_path)
    issued = learning_path.certificate_issued_at
    fields = { startTask: "CERTIFICATION_NAME", name: learning_path.title }
    if (organization_id = ENV["LINKEDIN_ORGANIZATION_ID"].presence)
      fields[:organizationId] = organization_id
    else
      fields[:organizationName] = "Path Aviator"
    end
    fields.merge!(issueYear: issued.year, issueMonth: issued.month,
      certUrl: certificate_url(learning_path.certificate_token), certId: learning_path.certificate_token)

    "https://www.linkedin.com/profile/add?" + fields.map { |key, value| "#{key}=#{ERB::Util.url_encode(value.to_s)}" }.join("&")
  end

  def certificate_holder_name(learning_path)
    learning_path.user.name.presence || "A Path Aviator learner"
  end

  # Evenly spaced waypoints on a gentle wave, one per step, for the certificate's route band.
  def certificate_route_points(count, width: 640, height: 72)
    return [] if count.zero?

    step = count > 1 ? (width - 40) / (count - 1).to_f : 0
    Array.new(count) { |i| [ (20 + i * step).round(1), (height / 2 + Math.sin(i * 1.3) * height * 0.28).round(1) ] }
  end
end
