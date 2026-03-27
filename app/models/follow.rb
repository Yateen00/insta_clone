class Follow < ApplicationRecord
  enum :status, { pending: 0, accepted: 1 }, default: :accepted

  belongs_to :follower, class_name: "User", inverse_of: :follows_as_follower
  belongs_to :followee, class_name: "User", inverse_of: :follows_as_followee

  validates :follower_id, uniqueness: { scope: :followee_id }
  validate :self_follow
  def self_follow
    errors.add(:base, "You cannot follow yourself") if follower_id == followee_id
  end

  after_create :update_counters_on_create
  after_update :update_counters_on_status_change
  before_destroy :update_counters_on_destroy

  after_create :create_notification
  before_destroy :delete_notification
  after_update :handle_accepted_notification, if: -> { saved_change_to_status? && accepted? }

  private
    def update_counters_on_create
      if accepted?
        User.increment_counter(:follows_count, follower_id)
        User.increment_counter(:followers_count, followee_id)
      end
    end

    def update_counters_on_status_change
      return unless saved_change_to_status?
      if accepted?
        User.increment_counter(:follows_count, follower_id)
        User.increment_counter(:followers_count, followee_id)
      end
    end

    def update_counters_on_destroy
      if accepted?
        User.decrement_counter(:follows_count, follower_id)
        User.decrement_counter(:followers_count, followee_id)
      end
    end

    def create_notification
      return if follower == followee
      Notification.create(user: followee, notifiable: self)
    end

    def delete_notification
      # Destroy all notifications for this follow (both followee's request notification
      # and any follower's acceptance notification)
      Notification.where(notifiable: self).destroy_all
    end

    def handle_accepted_notification
      Notification.create(user: follower, notifiable: self)
    end
end
