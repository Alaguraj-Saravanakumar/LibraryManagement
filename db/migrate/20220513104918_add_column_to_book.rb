class AddColumnToBook < ActiveRecord::Migration[7.0]
  def change
    add_column :books, :Total_book, :integer
    add_column :books, :Current_book, :integer
  end
end
