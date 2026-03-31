class ChatMember < ApplicationRecord
  enum :role, { member: 0, admin: 1 }, default: :member

  belongs_to :user
  belongs_to :chat_room

  # Returns the count of unread messages for this member in the chat room
  def unread_messages_count
    last_read = last_read_at || Time.at(0)
    chat_room.messages.where("created_at > ?", last_read).count
  end

  # Marks all messages as read up to now and syncs across devices
  def mark_as_read!
    update!(last_read_at: Time.current)
    ActionCable.server.broadcast("user_#{user_id}_channel", { 
      event: "room_read", 
      room_id: chat_room_id 
    })
  end
end
