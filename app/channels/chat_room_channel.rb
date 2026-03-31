class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    if params["chat_room_id"].present?
      room = ChatRoom.find_by(id: params["chat_room_id"])
      return reject unless room

      # Seamlessly join if it's a group
      room.join_user!(current_user)

      if room.users.include?(current_user)
        stream_from "chat_room_#{params['chat_room_id']}_channel"
      else
        reject
      end
    else
      # Personal channel: receives "you were added to a group" events
      stream_from "user_#{current_user.id}_channel"
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
