class ChatRoomsController < ApplicationController


  def create_group
    user_ids = params[:user_ids] || []
    user_ids << current_user.id unless user_ids.include?(current_user.id)
    chat_room = ChatRoom.new(name: params[:name], kind: "group")
    if chat_room.save
      user_ids.uniq.each { |uid| chat_room.chat_members.create(user_id: uid) }
      # Notify each added user in real time so they see the group without refreshing
      user_ids.uniq.each do |uid|
        user = User.find_by(id: uid)
        next unless user

        ActionCable.server.broadcast(
          "user_#{uid}_channel",
          { event: "group_added", room: chat_room.as_api_json(user) }
        )
      end
      render json: chat_room.as_api_json(current_user), status: :created
    else
      render json: { errors: chat_room.errors.full_messages }, status: :unprocessable_content
    end
  end

  # GET /chat_rooms
  def index
    # Note: Scoped to current_user to prevent leaking other people's chats!
    chat_rooms = current_user.chat_rooms.includes(:users, :messages)
                             .left_joins(:messages)
                             .group("chat_rooms.id")
                             .order("MAX(messages.created_at) DESC NULLS LAST")
    render json: chat_rooms.map { |room| room.as_api_json(current_user) }
  end

  # GET /chat_rooms/:id
  def show
    chat_room = ChatRoom.includes(:users, messages: %i[user content]).find(params[:id])
    render json: chat_room.as_api_json(current_user, include_messages: true)
  end

  # POST /chat_rooms/:id/join
  def join
    chat_room = find_chat_room
    if chat_room.kind != "group"
      render json: { error: "Can only join group chat rooms" }, status: :unprocessable_content
      return
    end
    member = chat_room.chat_members.find_by(user_id: current_user.id)
    if member
      render json: { message: "Already a member" }, status: :ok
    else
      chat_room.chat_members.create(user: current_user)
      render json: { message: "Joined group" }, status: :created
    end
  end

  # POST /chat_rooms
  def create
    # For DMs: find or create a DM between two users
    if params[:kind] == "dm"
      other_user_id = params[:user_id]
      chat_room = ChatRoom.joins(:chat_members)
                          .where(kind: "dm")
                          .where(chat_members: { user_id: [current_user.id, other_user_id] })
                          .group("chat_rooms.id")
                          .having("COUNT(chat_members.user_id) = 2")
                          .first
                          
      unless chat_room
        chat_room = ChatRoom.create(kind: "dm")
        chat_room.chat_members.create(user_id: current_user.id)
        chat_room.chat_members.create(user_id: other_user_id)
        
        # Broadcast to the other user's personal channel to update their UI
        ActionCable.server.broadcast(
          "user_#{other_user_id}_channel",
          { event: "dm_added", room: chat_room.as_api_json(User.find_by(id: other_user_id)) }
        )
      end
      render json: chat_room.as_api_json(current_user), status: :created
    else
      chat_room = ChatRoom.new(chat_room_params)
      if chat_room.save
        chat_room.chat_members.create(user: current_user)
        render json: chat_room.as_api_json(current_user), status: :created
      else
        render json: { errors: chat_room.errors.full_messages }, status: :unprocessable_content
      end
    end
  end

  # PATCH /chat_rooms/:id/mark_as_read
  def mark_as_read
    chat_room = find_chat_room
    member = chat_room.chat_members.find_by(user_id: current_user.id)
    if member
      member.mark_as_read!
      head :no_content
    else
      render json: { error: "Not a member" }, status: :forbidden
    end
  end

  # GET /chat_rooms/unread_count
  def unread_count
    # Count of rooms where the user's last_read_at is earlier than the room's last message created_at
    # Or simply sum the unread_messages_count over all their memberships
    count = current_user.chat_memberships.count do |member|
      member.unread_messages_count > 0
    end
    render json: { unread_rooms_count: count }
  end

  private
    def find_chat_room
      ChatRoom.find(params[:id])
    end

    def chat_room_params
      params.require(:chat_room).permit(:name, :kind, user_ids: [])
    end
end
