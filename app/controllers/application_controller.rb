class ApplicationController < ActionController::Base

    helper_method :current_user
    def ensure_user_logged_in
        unless current_user
          redirect_to(login_path, notice: 'Please login')
        end
    end


    def ensure_admin_logged_in
        unless current_user.is_admin?
            redirect_to(login_path, notice: 'Access denied')
        end
    end

    def current_user
        return @current_user if @current_user
        current_user_id=session[:current_user_id]
        if current_user_id
            current_user= User.find_by_id(current_user_id)
        else
            nil
        end
    end

end
