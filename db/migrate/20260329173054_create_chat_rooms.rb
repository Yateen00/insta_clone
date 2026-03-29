class CreateChatRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_rooms do |t|
      t.integer :kind, default: 0, null: false
      t.string :name

      t.timestamps
    end
  end
end
