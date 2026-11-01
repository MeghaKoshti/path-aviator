module PathGenerator
  # Offline stand-in for Gemini: a realistic 8-step path that adapts to the
  # goal's topic. Used in tests, and in development when GEMINI_API_KEY is unset.
  # From a job post it picks out well-known skill names, and with a target date
  # it shortens the steps so they fit the time left, as the real prompt asks.
  class Fake
    KNOWN_SKILLS = [
      "Ruby", "Ruby on Rails", "Hotwire", "RSpec", "Sidekiq", "SQL", "PostgreSQL", "MySQL", "Redis",
      "JavaScript", "TypeScript", "React", "Node.js", "Python", "Django", "Go", "Java", "Docker",
      "Kubernetes", "AWS", "Git", "REST APIs", "GraphQL", "CI/CD", "Linux", "System design"
    ].freeze

    def generate(goal)
      topic = goal.topic
      level = goal.current_level.to_s.humanize.downcase
      query = CGI.escape(topic)

      path = {
        title: "#{topic}: #{level.capitalize} Learning Path",
        summary: "A practical route through #{topic} for #{level} learners with about #{goal.hours_per_week} hours a week. " \
                 "You'll start with the core ideas, practise them on small exercises and finish by building a project you can show.",
        steps: [
          step("Watch a #{topic} crash course", "Get the big picture first so later details have somewhere to fit.",
               "video", "https://www.youtube.com/results?search_query=#{query}+crash+course", 60),
          step("Read the official #{topic} documentation", "Skim the getting-started guide and note the key concepts.",
               "docs", "https://www.google.com/search?q=#{query}+official+documentation", 90),
          step("Learn the core concepts", "Read an in-depth article on the fundamentals and write a one-page summary.",
               "article", "https://dev.to/search?q=#{query}", 45),
          step("Do guided exercises", "Work through small exercises to turn reading into muscle memory.",
               "practice", "https://exercism.org/tracks", 120),
          step("Take a structured course module", "Follow one free course module end to end without skipping.",
               "course", "https://www.freecodecamp.org/news/search/?query=#{query}", 180),
          step("Study common patterns and pitfalls", "Learn the mistakes people usually make and how to avoid them.",
               "article", "https://roadmap.sh/", 45),
          step("Read real-world #{topic} code", "Explore well-known open-source projects to see how experts structure things.",
               "practice", "https://github.com/search?q=#{query}&type=repositories", 90),
          step("Build and share a small project", "Combine everything in a small project and publish it on GitHub.",
               "practice", "https://github.com/new", 240)
        ]
      }
      path[:skills] = skills_in(goal.job_post, fallback: topic) if goal.job_post?
      fit_to_budget(path[:steps], goal.minutes_until_target) if goal.target_date
      path.to_json
    end

    # A substitute resource for a step whose link is broken: a search for the
    # step itself, which always exists.
    def replace_step(path_step)
      {
        description: "#{path_step.description.to_s.strip.presence || path_step.title} Start from a fresh, well-rated guide.".squish,
        resource_type: "article",
        resource_url: "https://dev.to/search?q=#{CGI.escape(path_step.title)}"
      }.to_json
    end

    private
      def skills_in(text, fallback:)
        found = KNOWN_SKILLS.select { |skill| text.match?(/(?<![\w.])#{Regexp.escape(skill)}(?![\w-])/i) }
        # "Ruby on Rails" already says "Ruby".
        found -= [ "Ruby" ] if found.include?("Ruby on Rails")
        found.presence&.first(8) || [ fallback ]
      end

      def fit_to_budget(steps, budget)
        total = steps.sum { |step| step[:estimated_minutes] }
        return if total <= budget

        steps.each { |step| step[:estimated_minutes] = [ step[:estimated_minutes] * budget / total, 10 ].max }
      end

      def step(title, description, resource_type, resource_url, estimated_minutes)
        { title:, description:, resource_type:, resource_url:, estimated_minutes: }
      end
  end
end
