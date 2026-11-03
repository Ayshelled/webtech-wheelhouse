class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  after_action :verify_authorized
  after_action :verify_policy_scoped, if: :index_action?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def pundit_user
    Current.user
  end

  private

  def index_action?
    action_name == "index"
  end

  def user_not_authorized
    render "errors/forbidden", status: :forbidden
  end
end
