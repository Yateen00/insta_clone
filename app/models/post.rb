class Post < ApplicationRecord
  belongs_to :postable, polymorphic: true, dependent: :destroy
  belongs_to :creator, class_name: "User", inverse_of: :posts
  accepts_nested_attributes_for :postable
  validates :postable, presence: true
  validates :description, length: { maximum: 500 }

  # has_many :likes, as: :likeable, dependent: :destroy
  has_many :comments, dependent: :destroy
  POSTABLE_TYPES = %w[Text Image Video].freeze
  # def build_postable(type)
  #   if type.is_a?(String)
  #     case type
  #     when "Text"
  #       self.postable = Text.new
  #     when "Video"
  #       self.postable = Video.new
  #     end
  #   else
  #     case type[:type]
  #     when "Text"
  #       self.postable = Text.new(content: type[:content])
  #     when "Video"
  #       self.postable = Video.new(content: type[:content])
  #     end
  #   end
  # end

  # def text?
  #   postable_type == "Text"
  # end

  # def image?
  #   postable_type == "Image"
  # end

  def build_postable(type)
    type = { type: type } if type.is_a?(String)
    klass = type[:type].constantize
    p klass, type
    self.postable = klass.new(content: type[:content])
  end

  POSTABLE_TYPES.each do |type|
    define_method(:"#{type.downcase}?") do
      postable_type == type
    end
  end

end
