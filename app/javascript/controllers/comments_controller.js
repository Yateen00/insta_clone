import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["replyFormTemplate"];

  connect() {
    console.log("Stimulus comments controller connected!");
  }

  showReplyForm(event) {
    event.preventDefault();
    console.log("Reply button clicked!");

    const replyToId = event.currentTarget.dataset.commentsReplyToId;
    console.log("Replying to comment ID:", replyToId);

    // ✅ Remove existing reply forms before adding a new one
    document.querySelectorAll(".reply-form").forEach((form) => {
      form.remove();
    });

    // ✅ Clone the reply form template safely
    const template = this.replyFormTemplateTarget.content.cloneNode(true);
    const container = document.getElementById(
      `reply_form_container_${replyToId}`
    );

    if (container) {
      container.innerHTML = ""; // Ensure the container is empty before inserting
      container.appendChild(template);

      // ✅ Set the reply_to_id hidden field
      const hiddenField = container.querySelector(
        "input[name='comment[reply_to_id]']"
      );
      if (hiddenField) {
        hiddenField.value = replyToId;
      }

      // ✅ Ensure the form is visible
      container.querySelector(".reply-form").classList.remove("hidden");
    }
  }

  cancelReply(event) {
    event.preventDefault();
    console.log("Cancel button clicked!");

    // ✅ Remove the reply form when cancel is clicked
    event.currentTarget.closest(".reply-form").remove();
  }
}
