import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "textInput",
    "fileInput",
    "input",
    "preview",
    "fileButton",
    "deleteButton",
  ];

  connect() {
    console.log("AssetController connected");

    if (this.previewTarget.querySelector("img, video")) {
      this.showFileInput();
      this.fileButtonTarget.classList.add("hidden");
      this.deleteButtonTarget.classList.remove("hidden");
    } else {
      this.showTextInput();
    }
  }

  toggleText() {
    this.showTextInput();
  }

  toggleMedia() {
    this.showFileInput();
  }

  showTextInput() {
    this.textInputTarget.classList.remove("hidden");
    this.fileInputTarget.classList.add("hidden");
  }

  showFileInput() {
    this.textInputTarget.classList.add("hidden");
    this.fileInputTarget.classList.remove("hidden");
  }

  clickFileInput(event) {
    event.preventDefault();
    this.inputTarget.click();
  }

  preview() {
    const file = this.inputTarget.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      let previewContent = "";
      const fileType = file.type;
      const fileExtension = file.name.split(".").pop().toLowerCase();

      if (fileType.startsWith("image/")) {
        previewContent = `
          <img src="${e.target.result}" 
               class="w-auto h-auto max-w-full max-h-full object-contain" />`;
      } else if (fileType.startsWith("video/") && fileExtension !== "mkv") {
        previewContent = `
          <video controls 
                 class="w-auto h-auto max-w-full max-h-full object-contain">
            <source src="${e.target.result}" type="${fileType}">
            Your browser does not support the video tag.
          </video>`;
      } else {
        previewContent = `<div class="text-white text-center">Preview not available for this file type.</div>`;
      }

      this.previewTarget.innerHTML = previewContent;
      this.fileButtonTarget.classList.add("hidden");
      this.deleteButtonTarget.classList.remove("hidden");
    };

    reader.readAsDataURL(file);
  }

  deleteMedia(event) {
    event.preventDefault();
    this.previewTarget.innerHTML = "";
    this.inputTarget.value = "";
    this.fileButtonTarget.classList.remove("hidden");
    this.deleteButtonTarget.classList.add("hidden");
  }
}
