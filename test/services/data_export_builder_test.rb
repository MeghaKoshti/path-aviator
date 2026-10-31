require "test_helper"
require "rubygems/package"

class DataExportBuilderTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    learning_goals(:rails).update!(job_post: "Rails role at Acme", target_date: 4.weeks.from_now.to_date)
    learning_paths(:rails).update!(skills: [ "Hotwire" ])
    path_steps(:rails_intro).update!(evidence_url: "https://github.com/riya/blog")
    Event.track(:signed_up, user: @user)
  end

  def read_archive(bytes)
    files = {}
    Zlib::GzipReader.wrap(StringIO.new(bytes)) do |gzip|
      Gem::Package::TarReader.new(gzip) { |tar| tar.each { |entry| files[entry.full_name] = entry.read.force_encoding("UTF-8") } }
    end
    files
  end

  test "data.json holds the account, goals with the job post, paths, steps, notes and events" do
    data = JSON.parse(DataExportBuilder.new(@user).files.fetch("data.json"))

    assert_equal "one@example.com", data.dig("account", "email_address")
    assert_not data["account"].key?("password_digest")
    assert_equal [ "Ruby on Rails", "SQL for analytics" ], data["goals"].map { |goal| goal["topic"] }
    rails = data["goals"].first
    assert_equal "Rails role at Acme", rails["job_post"]
    assert_equal [ "Hotwire" ], rails.dig("path", "skills")
    assert_equal 4, rails.dig("path", "steps").size
    assert_equal "Redo the blog with my own models.", rails.dig("path", "steps", 0, "note")
    assert_equal "https://github.com/riya/blog", rails.dig("path", "steps", 0, "evidence_url")
    assert_equal [ "signed_up" ], data["events"].map { |event| event["name"] }
    assert_not_includes data.to_s, "two@example.com"
  end

  test "each path gets a readable Markdown checklist" do
    files = DataExportBuilder.new(@user).files
    markdown = files.fetch("paths/1-ruby-on-rails-from-zero-to-deploy.md")

    assert_includes markdown, "# Ruby on Rails from zero to deploy"
    assert_includes markdown, "- Skills: Hotwire"
    assert_includes markdown, "- [x] **Getting Started with Rails** (90 min): https://guides.rubyonrails.org/getting_started.html"
    assert_includes markdown, "  > Note: Redo the blog with my own models."
    assert_includes markdown, "  Proof: https://github.com/riya/blog"
    assert_includes markdown, "- [ ] **Active Record basics**"
    assert files.key?("paths/2-sql-for-analytics.md"), "a path still generating is listed by its topic"
  end

  test "the archive is a .tar.gz with every file under one folder" do
    files = read_archive(DataExportBuilder.new(@user).archive)

    assert_equal %w[README.txt data.json paths/1-ruby-on-rails-from-zero-to-deploy.md paths/2-sql-for-analytics.md].map { |name| "path-aviator-export/#{name}" }, files.keys.sort
    assert_includes files["path-aviator-export/README.txt"], "Your password is not included"
  end
end
