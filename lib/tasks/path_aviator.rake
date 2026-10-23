namespace :path_aviator do
  desc "Generate one learning path with Gemini and print it, without saving anything (needs GEMINI_API_KEY)"
  task :smoke_generate, %i[topic level hours] => :environment do |_task, args|
    abort "GEMINI_API_KEY is not set, so there is no real generator to test." if ENV["GEMINI_API_KEY"].blank?

    args.with_defaults(topic: "Ruby on Rails", level: "beginner", hours: "5")
    hours = Integer(args[:hours], exception: false)

    exit 1 unless PathGenerator::SmokeRun.new(topic: args[:topic], level: args[:level], hours: hours).run
  end
end
