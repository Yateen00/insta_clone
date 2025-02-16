class Image < ApplicationRecord
  has_one :post, as: :postable, dependent: :destroy
end
