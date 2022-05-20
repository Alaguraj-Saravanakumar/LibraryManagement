class UserbooksController < ApplicationController
    
    def rent
    BookUser.create(user_id: current_user.id, book_id: params[:book_id])
    @book = Book.find(params[:book_id])
    @book.Current_book -= 1;
    @book.save
    UserMailer.with(user: current_user,book: @book ).rent_mailer_alert.deliver_later
    UserMailer.with(user: current_user,book: @book ).reminder_mailer_alert.deliver_later(wait_until: 7.days.from_now)
    flash[:notice] = "Book has been added"
    redirect_to current_user
    end

    def unrent
     book = BookUser.find_by(user_id:current_user.id,book_id:params[:book_id])
     book.destroy
     @bookdb = Book.find(params[:book_id])
     @bookdb.Current_book += 1;
     @bookdb.save
     UserMailer.with(user: current_user,book: @bookdb ).unrent_mailer_alert.deliver_later
     flash[:notice] = "Book has been Unrented"
     redirect_to current_user
    end

end


