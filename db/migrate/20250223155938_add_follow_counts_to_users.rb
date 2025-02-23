class AddFollowCountsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :followers_count, :integer, default: 0
    add_column :users, :follows_count, :integer, default: 0
  end
end
