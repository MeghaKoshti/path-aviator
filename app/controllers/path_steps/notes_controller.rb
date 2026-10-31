# A private note on one step, edited in place. On the path page the note sits
# in a Turbo Frame: "Add note" / "Edit note" loads the form into it, and Save
# or Cancel swaps the note back. Without JavaScript the form is its own page
# and both lead back to the step on the path page.
class PathSteps::NotesController < ApplicationController
  before_action :set_path_step

  def show
    if turbo_frame_request?
      render partial: "path_steps/notes/note", locals: { path_step: @path_step, focus: true }
    else
      redirect_to step_on_path_page
    end
  end

  def edit
  end

  def update
    if @path_step.update(note_params)
      if turbo_frame_request?
        render partial: "path_steps/notes/note", locals: { path_step: @path_step, focus: true }
      else
        redirect_to step_on_path_page, status: :see_other
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    # Scoped to the signed-in user, so anyone else's step is a 404.
    def set_path_step
      @path_step = PathStep.owned_by(Current.user).find(params[:path_step_id])
    end

    def note_params
      params.expect(path_step: [ :note ])
    end

    def step_on_path_page
      learning_path_path(@path_step.learning_path, anchor: helpers.dom_id(@path_step))
    end
end
