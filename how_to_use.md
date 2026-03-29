how to structure things (important)
📁 keep this pattern
app/javascript/
  components/
    Chat.jsx
    Comments.jsx
  react/
    mount.jsx
🧱 mounting pattern (your core)
ERB:
<div id="chat-root" data-room-id="<%= @room.id %>"></div>
JS:
document.addEventListener("turbo:load", () => {
  const el = document.getElementById("chat-root");

  if (el) {
    mountReactComponent(Chat, "chat-root", {
      roomId: el.dataset.roomId
    });
  }
});


⚠️ important differences vs normal React apps
1. no global app

👉 you DON’T do:

<App />

👉 instead:

many small React islands
2. Rails still controls everything
routes ✅
auth ✅
DB ✅

React only handles UI

3. data comes from DOM, not API (initially)
const roomId = el.dataset.roomId;
4. Turbo affects lifecycle

👉 ALWAYS use:

turbo:load

not:

DOMContentLoaded ❌
5. CSRF still required

when using fetch:

headers: {
  "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
}
⚠️ common mistakes (avoid these)
❌ mounting twice

→ causes duplicate UI

❌ mixing stimulus + react on same element

→ conflicts

❌ over-converting app to React

→ unnecessary complexity

❌ building API too early

→ not needed