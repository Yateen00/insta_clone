class ChatRoomsController < ApplicationController
  include ChatBootstrapper

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
    # Fetch rooms with optimized unread counts and timestamps
    chat_rooms = fetch_rooms_with_counts
    render json: chat_rooms.map { |r|
      r.as_api_json(current_user,
                    unread_count: r.rooms_unread_count,
                    last_message_at: r.latest_message_at)
    }
  end

  # NEW: Consolidate everything for initial load
  def bootstrap
    render json: prepare_chat_bootstrap_data
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
      
      # Notify ALL of the user's devices that they just joined a group!
      ActionCable.server.broadcast(
        "user_#{current_user.id}_channel",
        { event: "group_added", room: chat_room.as_api_json(current_user) }
      )
      
      render json: { message: "Joined group" }, status: :created
    end
  end

  # POST /chat_rooms
  def create
    # Extract params that might be nested under `chat_room`
    kind = params.dig(:chat_room, :kind) || params[:kind]

    # For DMs: find or create a DM between two users
    if %w[dm kind_dm].include?(kind)
      other_user_id = params.dig(:chat_room, :user_id) || params[:user_id]
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

        # Broadcast to the CURRENT user's other devices so their laptop perfectly syncs with their phone!
        ActionCable.server.broadcast(
          "user_#{current_user.id}_channel",
          { event: "dm_added", room: chat_room.as_api_json(current_user) }
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

  def unread_count
    # Optimized query to count distinct rooms that have messages newer than the user's last_read_at
    count = ChatRoom.joins(:chat_members)
                    .where(chat_members: { user_id: current_user.id })
                    .joins(:messages)
                    .where("messages.created_at > COALESCE(chat_members.last_read_at, chat_rooms.created_at)")
                    .distinct
                    .count("chat_rooms.id")

    render json: { unread_rooms_count: count }
  end

  # POST /chat_rooms/:id/add_members
  def add_members
    chat_room = find_chat_room

    if chat_room.kind != "group"
      render json: { error: "Can only add members to group chats" }, status: :unprocessable_content
      return
    end

    # Check if the current user is legally a member of this chat group
    unless chat_room.chat_members.exists?(user_id: current_user.id)
      render json: { error: "Unauthorized" }, status: :forbidden
      return
    end

    user_ids = params[:user_ids] || []
    added_user_ids = []

    user_ids.uniq.each do |uid|
      # Only add them if they aren't already a member
      unless chat_room.chat_members.exists?(user_id: uid)
        chat_room.chat_members.create(user_id: uid)
        added_user_ids << uid
      end
    end

    # Notify newly added members in real-time so the room appears in their sidebar
    added_user_ids.each do |uid|
      user = User.find_by(id: uid)
      next unless user

      ActionCable.server.broadcast(
        "user_#{uid}_channel",
        { event: "group_added", room: chat_room.as_api_json(user) }
      )
    end

    render json: { message: "Successfully added #{added_user_ids.length} members.", members: chat_room.users.as_json(only: %i[id username online]) },
           status: :ok
  end

  private
    def find_chat_room
      ChatRoom.find(params[:id])
    end

    def chat_room_params
      params.require(:chat_room).permit(:name, :kind, user_ids: [])
    end
end
