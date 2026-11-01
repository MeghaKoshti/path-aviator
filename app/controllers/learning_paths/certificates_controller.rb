# Owner controls for a finished path's certificate: choose evidence links and
# publish (Pro), or revoke. Revoking turns the public link off.
class LearningPaths::CertificatesController < ApplicationController
  before_action :set_learning_path
  before_action :require_finished_path, :require_pro, except: :destroy

  def new
  end

  def create
    if Current.user.name.blank?
      redirect_to new_learning_path_certificate_path(@learning_path), alert: "Add your name in Settings first. It’s printed on the certificate."
    elsif save_evidence
      @learning_path.publish_certificate!
      redirect_to certificate_path(@learning_path.certificate_token), notice: "Certificate published.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @learning_path.revoke_certificate!
    redirect_to learning_path_path(@learning_path), notice: "Certificate revoked. Its link no longer works.", status: :see_other
  end

  private
    def set_learning_path
      @learning_path = Current.user.learning_paths.includes(:path_steps).find(params[:learning_path_id])
    end

    def require_finished_path
      redirect_to @learning_path, alert: "Finish every step to get a certificate." unless @learning_path.completed?
    end

    def require_pro
      redirect_to pricing_path, alert: "Certificates are part of Pro." unless ProAccess.granted?(Current.user)
    end

    # Evidence links arrive as { step_id => url }. Only this path's steps are touched.
    def save_evidence
      urls = params.fetch(:evidence, {}).permit(@learning_path.path_steps.map { |step| step.id.to_s })
      steps = @learning_path.path_steps.each { |step| step.evidence_url = urls[step.id.to_s] if urls.key?(step.id.to_s) }
      PathStep.transaction { steps.map(&:save).all? or raise ActiveRecord::Rollback }
      steps.none? { |step| step.errors.any? }
    end
end
