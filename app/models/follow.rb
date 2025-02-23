class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User", inverse_of: :follows_as_follower, counter_cache: :follows_count
  belongs_to :followee, class_name: "User", inverse_of: :follows_as_followee, counter_cache: :followers_count

  validates :follower_id, uniqueness: { scope: :followee_id }
  validate :self_follow
  def self_follow
    errors.add(:base, "You cannot follow yourself") if follower_id == followee_id
  end
end
