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

  def user_display_name(user)
    user.try(:name).presence || user.email_address
  end
end
