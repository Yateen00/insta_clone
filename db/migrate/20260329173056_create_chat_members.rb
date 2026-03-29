class CreateChatMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat_room, null: false, foreign_key: true
      t.integer :role, default: 0, null: false

      t.timestamps
    end
  end
end
