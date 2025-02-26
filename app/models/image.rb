class Image < ApplicationRecord
  has_one :post, as: :postable
  mount_uploader :content, ImageUploader

  after_find :set_default_image

  def set_default_image
    return if content.present?

    self.content = File.open(Rails.root.join("app/assets/images/default_image.svg"))
  end
end
