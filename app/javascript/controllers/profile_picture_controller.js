import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "image"];

  click() {
    this.inputTarget.click();
  }

  preview() {
    const file = this.inputTarget.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        this.imageTarget.src = e.target.result;
      };
      reader.readAsDataURL(file);
    }
  }
}