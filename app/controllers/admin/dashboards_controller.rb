class Admin::DashboardsController < Admin::BaseController
  def show
    @stats = AdminStats.new
  end
end
