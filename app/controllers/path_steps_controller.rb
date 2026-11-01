class PathStepsController < ApplicationController
  # Ticks a step on or off. Turbo gets back the updated route and progress;
  # without JavaScript the browser returns to the same step on the page.
  def toggle
    @path_step = PathStep.owned_by(Current.user).find(params[:id])
    @path_step.toggle_completion!
    Event.track_once(:first_step_done, user: Current.user) if @path_step.completed?
    @learning_path = @path_step.learning_path.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to learning_path_path(@learning_path, anchor: helpers.dom_id(@path_step)), status: :see_other }
    end
  end
end
