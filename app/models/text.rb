class Text < ApplicationRecord
  has_one :post, as: :postable
  validates :content, presence: true
  validates :content, length: { maximum: 500 }
end
