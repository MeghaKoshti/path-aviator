require "test_helper"

class UiHelperTest < ActionView::TestCase
  test "ui_button renders a link when given a path" do
    html = ui_button("Dashboard", "/dashboard", variant: :secondary)

    assert_dom_equal %(<a class="#{ui_button_classes(variant: :secondary)}" href="/dashboard">Dashboard</a>), html
  end

  test "ui_button renders a form button for non-GET methods" do
    render html: ui_button("Sign out", "/session", method: :delete)

    assert_select "form[action='/session'] input[name=_method][value=delete]", count: 1
    assert_select "form button", "Sign out"
  end

  test "ui_button without a path renders a plain button" do
    render html: ui_button("Save", type: :submit)

    assert_select "button[type=submit]", "Save"
  end

  test "ui_button_classes supports sizes and full width" do
    classes = ui_button_classes(variant: :danger, size: :lg, block: true)

    assert_includes classes, "bg-danger-600"
    assert_includes classes, "w-full"
    assert_raises(KeyError) { ui_button_classes(variant: :unknown) }
  end

  test "ui_badge applies the tone" do
    render html: ui_badge("Ready", :success)

    assert_select "span.bg-success-50", "Ready"
  end
end
