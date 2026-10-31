# Turns a LearningGoal into a validated learning path, and finds a substitute
# resource for a step whose link is broken.
#
#   PathGenerator.call(goal)              # => PathGenerator::Result
#   PathGenerator.replace_step(path_step) # => PathGenerator::Replacement
#
# The client (Gemini in production, Fake in dev without a key and in tests)
# only returns raw text; parsing and validation live here so every client
# goes through the same checks.
module PathGenerator
  class Error < StandardError; end
  class Timeout < Error; end
  class RequestFailed < Error; end

  class InvalidOutput < Error
    attr_reader :raw

    def initialize(message = "Generator returned invalid output", raw: nil)
      super(message)
      @raw = raw
    end
  end

  # usage: token counts for the cost log ({ input_tokens:, output_tokens:,
  # thinking_tokens: }), or nil when the client doesn't report them.
  Result = Data.define(:title, :summary, :steps, :skills, :raw, :usage)
  Replacement = Data.define(:description, :resource_type, :resource_url, :raw)

  # What a client may return instead of plain text when it knows token usage.
  Reply = Data.define(:text, :usage)

  class << self
    attr_writer :client

    def call(learning_goal)
      raw, usage = unwrap(client.generate(learning_goal))
      data = parse(raw)

      validator = Validator.new(data, require_skills: learning_goal.job_post?, budget_minutes: learning_goal.minutes_until_target)
      raise InvalidOutput.new(validator.errors.to_sentence, raw: raw) unless validator.valid?

      build_result(data, raw, usage)
    end

    # Asks for a different resource for one step whose link is broken.
    #
    #   PathGenerator.replace_step(step) # => PathGenerator::Replacement
    def replace_step(path_step)
      raw, _usage = unwrap(client.replace_step(path_step))
      data = parse(raw)

      validator = Validator.new(data, replacement: true)
      raise InvalidOutput.new(validator.errors.to_sentence, raw: raw) unless validator.valid?

      url = data["resource_url"].strip
      raise InvalidOutput.new("replacement repeats the broken link", raw: raw) if url == path_step.resource_url

      Replacement.new(description: data["description"].strip, resource_type: data["resource_type"].strip.downcase, resource_url: url, raw: raw)
    end

    def client
      @client || default_client
    end

    private
      # Clients return plain text, or a Reply when they also know token usage.
      def unwrap(reply)
        reply.is_a?(Reply) ? [ reply.text, reply.usage ] : [ reply, nil ]
      end

      def default_client
        api_key = ENV["GEMINI_API_KEY"]
        return Fake.new if Rails.env.test? || api_key.blank?

        Gemini.new(api_key: api_key)
      end

      def parse(raw)
        # Models sometimes wrap JSON in a markdown fence even when asked not to.
        json = raw.to_s.strip.delete_prefix("```json").delete_prefix("```").delete_suffix("```")
        data = JSON.parse(json)
        raise InvalidOutput.new("Expected a JSON object", raw: raw) unless data.is_a?(Hash)

        data
      rescue JSON::ParserError => e
        raise InvalidOutput.new("Response is not valid JSON: #{e.message.truncate(100)}", raw: raw)
      end

      def build_result(data, raw, usage)
        steps = data["steps"].map do |step|
          {
            title: step["title"].strip,
            description: step["description"].strip,
            resource_type: step["resource_type"].strip.downcase,
            resource_url: step["resource_url"].strip,
            estimated_minutes: step["estimated_minutes"]
          }
        end

        skills = Array(data["skills"]).grep(String).map(&:squish).compact_blank.uniq.first(Validator::SKILL_COUNT.max)

        Result.new(title: data["title"].strip, summary: data["summary"].strip, steps: steps, skills: skills, raw: raw, usage: usage)
      end
  end
end
