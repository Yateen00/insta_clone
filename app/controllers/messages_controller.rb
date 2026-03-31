class MessagesController < ApplicationController
  # GET /chat_rooms/:chat_room_id/messages
  def index
    chat_room = ChatRoom.find(params[:chat_room_id])
    # Seamless join for groups if the user isn't a member yet
    chat_room.join_user!(current_user)

    # Fetch last 100 messages to ensure performance in large chat rooms
    messages = chat_room.messages.includes(:user, :content).order(created_at: :asc).last(100)
    render json: messages.as_json(include: { user: { only: %i[id username] }, content: {} })
  end

  # POST /chat_rooms/:chat_room_id/messages
  def create
    chat_room = ChatRoom.find(params[:chat_room_id])
    message = chat_room.messages.build(user: current_user)
    content_type = determine_content_type(message_params[:content_attributes][:content])
    if content_type == "Unknown"
      render json: { errors: ["Unsupported content type"] }, status: :unprocessable_content
      return
    end
    message.build_content(type: content_type, content: message_params[:content_attributes][:content])
    if message.save
      # Automatically mark as read for the sender so their own messages don't show as unread
      sender_member = chat_room.chat_members.find_by(user_id: current_user.id)
      sender_member&.mark_as_read!

      # Broadcast to ActionCable specific room channel (for active chat viewers)
      ActionCable.server.broadcast(
        "chat_room_#{chat_room.id}_channel",
        { message: message.as_json(include: { user: { only: %i[id username] }, content: {} }) }
      )

      # Broadcast to each member's personal channel (for navbar badge / sidebar updates)
      chat_room.users.each do |u|
        ActionCable.server.broadcast(
          "user_#{u.id}_channel",
          {
            event: "new_message",
            room_id: chat_room.id,
            # Broadcaster authoritative room snapshot with CURRENT user-specific unread count
            room: chat_room.as_api_json(u),
            message: message.as_json(include: { user: { only: %i[id username] }, content: {} })
          }
        )
      end

      render json: message.as_json(include: { user: { only: %i[id username] }, content: {} }), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_content
    end
  end

  private
    def determine_content_type(content)
      if content.is_a?(String)
        "Text"
      elsif content.is_a?(ActionDispatch::Http::UploadedFile) || (content.respond_to?(:file) && content.file.present?)
        mime_type = content.content_type
        if mime_type.start_with?("image/")
          "Image"
        elsif mime_type.start_with?("video/")
          "Video"
        else
          "Unknown"
        end
      else
        "Unknown"
      end
    end

    def message_params
      params.require(:message).permit(:content_type, :content_id, content_attributes: [:content])
    end
end
