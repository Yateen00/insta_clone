import React, { useState, useEffect } from "react";
import { MessageSquare } from "lucide-react";
import { useActionCable } from "../hooks/useActionCable";

export default function ChatNavbarIcon() {
  const [unreadCount, setUnreadCount] = useState(() => {
    const metaTag = document.querySelector('meta[name="chat-unread-count"]');
    return metaTag ? (parseInt(metaTag.content) || 0) : 0;
  });
  const [isReconnecting, setIsReconnecting] = useState(false);

  // Initial hydration from meta tag (0ms delay)
  useEffect(() => {
    // Listen for custom events dispatched by the ChatApp when marking as read
    const handleLocalRead = () => {
      // Re-fetch only when explicitly needed after marking as read to guarantee server sync
      fetch("/chat_rooms/unread_count")
        .then(res => res.json())
        .then(data => setUnreadCount(data.unread_rooms_count || 0));
    };
    window.addEventListener("chat:mark_read", handleLocalRead);
    return () => window.removeEventListener("chat:mark_read", handleLocalRead);
  }, []);

  // Listen to personal ActionCable channel for any background updates
  useActionCable("ChatRoomChannel", {}, {
    disconnected: () => setIsReconnecting(true),
    connected: () => {
      if (isReconnecting) {
        // Heal the unread badge if we dropped packets while offline
        fetch("/chat_rooms/unread_count")
          .then(res => res.json())
          .then(data => {
            setUnreadCount(data.unread_rooms_count || 0);
            setIsReconnecting(false);
          })
          .catch(console.error);
      }
    },
    received: (data) => {
      if (["new_message", "group_added", "dm_added"].includes(data.event)) {
        const currentPath = window.location.pathname;
        
        // If we are looking at the room that just got a message, the ChatContext will handle marking as read 
        // which triggers the "chat:mark_read" listener above. No need to double fetch here.
        if (data.event === "new_message" && currentPath === `/chats/room/${data.room_id}`) return;

        fetch("/chat_rooms/unread_count")
          .then(res => res.json())
          .then(data => setUnreadCount(data.unread_rooms_count || 0))
          .catch(console.error);
      }
    }
  });

  return (
    <a href="/chats" className="relative hover:text-indigo-800 px-3 py-1 rounded flex items-center group transition-colors">
      <MessageSquare className="w-7 h-7" />
      {unreadCount > 0 && (
        <span className="absolute top-0 right-1 translate-x-1/2 -translate-y-1/4 bg-red-500 text-white text-[10px] font-bold px-[6px] py-[1px] rounded-full border-2 border-gray-900 group-hover:border-indigo-800 transition-colors">
          {unreadCount > 99 ? "99+" : unreadCount}
        </span>
      )}
    </a>
  );
}
