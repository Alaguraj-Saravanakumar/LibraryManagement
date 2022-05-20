class User < ApplicationRecord
    has_secure_password
    has_many :book_users, dependent: :destroy
    has_many :books, through: :book_users,dependent: :destroy

    validates :email, presence: true
    validates :name, presence: true

    ADMIN = 'admin'.freeze
    def is_admin?
       role.eql?(ADMIN)
    end

    def self.search(search)
        if search
          where(["name LIKE?","#{search}%"])
        else
          all
        end
    end

end
