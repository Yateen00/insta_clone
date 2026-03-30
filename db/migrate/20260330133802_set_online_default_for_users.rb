class SetOnlineDefaultForUsers < ActiveRecord::Migration[8.0]
  def change
    # Backfill any existing NULLs to false (offline)
    User.where(online: nil).update_all(online: false)
    change_column_default :users, :online, from: nil, to: false
    change_column_null :users, :online, false, false
  end
end
