# PicSwipe

PicSwipe is a mobile media management application built with Flutter. It utilizes a gesture-based interface to help users organize, favorite, and prune their local photo and video libraries.

## Core Features

### Media Procurement and Performance
The application accesses the device's local storage using the photo_manager package. It employs a sliding window pagination strategy, fetching media in batches of 50 assets to maintain performance. To prevent Out of Memory (OOM) errors, the main feed renders low-resolution thumbnails rather than full-resolution files.

### Swipe-to-Action Interface
The primary interaction is handled through a card stack interface:
* Swipe Right: Marks the asset as a favorite at the system level.
* Swipe Up: Marks the asset as reviewed/kept without modifying the file system.
* Swipe Left: Moves the asset reference into a local recycle bin state.

### Persistent Recycle Bin
The recycle bin list is persisted using the shared_preferences package. This ensures that assets marked for deletion remain in the bin even after the application is closed. On startup, a hydration phase verifies that the files still exist on the device before displaying them in the bin.

### Multi-Select and Batch Processing
The Recycle Bin view supports a long-press selection mode. Users can select multiple items to perform batch actions:
* Batch Restore: Removes items from the bin and returns them to the active feed.
* Batch Delete: Triggers the native operating system confirmation dialog for permanent file removal.

### Undo Functionality
The application maintains a history of the last 10 swipes. An undo mechanism is available to revert these actions, restoring the previously swiped card to the top of the stack and reversing any state changes associated with that specific swipe.

### Advanced Video Support
Video assets autoplay when they reach the top of the card stack. The player includes a playback progress bar and a dedicated mute/unmute toggle. Videos are muted by default to ensure a non-disruptive user experience.

### Feed Customization
Users can modify the order of the media feed through three sorting modes:
* Date Ascending: Displays the oldest media first.
* Date Descending: Displays the newest media first.
* Random: Shuffles the available assets for a non-chronological browsing experience.

## Technical Precautions
The application adheres to scoped storage requirements on Android 13+ and iOS. Permanent deletions always require user confirmation via the native system prompt, ensuring the application cannot delete files without explicit user consent.
