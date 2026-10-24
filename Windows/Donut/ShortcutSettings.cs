using System.IO;
using System.Windows.Input;

namespace Donut;

public sealed record ShortcutBinding(uint Modifiers, uint Key, string DisplayName);

public static class ShortcutSettings
{
    private static readonly string SettingsDirectory =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Donut");
    private static readonly string SettingsPath = Path.Combine(SettingsDirectory, "shortcut.txt");

    public static bool Exists => File.Exists(SettingsPath);

    public static ShortcutBinding Load()
    {
        if (!Exists)
            return Default;

        string[] parts = File.ReadAllText(SettingsPath).Split('|', 3);
        if (parts.Length == 3
            && uint.TryParse(parts[0], out uint modifiers)
            && uint.TryParse(parts[1], out uint key)
            && !string.IsNullOrWhiteSpace(parts[2]))
            return new ShortcutBinding(modifiers, key, parts[2]);

        return Default;
    }

    public static void Save(ShortcutBinding binding)
    {
        Directory.CreateDirectory(SettingsDirectory);
        File.WriteAllText(SettingsPath, $"{binding.Modifiers}|{binding.Key}|{binding.DisplayName}");
    }

    public static void Delete()
    {
        if (File.Exists(SettingsPath))
            File.Delete(SettingsPath);

        if (Directory.Exists(SettingsDirectory)
            && !Directory.EnumerateFileSystemEntries(SettingsDirectory).Any())
            Directory.Delete(SettingsDirectory);
    }

    public static ShortcutBinding FromKey(Key key, ModifierKeys modifiers)
    {
        uint nativeModifiers = 0;
        if (modifiers.HasFlag(ModifierKeys.Control)) nativeModifiers |= 0x0002;
        if (modifiers.HasFlag(ModifierKeys.Alt)) nativeModifiers |= 0x0001;
        if (modifiers.HasFlag(ModifierKeys.Shift)) nativeModifiers |= 0x0004;
        if (modifiers.HasFlag(ModifierKeys.Windows)) nativeModifiers |= 0x0008;

        int virtualKey = KeyInterop.VirtualKeyFromKey(key);
        string modifierText = modifiers.HasFlag(ModifierKeys.Control) ? "Ctrl + " : string.Empty;
        modifierText += modifiers.HasFlag(ModifierKeys.Alt) ? "Alt + " : string.Empty;
        modifierText += modifiers.HasFlag(ModifierKeys.Shift) ? "Shift + " : string.Empty;
        modifierText += modifiers.HasFlag(ModifierKeys.Windows) ? "Win + " : string.Empty;

        return new ShortcutBinding(
            nativeModifiers,
            (uint)virtualKey,
            modifierText + key);
    }

    public static ShortcutBinding Default { get; } =
        new(0x0002 | 0x0001, (uint)KeyInterop.VirtualKeyFromKey(Key.D), "Ctrl + Alt + D");
}
