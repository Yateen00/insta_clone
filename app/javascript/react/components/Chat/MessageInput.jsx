import React, { useState, useRef } from "react";
import { Send, Image as ImageIcon, Video, Loader2 } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useChat } from "./ChatContext";

export default function MessageInput({ type, activeRoom, activeUserTarget }) {
  const { setRooms } = useChat();
  const navigate = useNavigate();

  const [content, setContent] = useState("");
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  
  const fileInputRef = useRef(null);

  const getCsrfToken = () => document.querySelector('meta[name="csrf-token"]').content;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!content.trim() && !file) return;

    setLoading(true);

    try {
      let submitRoomId = type === "room" ? activeRoom.id : null;

      // LAZY DM INSTANTIATION
      if (type === "user" && activeUserTarget) {
        // We must first create the DM
        const createRes = await fetch("/chat_rooms", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": getCsrfToken()
          },
          body: JSON.stringify({ chat_room: { kind: "dm", user_id: activeUserTarget.id } })
        });

        if (!createRes.ok) throw new Error("Failed to create DM");
        const newRoom = await createRes.json();
        submitRoomId = newRoom.id;
        
        // Add to global state so Sidebar picks it up immediately
        setRooms(prev => [newRoom, ...prev]);

        // Secretly transition URL without reloading so subsequent messages go straight to the room
        navigate(`/room/${submitRoomId}`, { replace: true });
      }

      // SEND THE MESSAGE(S)
      
      // Send the ActionCable file payload FIRST so it visually acts as a parent to the text message
      if (file) {
        const fileData = new FormData();
        fileData.append("message[content_attributes][content]", file);
        const fileRes = await fetch(`/chat_rooms/${submitRoomId}/messages`, {
          method: "POST",
          headers: { "X-CSRF-Token": getCsrfToken() },
          body: fileData
        });
        if (!fileRes.ok) throw new Error("Failed to send file attachment");
      }

      // If the user typed text, fire that sequentially after the file finishes uploading
      if (content.trim()) {
        const textData = new FormData();
        textData.append("message[content_attributes][content]", content);
        const textRes = await fetch(`/chat_rooms/${submitRoomId}/messages`, {
          method: "POST",
          headers: { "X-CSRF-Token": getCsrfToken() },
          body: textData
        });
        if (!textRes.ok) throw new Error("Failed to send text message");
      }

      // Reset everything once both are sent
      setContent("");
      setFile(null);
      if (fileInputRef.current) fileInputRef.current.value = "";
    } catch (err) {
      console.error(err);
      alert("Failed to send message: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleFileClick = (acceptType) => {
    if (fileInputRef.current) {
      // In a more robust app, we'd have two inputs or change accept dynamically
      fileInputRef.current.accept = acceptType;
      fileInputRef.current.click();
    }
  };

  return (
    <div className="p-4 bg-gray-800/90 border-t border-gray-700">
      {file && (
        <div className="mb-2 p-2 bg-gray-700/50 rounded-lg flex items-center justify-between shadow-inner">
          <span className="text-sm font-medium text-emerald-400 truncate max-w-[200px] flex items-center">
            {file.type.startsWith("video") ? <Video className="w-4 h-4 mr-2" /> : <ImageIcon className="w-4 h-4 mr-2" />}
            {file.name}
          </span>
          <button type="button" onClick={() => setFile(null)} className="text-gray-400 hover:text-red-400 text-xs px-2 cursor-pointer font-bold">
            Remove
          </button>
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex items-center space-x-2">
        <input 
          type="file" 
          ref={fileInputRef} 
          className="hidden" 
          onChange={(e) => setFile(e.target.files[0])}
        />
        
        <button 
          type="button" 
          title="Attach Image"
          onClick={() => handleFileClick("image/*")}
          className="p-2 text-gray-400 hover:text-indigo-400 transition-colors focus:outline-none"
        >
          <ImageIcon strokeWidth={2.5} className="w-6 h-6" />
        </button>

        <button 
          type="button" 
          title="Attach Video"
          onClick={() => handleFileClick("video/*")}
          className="p-2 text-gray-400 hover:text-indigo-400 transition-colors focus:outline-none"
        >
          <Video strokeWidth={2.5} className="w-6 h-6" />
        </button>

        <input
          type="text"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          disabled={loading} // Only disable if actively sending to server
          placeholder={file ? "Add a message with your file..." : "Type a message..."}
          className="flex-1 bg-gray-900 border border-gray-700 text-gray-100 placeholder-gray-500 rounded-full px-5 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all shadow-inner"
        />

        <button 
          type="submit" 
          disabled={loading || (!content.trim() && !file)}
          className={`p-2.5 rounded-full transition-transform ${loading || (!content.trim() && !file) ? 'bg-gray-700 text-gray-500 cursor-not-allowed' : 'bg-indigo-600 text-white hover:bg-indigo-500 hover:scale-105 shadow-md active:scale-95'}`}
        >
          {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5 -ml-0.5 mt-0.5" />}
        </button>
      </form>
    </div>
  );
}
