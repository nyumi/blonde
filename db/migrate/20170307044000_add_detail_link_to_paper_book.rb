  class AddDetailLinkToPaperBook < ActiveRecord::Migration[5.0]
  def change
    add_column :paper_books, :detail_link, :string
  end
end
