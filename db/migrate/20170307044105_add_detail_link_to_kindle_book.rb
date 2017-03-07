class AddDetailLinkToKindleBook < ActiveRecord::Migration[5.0]
  def change
    add_column :kindle_books, :detail_link, :string
  end
end
