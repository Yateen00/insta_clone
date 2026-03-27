class AddStatusToFollows < ActiveRecord::Migration[8.0]
  def change
    add_column :follows, :status, :integer, default: 1, null: false
    add_index :follows, :status
  end
end
