class RenameUrlToContentInVideosAndImages < ActiveRecord::Migration[8.0]
  def change
    rename_column :videos, :url, :content
    rename_column :images, :url, :content
  end
end
