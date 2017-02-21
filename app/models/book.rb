class Book < ApplicationRecord
  belongs_to :user
  has_one :paper_book
  has_one :kindle_book
end
