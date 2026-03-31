import React, { useMemo, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { PlusCircle } from "lucide-react";
import { useChat } from "./ChatContext";
import CreateGroupModal from "./CreateGroupModal";

export default function Sidebar() {
  const { currentUserId, rooms, users } = useChat();
  const location = useLocation();
  const navigate = useNavigate();
  const [showCreateModal, setShowCreateModal] = useState(false);

  const chatItems = useMemo(() => {
    // Collect all real rooms
    const items = rooms.map(room => ({
      ...room,
      isVirtual: false,
      sortTime: room.last_message_at ? new Date(room.last_message_at).getTime() : new Date(room.created_at).getTime(),
    }));

    // Find users who we do not have a DM room with yet
    const usersWithDMRooms = new Set();
    rooms.forEach(r => {
      if (r.kind === "dm") {
        const otherUser = r.users.find(u => u.id !== currentUserId);
        if (otherUser) usersWithDMRooms.add(otherUser.id);
      }
    });

    users.forEach(user => {
      // Add user to virtual DMs list only if we don't already have a DM, AND they are not the current user
      if (!usersWithDMRooms.has(user.id) && user.id !== currentUserId) {
        items.push({
          id: `virtual_${user.id}`,
          isVirtual: true,
          targetUserId: user.id,
          name: user.username,
          kind: "dm",
          users: [user],
          online_count: user.online ? 1 : 0,
          unread_count: 0,
          sortTime: 0, // Virtual users go at the bottom
        });
      }
    });

    // Sort: most recent real messages first, then virtuals
    return items.sort((a, b) => b.sortTime - a.sortTime);
  }, [rooms, users, currentUserId]);

  return (
    <div className="flex-1 overflow-y-auto flex flex-col relative w-full h-full">
      <div className="p-4 border-b border-gray-700 bg-gray-800/90 top-0 sticky z-10 flex justify-between items-center">
        <span className="font-bold text-lg text-white">Messages</span>
        <button
          onClick={() => setShowCreateModal(true)}
          className="text-gray-400 hover:text-indigo-400 transition-colors tooltip flex items-center"
          title="New Group Chat"
        >
          <PlusCircle strokeWidth={2.5} className="w-6 h-6" />
        </button>
      </div>
      <div className="flex flex-col flex-1">
        {chatItems.map(item => {
          const path = item.isVirtual ? `/user/${item.targetUserId}` : `/room/${item.id}`;
          const isNonMemberGroup = item.kind === "group" && item.is_member === false;
          const isActive = location.pathname.endsWith(path);

          let avatarUrl = '/icon.png'; // Fallback
          let displayName = item.name;
          let isOnline = false;

          if (item.kind === "dm") {
            const otherUser = item.users?.find(u => u.id !== currentUserId) || item.users?.[0];
            if (otherUser) {
              avatarUrl = `https://ui-avatars.com/api/?name=${otherUser.username}&background=random`;
              displayName = otherUser.username;
              isOnline = otherUser.online;
            }
          } else {
            // Group chat avatar
            avatarUrl = `https://ui-avatars.com/api/?name=${item.name}&background=3730a3&color=fff`;
            // Only show the green dot for groups if at least ONE OTHER person is online
            isOnline = item.online_members?.some(u => u.id !== currentUserId);
          }

          return (
            <Link
              to={path}
              key={item.id}
              className={`flex items-center p-4 border-b border-gray-700/50 hover:bg-gray-700/50 transition-colors ${isActive ? "bg-gray-700/80" : ""} ${isNonMemberGroup ? "opacity-75 grayscale-[0.3]" : ""}`}
            >
              <div className="relative">
                <img src={avatarUrl} alt={displayName} className={`w-12 h-12 rounded-full object-cover ${isNonMemberGroup ? "border-2 border-dashed border-gray-600" : ""}`} />
                {isOnline && (
                  <span className="absolute bottom-0 right-0 w-3.5 h-3.5 bg-green-500 border-2 border-gray-800 rounded-full"></span>
                )}
              </div>
              <div className="ml-3 flex-1 overflow-hidden">
                <div className="flex justify-between items-center">
                  <h3 className="font-semibold text-gray-100 truncate">{displayName}</h3>
                  {item.unread_count > 0 && (
                    <span className="bg-blue-600 text-white text-xs px-2 py-0.5 rounded-full font-bold">
                      {item.unread_count}
                    </span>
                  )}
                  {isNonMemberGroup && (
                    <span className="bg-indigo-500/20 text-indigo-400 text-[10px] uppercase tracking-wider px-2 py-0.5 rounded-full font-black border border-indigo-500/30">
                      Discovery
                    </span>
                  )}
                </div>
                <p className="text-sm text-gray-400 truncate italic">
                  {isNonMemberGroup ? "Public Group · Join now" : (item.kind === "group" ? `${item.online_count} active, out of ${item.member_count} members` : (isOnline ? "Active now" : "Offline"))}
                </p>
              </div>
            </Link>
          );
        })}

        {chatItems.length === 0 && (
          <div className="p-8 text-center text-gray-400 text-sm">No conversations found.</div>
        )}
      </div>

      {/* group creation */}
      {showCreateModal && (
        <CreateGroupModal
          onClose={() => setShowCreateModal(false)}
          onCreated={(newRoomId) => {
            setShowCreateModal(false);
            navigate(`/room/${newRoomId}`);
          }}
        />
      )}
    </div>
  );
}
