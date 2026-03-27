class AddPrivateAccountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :private_account, :boolean, default: false, null: false
  end
end
