class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :ensure_admin_logged_in, only: [:index]

  def index
    if params[:search] != nil
      @users=User.where("name like '%#{params[:search]}%'").paginate(page: params[:page], per_page: 5).order('name ASC')
    else
      @users=User.all.paginate(page: params[:page], per_page: 5).order('name ASC') 
    end
  end

  def show
    @user = User.find(params[:id])
    @books= @user.books
    @rented_at = BookUser.all
    respond_to do |format|
      format.html
      format.pdf{render template:'users/report', pdf:'report'}
    end
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        session[:current_user_id] = @user.id
        UserMailer.with(user: @user).new_user_alert.deliver_later
        format.html { redirect_to user_url(@user), notice: "User was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to user_url(@user), notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @books=@user.books
    @books.each do |bookdb|
     bookdb.Current_book += 1;
     bookdb.save!
    end

    @user.destroy
    
    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def admin_path

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :email, :password)
    end
end
