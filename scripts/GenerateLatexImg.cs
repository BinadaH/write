using Godot;
using System;
using CSharpMath.SkiaSharp;
using System.IO;
using SkiaSharp;

public partial class GenerateLatexImg : Node
{
	public ImageTexture GenerateImg(string text, int curr_font_size)
	{
        var painter = new MathPainter();
        painter.LaTeX = text;
        painter.FontSize = curr_font_size;
        painter.TextColor = SKColor.Parse("#FFFFFF");

        using var png = painter.DrawAsStream();

        byte[] buffer;
        using (var ms = new MemoryStream())
        {
            png.CopyTo(ms);
            buffer = ms.ToArray();
        }

        var image = new Image();
        Error err = image.LoadPngFromBuffer(buffer);

        if (err == Error.Ok)
        {
            return ImageTexture.CreateFromImage(image);
        }

        return null;

    }	
}
