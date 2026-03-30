class DropChatRoomsUsers < ActiveRecord::Migration[8.0]
  def change
    drop_table :chat_rooms_users, if_exists: true
  end
end
