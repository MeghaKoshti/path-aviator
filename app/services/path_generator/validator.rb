module PathGenerator
  # Checks the parsed JSON before anything touches the database.
  class Validator
    STEP_COUNT = 6..12
    STEP_FIELDS = %w[title description resource_type resource_url estimated_minutes].freeze
    # A substitute for one step whose link is broken.
    REPLACEMENT_FIELDS = %w[description resource_type resource_url].freeze

    attr_reader :errors

    def initialize(data, replacement: false)
      @data = data
      @replacement = replacement
      @errors = []
      validate
    end

    def valid?
      errors.empty?
    end

    private
      def validate
        return validate_step(@data, "replacement", fields: REPLACEMENT_FIELDS) if @replacement

        %w[title summary].each do |field|
          errors << "#{field} is missing" unless present_string?(@data[field])
        end

        steps = @data["steps"]
        unless steps.is_a?(Array) && STEP_COUNT.cover?(steps.size)
          errors << "steps must be a list of #{STEP_COUNT.min}-#{STEP_COUNT.max} items"
          return
        end

        steps.each.with_index(1) { |step, number| validate_step(step, "step #{number}") }
      end

      def validate_step(step, name, fields: STEP_FIELDS)
        unless step.is_a?(Hash)
          errors << "#{name} is not an object"
          return
        end

        fields.excluding("estimated_minutes").each do |field|
          errors << "#{name} #{field} is missing" unless present_string?(step[field])
        end

        type = step["resource_type"].to_s.strip.downcase
        errors << "#{name} resource_type #{type.inspect} is not allowed" if type.present? && !PathStep::RESOURCE_TYPES.include?(type)

        url = step["resource_url"].to_s.strip
        errors << "#{name} resource_url must be http(s)" if url.present? && !PathStep.http_url?(url)

        return unless fields.include?("estimated_minutes")

        minutes = step["estimated_minutes"]
        errors << "#{name} estimated_minutes must be a positive integer" unless minutes.is_a?(Integer) && minutes.positive?
      end

      def present_string?(value)
        value.is_a?(String) && value.strip.present?
      end
  end
end
