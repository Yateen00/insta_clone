import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from "react";
import { useActionCable } from "../../hooks/useActionCable";

const ChatContext = createContext(null);

//wrapper to populate context
//handles: 1) inital data fetch 2)store global state of rooms(updated) and users(not updated)
//3)manage action cable of online users and personal channel(only sent to you)     4)provide callback for updating unread rooms
export function ChatProvider({ currentUserId, children }) {
  // ⚡ ULTRA HYDRATION: Parse data during construction to skip the initial 'Empty Frame'.
  //used coz we dont have ssr, so we pass data from rails to react via a script tag so theres no 2 rtt
  //coz ideally chats is handled by react router, but if user directly goes to chat, we need to do this
  //coz if react hadnles, reqeust for html is never sent thus no hydration script attached. 
  const getHydratedData = () => {
    const el = document.getElementById("chat-bootstrap-hydration");
    if (!el) return null;
    try {
      return JSON.parse(el.textContent);
    } catch (e) {
      console.error("Hydration error:", e);
      return null;
    }
  };

  const hydratedData = getHydratedData();
  
  // Professional React Tracking: Silent reference to avoid re-render cascades
  const activeRoomRef = useRef(null);
  const setActiveRoomId = useCallback((id) => {
    activeRoomRef.current = id;
  }, []);

  const [rooms, setRooms] = useState(() => hydratedData?.rooms || []);
  const [users, setUsers] = useState(() => hydratedData?.available_users || []);
  const [isReconnecting, setIsReconnecting] = useState(false);
  const [initialMessages, setInitialMessages] = useState(() => {
    const currentRoomId = window.location.pathname.split("/room/")[1] ||
      window.location.pathname.split("/chats/")[1];
    if (hydratedData?.initial_messages && String(hydratedData.active_room_id) === String(currentRoomId)) {
      return { [hydratedData.active_room_id]: hydratedData.initial_messages };
    }
    return {};
  });
  const [ready, setReady] = useState(() => !!hydratedData);

  // Initial fetch - Only if we didn't hydrate from HTML
  //eg: if we are on chats then went clicked on /chats/1, we need to fetch as theres no cache
  useEffect(() => {
    if (ready) return;

    const roomId = window.location.pathname.split("/room/")[1] ||
      window.location.pathname.split("/chats/")[1];
    const url = `/chat_rooms/bootstrap${roomId ? `?room_id=${roomId}` : ""}`;

    fetch(url)
      .then(r => r.json())
      .then(data => {
        setRooms(data.rooms);
        setUsers(data.available_users);
        if (data.initial_messages) {
          setInitialMessages({ [data.active_room_id]: data.initial_messages });
        }
        setReady(true);
      }).catch(console.error);
  }, [currentUserId, ready]);

  const removeInitialMessages = useCallback((roomId) => {
    setInitialMessages(prev => {
      const next = { ...prev };
      delete next[roomId];
      return next;
    });
  }, []);

  // Handle Presence Updates
  useActionCable("PresenceChannel", {}, {
    received: (data) => {
      // data format: { user_id: 1, online: true }
      setUsers(prev => prev.map(u => u.id === data.user_id ? { ...u, online: data.online } : u));
      // Also update inside cached rooms if needed, or rely on computed properties in Sidebar
    }
  });

  // Handle Personal Events (New message, added to group, DM started from other person)
  useActionCable("ChatRoomChannel", {}, {
    disconnected: () => setIsReconnecting(true),
    connected: () => {
      // If we regain connection after losing it, safely fetch the absolute truth from the server
      if (isReconnecting) {
        fetch('/chat_rooms/bootstrap')
          .then(r => r.json())
          .then(data => {
            setRooms(data.rooms);
            setUsers(data.available_users);
            setIsReconnecting(false);
          })
          .catch(console.error);
      }
    },
    received: (data) => {
      //not deleting users as users still mean something differnet too. logic handled in sidebar instead 
      if (data.event === "group_added" || data.event === "dm_added") {
        setRooms(prev => {
          if (prev.find(r => r.id === data.room.id)) return prev;
          return [data.room, ...prev];
        });
      } else if (data.event === "new_message") {
        setRooms(prev => {
          const roomExists = prev.some(r => r.id === data.room_id);

          if (roomExists) {
            return prev.map(room => {
              if (room.id === data.room_id) {
                // Determine unread count authoritatively instantly via Ref
                const isLookingAtIt = String(activeRoomRef.current) === String(data.room_id);

                return {
                  ...room,
                  ...data.room, // authoritative room metadata from server 
                  unread_count: isLookingAtIt ? 0 : (data.room?.unread_count || 0)
                };
              }
              return room;
            }).sort((a, b) => new Date(b.last_message_at || 0) - new Date(a.last_message_at || 0));
          } else if (data.room) {
            // New room appeared via a message (DM/Group added late)
            return [data.room, ...prev];
          }
        });

      }
      //for cross device sync of read messages, room read is sent by other device. so trigger room reading effects  
      else if (data.event === "room_read") {
        setRooms(prev => prev.map(room => room.id === data.room_id ? { ...room, unread_count: 0 } : room));
        // Sync Navbar too
        window.dispatchEvent(new CustomEvent("chat:mark_read"));
      }
    }
  });

  // Helper to visually mark a room as read optimally
  const markRoomAsReadLocally = useCallback((roomId) => {
    setRooms(prev => prev.map(r => r.id === roomId ? { ...r, unread_count: 0 } : r));
    // Emit global event to sync navbar
    window.dispatchEvent(new CustomEvent("chat:mark_read"));
  }, []);

  if (!ready) {
    return <div className="p-8 text-center text-gray-400">Loading chats...</div>;
  }

  return (
    <ChatContext.Provider value={{
      currentUserId: currentUserId || hydratedData?.current_user_id,
      rooms,
      users,
      initialMessages,
      ready,
      markRoomAsReadLocally,
      setRooms,
      setUsers,
      removeInitialMessages,
      setActiveRoomId // <-- Expose setter to specific children (MessageArea)
    }}>
      {children}
    </ChatContext.Provider>
  );
}

export function useChat() {
  return useContext(ChatContext);
}
