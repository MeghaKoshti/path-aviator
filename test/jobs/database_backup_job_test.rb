require "test_helper"

class DatabaseBackupJobTest < ActiveJob::TestCase
  # VACUUM INTO can't run inside the transaction each test normally gets.
  self.use_transactional_tests = false

  test "copies the database to the backup folder as a readable SQLite file" do
    Dir.mktmpdir do |dir|
      path = DatabaseBackupJob.perform_now(dir: dir, now: Time.utc(2026, 10, 31, 2, 30))

      assert_equal File.join(dir, "test-20261031-023000.sqlite3"), path
      copy = SQLite3::Database.new(path)
      assert_equal User.count, copy.get_first_value("SELECT COUNT(*) FROM users")
    ensure
      copy&.close
    end
  end

  test "keeps only the newest copies" do
    Dir.mktmpdir do |dir|
      4.times { |day| DatabaseBackupJob.perform_now(dir: dir, keep: 2, now: Time.utc(2026, 10, 28 + day, 2, 30)) }

      assert_equal %w[test-20261030-023000.sqlite3 test-20261031-023000.sqlite3], Dir.children(dir).sort
    end
  end

  test "does nothing without a backup folder" do
    assert_nil DatabaseBackupJob.perform_now(dir: nil)
  end
end
