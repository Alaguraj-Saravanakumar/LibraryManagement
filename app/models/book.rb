class Book < ApplicationRecord
    has_many :book_users, dependent: :destroy
    has_many :users, through: :book_users,dependent: :destroy
    validates :title, presence: true
    validates :author, presence: true
    validates :published_date, presence: true

    def self.search(search)
        if search
          where(["title LIKE? OR author LIKE?","%#{search}%","%#{search}%"])
        else
          all
        end
    end 

end
