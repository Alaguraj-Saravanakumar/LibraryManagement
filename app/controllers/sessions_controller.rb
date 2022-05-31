class SessionsController < ApplicationController

    def create
        email = params[:email]
        password = params[:password]
        user = User.find_by(email: email)
        if user && user.authenticate(password)
            redirect_to(user, notice: 'successfully logged in')
            session[:current_user_id] = user.id
            UserMailer.with(user: user).login_alert.deliver_later
        else
           redirect_to(login_path, alert: "invalid credentials")
        end
    end

    def destroy
        session[:current_user_id] = nil
        redirect_to(root_path, notice:'Successfully logged out', status:303)
    end
end
