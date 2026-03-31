import React, { useEffect, useState, useRef, useLayoutEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useChat } from "./ChatContext";
import { useActionCable } from "../../hooks/useActionCable";
import { UserPlus } from "lucide-react";
import MessageInput from "./MessageInput";
import AddMembersModal from "./AddMembersModal";

export default function MessageArea({ type }) {
  const { currentUserId, rooms, users, markRoomAsReadLocally, setRooms, initialMessages, removeInitialMessages, setActiveRoomId } = useChat();
  const { chatRoomId, userId } = useParams();
  const navigate = useNavigate();
  const rid = parseInt(chatRoomId);

  // DERIVE ACTIVE OBJECTS FROM CONTEXT
  const activeRoom = type === "room" && chatRoomId ? rooms.find(r => r.id === rid) : null;
  const activeUserTarget = type === "user" && userId ? users.find(u => u.id === parseInt(userId)) : null;

  // Tearing Fix: Initialize state immediately if messages are already hydrated
  const [messages, setMessages] = useState(() => {
    return (type === "room" && rid && initialMessages[rid]) ? initialMessages[rid] : [];
  });
  const [loading, setLoading] = useState(false);
  const [isReconnecting, setIsReconnecting] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const messagesEndRef = useRef(null);
  const scrollContainerRef = useRef(null);

  // Tearing Fix: Force scroll to bottom BEFORE paint
  useLayoutEffect(() => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = scrollContainerRef.current.scrollHeight;
    }
  }, [rid, messages.length]); // Re-run if we switch rooms OR if the initial messages load

  // Tell Context what room we are actively staring at seamlessly
  useEffect(() => {
    if (type === "room" && chatRoomId) {
      setActiveRoomId(chatRoomId);
    }
    // Cleanup: When we leave this component, tell context we are looking at nothing.
    return () => setActiveRoomId(null);
  }, [type, chatRoomId, setActiveRoomId]);

  // Load messages if it's a real room and not yet hydrated
  useEffect(() => {
    if (type === "room" && chatRoomId) {
      // If we used the hydrated messages, just mark as read and clean up
      if (initialMessages[rid]) {
        removeInitialMessages(rid);
        fetch(`/chat_rooms/${chatRoomId}/mark_as_read`, {
          method: "PATCH",
          headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
        }).then(() => markRoomAsReadLocally(rid));
        return;
      }

      setLoading(true);
      fetch(`/chat_rooms/${chatRoomId}/messages`)
        .then(r => r.json())
        .then(data => {
          setMessages(data);
          setLoading(false);
          fetch(`/chat_rooms/${chatRoomId}/mark_as_read`, {
            method: "PATCH",
            headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
          }).then(() => markRoomAsReadLocally(rid));
        })
        .catch(err => {
          console.error(err);
          setLoading(false);
        });
    } else {
      setMessages([]);
    }
  }, [type, chatRoomId, markRoomAsReadLocally, removeInitialMessages]);

  // Subscribe to raw new messages for ALREADY EXISTING room ONLY
  useActionCable(
    "ChatRoomChannel",
    type === "room" && chatRoomId ? { chat_room_id: parseInt(chatRoomId) } : null,
    {
      disconnected: () => {
        // User entered a tunnel or lost WiFi
        setIsReconnecting(true);
      },
      connected: () => {
        // User regained connection!
        if (isReconnecting) {
          // Silently backfill any messages missed while disconnected
          fetch(`/chat_rooms/${chatRoomId}/messages`)
            .then(r => r.json())
            .then(data => {
              setMessages(data);
              setIsReconnecting(false);
            })
            .catch(console.error);
        }
      },
      received: (data) => {
        setMessages(prev => {
          // Defensive Check: Prevent double-bubbles if ActionCable accidentally double-fires
          if (prev.some(m => m.id === data.message.id)) return prev;
          
          // Push the new message into the state
          const updated = [...prev, data.message];
          
          return updated.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
        });

        // Also call mark as read in the background since we are staring at the chat
        fetch(`/chat_rooms/${chatRoomId}/mark_as_read`, {
          method: "PATCH",
          headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
        }).then(() => markRoomAsReadLocally(parseInt(chatRoomId)));
      }
    }
  );

  // Auto-scroll Logic
  useEffect(() => {
    if (messages.length === 0) return;
    
    const lastMsg = messages[messages.length - 1];
    const isMe = lastMsg.user_id === currentUserId;
    const scroller = scrollContainerRef.current;
    
    if (scroller) {
      // Check if the user is already natively scrolled to the bottom (within ~150px)
      const isNearBottom = scroller.scrollHeight - scroller.scrollTop - scroller.clientHeight < 150;
      
      // Only forcibly auto-scroll if YOU sent the message, OR if you are already looking at the bottom of the feed
      if (isMe || isNearBottom) {
        messagesEndRef.current?.scrollIntoView({ behavior: "auto" });
      }
    }
  }, [messages, currentUserId]);

  if (type === "room" && !activeRoom) return <div className="p-8 text-center text-gray-400">Room not found.</div>;
  if (type === "user" && !activeUserTarget) return <div className="p-8 text-center text-gray-400">User not found.</div>;

  let displayName = type === "room" ? activeRoom.name : activeUserTarget.username;
  if (type === "room" && activeRoom.kind === "dm" && !displayName) {
    const otherUser = activeRoom.users?.find(u => u.id !== currentUserId) || activeRoom.users?.[0];
    displayName = otherUser?.username || "Unknown";
  }

  return (
    <div className="flex flex-col h-full bg-gray-900 overflow-hidden w-full relative">
      {/* Header */}
      <div className="p-4 border-b border-gray-700 bg-gray-800 flex items-center justify-between shadow-sm z-10">
        <div className="flex items-center">
          <h2 className="text-xl font-bold tracking-tight text-white">{displayName}</h2>
          {type === "room" && activeRoom.kind === "group" && (
            <span className="ml-3 px-2 py-0.5 rounded-md bg-gray-700 text-xs font-semibold text-gray-300">
              {activeRoom.member_count} members ({activeRoom.online_count} online)
            </span>
          )}
        </div>
        
        {type === "room" && activeRoom.kind === "group" && (
          <button 
            onClick={() => setShowAddModal(true)}
            className="flex items-center text-sm font-medium text-indigo-400 hover:text-indigo-300 bg-indigo-500/10 hover:bg-indigo-500/20 px-3 py-1.5 rounded-full transition-colors"
          >
            <UserPlus className="w-4 h-4 mr-1.5" />
            Add Users
          </button>
        )}
      </div>

      {/* Messages Feed */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 relative" ref={scrollContainerRef}>
        {isReconnecting && (
          <div className="sticky top-0 z-10 w-full flex justify-center mt-[-8px]">
            <div className="mx-auto px-auto py-1 px-4 bg-yellow-500/90 backdrop-blur-sm text-white text-xs font-semibold rounded-full shadow-lg transition-all animate-pulse duration-1000">
              Offline • Connecting...
            </div>
          </div>
        )}
        
        {loading && <div className="text-center text-gray-400">Loading messages...</div>}
        
        {messages.map((msg, idx) => {
          const isMe = msg.user_id === currentUserId;
          return (
            <div key={msg.id || `temp_${idx}`} className={`flex ${isMe ? "justify-end" : "justify-start"}`}>
              <div className={`flex flex-col max-w-[70%] ${isMe ? "items-end" : "items-start"}`}>
                <span className="text-xs text-gray-500 mb-1 px-1">{msg.user?.username}</span>
                {msg.content_type === "Text" ? (
                  <div className={`px-4 py-2.5 rounded-2xl ${isMe ? "bg-indigo-600 text-white rounded-br-sm" : "bg-gray-700 text-gray-100 rounded-bl-sm"}`}>
                    <p className="whitespace-pre-wrap leading-relaxed">{msg.content?.content}</p>
                  </div>
                ) : (
                  <div className="flex flex-col">
                    {msg.content_type === "Image" && (
                      <img src={msg.content?.content?.url || "#"} alt="Attachment" className="max-w-xs sm:max-w-sm rounded-2xl shadow-sm border border-gray-700/50" />
                    )}
                    {msg.content_type === "Video" && (
                      <video src={msg.content?.content?.url || "#"} controls className="max-w-xs sm:max-w-sm rounded-2xl shadow-sm border border-gray-700/50" />
                    )}
                  </div>
                )}
              </div>
            </div>
          );
        })}
        {messages.length === 0 && !loading && (
          <div className="text-center font-medium mt-10 text-gray-500">Say hello! Starting a conversation securely.</div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <MessageInput 
        type={type} 
        activeRoom={activeRoom} 
        activeUserTarget={activeUserTarget} 
      />

      {showAddModal && type === "room" && (
        <AddMembersModal 
          roomId={activeRoom.id}
          onClose={() => setShowAddModal(false)}
          onAdded={() => setShowAddModal(false)}
        />
      )}
    </div>
  );
}
