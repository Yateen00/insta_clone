import { useEffect, useRef } from "react";
import consumer from "../../channels/consumer";

export function useActionCable(channelName, params, handlers) {
  const channelRef = useRef(null);

  useEffect(() => {
    const channelParams = params ? { channel: channelName, ...params } : channelName;
    
    channelRef.current = consumer.subscriptions.create(channelParams, {
      received: (data) => {
        if (handlers?.received) handlers.received(data);
      },
      connected: () => {
        if (handlers?.connected) handlers.connected();
      },
      disconnected: () => {
        if (handlers?.disconnected) handlers.disconnected();
      }
    });

    return () => {
      if (channelRef.current) {
        channelRef.current.unsubscribe();
        consumer.subscriptions.remove(channelRef.current);
      }
    };
  }, [channelName, JSON.stringify(params)]);

  return channelRef.current;
}
