class AddUniqueIndexToFollows < ActiveRecord::Migration[8.0]
  def change
    add_index :follows, %i[follower_id followee_id], unique: true
  end
end
