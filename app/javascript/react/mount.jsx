import React from "react";
import { createRoot } from "react-dom/client";

// Global registry to prevent double-mounting and allow clean unmounting across Turbo visits
const roots = new Map();

export function mountReactComponent(Component, elementId, props = {}) {
  const el = document.getElementById(elementId);

  if (!el) return;

  // If we already have a root for this element name, unmount it explicitly.
  // This triggers React's useEffect cleanup functions (killing ActionCable subs, etc).
  unmountReactComponent(elementId);

  const root = createRoot(el);
  roots.set(elementId, root);
  root.render(<Component {...props} />);
}

export function unmountReactComponent(elementId) {
  if (roots.has(elementId)) {
    try {
      roots.get(elementId).unmount();
    } catch (e) {
      console.warn("Unmount failed (already destroyed?):", e);
    }
    roots.delete(elementId);
  }
}
