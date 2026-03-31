import React from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";

import { ChatProvider } from "./ChatContext";

import Sidebar from "./Sidebar";
import MessageArea from "./MessageArea";

function ChatLayout() {
  return (
    <div className="flex h-[85vh] w-full max-w-7xl mx-auto bg-gray-800 rounded-xl overflow-hidden border border-gray-700 shadow-2xl">
      <div className="w-1/3 border-r border-gray-700 bg-gray-800/80 flex flex-col">
        <Sidebar />
      </div>
      <div className="w-2/3 bg-gray-900/80 flex flex-col relative w-full h-full object-cover">
        <Routes>
          <Route path="/" element={<div className="flex-1 flex items-center justify-center text-gray-400 font-medium">Select a chat to start messaging</div>} />
          <Route path="/room/:chatRoomId" element={<MessageArea type="room" />} />
          <Route path="/user/:userId" element={<MessageArea type="user" />} />
        </Routes>
      </div>
    </div>
  );
}

export default function ChatApp({ currentUserId }) {
  return (
    <BrowserRouter basename="/chats">
      <ChatProvider currentUserId={currentUserId}>
        <ChatLayout />
      </ChatProvider>
    </BrowserRouter>
  );
}
