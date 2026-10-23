using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

namespace Donut;

public sealed class FileConverter
{
    public string Convert(string sourcePath, OutputFormat format)
    {
        if (!File.Exists(sourcePath))
            throw new FileNotFoundException("The source file could not be read.", sourcePath);

        string extension = Path.GetExtension(sourcePath).TrimStart('.').ToLowerInvariant();
        string destination = CreateDestinationPath(sourcePath, format);

        if (extension == format.Extension())
        {
            File.Copy(sourcePath, destination);
            return destination;
        }

        if (format is OutputFormat.Webp or OutputFormat.Heic or OutputFormat.Pdf)
            throw new NotSupportedException(
                $"{format.DisplayName()} encoding is not available in the Windows built-in codec set.");

        using var source = new Bitmap(sourcePath);
        using var output = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        using (Graphics graphics = Graphics.FromImage(output))
        {
            graphics.Clear(Color.White);
            graphics.DrawImage(source, 0, 0, source.Width, source.Height);
        }

        ImageCodecInfo codec = format switch
        {
            OutputFormat.Jpeg => GetCodec(ImageFormat.Jpeg),
            OutputFormat.Png => GetCodec(ImageFormat.Png),
            OutputFormat.Tiff => GetCodec(ImageFormat.Tiff),
            _ => throw new NotSupportedException()
        };

        if (format == OutputFormat.Jpeg)
        {
            using var parameters = new EncoderParameters(1);
            parameters.Param[0] = new EncoderParameter(
                System.Drawing.Imaging.Encoder.Quality,
                100L);
            output.Save(destination, codec, parameters);
        }
        else
        {
            output.Save(destination, codec, null);
        }

        return destination;
    }

    private static ImageCodecInfo GetCodec(ImageFormat format) =>
        ImageCodecInfo.GetImageEncoders()
            .First(codec => codec.FormatID == format.Guid);

    private static string CreateDestinationPath(string sourcePath, OutputFormat format)
    {
        string directory = Path.GetDirectoryName(sourcePath)
            ?? throw new IOException("The source directory could not be resolved.");
        string baseName = Path.GetFileNameWithoutExtension(sourcePath);
        string sourceExtension = Path.GetExtension(sourcePath)
            .TrimStart('.')
            .ToLowerInvariant();

        if (sourceExtension == format.Extension())
            baseName += "_converted";

        string candidate = Path.Combine(directory, $"{baseName}.{format.Extension()}");
        int suffix = 2;
        while (File.Exists(candidate))
        {
            candidate = Path.Combine(
                directory,
                $"{baseName}_{suffix}.{format.Extension()}");
            suffix++;
        }

        return candidate;
    }
}
