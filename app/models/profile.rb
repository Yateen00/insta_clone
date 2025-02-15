class Profile < ApplicationRecord
  belongs_to :user
  accepts_nested_attributes_for :user
  enum :gender, { male: 0, female: 1, trans: 2, other: 3, prefer_not_to_say: 4 }

  validates :link, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :bio, length: { maximum: 200 }

  mount_uploader :profile_picture, ProfilePictureUploader
end
