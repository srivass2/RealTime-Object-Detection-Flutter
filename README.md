# Flutter Object Detection with TensorFlow Lite

A Flutter application demonstrating object detection using TensorFlow Lite via the `tflite_flutter` package. This app features:

- **Live Object Detection** using the device camera
- **Network Image Detection** utilizing Unsplash API
- **Gallery Photo Detection** from the device's photo library

## 🚀 Features

- Real-time object detection through the camera
- Detect objects in images fetched from the Unsplash API
- Detect objects in images selected from the device gallery

## 🛠️ Setup Instructions

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/dhyash-simform/object_detection.git
   cd object_detection
   ```

2. **Install Dependencies:**

   ```bash
   flutter pub get
   ```

3. **Add Unsplash API Key:**

    - Sign up at [Unsplash Developers](https://unsplash.com/developers) to get your API key.
    - Open `lib/services/api_service_type.dart`.
    - Locate the headers parameter and replace `YOUR_API_KEY` with your actual API key:
      ```dart
      headers: {
        'Authorization': 'Client-ID YOUR_API_KEY',
      }
      ```

4. **Run the App:**

   ```bash
   flutter run
   ```

## 📦 Dependencies

### `tflite_flutter` (v0.11.0)
A Flutter plugin for TensorFlow Lite that allows running machine learning models directly on mobile devices with efficient performance.

### `image` (^4.5.2)
A pure Dart library for decoding, encoding, and processing image files. It supports a wide range of image formats and manipulation features.

### `image_picker` (^1.1.2)
A Flutter plugin that provides an easy way to pick images and videos from the device's gallery or camera.

### `camera` (^0.10.6)
A Flutter plugin to access and control the device's cameras. It enables capturing photos, recording videos, and implementing real-time camera previews.

### `retrofit` (^4.1.0)
A type-safe HTTP client generator for Dart inspired by Square's Retrofit library for Android. It simplifies API calls using annotations.

### `json_annotation` (^4.8.1)
Provides annotations to support JSON serialization and deserialization in Dart. Often used with `json_serializable` for automated code generation.

### `dio` (^5.4.3+1)
A powerful HTTP client for Dart, featuring interceptors, request cancellation, form data handling, file downloading, and more.

### `mobx` (^2.3.3+2)
A state-management library that makes state observable and reactive in Flutter apps. It enables efficient UI updates based on data changes.

### `flutter_mobx` (^2.2.1+1)
A Flutter integration library for MobX, allowing easy reactive state management with `Observer` widgets to rebuild UI efficiently.

### `provider` (^6.1.2)
A popular state-management solution in Flutter. It offers a simple and efficient way to manage and propagate app state.

### `flutter_svg` (^2.0.17)
A Flutter library to render SVG (Scalable Vector Graphics) files directly in the app. Useful for displaying vector images with high scalability.

## 📸 Screenshots

| Live Object Detection                                                                                                                                                                                                                                               | Network Image Object Detection                                                                                                                                                                                                                           | Gallery Image Object Detection                                                                                                                                                                                                                                                     |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <a href="https://github.com/dhyash-simform/object_detection/blob/main/screenshots/live_object_detection.gif?raw=true"><img src="https://github.com/dhyash-simform/object_detection/blob/main/screenshots/live_object_detection.gif?raw=true"  height="600px;"/></a> | <a href="https://github.com/dhyash-simform/object_detection/blob/main/screenshots/object_detection.gif?raw=true"><img src="https://github.com/dhyash-simform/object_detection/blob/main/screenshots/object_detection.gif?raw=true" height="600px;"/></a> | <a href="https://github.com/dhyash-simform/object_detection/blob/main/screenshots/object_detection_from_gallery.gif?raw=true"><img src="https://github.com/dhyash-simform/object_detection/blob/main/screenshots/object_detection_from_gallery.gif?raw=true" height="600px;"/></a> |

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.h

