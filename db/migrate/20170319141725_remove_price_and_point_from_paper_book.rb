class RemovePriceAndPointFromPaperBook < ActiveRecord::Migration[5.0]
  def change
    remove_column :paper_books, :price, :integer
    remove_column :paper_books, :point, :integer
  end
end
