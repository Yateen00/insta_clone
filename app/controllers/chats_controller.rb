class ChatsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Renders app/views/chats/index.html.erb to mount React
  end
end
