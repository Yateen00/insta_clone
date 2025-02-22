class Comment < ApplicationRecord
  belongs_to :post, counter_cache: :comments_count
  belongs_to :user
  belongs_to :reply_to, class_name: "Comment", optional: true, inverse_of: :replies, counter_cache: :replies_count
  has_many :replies, class_name: "Comment", foreign_key: "reply_to_id", dependent: :destroy, inverse_of: :reply_to
  validates :content, presence: true
  # has_many :likes, as: :likeable, dependent: :destroy
end
