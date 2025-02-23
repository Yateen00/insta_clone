class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: true
  validate :unique_like
  def unique_like
    return unless Like.where(user: user, likeable: likeable).exists?

    errors.add(:user, "has already liked this")
  end
end
