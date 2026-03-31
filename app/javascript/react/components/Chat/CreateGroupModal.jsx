import React, { useState } from "react";
import { X, Search, Check, Loader2 } from "lucide-react";
import { useChat } from "./ChatContext";
// modal means a pop up window that appears on top of the current screen
export default function CreateGroupModal({ onClose, onCreated }) {
  const { currentUserId, users, setRooms } = useChat();
  const [groupName, setGroupName] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedUserIds, setSelectedUserIds] = useState(new Set());
  const [loading, setLoading] = useState(false);

  // Filter out the current user, and then filter by search query
  const availableUsers = users.filter(u =>
    u.id !== currentUserId &&
    u.username.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const toggleUser = (id) => {
    const nextSet = new Set(selectedUserIds);
    if (nextSet.has(id)) {
      nextSet.delete(id);
    } else {
      nextSet.add(id);
    }
    setSelectedUserIds(nextSet);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!groupName.trim() || selectedUserIds.size === 0) return;

    setLoading(true);
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

      const res = await fetch("/chat_rooms/create_group", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          name: groupName.trim(),
          user_ids: Array.from(selectedUserIds)
        })
      });

      if (!res.ok) throw new Error("Failed to create group");

      const newGroup = await res.json();

      // Instantly inject the new group into our local Sidebar list securely preventing duplicates
      setRooms(prev => {
        if (prev.find(r => r.id === newGroup.id)) return prev;
        return [newGroup, ...prev];
      });

      onCreated(newGroup.id);
    } catch (err) {
      console.error(err);
      alert("Error creating group: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Close purely on overlay click
  const handleOverlayClick = (e) => {
    if (e.target === e.currentTarget) onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 fade-in" onClick={handleOverlayClick}>
      <div className="bg-gray-800 border border-gray-700 rounded-2xl w-full max-w-md shadow-2xl overflow-hidden flex flex-col h-[70vh] max-h-[600px] slide-up">

        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-700">
          <h2 className="text-xl font-bold text-gray-100">New Group Chat</h2>
          <button onClick={onClose} className="p-1 text-gray-400 hover:text-white rounded-full bg-gray-700/50 hover:bg-gray-700 transition">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col flex-1 overflow-hidden">
          {/* Group Name */}
          <div className="p-4 border-b border-gray-700 bg-gray-900/30">
            <label className="block text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Group Name</label>
            <input
              type="text"
              value={groupName}
              onChange={(e) => setGroupName(e.target.value)}
              placeholder="e.g. Weekend Trip, Work Team..."
              className="w-full bg-gray-900 text-white border border-gray-700 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
              autoFocus
            />
          </div>

          {/* Search Bar */}
          <div className="p-4 py-3 bg-gray-800 relative shadow-sm z-10">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search people..."
                className="w-full bg-gray-900/80 text-gray-200 border border-gray-700 rounded-full pl-9 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
              />
            </div>
            <div className="mt-2 flex justify-between items-center text-xs font-medium text-gray-400">
              <span>Select members</span>
              <span className="text-indigo-400">{selectedUserIds.size} selected</span>
            </div>
          </div>

          {/* Users List */}
          <div className="flex-1 overflow-y-auto w-full p-2 space-y-1 bg-gray-900/50">
            {availableUsers.length === 0 ? (
              <div className="text-center p-8 text-sm text-gray-500">No users found.</div>
            ) : (
              availableUsers.map(user => {
                const isSelected = selectedUserIds.has(user.id);
                return (
                  <label
                    key={user.id}
                    className={`flex items-center justify-between p-3 rounded-xl cursor-pointer transition-colors ${isSelected ? 'bg-indigo-600/10 border border-indigo-500/30' : 'hover:bg-gray-800 border border-transparent'}`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="relative">
                        <img
                          src={`https://ui-avatars.com/api/?name=${user.username}&background=random`}
                          alt={user.username}
                          className={`w-10 h-10 rounded-full object-cover transition-transform ${isSelected ? 'scale-105 ring-2 ring-indigo-500 ring-offset-2 ring-offset-gray-900' : ''}`}
                        />
                        {user.online && <span className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-gray-900 rounded-full"></span>}
                      </div>
                      <span className={`font-medium ${isSelected ? 'text-indigo-100' : 'text-gray-300'}`}>{user.username}</span>
                    </div>

                    <div className={`w-5 h-5 rounded-md flex items-center justify-center transition-colors ${isSelected ? 'bg-indigo-500' : 'bg-gray-700 border border-gray-600'}`}>
                      {isSelected && <Check className="w-3.5 h-3.5 text-white" strokeWidth={3} />}
                    </div>

                    {/* Hidden input to make it functionally a checkbox form */}
                    <input
                      type="checkbox"
                      className="hidden"
                      checked={isSelected}
                      onChange={() => toggleUser(user.id)}
                    />
                  </label>
                );
              })
            )}
          </div>

          {/* Submit Footer */}
          <div className="p-4 border-t border-gray-700 bg-gray-800">
            <button
              type="submit"
              disabled={loading || !groupName.trim() || selectedUserIds.size === 0}
              className={`w-full flex justify-center items-center py-3 rounded-lg font-semibold transition-all ${loading || !groupName.trim() || selectedUserIds.size === 0
                  ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                  : 'bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/20 hover:shadow-indigo-600/40 transform hover:-translate-y-0.5'
                }`}
            >
              {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : "Create Group"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
