class ApplicationController < ActionController::Base
  layout -> { devise_controller? ? "finance" : "application" }

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || finance_root_path
  end
end
