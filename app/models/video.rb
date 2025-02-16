class Video < ApplicationRecord
  has_one :post, as: :postable, dependent: :destroy
end
