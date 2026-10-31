# Onboarding: the three-step "where do you want to go?" form.
# The same form plans every later path ("New path" in the nav). With
# ?from=job_post the first step asks for a job post instead of a topic.
class LearningGoalsController < ApplicationController
  include GenerationGuard

  rate_limit to: 5, within: 10.minutes, only: :create, by: -> { Current.user.id },
    with: -> { redirect_to new_learning_goal_path, alert: GenerationGuard::RATE_LIMIT_MESSAGE }

  def new
    # Out of generations: the page explains why instead of showing a form
    # that can't be sent.
    @refusal = generation_refusal
    @learning_goal = Current.user.learning_goals.new(current_level: :beginner, hours_per_week: 5, from_job_post: params[:from] == "job_post")
  end

  def create
    @learning_goal = Current.user.learning_goals.new(learning_goal_params)

    if (@refusal = generation_refusal)
      render :new, status: :forbidden
    elsif @learning_goal.valid?
      learning_path = plan_path_for(@learning_goal)
      redirect_to learning_path, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def learning_goal_params
      params.expect(learning_goal: [ :topic, :current_level, :hours_per_week, :goal_description, :target_date, :job_post, :from_job_post ])
    end

    def plan_path_for(goal)
      learning_path = LearningGoal.transaction do
        goal.save!
        goal.create_learning_path!(user: Current.user).tap { |path| record_generation(path) }
      end
      GenerateLearningPathJob.perform_later(learning_path)
      learning_path
    end
end
