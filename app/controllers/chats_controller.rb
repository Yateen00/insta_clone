class ChatsController < ApplicationController
  include ChatBootstrapper
  before_action :authenticate_user!
  
  def index
    # Hydration: Fetching everything for initial HTML render to save one round-trip
    # Using the same logic as ChatRooms#bootstrap but on the main page load
    @chat_bootstrap_data = prepare_chat_bootstrap_data
  end
end
