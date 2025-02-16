class CreateImages < ActiveRecord::Migration[8.0]
  def change
    create_table :images do |t|
      t.string :url, null: false

      t.timestamps
    end
  end
end
