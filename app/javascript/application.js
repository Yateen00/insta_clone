import "@hotwired/turbo-rails";
import "./controllers";

import React from "react";
import { mountReactComponent, unmountReactComponent } from "./react/mount";
import Hello from "./components/Hello";

import ChatNavbarIcon from "./react/components/ChatNavbarIcon";
import ChatApp from "./react/components/Chat/ChatApp";

document.addEventListener("turbo:load", () => {
  const helloEl = document.getElementById("hello-root");
  if (helloEl) mountReactComponent(Hello, "hello-root", { name: helloEl.dataset.name });

  const navbarIconEl = document.getElementById("react-chat-navbar-icon");
  if (navbarIconEl) {
    mountReactComponent(ChatNavbarIcon, "react-chat-navbar-icon");
  }

  const chatAppEl = document.getElementById("chat-app-root");
  if (chatAppEl) {
    mountReactComponent(ChatApp, "chat-app-root", { currentUserId: parseInt(chatAppEl.dataset.currentUserId) });
  } else {
    // Kill any lingering background chat listeners if we've left the chat page
    unmountReactComponent("chat-app-root");
  }
});
import "./channels"
