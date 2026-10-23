require "test_helper"

class SharedPartialsTest < ActionView::TestCase
  test "field shows the model error inline and links it to the input" do
    user = User.new
    user.errors.add(:email_address, "can't be blank")

    render html: form_with(model: user, url: "/users") { |form|
      render "shared/field", form: form, attribute: :email_address, label: "Email", as: :email_field, hint: "We never share it."
    }

    assert_select "label[for=user_email_address]", "Email"
    assert_select "input#user_email_address[aria-invalid=true][aria-describedby='user_email_address_hint user_email_address_error']"
    assert_select "#user_email_address_error", /Email address can't be blank/
  end

  test "field without errors is not marked invalid" do
    render html: form_with(url: "/session") { |form|
      render "shared/field", form: form, attribute: :password, label: "Password", as: :password_field, reveal: true
    }

    assert_select "input#password[type=password]:not([aria-invalid])"
    assert_select "[data-controller=password-visibility] button[aria-label='Show password'][aria-pressed=false]"
  end

  test "progress bar clamps its value and has an accessible name" do
    render "shared/progress_bar", value: 140, label: "Rails path progress"

    assert_select "progress[value='100'][max='100'][aria-label='Rails path progress']"
  end

  test "empty state renders an optional action" do
    render "shared/empty_state", title: "No paths yet", body: "Plan one to get started.", action_label: "New path", action_href: "/learning_goals/new"

    assert_select "h2", "No paths yet"
    assert_select "a[href='/learning_goals/new']", "New path"
  end

  test "card yields its content under an optional title" do
    render("shared/card", title: "Next step") { "Watch the video" }

    assert_select "section h2", "Next step"
    assert_includes rendered, "Watch the video"
  end
end
