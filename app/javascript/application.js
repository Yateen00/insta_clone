import "@hotwired/turbo-rails";
import "./controllers";

import React from "react";
import { mountReactComponent } from "./react/mount";
import Hello from "./components/Hello";

document.addEventListener("turbo:load", () => {
  const el = document.getElementById("hello-root");

  if (el) {
    mountReactComponent(Hello, "hello-root", {
      name: el.dataset.name,
    });
  }
});
import "./channels"
