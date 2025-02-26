class Video < ApplicationRecord
  has_one :post, as: :postable
  mount_uploader :content, VideoUploader

  after_find :set_default_video

  def set_default_video
    return if content.present?

    self.content = File.open(Rails.root.join("app/assets/images/default_video.mp4"))
  end
end
