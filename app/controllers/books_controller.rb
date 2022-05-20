class BooksController < ApplicationController
  before_action :set_book, only: %i[ show edit update destroy ]
  before_action :ensure_user_logged_in
  before_action :ensure_admin_logged_in, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    if params[:search] != nil
      @books=Book.where("title like '%#{params[:search]}%' OR author like '%#{params[:search]}%'").paginate(page: params[:page], per_page: 5).order('title ASC')
    else
      @books=Book.all.paginate(page: params[:page], per_page: 5).order('title ASC') 
    end
  end

  def show
    @user=current_user
    @book = Book.find(params[:id])

  end


  def new
    @book = Book.new
  end


  def edit
  end


  def create
    @book = Book.new(book_params)

    respond_to do |format|
      if @book.save
        format.html {redirect_to book_url(@book), notice: "Book was successfully created." }
      else
         format.html { render :new, status: :unprocessable_entity } 
      end
    end
  end

 
  def update
    respond_to do |format|
      if @book.update(book_params)
         format.html { redirect_to book_url(@book), notice: "Book was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @book.destroy
    respond_to do |format|
      format.html {redirect_to books_url, notice: "Book was successfully destroyed." }
    end
  end

  def search
  end

  private
    def set_book
      @book = Book.find(params[:id])
    end
    
    def book_params
      params.require(:book).permit(:title, :author, :published_date,:Total_book,:Current_book)
    end
end
