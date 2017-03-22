class RemovePriceAndPointFromKindleBook < ActiveRecord::Migration[5.0]
  def change
    remove_column :kindle_books, :price, :integer
    remove_column :kindle_books, :point, :integer
  end
end
