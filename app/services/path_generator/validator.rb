module PathGenerator
  # Checks the parsed JSON before anything touches the database.
  class Validator
    STEP_COUNT = 6..12
    STEP_FIELDS = %w[title description resource_type resource_url estimated_minutes].freeze

    attr_reader :errors

    def initialize(data)
      @data = data
      @errors = []
      validate
    end

    def valid?
      errors.empty?
    end

    private
      def validate
        %w[title summary].each do |field|
          errors << "#{field} is missing" unless present_string?(@data[field])
        end

        steps = @data["steps"]
        unless steps.is_a?(Array) && STEP_COUNT.cover?(steps.size)
          errors << "steps must be a list of #{STEP_COUNT.min}-#{STEP_COUNT.max} items"
          return
        end

        steps.each.with_index(1) { |step, number| validate_step(step, number) }
      end

      def validate_step(step, number)
        unless step.is_a?(Hash)
          errors << "step #{number} is not an object"
          return
        end

        STEP_FIELDS.excluding("estimated_minutes").each do |field|
          errors << "step #{number} #{field} is missing" unless present_string?(step[field])
        end

        type = step["resource_type"].to_s.strip.downcase
        errors << "step #{number} resource_type #{type.inspect} is not allowed" if type.present? && !PathStep::RESOURCE_TYPES.include?(type)

        url = step["resource_url"].to_s.strip
        errors << "step #{number} resource_url must be http(s)" if url.present? && !PathStep.http_url?(url)

        minutes = step["estimated_minutes"]
        errors << "step #{number} estimated_minutes must be a positive integer" unless minutes.is_a?(Integer) && minutes.positive?
      end

      def present_string?(value)
        value.is_a?(String) && value.strip.present?
      end
  end
end
