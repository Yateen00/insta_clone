class CreateTexts < ActiveRecord::Migration[8.0]
  def change
    create_table :texts do |t|
      t.text :content, null: false

      t.timestamps
    end
  end
end
