class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :content, null: false
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :reply_to, foreign_key: { to_table: :comments }

      t.timestamps
    end
  end
end
