# Small building blocks of the Path Aviator design system.
# Bigger pieces (field, card, flash, empty state, progress bar) live as
# partials in app/views/shared.
module UiHelper
  BUTTON_BASE = "inline-flex items-center justify-center gap-2 rounded-control font-semibold " \
                "transition-colors duration-150 cursor-pointer " \
                "disabled:cursor-not-allowed disabled:opacity-60".freeze

  BUTTON_VARIANTS = {
    primary: "bg-brand-600 text-white shadow-sm hover:bg-brand-700 active:bg-brand-800",
    secondary: "bg-surface-raised text-ink ring-1 ring-inset ring-line-strong hover:bg-surface-sunken",
    ghost: "text-ink-muted hover:bg-surface-sunken hover:text-ink",
    danger: "bg-danger-600 text-white shadow-sm hover:bg-danger-700",
    danger_ghost: "text-danger-700 hover:bg-danger-50", # quiet destructive action next to a primary one
    inverse: "bg-white text-brand-800 shadow-sm hover:bg-brand-50" # on dark brand backgrounds
  }.freeze

  BUTTON_SIZES = {
    sm: "px-3 py-1.5 text-sm pointer-coarse:min-h-10", # roomier tap target on touch screens
    md: "px-4 py-2.5 text-[0.9375rem]",
    lg: "px-6 py-3.5 text-base"
  }.freeze

  BADGE_TONES = {
    neutral: "bg-surface-sunken text-ink-muted",
    brand: "bg-brand-50 text-brand-700",
    success: "bg-success-50 text-success-700",
    warning: "bg-warning-50 text-warning-700",
    danger: "bg-danger-50 text-danger-700"
  }.freeze

  INPUT_BASE = "block w-full rounded-control border bg-surface-raised px-3.5 py-2.5 text-base text-ink " \
               "placeholder:text-ink-subtle transition-colors " \
               "focus:border-brand-600 focus-visible:outline-brand-500 " \
               "disabled:cursor-not-allowed disabled:bg-surface-sunken disabled:text-ink-muted".freeze

  # Classes for anything that should look like a button, e.g. `form.submit "Save", class: ui_button_classes`.
  def ui_button_classes(variant: :primary, size: :md, block: false, extra: nil)
    class_names(BUTTON_BASE, BUTTON_VARIANTS.fetch(variant), BUTTON_SIZES.fetch(size), extra, "w-full": block)
  end

  # One helper for the three kinds of buttons:
  #   ui_button "Dashboard", dashboard_path                      # <a>
  #   ui_button "Sign out", session_path, method: :delete        # button_to form
  #   ui_button "Save", type: :submit                            # <button>
  def ui_button(label = nil, href = nil, variant: :primary, size: :md, block: false, method: nil, **options, &content)
    options[:class] = ui_button_classes(variant:, size:, block:, extra: options[:class])
    body = content ? capture(&content) : label

    if href.nil?
      button_tag(body, { type: :button }.merge(options))
    elsif method && method.to_sym != :get
      button_to(href, method:, class: options.delete(:class), form: { class: block ? "w-full" : "inline-flex" }, **options) { body }
    else
      link_to(body, href, options)
    end
  end

  def ui_badge(text, tone = :neutral)
    tag.span(text, class: class_names("inline-flex shrink-0 items-center whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-semibold", BADGE_TONES.fetch(tone.to_sym)))
  end

  def ui_input_classes(invalid: false)
    class_names(INPUT_BASE, invalid ? "border-danger-600" : "border-line-strong")
  end
end
