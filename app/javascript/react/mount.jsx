import React from "react";
import { createRoot } from "react-dom/client";

export function mountReactComponent(Component, elementId, props = {}) {
  const el = document.getElementById(elementId);

  if (!el) return;

  const root = createRoot(el);
  root.render(<Component {...props} />);
}
