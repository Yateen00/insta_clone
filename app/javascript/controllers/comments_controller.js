import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["replyFormTemplate"];

  connect() {
    console.log("✅ Stimulus comments controller connected!");
  }

  showReplyForm(event) {
    event.preventDefault();

    const replyToId = event.currentTarget.dataset.commentsReplyToId;
    console.log(
      `🟢 Reply button clicked! Replying to comment ID: ${replyToId}`
    );

    if (!replyToId) {
      console.error("❌ Error: Missing replyToId");
      return;
    }

    // ✅ Remove existing reply forms before adding a new one
    document.querySelectorAll(".reply-form").forEach((form) => {
      console.log("🗑 Removing existing reply form:", form);
      form.remove();
    });

    // ✅ Clone the reply form template
    const template = this.replyFormTemplateTarget.content.cloneNode(true);
    if (!template) {
      console.error("❌ Error: Reply form template not found!");
      return;
    }

    const container = document.getElementById(
      `reply_form_container_${replyToId}`
    );
    if (!container) {
      console.error(
        `❌ Error: No reply container found for comment ID ${replyToId}`
      );
      return;
    }

    // ✅ Ensure container is empty before inserting new form
    container.innerHTML = "";
    container.appendChild(template);
    console.log(
      `✅ Inserted reply form into #reply_form_container_${replyToId}`
    );

    // ✅ Set the reply_to_id hidden field
    const hiddenField = container.querySelector(
      "input[name='comment[reply_to_id]']"
    );
    if (!hiddenField) {
      console.error(
        "❌ Error: Hidden reply_to_id field not found in the form!"
      );
      return;
    }
    hiddenField.value = replyToId;
    console.log(`✅ Set hidden reply_to_id field value to ${replyToId}`);

    // ✅ Ensure the form is visible
    const formElement = container.querySelector(".reply-form");
    if (!formElement) {
      console.error(
        "❌ Error: Could not find the reply form inside the container!"
      );
      return;
    }
    formElement.classList.remove("hidden");
    console.log(`✅ Reply form for comment ID ${replyToId} is now visible.`);
  }

  cancelReply(event) {
    event.preventDefault();
    const form = event.currentTarget.closest(".reply-form");

    if (form) {
      console.log("🗑 Removing reply form:", form);
      form.remove();
    } else {
      console.error("❌ Error: Could not find reply form to remove.");
    }
  }
}
