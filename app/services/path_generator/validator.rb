module PathGenerator
  # Checks the parsed JSON before anything touches the database.
  class Validator
    STEP_COUNT = 6..12
    STEP_FIELDS = %w[title description resource_type resource_url estimated_minutes].freeze
    # A substitute for one step whose link is broken.
    REPLACEMENT_FIELDS = %w[description resource_type resource_url].freeze
    SKILL_COUNT = 1..10
    # Estimates are rough, so a plan may run this much over the time available.
    BUDGET_SLACK = 1.25

    attr_reader :errors

    # require_skills: the goal came from a job post, so the skills it asks for
    # must be listed. budget_minutes: the time until the target date, which
    # the steps must fit into.
    def initialize(data, replacement: false, require_skills: false, budget_minutes: nil)
      @data = data
      @replacement = replacement
      @require_skills = require_skills
      @budget_minutes = budget_minutes
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
        validate_skills if @require_skills
        validate_budget(steps) if @budget_minutes && errors.empty?
      end

      def validate_skills
        skills = @data["skills"]
        return if skills.is_a?(Array) && SKILL_COUNT.cover?(skills.size) && skills.all? { |skill| present_string?(skill) }

        errors << "skills must be a list of #{SKILL_COUNT.min}-#{SKILL_COUNT.max} names"
      end

      def validate_budget(steps)
        total = steps.sum { |step| step["estimated_minutes"] }
        return if total <= @budget_minutes * BUDGET_SLACK

        errors << "steps take #{total} minutes but only #{@budget_minutes} are available before the target date"
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
