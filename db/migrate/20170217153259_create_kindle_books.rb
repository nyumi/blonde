class CreateKindleBooks < ActiveRecord::Migration[5.0]
  def change
    create_table :kindle_books do |t|
      t.integer :book_id
      t.integer :price
      t.date :published_date
      t.integer :point

      t.timestamps
    end
  end
end
