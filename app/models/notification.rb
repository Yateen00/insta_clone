class Notification < ApplicationRecord
  belongs_to :user # The recipient of the notification
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update(read: true)
  end
end
