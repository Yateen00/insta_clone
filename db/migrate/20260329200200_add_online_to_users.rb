class AddOnlineToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :online, :boolean
  end
end
