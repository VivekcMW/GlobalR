# Splash Screen Assets

This directory contains the native splash screen assets.

## Current Assets

- `logo_mark.svg` - Vector source file (1024×1024)
- `logo_mark.png` - Rasterized splash image (generate from SVG)

## Required: Generate PNG from SVG

### Option 1: Using Inkscape (Recommended)
```bash
inkscape logo_mark.svg -o logo_mark.png -w 1024 -h 1024
```

### Option 2: Using ImageMagick
```bash
convert -background none -resize 1024x1024 logo_mark.svg logo_mark.png
```

### Option 3: Using rsvg-convert (librsvg)
```bash
rsvg-convert -w 1024 -h 1024 logo_mark.svg -o logo_mark.png
```

### Option 4: Using macOS Preview
1. Open `logo_mark.svg` in Preview
2. File → Export → PNG, 1024x1024
3. Save as `logo_mark.png`

## After Generating the PNG

Uncomment the splash screen lines in `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#14110E"
  image: assets/splash/logo_mark.png  # Uncomment
  android_12:
    color: "#14110E"
    image: assets/splash/logo_mark.png  # Uncomment
  ios: true
  web: false
```

Then regenerate native splash screens:

```bash
flutter pub run flutter_native_splash:create
```

## Brand Colors Reference

| Name | Hex |
|------|-----|
| Background | `#14110E` |
| Saffron/Accent | `#E0A93B` / `#FF9933` |
| Off-White | `#EDE6DA` |
| Muted Grey | `#A09890` |
