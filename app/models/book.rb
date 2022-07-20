class Book < ApplicationRecord
    has_many :book_users, dependent: :destroy
    has_many :users, through: :book_users,dependent: :destroy
    validates :title, presence: true,uniqueness: true
    validates :author, presence: true
    validates :published_date, presence: true
end
