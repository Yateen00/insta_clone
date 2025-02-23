class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User", inverse_of: :follows_as_follower, counter_cache: :follows_count
  belongs_to :followee, class_name: "User", inverse_of: :follows_as_followee, counter_cache: :followers_count

  validates :follower_id, uniqueness: { scope: :followee_id }
  validate :self_follow
  def self_follow
    errors.add(:base, "You cannot follow yourself") if follower_id == followee_id
  end

  after_create :create_notification
  before_destroy :delete_notification

  private
    def create_notification
      return if follower == followee # Don't notify if following self

      Notification.create(user: followee, notifiable: self)
    end

    def delete_notification
      Notification.find_by(user: followee, notifiable: self)&.destroy
    end
end
