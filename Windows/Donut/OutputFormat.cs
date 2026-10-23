namespace Donut;

public enum OutputFormat
{
    Jpeg,
    Png,
    Webp,
    Heic,
    Tiff,
    Pdf
}

public static class OutputFormatExtensions
{
    public static string DisplayName(this OutputFormat format) => format switch
    {
        OutputFormat.Jpeg => "JPG",
        OutputFormat.Png => "PNG",
        OutputFormat.Webp => "WEBP",
        OutputFormat.Heic => "HEIC",
        OutputFormat.Tiff => "TIFF",
        OutputFormat.Pdf => "PDF",
        _ => format.ToString().ToUpperInvariant()
    };

    public static string Extension(this OutputFormat format) => format switch
    {
        OutputFormat.Jpeg => "jpg",
        OutputFormat.Png => "png",
        OutputFormat.Webp => "webp",
        OutputFormat.Heic => "heic",
        OutputFormat.Tiff => "tiff",
        OutputFormat.Pdf => "pdf",
        _ => throw new ArgumentOutOfRangeException(nameof(format))
    };
}
