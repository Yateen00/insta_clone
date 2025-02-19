class Post < ApplicationRecord
  belongs_to :postable, polymorphic: true, dependent: :destroy
  belongs_to :creator, class_name: "User", foreign_key: "creator_id", inverse_of: :posts
  accepts_nested_attributes_for :postable

  def build_postable(type)
    if type.is_a?(String)
      case type
      when "Text"
        self.postable = Text.new
      when "Video"
        self.postable = Video.new
      end
    else
      case type[:type]
      when "Text"
        self.postable = Text.new(content: type[:content])
      when "Video"
        self.postable = Video.new(content: type[:content])
      end
    end
  end
  def text?
    postable_type == "Text"
  end
  def image?
    postable_type == "Image"
  end
end
