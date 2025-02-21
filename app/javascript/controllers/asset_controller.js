import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["textInput", "fileInput", "input", "preview", "fileButton"];

  connect() {
    console.log("AssetController connected");

    if (this.previewTarget.innerHTML.trim() !== "") {
      this.showFileInput(); // If a file is already uploaded (edit mode)
    } else {
      this.showTextInput(); // Default to text input
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

      if (file.type.startsWith("image/")) {
        previewContent = `
          <div class="relative w-full h-full flex items-center justify-center">
            <img src="${e.target.result}" class="max-w-full max-h-full object-contain mx-auto" />
          </div>`;
      } else if (file.type.startsWith("video/")) {
        previewContent = `
          <div class="relative w-full h-full flex items-center justify-center">
            <video controls class="max-w-full max-h-full object-contain mx-auto">
              <source src="${e.target.result}" type="${file.type}">
              Your browser does not support the video tag.
            </video>
          </div>`;
      } else {
        previewContent = `<div class="text-white text-center">Preview not available for this file type.</div>`;
      }

      this.previewTarget.innerHTML = previewContent;
      this.fileButtonTarget.classList.add("hidden");

      // Add delete button
      const deleteButton = document.createElement("button");
      deleteButton.type = "button";
      deleteButton.dataset.action = "click->asset#deleteMedia";
      deleteButton.classList.add(
        "absolute",
        "top-2",
        "right-2",
        "w-8",
        "h-8",
        "bg-gray-800",
        "rounded-full",
        "p-1",
        "hover:bg-red-600"
      );
      deleteButton.innerHTML = "🗑️";
      this.previewTarget.appendChild(deleteButton);
    };

    reader.readAsDataURL(file);
  }

  deleteMedia(event) {
    event.preventDefault();
    this.previewTarget.innerHTML = "";
    this.inputTarget.value = "";
    this.fileButtonTarget.classList.remove("hidden");
  }
}
