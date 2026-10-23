# Donut

A small macOS 13+ background utility that shows a radial conversion HUD while
dragging a file with Shift held.

The menu-bar item uses the Donut artwork, and the packaging script creates a
multi-size `Donut.icns` app icon for Finder and the Dock.

## Create the macOS installer

On macOS, run:

```bash
chmod +x package-macos.sh
./package-macos.sh
```

This creates `build/Install Donut.dmg`, containing `Donut.app` with a
multi-size `Donut.icns` icon. The DMG is the single file to share with a Mac
user. For distribution outside your own devices, sign and notarize the app
with an Apple Developer certificate before sharing it publicly.

## Open and run

1. Open `Donut.xcodeproj` in Xcode on macOS.
2. Select the `Donut` scheme and a Mac destination.
3. Build and run.
4. In **System Settings > Privacy & Security > Accessibility**, enable
   **Donut**. Relaunch the app if macOS asks.
5. In Finder, drag an image or PDF, hold **Shift**, and drop it on a format.

The app is configured as an agent with `LSUIElement = YES`, so it does not
appear in the Dock. The converted file is written beside the original. If the
target name already exists, a numeric suffix is used.

The HUD uses full donut wedges as drop targets, supports multiple Finder
providers in one drop, and can rasterize the first page of a PDF when
converting PDF to an image format. Image-to-PDF uses Core Graphics PDF output.
Conversions run off the main thread, report partial failures, and never
overwrite an existing file.

The converter uses a preserve-first policy. Files whose source extension
already matches the selected format are copied byte-for-byte. Other raster
formats retain available metadata and use maximum encoder quality; PNG and
TIFF remain lossless. PDF input is rasterized only when converting it to an
image format, because that operation necessarily produces pixels rather than
editable PDF content.

## Notes

The project is intentionally non-sandboxed so it can write next to arbitrary
Finder files without requiring security-scoped bookmark management. WebP and
HEIC availability depends on the ImageIO encoders provided by the Mac.
The menu-bar icon is a monochrome SF Symbol so it automatically adapts to
light and dark menu bars.

## Current platform

The implemented target is macOS 13 and later. The `Windows` folder is reserved
for a future native implementation.
