class Post < ApplicationRecord
  belongs_to :postable, polymorphic: true
  belongs_to :creator, class_name: "User", foreign_key: "creator_id", inverse_of: :posts
end
