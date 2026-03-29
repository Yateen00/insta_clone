import { application } from "./application";

import AssetController from "./asset_controller";
import CommentsController from "./comments_controller";
import FlashController from "./flash_controller";
import HelloController from "./hello_controller";
import PasswordVisibilityController from "./password_visibility_controller";
import ProfilePictureController from "./profile_picture_controller";
import ReadMoreController from "./read_more_controller";
import ResetFormController from "./reset_form_controller";

application.register("asset", AssetController);
application.register("comments", CommentsController);
application.register("flash", FlashController);
application.register("hello", HelloController);
application.register("password-visibility", PasswordVisibilityController);
application.register("profile-picture", ProfilePictureController);
application.register("read-more", ReadMoreController);
application.register("reset-form", ResetFormController);
