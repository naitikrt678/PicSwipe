# PicSwipe

PicSwipe is a high-performance mobile media management application. It utilizes a highly responsive gesture-based card stack interface to help users seamlessly organize, favorite, and prune their local photo and video libraries.

## Core Features

### Fast & Reliable Media Loading
The application securely accesses your device's local storage. It employs a sliding window pagination strategy, fetching media in strict batches to maintain rapid rendering and smooth swiping. To prevent memory issues, the primary feed generates low-resolution thumbnails dynamically rather than loading massive full-resolution images. Robust safety checks ensure empty folders display proper placeholders and prevent deleted assets from causing visual glitches.

### Swipe-to-Action Interface
The primary interaction is handled through a liquid-smooth card stack interface:
* **Swipe Right (Favorite)**: Moves the photo or video into the persistent Favorites menu for safekeeping.
* **Swipe Up (Keep)**: Acknowledges the asset without modifying any lists or file systems.
* **Swipe Left (Bin)**: Moves the asset into a local Recycle Bin state for impending deletion.
* *Note: Downward swiping is disabled by default but can be enabled in the Settings for custom layouts.*

### Persistent State & Perfect Synchronization
Both the **Recycle Bin** and **Favorites** lists are saved directly to your device. Because the app independently governs your favorite items, it bypasses unpredictable bugs found in standard operating systems. 
* **Startup Check**: On launch, the app cross-references all saved media. If a file was manually deleted from your phone outside of PicSwipe, the app dynamically removes the dead link.
* **Live Feed Sync**: When fetching new media chunks, PicSwipe explicitly filters out any items currently sitting in your Bin or Favorites. It is impossible for a previously swiped photo to "ghost" back into your feed.

### Real-Time Storage Metrics
When managing the Recycle Bin, the app continuously calculates the exact file size of every asset. It prominently displays the total amount of storage space (in MB or GB) that will be successfully reclaimed upon confirming a permanent deletion.

### Context-Aware Previews
Tapping any image or video opens a full-screen preview. The action toolbar dynamically adapts based on where you opened it from:
* **Recycle Bin Previews**: Features "Restore" to move the item back to the main feed, and "Delete" for individual permanent removal.
* **Favorites Previews**: Features "Share" to send the asset to friends, and "Gallery". 
* **True External Gallery**: The "Open in Gallery" function commands your operating system to completely break out of PicSwipe and open the media inside your dedicated default app (like Google Photos or Samsung Gallery).

### Multi-Select & Batch Processing
Both the Recycle Bin and Favorites grid layouts support intuitive **Long-Press Selection**:
* **Batch Restore / Unfavorite**: Rapidly remove multiple items from their respective menus.
* **Batch Delete**: Triggers the native operating system confirmation dialog for permanent bulk file removal.
* **Batch Share**: Passes multiple selected media files directly to the native share menu (e.g., Messages, AirDrop, WhatsApp).

### Undo Functionality
The application maintains a history of your last 10 swipes. An undo mechanism is available to revert these actions, restoring the previously swiped card to the top of the stack and instantly reversing its addition to the Bin or Favorites.

### Customization & Settings
Users have full control over the app's logic and aesthetics:
* **Sort Modes**: View media by Newest First, Oldest First, or True Random (which utilizes a secure randomizer for flawless shuffling).
* **Global Theming**: Instantly swap between Light and Dark mode via the Settings panel without requiring an app restart.

## Privacy & Safety
The application adheres strictly to modern scoped storage guidelines on Android and iOS. Permanent file deletions always require an explicit, un-bypassable native system confirmation prompt. PicSwipe is incapable of permanently deleting user data without your direct, final consent.
