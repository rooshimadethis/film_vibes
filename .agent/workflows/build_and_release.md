---
description: Build the APK and release to GitHub
---

# Build and Release Workflow

1.  **Build the APK**
    Run the following command in your terminal to build a release version of the APK:
    ```bash
    flutter build apk --release
    ```
    This process might take a few minutes.

2.  **Locate the APK**
    Once the build finishes, your new APK will be located at:
    `build/app/outputs/flutter-apk/app-release.apk`

3.  **Create a GitHub Release**
    - Go to your repository: [https://github.com/rooshimadethis/paper_vibes](https://github.com/rooshimadethis/paper_vibes)
    - Click on **Releases** on the right sidebar (or go to `/releases`).
    - Click **Draft a new release**.
    - **Tag version**: Enter a version number (e.g., `v1.0.1`).
    - **Release title**: Enter a title (e.g., `Values Persistence`).
    - **Description**: Describe the changes (e.g., "Added slider persistence so settings are saved between launches.").
    - **Attach binaries**: Drag and drop the `app-release.apk` file from your build folder into the "Attach binaries by dropping them here or selecting them" box.
    - Click **Publish release**.

4.  **Done!**
    Your APK is now available for download from the GitHub release page.
