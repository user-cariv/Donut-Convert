using System.Windows;
using System.Windows.Input;

namespace Donut;

public partial class ShortcutSetupWindow : Window
{
    private ShortcutBinding? binding;

    public ShortcutSetupWindow()
    {
        InitializeComponent();
        PreviewKeyDown += ShortcutSetupWindow_PreviewKeyDown;
    }

    private void Window_Loaded(object sender, RoutedEventArgs e)
    {
        Activate();
        ShortcutText.Focus();
    }

    private void ShortcutSetupWindow_PreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        CaptureShortcut(e);
    }

    private void ShortcutText_PreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        CaptureShortcut(e);
    }

    private void CaptureShortcut(System.Windows.Input.KeyEventArgs e)
    {
        Key key = e.Key == Key.System ? e.SystemKey : e.Key;
        if (key is Key.LeftCtrl or Key.RightCtrl
            or Key.LeftAlt or Key.RightAlt
            or Key.LeftShift or Key.RightShift
            or Key.LWin or Key.RWin)
            return;

        ModifierKeys modifiers = Keyboard.Modifiers;
        if (modifiers == ModifierKeys.None)
        {
            ShortcutText.Text = "Add Ctrl, Alt, Shift, or Win";
            e.Handled = true;
            return;
        }

        binding = ShortcutSettings.FromKey(key, modifiers);
        ShortcutText.Text = binding.DisplayName;
        e.Handled = true;
    }

    private void Default_Click(object sender, RoutedEventArgs e)
    {
        binding = ShortcutSettings.Default;
        ShortcutText.Text = binding.DisplayName;
    }

    private void Save_Click(object sender, RoutedEventArgs e)
    {
        if (binding is null)
        {
            ShortcutText.Text = "Press a key combination first";
            return;
        }

        ShortcutSettings.Save(binding);
        DialogResult = true;
    }
}
