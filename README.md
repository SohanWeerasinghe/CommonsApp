# CommonsApp

**A native iOS community management application for residents and building administrators.**

CommonsApp brings everyday residential community services into one SwiftUI application: community communication, events, shared-facility reservations, lending and borrowing, maintenance reporting, and administrative workflows. It integrates Firebase services with native iOS capabilities, including on-device machine learning, widgets, Siri/App Intents, and Live Activities.

> **Project status:** Coursework application / development project. Features described below are based on the project's documented implementation and repository history. Availability of individual workflows depends on user role, Firebase configuration, and device support.

## Features

### Accounts, identity, and access
- Firebase Authentication-based account access.
- Google Sign-In integration.
- Resident onboarding and administrator approval workflow.
- Role-aware resident and administrator experiences.
- Profile photo handling.
- Face ID-based biometric access functionality on supported devices.

### Resident community experience
- Community wall for resident communication and updates.
- Community events browsing and event calendar.
- Event RSVP and eligibility validation.
- Gym / shared-amenity reservation workflows, including availability, booking, and cancellation.
- Reservation progress feedback and accessible button labels.
- Lending and borrowing features for community members.
- Private resident chat.
- Local notifications for supported chat and gym booking activity.

### Maintenance management
- Submit maintenance requests with an issue title, description, and optional photo.
- Select a photo from the device photo library.
- On-device Core ML image analysis to assist with maintenance issue reporting.
- Maintenance request validation and submission feedback.
- Maintenance status tracking and stage-transition validation.
- Resident maintenance status notifications.
- Maintenance Live Activities using ActivityKit on supported iOS devices.

### Administrator functionality
- Dedicated administrator interface and management workflows.
- Resident approval and community administration.
- Management of relevant community activities and maintenance workflows.

### Native iOS integrations
- SwiftUI user interface with reusable components and themed styling.
- Siri / App Intents integration for supported app actions.
- WidgetKit extension.
- ActivityKit Live Activities.
- Local notifications.
- Accessibility labels, hints, progress indicators, and empty-state improvements.
- Haptic feedback in supported interactions.

### Data, validation, and security
- Firebase-backed authentication and Firestore data storage.
- Firestore security rules maintained in the repository.
- Client-side validation for key community workflows.
- Firebase rules test project for access-control verification.

## Technology stack

| Layer | Technology |
| --- | --- |
| Platform | iOS |
| Language | Swift |
| UI | SwiftUI |
| Authentication | Firebase Authentication; Google Sign-In |
| Data | Cloud Firestore |
| Machine learning | Core ML; bundled YOLO model package |
| Native integrations | App Intents / Siri, WidgetKit, ActivityKit, local notifications, biometric authentication |
| Testing | Swift Testing / Xcode tests; Firebase security rules tests |
| Development | Xcode, Swift Package Manager, Git and GitHub |

## Repository structure

```text
CommonsApp/
├── CommonsApp/                  # Main iOS app source and resources
├── CommonsApp.xcodeproj/        # Xcode project and shared schemes
├── CommonsAppTests/             # App tests
├── CommonsWidget/               # Widget extension source
├── firebase-tests/              # Firebase security rules tests
├── firestore.rules              # Firestore security rules
├── firebase.json                # Firebase tooling configuration
├── package.json                 # Firebase test tooling dependencies
└── package-lock.json
```

The application source is organized into feature-focused views, models, components, and shared application state/services. This is a practical project structure, **not** a claim of strict MVVM or clean architecture throughout the codebase.

## Getting started

### Requirements
- A Mac with a compatible version of Xcode.
- An iOS simulator or a compatible physical iPhone.
- A Firebase project configured for the application's authentication and Firestore requirements.
- Appropriate Apple signing configuration for deployment to a device.

### Open and build

1. Clone the repository:
   ```bash
   git clone https://github.com/SohanWeerasinghe/CommonsApp.git
   cd CommonsApp
   ```
2. Open `CommonsApp.xcodeproj` in Xcode.
3. Allow Xcode to resolve the Swift Package Manager dependencies.
4. Configure the Firebase project and add the required Firebase iOS configuration file locally, using the Firebase console and the application's bundle identifier. **Do not commit credentials or private keys.**
5. Select the **CommonsApp** scheme and a compatible simulator/device.
6. Build and run the project in Xcode.

> Some capabilities (for example, biometric authentication, Siri integrations, notifications, and Live Activities) require appropriate device support, permissions, or entitlements. A working Firebase backend is required for cloud-connected flows.

## Testing

The repository includes app-level tests and a Firebase rules test project. Coverage includes validation for maintenance requests and transitions, gym bookings, events and RSVP eligibility, core models, and Firestore access rules.

To run iOS tests, select the **CommonsApp** scheme in Xcode and choose **Product → Test**. To inspect the Firebase test setup, see `firebase-tests/`, `package.json`, and `firebase.json`; run it against the configured Firebase emulator/test environment rather than production data.

## Security and privacy

- Firebase Authentication identifies signed-in users.
- Firestore security rules are included for server-side access enforcement.
- Administrative privileges should be enforced by backend security rules, not merely by hiding interface controls.
- Maintenance photo analysis is designed to run on-device using Core ML.
- Configure Firebase and Apple capabilities for your own environment before running the application.
- Never commit service account keys, private credentials, or production user data.

## Project scope

CommonsApp is an academic software project demonstrating an integrated native iOS application for residential community management. It is not represented here as a production-certified building management system. Real-world deployment would require further operational, accessibility, security, privacy, and reliability review.

## Repository

[CommonsApp on GitHub](https://github.com/SohanWeerasinghe/CommonsApp)

## Author

Developed by **Sohan Weerasinghe**.
