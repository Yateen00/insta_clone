class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :postable, null: false, polymorphic: true
      t.text :description, default: ""
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
