class Book < ApplicationRecord
  has_one :paper_book
  has_one :kindle_book
end
