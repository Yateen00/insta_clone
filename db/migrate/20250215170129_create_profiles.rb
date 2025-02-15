class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :gender, default: 4
      t.string :link
      t.text :bio
      t.string :profile_picture
      t.string :name
      t.date :dob
      t.timestamps
    end
  end
end
