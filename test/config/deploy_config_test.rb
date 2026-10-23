require "test_helper"

# Guards the Kamal setup: settings that must not drift, and no secrets in git.
class DeployConfigTest < ActiveSupport::TestCase
  DEPLOY_ENV = { "KAMAL_SERVER_IP" => "203.0.113.10", "KAMAL_REGISTRY_USERNAME" => "megha", "APP_HOST" => "pathaviator.example.com" }.freeze

  def deploy_config(env = DEPLOY_ENV)
    old = env.keys.to_h { |key| [ key, ENV[key] ] }
    env.each { |key, value| ENV[key] = value }
    YAML.safe_load(ERB.new(Rails.root.join("config/deploy.yml").read).result)
  ensure
    old.each { |key, value| ENV[key] = value }
  end

  test "server, image and domain all come from the environment" do
    config = deploy_config

    assert_equal [ "203.0.113.10" ], config.dig("servers", "web")
    assert_equal "megha/path_aviator", config["image"]
    assert_equal "megha", config.dig("registry", "username")
    assert_nil config.dig("registry", "server")
    assert_equal({ "ssl" => true, "host" => "pathaviator.example.com" }, config["proxy"].slice("ssl", "host"))
    assert_equal "/up", config.dig("proxy", "healthcheck", "path")
    assert_equal "pathaviator.example.com", config.dig("env", "clear", "APP_HOST")
  end

  test "runs jobs in Puma and keeps SQLite on a persistent volume" do
    config = deploy_config

    assert_equal true, config.dig("env", "clear", "SOLID_QUEUE_IN_PUMA")
    assert_includes config["volumes"], "path_aviator_storage:/rails/storage"
    assert_match %r{\Astorage/}, ActiveRecord::Base.configurations.configs_for(env_name: "production", name: "primary").database
  end

  test "a different registry can be chosen" do
    assert_equal "ghcr.io", deploy_config(DEPLOY_ENV.merge("KAMAL_REGISTRY_SERVER" => "ghcr.io")).dig("registry", "server")
  end

  test "fails loudly when a required setting is missing" do
    assert_raises(KeyError) { deploy_config(DEPLOY_ENV.merge("APP_HOST" => nil)) }
  end

  test "every secret is read from the environment, never written in the file" do
    secrets = Rails.root.join(".kamal/secrets").readlines(chomp: true).reject { |line| line.blank? || line.start_with?("#") }
    secret_names = deploy_config.dig("env", "secret") + deploy_config.dig("registry", "password")

    assert_equal secret_names.sort, secrets.map { |line| line.split("=").first }.sort
    secrets.each { |line| assert_match(/\A(\w+)=\$\1\z/, line) }
  end
end
