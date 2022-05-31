class UserMailer < ApplicationMailer
    def login_alert
      @user=params[:user]
      mail(to:@user.email , subject: "Login Alert")
    end

    def new_user_alert
      @user=params[:user]
      mail(to:@user.email , subject: "User Signup Alert")
    end

    def rent_mailer_alert
        @user=params[:user]
        @book=params[:book]
        attachments['receipt.pdf'] = WickedPdf.new.pdf_from_string(
            render_to_string(:pdf => 'MyPDF',:template => 'userbooks/rented')
          )
        mail(to:@user.email , subject: "User Book Rent Alert")
    end

    def unrent_mailer_alert
        @user=params[:user]
        @book=params[:book]
        mail(to:@user.email , subject: "User Book UnRent Alert")
    end

    def reminder_mailer_alert
        @user=params[:user]
        @book=params[:book]
        mail(to:@user.email , subject: "Book reminder Notification")
    end
    
end
