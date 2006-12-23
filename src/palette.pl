#!/usr/bin/perl

#
# Concept : http://alanjstr.blogspot.com/2006/11/grepping-css.html
# Author  : Mahesh Asolkar <asolkar@gmail.com>
#

use strict;
use warnings;

use FileHandle;
use File::Find;
use Getopt::Long;

my $ext = "css"; # Default extension
my $src = ".";   # Default source. File or directory
my $correct_usage = GetOptions ('ext=s' => \$ext, 'src=s' => \$src);

unless ($correct_usage) {
  print qq {
USAGE: palette.pl --ext=file_extension --src=source > palette.html
       Source can be a file or a directory. If directory, color
       information will be gathered from all stylesheet files under it
};
  die;
}

my $colors = {};

#
# If source is a directory, traverse it, or parse for colors
#
die "$src does not exist" unless (-e $src);
if (-d $src) {
  find (sub { get_colors_from_file ($_, $colors, $File::Find::name) if (/\.$ext$/)}, $src);
} else {
  get_colors_from_file ($src, $colors, $src);
}

present_palette ($colors, $src);

# -----------
# Subroutines
# -----------
sub get_colors_from_file {
  my ($file, $colors, $file_path) = @_;

  my $css_h = new FileHandle ($file);
  die "Could not open \'$file\' to read: $!" unless (defined ($css_h));
  my $css = do { local $/; <$css_h> };
  $css_h->close ();

  $css =~ s/\/\*.*?\*\///msg;

  my @lines = split ("\n", $css);

  my $color_re  = '\b' . join ('\b|\b', &get_named_colors) . '\b'; # Named colors
     $color_re .= '|rgb\s*\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*\)'; # rgb
     $color_re .= '|#[a-f0-9]{3,6}'; # Hex

  foreach (@lines) {
    if (m/:.*?($color_re)/imsg) {
      my ($line) = m/:(.*)/;
      while ($line =~ m/($color_re)/imsg) {
        my $color = $1;
        $color = lc($color) if ($color =~ m/^#/);
        $color = get_proper_case_name ($color, $File::Find::name);
        $colors->{$color} = [] unless (exists $colors->{$color});
        push (@{$colors->{$color}}, $file_path);
      }
    }
  }
}

sub present_palette {
  my ($colors, $src) = @_;
  my $swatch_width = (&get_max_name_length($colors) * 0.6);

  print qq {<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>Color Pallette</title>
    <style type="text/css">
    body {
      font-family: "Trebuchet MS", Sans-Serif;
    }
    .palette_cell {
      font-size: 0.75em;
      text-align: center;
      float: left; 
      width: ${swatch_width}em;
      border: 2px solid #cccccc;
      margin: 3px 3px 3px 3px;
      padding: 3px 3px 3px 3px;
      -moz-border-radius-topleft: 10px;
      -moz-border-radius-topright: 10px;
    }
    .palette_cell > div {
      font-size: 2em;
    }
    </style>
  </head>
  <body style="background-color: #ffffff">
  <h1>Color Pallette</h1>
  <p>Source: <code>$src</code></p>
};

  foreach my $color (sort keys %$colors ) {
    print qq {    <div class="palette_cell">$color
      <div style="background-color: $color; color: $color">
        -
      </div>
    </div>
};
  }

  print qq {  </body>
</html>
};
}

sub get_named_colors {
  my @color_names = qw (AliceBlue AntiqueWhite Aqua Aquamarine Azure Beige Bisque Black
                        BlanchedAlmond Blue BlueViolet Brown BurlyWood CadetBlue Chartreuse
                        Chocolate Coral CornflowerBlue Cornsilk Crimson Cyan DarkBlue DarkCyan
                        DarkGoldenRod DarkGray DarkGrey DarkGreen DarkKhaki DarkMagenta
                        DarkOliveGreen Darkorange DarkOrchid DarkRed DarkSalmon DarkSeaGreen
                        DarkSlateBlue DarkSlateGray DarkSlateGrey DarkTurquoise DarkViolet
                        DeepPink DeepSkyBlue DimGray DimGrey DodgerBlue FireBrick FloralWhite
                        ForestGreen Fuchsia Gainsboro GhostWhite Gold GoldenRod Gray Grey
                        Green GreenYellow HoneyDew HotPink IndianRed Indigo Ivory Khaki
                        Lavender LavenderBlush LawnGreen LemonChiffon LightBlue LightCoral
                        LightCyan LightGoldenRodYellow LightGray LightGrey LightGreen LightPink
                        LightSalmon LightSeaGreen LightSkyBlue LightSlateGray LightSlateGrey
                        LightSteelBlue LightYellow Lime LimeGreen Linen Magenta Maroon
                        MediumAquaMarine MediumBlue MediumOrchid MediumPurple MediumSeaGreen
                        MediumSlateBlue MediumSpringGreen MediumTurquoise MediumVioletRed
                        MidnightBlue MintCream MistyRose Moccasin NavajoWhite Navy OldLace
                        Olive OliveDrab Orange OrangeRed Orchid PaleGoldenRod PaleGreen
                        PaleTurquoise PaleVioletRed PapayaWhip PeachPuff Peru Pink Plum
                        PowderBlue Purple Red RosyBrown RoyalBlue SaddleBrown Salmon SandyBrown
                        SeaGreen SeaShell Sienna Silver SkyBlue SlateBlue SlateGray SlateGrey
                        Snow SpringGreen SteelBlue Tan Teal Thistle Tomato Turquoise Violet
                        Wheat White WhiteSmoke Yellow YellowGreen AliceBlue AntiqueWhite Aqua
                        Aquamarine Azure Beige Bisque Black BlanchedAlmond Blue BlueViolet
                        Brown BurlyWood CadetBlue Chartreuse Chocolate Coral CornflowerBlue
                        Cornsilk Crimson Cyan DarkBlue DarkCyan DarkGoldenRod DarkGray
                        DarkGrey DarkGreen DarkKhaki DarkMagenta DarkOliveGreen Darkorange
                        DarkOrchid DarkRed DarkSalmon DarkSeaGreen DarkSlateBlue DarkSlateGray
                        DarkSlateGrey DarkTurquoise DarkViolet DeepPink DeepSkyBlue DimGray
                        DimGrey DodgerBlue FireBrick FloralWhite ForestGreen Fuchsia Gainsboro
                        GhostWhite Gold GoldenRod Gray Grey Green GreenYellow HoneyDew HotPink
                        IndianRed Indigo Ivory Khaki Lavender LavenderBlush LawnGreen
                        LemonChiffon LightBlue LightCoral LightCyan LightGoldenRodYellow
                        LightGray LightGrey LightGreen LightPink LightSalmon LightSeaGreen
                        LightSkyBlue LightSlateGray LightSlateGrey LightSteelBlue LightYellow
                        Lime LimeGreen Linen Magenta Maroon MediumAquaMarine MediumBlue
                        MediumOrchid MediumPurple MediumSeaGreen MediumSlateBlue
                        MediumSpringGreen MediumTurquoise MediumVioletRed MidnightBlue
                        MintCream MistyRose Moccasin NavajoWhite Navy OldLace Olive OliveDrab
                        Orange OrangeRed Orchid PaleGoldenRod PaleGreen PaleTurquoise
                        PaleVioletRed PapayaWhip PeachPuff Peru Pink Plum PowderBlue Purple
                        Red RosyBrown RoyalBlue SaddleBrown Salmon SandyBrown SeaGreen SeaShell
                        Sienna Silver SkyBlue SlateBlue SlateGray SlateGrey Snow SpringGreen
                        SteelBlue Tan Teal Thistle Tomato Turquoise Violet Wheat White
                        WhiteSmoke Yellow YellowGreen);
  my @color_prefs = qw (ActiveBorder ActiveCaption AppWorkspace Background ButtonFace
                        ButtonHighlight ButtonShadow ButtonText CaptionText GrayText Highlight
                        HighlightText InactiveBorder InactiveCaption InactiveCaptionText
                        InfoBackground InfoText Menu MenuText Scrollbar ThreeDDarkShadow
                        ThreeDFace ThreeDHighlight ThreeDLightShadow ThreeDShadow Window
                        WindowFrame WindowText);

  return (@color_names, @color_prefs);
}

sub get_max_name_length {
  my ($colors) = @_;
  my $max_len = 11;

  foreach my $color (keys %$colors) {
    $max_len = length($color) if (length($color) > $max_len);
  }

  return $max_len;
}

sub get_proper_case_name {
  my ($color, $file) = @_;
  my @color_names = &get_named_colors;

  foreach my $proper_case_name (@color_names) {
    if ($color =~ /^$proper_case_name$/i) {
      # warn "Using proper cased name \'$proper_case_name\' instead of \'$color\' in file $file\n"
      #  if ($color ne $proper_case_name);
      $color = $proper_case_name;
    }
  }

  return $color;
}
