class User < ApplicationRecord
    has_secure_password
    has_many :book_users, dependent: :destroy
    has_many :books, through: :book_users,dependent: :destroy

    validates :email, presence: true,uniqueness: true,format: { with: URI::MailTo::EMAIL_REGEXP } 
    validates :name, presence: true,uniqueness: true

    ADMIN = 'admin'.freeze
    def is_admin?
      role.eql?(ADMIN)
    end
end
