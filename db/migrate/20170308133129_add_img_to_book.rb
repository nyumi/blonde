class AddImgToBook < ActiveRecord::Migration[5.0]
  def change
    add_column :books, :img, :string
  end
end
