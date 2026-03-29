class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat_room
  belongs_to :content, polymorphic: true, dependent: :destroy

  accepts_nested_attributes_for :content
  validates :content, presence: true

  CONTENT_TYPES = %w[Text Image Video].freeze

  def build_content(type)
    type = { type: type } if type.is_a?(String)
    klass = type[:type].constantize
    self.content = klass.new(content: type[:content])
  end

  CONTENT_TYPES.each do |type|
    define_method(:"#{type.downcase}?") do
      content_type == type
    end
  end
end
