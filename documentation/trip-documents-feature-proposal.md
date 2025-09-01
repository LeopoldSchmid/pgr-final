# Proposal: Trip Attachments Feature

This document outlines a plan to implement a feature that allows users to upload, view, and manage any files relevant to a trip.

## 1. Goal

The primary goal is to create a dedicated section within a trip's page where users can attach files. This provides a central, accessible location for all important information, available during both planning and execution of the trip.

## 2. Proposed Implementation

The implementation will be based on Ruby on Rails' built-in Active Storage framework, which is the standard and most integrated way to handle file uploads.

### a. Model Layer

- **Create a new model:** `TripAttachment`.
- **Attributes:**
    - `name` (string): A user-friendly name for the file (e.g., "Packing List Ideas", "Museum Opening Hours Screenshot").
    - `trip_id` (references `trips`): Associates the attachment with a specific trip.
    - `user_id` (references `users`): Tracks who uploaded the file.
- **Associations:**
    - `TripAttachment` will `belong_to :trip` and `belong_to :user`.
    - `Trip` will `have_many :trip_attachments`.
    - `User` will `have_many :trip_attachments`.
- **File Attachment:**
    - Use Active Storage to create the attachment association: `has_one_attached :file`. This will handle the underlying storage mechanism.

### b. Controller Layer

- **Create a new controller:** `TripAttachmentsController`.
- **Actions:**
    - `create`: Handles the uploading of a new file. It will require a `name` and the file itself. It will associate the new `TripAttachment` with the correct `Trip` and the `current_user`.
    - `destroy`: Allows a user to delete an attachment.
- **Authorization:**
    - The controller will ensure that only members of a trip can add or delete attachments.

### c. View / UI Layer

- **Location:** The UI for this feature will be on the main trip page (`/trips/:id`).
- **Components:**
    1.  **Upload Form:** A new card or section titled "Attachments" will be added to the trip view. This section will contain a simple form with a text input for the `name`, a file input for the `file`, and an "Upload" button.
    2.  **Attachments List:** Below the form, a list of already uploaded files will be displayed. Each item will show the attachment `name`, a link to the file, the uploader's name, and a "Delete" button.

### d. Routing

- The routes will be nested within the `trips` resource in `config/routes.rb`.

```ruby
# config/routes.rb
resources :trips do
  # ... existing nested resources
  resources :trip_attachments, only: [:create, :destroy]
end
```

## 3. User Flow

1.  A user navigates to a specific trip's page.
2.  They see a new "Attachments" section.
3.  They enter a name for their file (e.g., "Restaurant Menu PDF"), select a file, and click "Upload".
4.  The page reloads, and the new file appears in the list.
5.  They can click the file name to view/download it.
6.  They can click a "Delete" icon to remove it.

---

Please review this updated plan. If you approve, I can proceed with the implementation.