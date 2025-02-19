class Profile < ApplicationRecord
  belongs_to :user
  accepts_nested_attributes_for :user
  enum :gender, { male: 0, female: 1, trans: 2, other: 3, prefer_not_to_say: 4 }, default: :prefer_not_to_say

  validates :link, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" },
                   allow_blank: true
  validates :bio, length: { maximum: 200 }

  mount_uploader :profile_picture, ProfilePictureUploader
  after_find :set_default_profile_picture

  private
    def set_default_profile_picture
      return if profile_picture.present?

      self.profile_picture = ProfilePictureUploader.new
    end
end
