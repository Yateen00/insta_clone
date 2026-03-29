class ChatMember < ApplicationRecord
  enum :role, { member: 0, admin: 1 }, default: :member

  belongs_to :user
  belongs_to :chat_room
end
