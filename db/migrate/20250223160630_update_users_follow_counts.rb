class UpdateUsersFollowCounts < ActiveRecord::Migration[8.0]
  def up
    User.find_each do |user|
      User.reset_counters(user.id, :follows_as_followee)
      User.reset_counters(user.id, :follows_as_follower)
    end
  end

  def down
    # No need to rollback as counter_cache is auto-maintained
  end
end
