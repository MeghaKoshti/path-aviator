# Turns a LearningGoal into a validated learning path.
#
#   PathGenerator.call(goal) # => PathGenerator::Result
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

  Result = Data.define(:title, :summary, :steps, :raw)

  class << self
    attr_writer :client

    def call(learning_goal)
      raw = client.generate(learning_goal)
      data = parse(raw)

      validator = Validator.new(data)
      raise InvalidOutput.new(validator.errors.to_sentence, raw: raw) unless validator.valid?

      build_result(data, raw)
    end

    def client
      @client || default_client
    end

    private
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

      def build_result(data, raw)
        steps = data["steps"].map do |step|
          {
            title: step["title"].strip,
            description: step["description"].strip,
            resource_type: step["resource_type"].strip.downcase,
            resource_url: step["resource_url"].strip,
            estimated_minutes: step["estimated_minutes"]
          }
        end

        Result.new(title: data["title"].strip, summary: data["summary"].strip, steps: steps, raw: raw)
      end
  end
end
