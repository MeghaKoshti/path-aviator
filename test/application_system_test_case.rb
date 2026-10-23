require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # CI installs google-chrome and lets Selenium find a matching driver.
  # Locally, point CHROME_BIN / CHROMEDRIVER_PATH at any Chrome + driver pair.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"]
    options.add_argument("--no-sandbox") if ENV["CHROME_NO_SANDBOX"]
  end

  # First renders in the test server can be slow on shared CI machines.
  Capybara.default_max_wait_time = 5

  if ENV["CHROMEDRIVER_PATH"]
    Selenium::WebDriver::Chrome::Service.driver_path = ENV["CHROMEDRIVER_PATH"]
  end

  private
    def sign_in_through_ui(user, password: "password")
      visit new_session_path
      fill_in "Email", with: user.email_address
      fill_in "Password", with: password
      click_on "Sign in"
    end
end
