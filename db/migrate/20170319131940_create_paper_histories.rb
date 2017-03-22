class CreatePaperHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :paper_histories do |t|
      t.integer :book_id
      t.integer :price
      t.integer :point

      t.timestamps
    end
  end
end
