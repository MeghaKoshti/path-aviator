module PathGenerator
  # One real generator call for a made-up goal, printed for a human to read.
  # Backs `bin/rails path_aviator:smoke_generate`. Database writes are blocked,
  # so it is safe to run against production.
  class SmokeRun
    def initialize(topic:, level:, hours:, out: $stdout)
      @goal = LearningGoal.new(topic: topic, current_level: level, hours_per_week: hours)
      @out = out
    end

    # Returns true when the generator gave back a valid path.
    def run
      return false unless goal_valid?

      say "Client: #{PathGenerator.client.class.name}"
      say "Goal:   #{@goal.topic} (#{@goal.current_level}, #{@goal.hours_per_week} h/week)"

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = ActiveRecord::Base.while_preventing_writes { PathGenerator.call(@goal) }
      print_result(result)
      true
    rescue InvalidOutput => e
      say "Validation: FAILED (#{e.message})"
      say "Raw response:\n#{e.raw.to_s.truncate(2_000)}"
      false
    rescue Error => e
      say "Request failed: #{e.class.name.demodulize}: #{e.message}"
      false
    ensure
      say format("Time: %.1fs", Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) if started
    end

    private
      def goal_valid?
        # No user is needed: the goal is never saved.
        @goal.validate
        errors = @goal.errors.reject { |error| error.attribute == :user }
        errors.each { |error| say "Invalid input: #{error.full_message}" }
        errors.empty?
      end

      def print_result(result)
        say "Validation: passed"
        say ""
        say result.title
        say result.summary
        say ""
        result.steps.each.with_index(1) do |step, number|
          say "#{number}. #{step[:title]} [#{step[:resource_type]}, #{step[:estimated_minutes]} min]"
          say "   #{step[:resource_url]}"
        end
        say ""
        say "#{result.steps.size} steps, #{result.steps.sum { |step| step[:estimated_minutes] }} minutes in total"
      end

      def say(line)
        @out.puts(line)
      end
  end
end
