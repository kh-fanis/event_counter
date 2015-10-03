class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if:  :devise_controller?

  def set_user_information
    @user_inf = current_user ? current_user.full_name : need_to_auth
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :full_name
  end
end
