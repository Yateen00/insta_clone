class ChatRoom < ApplicationRecord
  enum :kind, { group: 0, dm: 1 }, default: :dm

  has_many :chat_members, dependent: :destroy
  has_many :users, through: :chat_members
  has_many :messages, dependent: :destroy
end
