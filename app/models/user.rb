class User < ApplicationRecord
  attr_writer :login

  has_many :follows_as_follower, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy,
                                 inverse_of: :follower
  has_many :follows_as_followee, class_name: "Follow", foreign_key: "followee_id", dependent: :destroy,
                                 inverse_of: :followee
  has_many :notifications, dependent: :destroy
  has_many :follows, -> { merge(Follow.accepted) }, through: :follows_as_follower, source: :followee
  has_many :followers, -> { merge(Follow.accepted) }, through: :follows_as_followee, source: :follower

  has_many :posts, foreign_key: "creator_id", dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :likeable, source_type: "Post"
  has_many :liked_comments, through: :likes, source: :likeable, source_type: "Comment"
  has_one :profile, dependent: :destroy, inverse_of: :user
  accepts_nested_attributes_for :profile

  after_create :create_profile
  validates :username, format: { with: /\A[a-zA-Z0-9_.-]*\z/, multiline: true,
                                 message: "can only contain letters, numbers, underscores, and periods." }
  validates :username, uniqueness: { case_sensitive: false }, presence: true, length: { in: 1..20 }
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[github google_oauth2]

  validate :validate_username
  after_create :send_welcome_email
  def validate_username
    return unless User.where(email: username).exists?

    errors.add(:username, :invalid)
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value",
                                    { value: login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end

  def login
    @login || username || email
  end

  def liked?(likeable)
    likes.exists?(likeable: likeable)
  end

  def follows?(user)
    follows_as_follower.accepted.exists?(followee: user)
  end

  def follow_requested?(user)
    follows_as_follower.pending.exists?(followee: user)
  end

  def follow(user)
    return if follows?(user) || follow_requested?(user)
    status = user.private_account? ? :pending : :accepted
    follows_as_follower.create(followee: user, status: status)
  end

  # Unfollow another user (also cancels a pending request)
  def unfollow(user)
    follows_as_follower.where(followee: user).destroy_all
  end

  # Toggle follow/unfollow (or request/cancel request)
  def toggle_follow(user)
    (follows?(user) || follow_requested?(user)) ? unfollow(user) : follow(user)
  end

  # Remove a follower (or reject a pending request from them)
  def remove_follower(user)
    follows_as_followee.where(follower: user).destroy_all
  end

  # Accept a pending follow request
  def accept_follow_request(user)
    follow = follows_as_followee.pending.find_by(follower: user)
    follow&.update(status: :accepted)
  end

  # Reject a pending follow request
  def reject_follow_request(user)
    follows_as_followee.pending.where(follower: user).destroy_all
  end

  # Pending follow requests received by this user
  def pending_follow_requests
    follows_as_followee.pending.includes(:follower)
  end

  private
    def send_welcome_email
      UserMailer.welcome_email(self).deliver_now
    end
end
