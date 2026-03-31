require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :chat_unread_count

  def chat_unread_count
    return 0 unless user_signed_in?
    
    @chat_unread_count ||= ChatRoom.joins(:chat_members)
                                  .where(chat_members: { user_id: current_user.id })
                                  .joins(:messages)
                                  .where("messages.created_at > COALESCE(chat_members.last_read_at, chat_rooms.created_at)")
                                  .distinct
                                  .count("chat_rooms.id")
  end

  protected
    def configure_permitted_parameters
      added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password]
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end
end
