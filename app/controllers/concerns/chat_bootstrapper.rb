module ChatBootstrapper
  extend ActiveSupport::Concern

  private

  def prepare_chat_bootstrap_data(room_id: nil)
    # Autojoin: If visiting a group we aren't part of yet
    active_room_id = room_id || params[:room_id] || params[:id]
    if active_room_id && (room = ChatRoom.find_by(id: active_room_id))
      room.join_user!(current_user)
    end

    rooms = fetch_rooms_with_counts
    
    # Authoritative unread count for navbar
    total_unread = rooms.select { |r| r.rooms_unread_count.to_i > 0 }.length
    # New DM Partners: exclude current user and users they already have a DM with
    dm_partner_ids = ChatMember.joins(:chat_room)
                               .where(chat_rooms: { kind: 'dm' })
                               .where(chat_room_id: current_user.chat_room_ids)
                               .where.not(user_id: current_user.id)
                               .pluck(:user_id)

    available_users = User.where.not(id: [current_user.id] + dm_partner_ids)
                          .as_json(only: %i[id username online])

    data = {
      rooms: rooms.map do |r|
        # Pass precalculated unread_count and latest_message_at to as_api_json
        r.as_api_json(current_user,
                      unread_count: r.rooms_unread_count,
                      last_message_at: r.latest_message_at)
      end,
      available_users: available_users,
      unread_rooms_count: total_unread
    }

    # If the user is navigating to a specific room, include messages in the bootstrap
    if active_room_id && (room = ChatRoom.find_by(id: active_room_id))
      data[:initial_messages] = room.messages
                                     .includes(:user, :content)
                                     .order(created_at: :asc)
                                     .last(100)
                                     .as_json(include: { user: { only: %i[id username] }, content: {} })
      data[:active_room_id] = room.id
    end

    data
  end

  def fetch_rooms_with_counts
    # Logic: Show ALL groups (public) but only DMs that current_user is part of
    joined_dm_ids = ChatMember.joins(:chat_room)
                              .where(chat_rooms: { kind: 'dm' })
                              .where(user_id: current_user.id)
                              .pluck(:chat_room_id)
    
    all_group_ids = ChatRoom.where(kind: 'group').pluck(:id)
    room_ids = joined_dm_ids + all_group_ids

    ChatRoom.where(id: room_ids)
            .select("chat_rooms.*, 
              (SELECT COUNT(*) FROM messages 
               WHERE messages.chat_room_id = chat_rooms.id 
               AND messages.created_at > COALESCE(
                 (SELECT last_read_at FROM chat_members WHERE user_id = #{current_user.id} AND chat_room_id = chat_rooms.id), 
                 '1970-01-01'
               )
              ) as rooms_unread_count,
              (SELECT MAX(created_at) FROM messages 
               WHERE messages.chat_room_id = chat_rooms.id
              ) as latest_message_at")
            .includes(:users, :chat_members)
            .order("latest_message_at DESC NULLS LAST")
  end
end
