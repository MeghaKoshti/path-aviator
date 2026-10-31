require "application_system_test_case"

class CertificateTest < ApplicationSystemTestCase
  test "finishing a path, publishing the certificate and opening it" do
    path = learning_paths(:rails)
    as_pro do
      sign_in_through_ui users(:one)
      visit learning_path_path(path)

      path.path_steps.reject(&:completed?).each do |step|
        find("##{dom_id(step, :toggle)}").click
        assert_selector "##{dom_id(step, :toggle)}[aria-checked=true]"
      end
      assert_text "You’ve finished every step."

      click_on "Get your certificate"
      fill_in "Step 4: Deploy with Kamal", with: "https://riya.dev/blog"
      click_on "Publish certificate"

      assert_text "Certificate published."
      assert_selector "h1", text: path.title
      assert_text "Riya Sharma"
      assert_link "See the work", href: "https://riya.dev/blog"
      assert_selector "a[href^='https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME']", text: "Add to LinkedIn"
    end
  end
end
