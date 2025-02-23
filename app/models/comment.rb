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
  after_create :create_notification
  before_destroy :delete_notification

  private
    def create_notification
      return if user == post.creator # Don't notify if commenting on own post

      Notification.create(user: post.creator, notifiable: self)
      Notification.create(user: reply_to.user, notifiable: self) if reply_to
    end

    def delete_notification
      Notification.find_by(user: post.creator, notifiable: self)&.destroy
      Notification.find_by(user: reply_to.user, notifiable: self)&.destroy if reply_to
    end

    def content_not_empty
      errors.add(:content, "can't be empty") if content.strip.empty?
    end
end
