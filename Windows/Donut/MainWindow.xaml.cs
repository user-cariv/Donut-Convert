using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using WpfButton = System.Windows.Controls.Button;
using WpfColor = System.Windows.Media.Color;
using WpfColorConverter = System.Windows.Media.ColorConverter;

namespace Donut;

public partial class MainWindow : Window, INotifyPropertyChanged
{
    private readonly FileConverter converter = new();
    private readonly Action changeShortcut;
    private OutputFormat? selectedFormat;
    private bool isBusy;
    private bool isDragActive;
    private string status = "Choose a format";

    public ObservableCollection<FormatTile> Formats { get; } =
    [
        new(OutputFormat.Jpeg, "JPG", "#D96B3B", 24, 76),
        new(OutputFormat.Png, "PNG", "#C98745", 184, 16),
        new(OutputFormat.Webp, "WEBP", "#A95A45", 342, 76),
        new(OutputFormat.Heic, "HEIC", "#8A4F4B", 342, 326),
        new(OutputFormat.Tiff, "TIFF", "#A2613B", 184, 386),
        new(OutputFormat.Pdf, "PDF", "#B5653F", 24, 326)
    ];

    public string Status
    {
        get => status;
        private set { status = value; OnPropertyChanged(); }
    }

    public bool IsBusy
    {
        get => isBusy;
        private set { isBusy = value; OnPropertyChanged(); }
    }

    public bool IsDragActive
    {
        get => isDragActive;
        private set { isDragActive = value; OnPropertyChanged(); }
    }

    public string SelectedFormatLabel =>
        selectedFormat is null ? "Choose a format first" : $"Convert to {selectedFormat.Value.DisplayName()}";

    public MainWindow(Action changeShortcut)
    {
        InitializeComponent();
        this.changeShortcut = changeShortcut;
        DataContext = this;
    }

    private void Window_Loaded(object sender, RoutedEventArgs e)
    {
        var animation = new DoubleAnimation
        {
            From = 1,
            To = 1.025,
            Duration = TimeSpan.FromSeconds(3.2),
            AutoReverse = true,
            RepeatBehavior = RepeatBehavior.Forever,
            EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut }
        };
        Logo.RenderTransform.BeginAnimation(ScaleTransform.ScaleXProperty, animation);
        Logo.RenderTransform.BeginAnimation(ScaleTransform.ScaleYProperty, animation);
    }

    private void Window_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.OriginalSource is DependencyObject source
            && FindVisualParent<WpfButton>(source) is not null)
            return;

        if (e.ButtonState == MouseButtonState.Pressed)
            DragMove();
    }

    private void Minimize_Click(object sender, RoutedEventArgs e) => Hide();

    private void Close_Click(object sender, RoutedEventArgs e) => Hide();

    private void ChangeShortcut_Click(object sender, RoutedEventArgs e) =>
        changeShortcut();

    private static T? FindVisualParent<T>(DependencyObject child)
        where T : DependencyObject
    {
        DependencyObject? parent = VisualTreeHelper.GetParent(child);
        while (parent is not null)
        {
            if (parent is T match)
                return match;
            parent = VisualTreeHelper.GetParent(parent);
        }

        return null;
    }

    public void ShowForDrop()
    {
        if (!IsVisible)
            Show();
        Activate();
    }

    private void Format_Click(object sender, RoutedEventArgs e)
    {
        if (sender is WpfButton button && button.Tag is OutputFormat format)
        {
            foreach (FormatTile tile in Formats)
                tile.IsSelected = tile.Format == format;

            selectedFormat = format;
            Status = $"Drop files on {format.DisplayName()}";
            OnPropertyChanged(nameof(SelectedFormatLabel));
        }
    }

    private async void Window_Drop(object sender, System.Windows.DragEventArgs e)
    {
        IsDragActive = false;
        if (IsBusy
            || selectedFormat is null
            || !e.Data.GetDataPresent(System.Windows.DataFormats.FileDrop))
            return;

        var files = ((string[])e.Data.GetData(System.Windows.DataFormats.FileDrop))
            .Where(File.Exists)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
        if (files.Length == 0)
        {
            Status = "No readable files";
            return;
        }

        OutputFormat format = selectedFormat.Value;
        IsBusy = true;
        Status = $"Converting {files.Length} file{(files.Length == 1 ? "" : "s")}…";
        int converted = 0;
        int failed = 0;
        string? firstError = null;

        await Task.Run(() =>
        {
            foreach (string file in files)
            {
                try
                {
                    converter.Convert(file, format);
                    converted++;
                }
                catch (Exception error)
                {
                    failed++;
                    firstError ??= error.Message;
                }
            }
        });

        IsBusy = false;
        Status = converted > 0
            ? failed == 0
                ? $"{converted} saved as {format.DisplayName()}"
                : $"{converted} saved · {failed} failed"
            : firstError ?? "Conversion failed";
    }

    private void Window_DragOver(object sender, System.Windows.DragEventArgs e)
    {
        IsDragActive = !IsBusy
            && selectedFormat is not null
            && e.Data.GetDataPresent(System.Windows.DataFormats.FileDrop);
        e.Effects = IsBusy || selectedFormat is null
            ? System.Windows.DragDropEffects.None
            : System.Windows.DragDropEffects.Copy;
        e.Handled = true;
    }

    private void Window_DragLeave(object sender, System.Windows.DragEventArgs e) =>
        IsDragActive = false;

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

public sealed class FormatTile : INotifyPropertyChanged
{
    private bool isSelected;

    public OutputFormat Format { get; }
    public string Label { get; }
    public string Detail { get; }
    public System.Windows.Media.Brush Brush { get; }
    public double Left { get; }
    public double Top { get; }

    public bool IsSelected
    {
        get => isSelected;
        set
        {
            if (isSelected == value)
                return;
            isSelected = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsSelected)));
        }
    }

    public FormatTile(OutputFormat format, string label, string color, double left, double top)
    {
        Format = format;
        Label = label;
    Detail = format switch
    {
        OutputFormat.Jpeg => "Photo",
        OutputFormat.Png => "Lossless",
        OutputFormat.Webp => "Web",
        OutputFormat.Heic => "Apple",
        OutputFormat.Tiff => "Print",
        OutputFormat.Pdf => "Document",
        _ => string.Empty
    };
        Brush = new SolidColorBrush(
            (WpfColor)WpfColorConverter.ConvertFromString(color));
        Left = left;
        Top = top;
    }

    public event PropertyChangedEventHandler? PropertyChanged;
}
