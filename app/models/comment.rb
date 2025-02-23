class Comment < ApplicationRecord
  belongs_to :post, counter_cache: :comments_count
  belongs_to :user
  belongs_to :reply_to, class_name: "Comment", optional: true, inverse_of: :replies, counter_cache: :replies_count
  has_many :replies, class_name: "Comment", foreign_key: "reply_to_id", dependent: :destroy, inverse_of: :reply_to
  validate :content, :content_not_empty
  has_many :likes, as: :likeable, dependent: :destroy
  scope :order_by_user, lambda { |user_id|
    order(Arel.sql("CASE WHEN user_id = #{user_id} THEN 0 ELSE 1 END"))
  }

  private
    def content_not_empty
      errors.add(:content, "can't be empty") if content.strip.empty?
    end
end
