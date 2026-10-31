require "rubygems/package"
require "zlib"

# Everything Path Aviator keeps about a user, as a .tar.gz (Ruby's standard
# library has no zip writer; every OS opens .tar.gz):
#
#   path-aviator-export/
#     README.txt
#     data.json              account, goals (with any job post), paths, steps, notes, events
#     paths/<n>-<slug>.md    one readable file per path
class DataExportBuilder
  ROOT = "path-aviator-export".freeze

  def initialize(user, now: Time.current)
    @user = user
    @now = now
  end

  def files
    goals = @user.learning_goals.includes(learning_path: :path_steps).order(:created_at).to_a
    {
      "README.txt" => readme,
      "data.json" => JSON.pretty_generate(data(goals)),
      **goals.filter_map(&:learning_path).each.with_index(1).to_h { |path, n| [ "paths/#{n}-#{path_slug(path)}.md", markdown(path) ] }
    }
  end

  def archive
    io = StringIO.new
    Zlib::GzipWriter.wrap(io) do |gzip|
      Gem::Package::TarWriter.new(gzip) do |tar|
        files.each do |name, content|
          bytes = content.b
          tar.add_file_simple("#{ROOT}/#{name}", 0o644, bytes.bytesize) { |file| file.write(bytes) }
        end
      end
    end
    io.string
  end

  private
    def data(goals)
      {
        exported_at: @now.iso8601,
        account: @user.slice(:name, :email_address, :time_zone, :weekly_digest, :created_at),
        goals: goals.map do |goal|
          goal.slice(:topic, :current_level, :hours_per_week, :goal_description, :job_post, :target_date, :created_at).merge(
            path: goal.learning_path && path_data(goal.learning_path)
          )
        end,
        events: @user.events.order(:created_at).map { |event| event.slice(:name, :properties, :created_at) }
      }
    end

    def path_data(path)
      path.slice(:title, :summary, :status, :skills, :generated_at, :certificate_issued_at).merge(
        shared: path.shared?,
        steps: path.path_steps.map do |step|
          step.slice(:position, :title, :description, :resource_type, :resource_url, :estimated_minutes, :completed_at, :note, :evidence_url, :link_status, :link_checked_at)
        end
      )
    end

    def markdown(path)
      goal = path.learning_goal
      lines = [ "# #{path.title.presence || goal.topic}", "" ]
      lines << path.summary << "" if path.summary.present?
      lines << "- Level: #{goal.current_level.humanize}, #{goal.hours_per_week} h a week"
      lines << "- Finish by: #{goal.target_date.iso8601}" if goal.target_date
      lines << "- Skills: #{path.skills.join(", ")}" if path.skills.present?
      lines << "- Progress: #{path.completed_steps_count} of #{path.path_steps_count} steps" << ""
      path.path_steps.each do |step|
        lines << "- [#{step.completed? ? "x" : " "}] **#{step.title}** (#{step.estimated_minutes} min): #{step.resource_url}"
        lines << "  #{step.description}" if step.description.present?
        lines << "  > Note: #{step.note.gsub("\n", "\n  > ")}" if step.note.present?
        lines << "  Proof: #{step.evidence_url}" if step.evidence_url.present?
      end
      lines.join("\n") + "\n"
    end

    def path_slug(path)
      (path.title.presence || path.learning_goal.topic).parameterize.truncate(60, omission: "").presence || "path"
    end

    def readme
      <<~TEXT
        Your Path Aviator data, exported #{@now.utc.iso8601}.

        data.json has everything we keep about your account: your goals (including
        any job post you pasted), paths, steps, notes and progress, and the
        activity events we record. paths/ has one Markdown file per path.

        Your password is not included; only a one-way hash of it is stored.
      TEXT
    end
end
