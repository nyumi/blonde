class Book < ApplicationRecord
  belongs_to :user
  has_one :paper_book, dependent: :destroy
  has_one :kindle_book, dependent: :destroy
end
