# Donut for Windows

Donut is a lightweight Windows desktop file-conversion utility that runs in
the notification area and accepts multiple files by drag and drop.

The Windows app and installer use the same sharp orange ring mark: the app
renders it as a vector, while the installer ships matching ICO and wizard
artwork so it stays clear in Explorer, setup pages, shortcuts, and the tray.

## Requirements

- Windows 10 or later
- .NET 8 SDK
- Visual Studio 2022 or VS Code with the C# Dev Kit

## Run

```powershell
cd Donut
dotnet run
```

## Install for another person

Use `installer\Install Donut.exe`. This is a single installer file; it does
not include the source code. It requests administrator permission, installs
Donut under `Program Files\Donut`, creates Start Menu and optional Desktop
shortcuts, and adds a normal Windows uninstaller. Uninstalling Donut removes
the installed program directory, shortcuts, and any Donut-specific per-user
data directories.

On first launch, choose a global keyboard shortcut. Donut then starts quietly
with Windows. Press that shortcut to open the drop window, choose a format,
and drag one or more image files onto it. The tray menu can be used to change
the shortcut later.
Converted files are written beside the originals. Existing files are never
overwritten; a numeric suffix is added instead.

## Quality behavior

If the source extension already matches the selected format, Donut copies the
file byte-for-byte. JPEG output uses the highest available GDI+ quality
setting. PNG and TIFF output use their lossless built-in codecs.

The Windows built-in codec stack does not provide reliable WebP, HEIC, or PDF
encoding on every supported machine. Those format tiles currently report a
clear error instead of silently producing a lower-quality or incorrect file.
They can be enabled later with a vetted codec package if broad format support
is required.
