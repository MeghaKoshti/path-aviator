# Demo data for local development and the public demo account.
# Safe to run any number of times: records are looked up before being created,
# and re-running resets the demo progress to the state below.

demo = User.find_or_initialize_by(email_address: "demo@pathaviator.dev")
demo.update!(name: "Demo Learner", password: "pathaviator-demo")

# A lambda rather than a method so loading seeds doesn't add a method to Object.
# completed_days_ago: one entry per finished step, in order (0 = today), so the
# dashboard's week and streak look alive whenever the seeds are run.
seed_path = lambda do |user, goal_attrs:, path_attrs:, steps:, completed_days_ago:, shared: false|
  goal = user.learning_goals.find_or_initialize_by(topic: goal_attrs.fetch(:topic))
  goal.update!(goal_attrs)

  path = goal.learning_path || goal.build_learning_path(user: user)
  path.update!(path_attrs.merge(status: :ready, error_message: nil, generated_at: path.generated_at || 3.weeks.ago))

  steps.each.with_index(1) do |attrs, position|
    step = path.path_steps.find_or_initialize_by(position: position)
    days_ago = completed_days_ago[position - 1]
    step.update!({ note: nil }.merge(attrs, completed_at: days_ago && days_ago.days.ago))
  end

  # Keep the same token on re-runs so a copied demo link keeps working.
  if shared
    path.share! unless path.shared?
  elsif path.shared?
    path.unshare!
  end

  path
end

seed_path.call demo,
  goal_attrs: {
    topic: "Ruby on Rails",
    current_level: :beginner,
    hours_per_week: 6,
    goal_description: "Build and deploy my own full-stack app with Rails 8 and Hotwire."
  },
  path_attrs: {
    title: "Ruby on Rails: from first app to production",
    summary: "Go from the Rails basics to a deployed Hotwire app in about two months. " \
             "Each step pairs reading with hands-on practice so you finish with a project you can show."
  },
  completed_days_ago: [ 2, 1, 0 ],
  shared: true,
  steps: [
    { title: "Ruby in 20 minutes", description: "Get comfortable with Ruby syntax, blocks and classes before touching Rails.",
      resource_type: "docs", resource_url: "https://www.ruby-lang.org/en/documentation/quickstart/", estimated_minutes: 30 },
    { title: "Getting Started with Rails", description: "Build the official blog app to see MVC, routing and generators in action.",
      resource_type: "docs", resource_url: "https://guides.rubyonrails.org/getting_started.html", estimated_minutes: 120,
      note: "Built the blog twice. The second time without scaffolds, which made routes and controllers click." },
    { title: "Active Record basics", description: "Learn models, migrations and validations, the heart of most Rails apps.",
      resource_type: "docs", resource_url: "https://guides.rubyonrails.org/active_record_basics.html", estimated_minutes: 60,
      note: "Revisit callbacks vs. service objects.\nTry `bin/rails console --sandbox` for experiments." },
    { title: "Associations in depth", description: "Model real relationships with has_many, belongs_to and has_many :through.",
      resource_type: "article", resource_url: "https://guides.rubyonrails.org/association_basics.html", estimated_minutes: 75 },
    { title: "Hotwire: Turbo Frames and Streams", description: "Add fast, SPA-like updates without writing a JavaScript framework.",
      resource_type: "video", resource_url: "https://hotwired.dev/", estimated_minutes: 60 },
    { title: "Testing Rails applications", description: "Write model, controller and system tests with Minitest.",
      resource_type: "docs", resource_url: "https://guides.rubyonrails.org/testing.html", estimated_minutes: 90 },
    { title: "Build a CRUD side project", description: "Combine everything in a small app of your own with authentication.",
      resource_type: "practice", resource_url: "https://github.com/new", estimated_minutes: 300 },
    { title: "Deploy with Kamal", description: "Ship the app to a server and learn how a production Rails setup fits together.",
      resource_type: "course", resource_url: "https://kamal-deploy.org/docs/installation/", estimated_minutes: 120 }
  ]

seed_path.call demo,
  goal_attrs: {
    topic: "Git and GitHub",
    current_level: :beginner,
    hours_per_week: 3,
    goal_description: "Use Git confidently at work and open my first pull request."
  },
  path_attrs: {
    title: "Git and GitHub essentials",
    summary: "Learn the everyday Git workflow, branching and pull requests so you can collaborate on any team."
  },
  completed_days_ago: [ 26, 24, 23, 19, 17, 12 ],
  steps: [
    { title: "What is version control?", description: "Understand why Git exists and how commits form a history.",
      resource_type: "docs", resource_url: "https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control", estimated_minutes: 20 },
    { title: "Git basics", description: "Practise init, add, commit, status and log on a throwaway repo.",
      resource_type: "docs", resource_url: "https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository", estimated_minutes: 60 },
    { title: "Branching interactively", description: "Visualise branches, merges and rebases in the browser.",
      resource_type: "practice", resource_url: "https://learngitbranching.js.org/", estimated_minutes: 90 },
    { title: "GitHub flow", description: "Learn the branch, pull request and review cycle used by most teams.",
      resource_type: "article", resource_url: "https://docs.github.com/en/get-started/using-github/github-flow", estimated_minutes: 20 },
    { title: "GitHub Skills: Introduction to GitHub", description: "Complete the guided course and open a real pull request.",
      resource_type: "course", resource_url: "https://github.com/skills/introduction-to-github", estimated_minutes: 60 },
    { title: "Resolve a merge conflict", description: "Create a conflict on purpose and fix it from the command line.",
      resource_type: "practice", resource_url: "https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-using-the-command-line", estimated_minutes: 30 }
  ]
