
# InstaClone

This is a full-featured Instagram clone built with **Ruby on Rails** as the final project for [The Odin Project's Ruby on Rails course](https://www.theodinproject.com/paths/full-stack-ruby-on-rails/courses/ruby-on-rails). It includes user authentication, posts with different media types, a follow system, notifications, and a comment system with replies.

## Features

- **User Authentication**: Sign up, log in, and manage profiles.
- **Oauth support**: Sign up, log in with github and google and have your basic profile automatically set for you
- **Posts**: Supports **text, images, and videos** (handled via CarrierWave).
- **Likes**: Users can like posts and comments.
- **Comments & Replies**: Nested comments with reply functionality.
- **Follow System**: Follow and unfollow users.
- **Notifications**: Get notified when someone interacts with your posts or follows you.
- **Turbo & Hotwire**: Enhances the UX with real-time updates.
- **Image & Video Processing**: Uses **MiniMagick** for image resizing and **FFmpeg** for video processing.

## Future Plans

- **Private & Public Profiles**: Allow users to choose their profile visibility.
- **Chat Feature**: Implement a real-time chat system.
- **Chat Feature**: Show posts to users that aren't logged in.
- **UI Improvements**: More consistent and polished user experience with UI that works across screens sizes.
- **Improve image processing**: tranfer to activestorage and improved media processing and storage. 
- **Deployment & Email Testing**: Deploy the app and refine email notifications.
- **Markdown Support**: Enable Markdown formatting for text posts and comments.
- **Tagging System**: Allow users to tag others in comments and posts.
- **Smart Feed Algorithm**: Implement an intelligent ranking system for displaying posts.
- **Lazy Loading**: Improve performance with infinite scrolling for posts and comments.
-  **Create Tests**: I focused on getting the features working, and testing only on terminal. Plan to create a test suite and learn to use Guard

## Setup Instructions

### Prerequisites

- Ruby 3.3.5
- Rails 8.0.1
- PostgreSQL
- Node.js & Yarn
- FFmpeg (for video processing)
- ImageMagick (for image processing)

### Installation

1. Clone the repository and navigate into the folder:

   ```sh
   git clone https://github.com/Yateen00/insta_clone.git
   cd insta_clone
   ```

2. Install dependencies:

   ```sh
   bundle install
   ```

3. Set up the database:

   ```sh
   rails db:create db:migrate db:seed
   ```

4. Configure environment variables:

   run the command to create a `.env` file:
   
   ```sh
   EDITOR=nano rails credentials:edit
   ```
   in the editor, add your keys for google and github:
   ```sh
   github:
     github_client_id=your_client_id
     github_client_secret=your_client_secret
   google:
     google_client_id=your_client_id  
     google_client_secret=your_client_secret
     
   ```

5. Start the server:

   ```sh
   ./bin/dev
   ```

6. Open the app in your browser:

   ```
   http://localhost:3000 
   ```
   or via the link from the terminal

