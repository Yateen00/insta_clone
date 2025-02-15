class User < ApplicationRecord
  attr_writer :login

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  after_create :create_profile
  validates_format_of :username, with: /^[a-zA-Z0-9_.]*$/, multiline: true
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github, :google_oauth2]


  validate :validate_username
  after_create :send_welcome_email
  def validate_username
    if User.where(email: username).exists?
      errors.add(:username, :invalid)
    end
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
    @login || self.username || self.email
  end

  private
    def create_profile
      Profile.create(user: self) unless self.profile
    end
    def send_welcome_email
      UserMailer.welcome_email(self).deliver_now
    end
end
