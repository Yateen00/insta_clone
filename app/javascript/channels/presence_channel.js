import consumer from "./consumer";

consumer.subscriptions.create("PresenceChannel", {
  received(data) {
    // Dispatch a custom event for React or update your state/store here
    window.dispatchEvent(new CustomEvent("presence-update", { detail: data }));
  },
});
