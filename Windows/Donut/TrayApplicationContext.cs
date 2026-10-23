using System.IO;
using System.Windows;
using System.Windows.Interop;
using Forms = System.Windows.Forms;
using System.Runtime.InteropServices;

namespace Donut;

public sealed class TrayApplicationContext : IDisposable
{
    private readonly Forms.NotifyIcon notifyIcon;
    private readonly HwndSource hotKeySource;
    private MainWindow? window;
    private const int HotKeyId = 7001;
    private const int WmHotKey = 0x0312;

    public TrayApplicationContext()
    {
        notifyIcon = new Forms.NotifyIcon
        {
            Icon = new System.Drawing.Icon(
                Path.Combine(AppContext.BaseDirectory, "Donut.ico")),
            Visible = true,
            Text = "Donut"
        };
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Open Donut", null, (_, _) => ShowHud());
        menu.Items.Add(
            "Change shortcut",
            null,
            (_, _) => ConfigureShortcut());
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(
            "Quit Donut",
            null,
            (_, _) => System.Windows.Application.Current.Shutdown());
        notifyIcon.ContextMenuStrip = menu;
        notifyIcon.DoubleClick += (_, _) => ShowHud();

        var parameters = new HwndSourceParameters("DonutHotKey")
        {
            Width = 0,
            Height = 0,
            WindowStyle = 0x800000
        };
        hotKeySource = new HwndSource(parameters);
        hotKeySource.AddHook(HotKeyHook);
    }

    public void RegisterShortcut()
    {
        ShortcutBinding binding = ShortcutSettings.Load();
        if (!RegisterHotKey(hotKeySource.Handle, HotKeyId, binding.Modifiers, binding.Key))
            System.Windows.MessageBox.Show(
                $"The shortcut {binding.DisplayName} is already in use. Open Donut from the tray to choose another shortcut.",
                "Donut shortcut unavailable",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
    }

    private void ConfigureShortcut()
    {
        UnregisterHotKey(hotKeySource.Handle, HotKeyId);
        var setup = new ShortcutSetupWindow();
        if (setup.ShowDialog() == true)
            RegisterShortcut();
        else
            RegisterShortcut();
    }

    private IntPtr HotKeyHook(IntPtr hwnd, int message, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (message == WmHotKey && wParam.ToInt32() == HotKeyId)
        {
            ShowHud();
            handled = true;
        }
        return IntPtr.Zero;
    }

    public void ShowHud()
    {
        if (window is null)
        {
            window = new MainWindow();
            window.Closed += (_, _) => window = null;
        }

        window.ShowForDrop();
    }

    public void Dispose()
    {
        UnregisterHotKey(hotKeySource.Handle, HotKeyId);
        hotKeySource.RemoveHook(HotKeyHook);
        hotKeySource.Dispose();
        notifyIcon.Visible = false;
        notifyIcon.Dispose();
        window?.Close();
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
