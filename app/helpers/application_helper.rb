module ApplicationHelper
  # Top-nav link that marks the current page for screen readers and styling.
  def nav_link_to(label, path, mobile: false)
    current = current_page?(path)
    classes = if mobile
      class_names("block rounded-control px-3 py-2.5 text-base font-medium",
        current ? "bg-brand-50 text-brand-700" : "text-ink-muted hover:bg-surface-sunken hover:text-ink")
    else
      class_names("relative rounded-md px-3 py-2 text-[0.9375rem] font-medium transition-colors",
        current ? "text-ink after:absolute after:inset-x-3 after:-bottom-[13px] after:h-0.5 after:bg-brand-600" : "text-ink-muted hover:text-ink")
    end
    link_to label, path, class: classes, aria: { current: ("page" if current) }
  end

  # After a failed submit, focus goes to the first invalid field (in form order)
  # so keyboard and screen reader users land on what needs fixing.
  def first_invalid_field(record, fields_in_order)
    fields_in_order.find { |field| record.errors.include?(field) }
  end

  # Links every footer carries, so policies are one click from any page.
  def site_footer_links
    [
      [ "Pricing", pricing_path ],
      [ "Study plans", learn_topics_path ],
      [ "Privacy", privacy_path ],
      [ "Terms", terms_path ],
      [ "Refunds", refunds_path ],
      [ "Contact", contact_path ],
      [ "GitHub", "https://github.com/MeghaKoshti/path-aviator" ]
    ]
  end

  def user_display_name(user)
    user.try(:name).presence || user.email_address
  end

  # Options for a time zone select, one per IANA zone, e.g.
  # ["(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi", "Asia/Kolkata"].
  # A zone the browser found that Rails has no name for is listed as itself.
  def time_zone_options(selected)
    options = ActiveSupport::TimeZone.all.group_by { |zone| zone.tzinfo.name }.map do |iana, zones|
      [ "(GMT#{zones.first.formatted_offset}) #{zones.map(&:name).join(", ")}", iana ]
    end
    options << [ selected, selected ] unless options.any? { |_, iana| iana == selected }
    options_for_select(options, selected)
  end
end
