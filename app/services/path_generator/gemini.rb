module PathGenerator
  # Calls the Google Generative Language API and returns the model's raw JSON text.
  class Gemini
    ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/%<model>s:generateContent".freeze
    DEFAULT_MODEL = "gemini-2.5-flash".freeze

    def initialize(api_key: ENV.fetch("GEMINI_API_KEY"), model: ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL), http: HttpClient.new)
      @api_key = api_key
      @model = model.presence || DEFAULT_MODEL
      @http = http
    end

    def generate(learning_goal)
      response = @http.post_json(
        format(ENDPOINT, model: @model),
        body: request_body(learning_goal).to_json,
        # Header rather than ?key= so the key never ends up in URL logs.
        headers: { "x-goog-api-key" => @api_key }
      )
      raise RequestFailed, "Gemini returned HTTP #{response.status}" unless response.success?

      extract_text(response.body)
    end

    def prompt_for(goal)
      <<~PROMPT
        You are an expert curriculum designer. Build a personalised learning path.

        Learner:
        - Topic: #{goal.topic}
        - Current level: #{goal.current_level}
        - Time available: #{goal.hours_per_week} hours per week
        - Goal: #{goal.goal_description.presence || "Not specified"}

        Respond with STRICT JSON only: no markdown, no code fences, no commentary.
        Use exactly this shape:
        {
          "title": "short, specific path title",
          "summary": "2-3 sentences on what the learner will be able to do",
          "steps": [
            {
              "title": "step title",
              "description": "1-2 sentences: what to do and why it matters",
              "resource_type": "one of: #{PathStep::RESOURCE_TYPES.join(", ")}",
              "resource_url": "a real, publicly reachable https URL",
              "estimated_minutes": 45
            }
          ]
        }

        Rules:
        - Between #{Validator::STEP_COUNT.min} and #{Validator::STEP_COUNT.max} steps, in the order they should be done.
        - Match the difficulty to a #{goal.current_level} learner.
        - Keep the workload realistic for #{goal.hours_per_week} hours per week.
        - estimated_minutes is a positive whole number.
        - Prefer official documentation and well-known free resources.
      PROMPT
    end

    private
      def request_body(goal)
        {
          contents: [ { role: "user", parts: [ { text: prompt_for(goal) } ] } ],
          generationConfig: { responseMimeType: "application/json", temperature: 0.7 }
        }
      end

      def extract_text(body)
        text = JSON.parse(body).dig("candidates", 0, "content", "parts", 0, "text")
        raise InvalidOutput.new("Gemini response had no text", raw: body) if text.blank?

        text
      rescue JSON::ParserError
        raise InvalidOutput.new("Gemini response envelope was not JSON", raw: body)
      end
  end
end
