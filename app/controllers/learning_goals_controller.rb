# Onboarding: the three-step "where do you want to go?" form.
# The same form plans every later path ("New path" in the nav).
class LearningGoalsController < ApplicationController
  def new
    @learning_goal = Current.user.learning_goals.new(current_level: :beginner, hours_per_week: 5)
  end

  def create
    @learning_goal = Current.user.learning_goals.new(learning_goal_params)

    if @learning_goal.valid?
      learning_path = plan_path_for(@learning_goal)
      redirect_to learning_path, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def learning_goal_params
      params.expect(learning_goal: [ :topic, :current_level, :hours_per_week, :goal_description ])
    end

    def plan_path_for(goal)
      learning_path = LearningGoal.transaction do
        goal.save!
        goal.create_learning_path!(user: Current.user)
      end
      GenerateLearningPathJob.perform_later(learning_path)
      learning_path
    end
end
