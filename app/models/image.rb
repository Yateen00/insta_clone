class Image < ApplicationRecord
  has_one :post, as: :postable
end
