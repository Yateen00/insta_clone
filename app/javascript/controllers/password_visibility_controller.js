import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-visibility"
export default class extends Controller {
  static targets = ["password", "toggle"];

  connect() {
    this.showIcon = "https://www.svgrepo.com/show/380010/eye-password-show.svg";
    this.hideIcon =
      "https://www.svgrepo.com/show/390427/eye-password-see-view.svg";
    this.toggleTarget.src = this.showIcon;
  }

  toggle() {
    if (this.passwordTarget.type === "password") {
      this.passwordTarget.type = "text";
      this.toggleTarget.src = this.hideIcon;
    } else {
      this.passwordTarget.type = "password";
      this.toggleTarget.src = this.showIcon;
    }
  }
}
