class RemovePublishedDateFromPaperBooks < ActiveRecord::Migration[5.0]
  def change
    remove_column :paper_books, :published_date, :date
  end
end
