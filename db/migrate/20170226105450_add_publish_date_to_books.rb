class AddPublishDateToBooks < ActiveRecord::Migration[5.0]
  def change
    add_column :books, :publish_date, :date
  end
end
