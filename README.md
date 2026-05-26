# Flashnote

Snap a photo, set a reminder, never forget again.

Flashnote is an iOS app that turns the act of taking a picture into a time-aware reminder. Capture an image (or jot a quick text note), attach a reminder date, and the app surfaces it back to you through a swipeable card stack with live countdowns and local notifications — making remembering as effortless as taking a picture.

## Background

Modern life moves fast, and small but important things — a parking spot, a product on a shelf, a handwritten note, a bill due next Tuesday — slip through the cracks of crowded camera rolls and forgotten reminder apps. Traditional reminder apps demand too much typing and structure for fleeting thoughts, while the Photos app captures the moment but offers no way to resurface it when it actually matters.

Flashnote bridges this gap. It is designed for **busy individuals — students, parents, professionals, and travelers** — who rely on visual cues and quick capture rather than structured to-do lists.

## Features

### 1. Snap-and-Remind Capture
Take a photo or jot a quick text note and instantly attach a reminder date. No menus, no forms — point, shoot, pick when you want to be nudged. Perfect for capturing a product on a shelf, a parking spot, or a handwritten note you don't want to forget.

### 2. Swipeable Card Stack with Live Countdown
All saved Flashnotes appear as a stack of cards, each showing a live countdown to its reminder time. See at a glance what's coming up next and how soon — a deck of visual sticky notes that always knows what's due.

### 3. Smart Local Notifications
When the moment arrives, Flashnote taps you on the shoulder with a notification — even if the app is closed. The app remembers for you, so the photo or note you saved actually serves its purpose when it matters most.

## Tech Stack

### Languages & Core Frameworks
- **Swift 5+**
- **SwiftUI** — declarative UI framework for all views and navigation
- **SwiftData** — persistence layer (`@Model`, `@Query`, `ModelContainer`)
- **UIKit (interop)** — `UIImagePickerController` wrapped via `UIViewControllerRepresentable` for camera capture

### Apple System APIs
- **UserNotifications** — local notification scheduling via `NotificationManager`
- **FileManager / Documents Directory** — file-based image persistence (`ImageStorage` utility)
- **AVFoundation / Camera** — accessed through `UIImagePickerController`
- **Share Extension** — `ShareViewController` + `ShareExtensionView` to receive images shared from other apps

### Architecture & Patterns
- **MVVM** — `@Observable` ViewModels (`GalleryViewModel`, `InstantDetailViewModel`)
- **`@Bindable` / `@State` / `@Query`** — SwiftUI state primitives
- **Async/Await + `Task.detached`** — concurrent image loading off the main thread
- **`NavigationStack`** — modern navigation container

### Design & Assets
- **SF Symbols** — Apple's system icon library
- **Asset Catalog** — light, dark, and tinted app icon variants
- **Dark-only UI** — custom palette tuned for low-light usage

## Project Structure

```
Flashnote/
├── Models/
│   └── FlashnoteItem.swift         # SwiftData model
├── Views/
│   ├── GalleryView.swift           # Main screen
│   ├── CardStackView.swift         # Swipeable card stack
│   ├── CameraView.swift            # UIImagePickerController wrapper
│   ├── CountdownLabel.swift        # Live countdown display
│   ├── InstantDetailSheet.swift    # New/edit note form
│   ├── ShareExtensionView.swift    # Share extension UI
│   └── ShareViewController.swift   # Share extension entry
├── ViewModels/
│   ├── GalleryViewModel.swift
│   └── InstantDetailViewModel.swift
├── Utilities/
│   ├── ImageStorage.swift          # File-based image persistence
│   └── NotificationManager.swift   # Local notification scheduling
└── FlashnoteApp.swift              # App entry point
```

## Requirements

- iOS 17+ (SwiftData and `@Observable` macro)
- Xcode 15+
- Swift 5.9+

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/bayujo/Flashnote.git
   ```
2. Open `Flashnote.xcodeproj` in Xcode
3. Select an iOS 17+ simulator or device
4. Build and run (`⌘R`)

## Author

[@bayujo](https://github.com/bayujo)
