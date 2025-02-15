import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "image"];

  connect() {
    this.cropper = null;
  }

  click() {
    this.inputTarget.click();
  }

  preview() {
    const file = this.inputTarget.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        this.imageTarget.src = e.target.result;
        if (this.cropper) {
          this.cropper.destroy();
        }
        this.cropper = new Cropper(this.imageTarget, {
          aspectRatio: 1,
          viewMode: 1,
          autoCropArea: 1,
          crop: (event) => {
            // You can handle the crop event here if needed
          },
        });
      };
      reader.readAsDataURL(file);
    }
  }
}
