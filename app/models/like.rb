class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: true
  validate :unique_like
  def unique_like
    return unless Like.where(user: user, likeable: likeable).exists?

    errors.add(:user, "has already liked this")
  end
  after_create :create_notification
  before_destroy :delete_notification

  private
    def create_notification
      # Determine the owner of the liked item (either post creator or comment user)
      owner = likeable.is_a?(Post) ? likeable.creator : likeable.user

      return if owner == user # Don't notify if liking own post/comment

      Notification.create(user: owner, notifiable: self)
    end

    def delete_notification
      Notification.find_by(user: likeable.is_a?(Post) ? likeable.creator : likeable.user, notifiable: self)&.destroy
    end
end
