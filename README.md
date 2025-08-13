# DualStatus Pro - WhatsApp Status Saver

![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-1C86F2.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

DualStatus Pro is a full-featured status saver application for Android, built with Flutter. It allows users to seamlessly view, download, and manage statuses from both WhatsApp and WhatsApp Business.

## ✨ Features

- **Dual WhatsApp Support**: View and download statuses from both **WhatsApp** and **WhatsApp Business**.
- **Image & Video Tabs**: Separate tabs for easy browsing of image and video statuses.
- **Built-in Gallery**: A dedicated "Saved" screen to view and manage all your downloaded statuses.
- **Delete Functionality**: Easily delete saved statuses directly from the app.
- **Status Viewer**: A full-screen image and video viewer with playback controls.
- **AdMob Integration**: Monetized with App Open and Banner ads for a non-intrusive user experience.
- **Settings Screen**: Includes options to:
  - **Rate the app** on the Google Play Store.
  - **Share the app** with friends.
  - View **Privacy Policy**.
  - Check the **App Version**.
- **Clean & Responsive UI**: A user-friendly interface that works well on various screen sizes.
- **Permission Handling**: Gracefully requests necessary storage permissions.

## 📸 Screenshots

| WhatsApp Statuses | Saved Gallery | Settings |
| :---: |:---:|:---:|
|  |

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- **Flutter SDK**: Make sure you have the Flutter SDK installed. For instructions, see the [official Flutter documentation](https://flutter.dev/docs/get-started/install).
- **Android Studio** or **VS Code** with the Flutter plugin.

### Installation

1.  **Clone the repo**
    ```sh
    git clone [https://github.com/davidchemwetich/DualStatus.git.git](https://github.com/davidchemwetich/DualStatus.git.git)
    ```
2.  **Navigate to the project directory**
    ```sh
    cd dualstatus-pro
    ```
3.  **Install dependencies**
    ```sh
    flutter pub get
    ```
4.  **Run the app**
    ```sh
    flutter run
    ```

## ⚙️ Configuration

Before publishing, you need to replace the test AdMob IDs with your own real IDs.

1.  **Android**: Update the AdMob App ID in `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-YOUR_ADMOB_APP_ID"/>
    ```

2.  **iOS** (if you plan to support it): Update the AdMob App ID in `ios/Runner/Info.plist`:
    ```xml
    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-YOUR_ADMOB_APP_ID</string>
    ```

3.  **Ad Unit IDs**: Replace the test ad unit IDs in `lib/services/ad_manager.dart` with your own.

## 🛠 Built With

This project is built using Flutter and leverages several key packages:

- **[google_mobile_ads](https://pub.dev/packages/google_mobile_ads)**: For displaying AdMob ads.
- **[permission_handler](https://pub.dev/packages/permission_handler)**: For handling runtime permissions.
- **[url_launcher](https://pub.dev/packages/url_launcher)**: For opening URLs (Privacy Policy, Rate Us).
- **[share_plus](https://pub.dev/packages/share_plus)**: For sharing the app link.
- **[package_info_plus](https://pub.dev/packages/package_info_plus)**: To get the app version.
- **[path_provider](https://pub.dev/packages/path_provider)**: To find the correct local paths.
- **[video_player](https://pub.dev/packages/video_player)**: For playing video statuses.
- **[photo_view](https://pub.dev/packages/photo_view)**: For a zoomable image viewer.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📧 Contact

Your Name - [@your_twitter](https://twitter.com/bynetops) - dchemwetich@outlook.com

Project Link: [https://github.com/davidchemwetich/DualStatus.git](https://github.com/davidchemwetich/DualStatus.git)
