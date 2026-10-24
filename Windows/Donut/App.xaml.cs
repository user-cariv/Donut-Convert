using System.Windows;

namespace Donut;

public partial class App : System.Windows.Application
{
    private TrayApplicationContext? tray;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        if (e.Args.Contains("--uninstall", StringComparer.OrdinalIgnoreCase))
        {
            ShortcutSettings.Delete();
            Environment.Exit(0);
            return;
        }

        tray = new TrayApplicationContext();
        if (!ShortcutSettings.Exists)
        {
            var setup = new ShortcutSetupWindow();
            if (setup.ShowDialog() != true)
                ShortcutSettings.Save(ShortcutSettings.Default);
        }

        tray.RegisterShortcut();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        tray?.Dispose();
        base.OnExit(e);
    }
}
