#!/usr/bin/env python3
"""Builds the App Store screenshots (6.9-inch iPhone, 1320×2868) from raw simulator screens.

Usage:  python3 scripts/make_store_screenshots.py <raw-dir> [--out AppStore/screenshots]

<raw-dir> holds the screens exported from StoreScreenshotTests (en-1-today.png, en-2-blood.png…).
Each one gets a headline, a device frame and a background with shapes in the brand color.
Keep the colors in sync with Irovi/DesignSystem/Palette.swift. Requires Pillow (pip3 install pillow).
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

WIDTH, HEIGHT = 1320, 2868
# Extra copies for App Store Connect slots that reject 1320×2868: folder suffix → size.
EXTRA_SIZES = {'6.5': (1284, 2778)}  # "iPhone 6.5\" Display" (accepts 1242×2688 or 1284×2778)
MARGIN = 96
FONT_FILE = '/System/Library/Fonts/SFNS.ttf'  # SF Pro, has Vietnamese glyphs

BRAND = (181, 64, 30)        # Palette.iron #B5401E
BRAND_SOFT = (248, 227, 217)  # Palette.ironSoft #F8E3D9
BACKGROUND = (251, 246, 240)  # Palette.background #FBF6F0
TEXT = (43, 32, 27)           # Palette.textPrimary #2B201B
SUBTEXT = (110, 95, 87)       # Palette.textSecondary #6E5F57

# Wording follows docs/PRODUCT_SPEC.md §5: no diagnosis, no treatment claims.
SCREENS = ['1-today', '2-blood', '3-absorb', '4-learn', '5-welcome']
COPY = {
    'en': {
        '1-today': ('An iron-rich plate,\nevery day', 'Tick the food groups you ate today'),
        '2-blood': ('Your blood results\nat a glance', 'Hemoglobin and ferritin over time'),
        '3-absorb': ('Help your body\nabsorb iron', 'Simple habits and gentle reminders'),
        '4-learn': ('Learn the\nbasics', 'Short reads with trusted sources'),
        '5-welcome': ('No account.\nJust your plate.', 'Everything stays on your iPhone'),
    },
}


def font(size, style):
    face = ImageFont.truetype(FONT_FILE, size)
    face.set_variation_by_name(style)
    return face


def fitted_font(lines, style, size, max_width):
    """Largest size (down from `size`) at which every line fits."""
    while size > 40:
        face = font(size, style)
        if all(face.getlength(line) <= max_width for line in lines):
            return face
        size -= 4
    return font(size, style)


def wrap(text, face, max_width):
    lines, line = [], ''
    for word in text.split():
        candidate = f'{line} {word}'.strip()
        if face.getlength(candidate) <= max_width or not line:
            line = candidate
        else:
            lines.append(line)
            line = word
    return lines + [line] if line else lines


def circle(cx, cy, r):
    return (cx - r, cy - r, cx + r, cy + r)


def decorate(draw, index):
    """Brand shapes around the device, different on every screenshot."""
    if index == 0:
        draw.ellipse(circle(-40, 2480, 560), fill=BRAND)
        draw.ellipse(circle(1260, 1150, 250), outline=BRAND_SOFT, width=44)
    elif index == 1:
        draw.ellipse(circle(1400, 2000, 620), fill=BRAND_SOFT)
        draw.ellipse(circle(150, 2650, 150), fill=BRAND)
    elif index == 2:
        draw.polygon([(0, 1900), (WIDTH, 1400), (WIDTH, 1800), (0, 2300)], fill=BRAND_SOFT)
        draw.ellipse(circle(1180, 2600, 300), fill=BRAND)
    elif index == 3:
        draw.ellipse(circle(1150, 2450, 420), outline=BRAND, width=60)
        draw.ellipse(circle(1230, 900, 160), fill=BRAND_SOFT)
    else:
        draw.ellipse(circle(40, 1500, 360), fill=BRAND)
        draw.ellipse(circle(900, 2750, 380), outline=BRAND_SOFT, width=50)


def frame(screen, height):
    """iPhone-style frame around a screenshot (with the Dynamic Island, absent from simulator shots)."""
    bezel = 24
    scale = (height - 2 * bezel) / screen.height
    sw, sh = round(screen.width * scale), height - 2 * bezel
    screen = screen.resize((sw, sh), Image.LANCZOS)
    radius = round(165 * scale)  # screen corner radius, ≈55 pt at 3×
    device = Image.new('RGBA', (sw + 2 * bezel, sh + 2 * bezel), (0, 0, 0, 0))
    draw = ImageDraw.Draw(device)
    draw.rounded_rectangle((0, 0, device.width - 1, device.height - 1), radius=radius + bezel, fill=(17, 17, 17, 255))
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=radius, fill=255)
    device.paste(screen, (bezel, bezel), mask)
    island_w, island_h = round(375 * scale), round(111 * scale)
    top = bezel + round(33 * scale)
    left = (device.width - island_w) // 2
    draw.rounded_rectangle((left, top, left + island_w, top + island_h), radius=island_h // 2, fill=(0, 0, 0, 255))
    return device


def shadow(canvas, x, y, size):
    w, h = size
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle((x + 20, y + 40, x + w - 20, y + h + 20), radius=160, fill=(15, 23, 42, 90))
    layer = layer.filter(ImageFilter.GaussianBlur(40))
    canvas.paste(layer, (0, 0), layer)


def compose(screen, title, subtitle, index):
    canvas = Image.new('RGB', (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(canvas)
    decorate(draw, index)

    max_width = WIDTH - 2 * MARGIN
    title_lines = title.split('\n')
    title_font = fitted_font(title_lines, 'Bold', 112, max_width)
    y = 150
    for line in title_lines:
        draw.text((MARGIN, y), line, font=title_font, fill=TEXT)
        y += int(title_font.size * 1.14)
    y += 18
    subtitle_font = font(48, 'Regular')
    for line in wrap(subtitle, subtitle_font, max_width):
        draw.text((MARGIN, y), line, font=subtitle_font, fill=SUBTEXT)
        y += 62

    top = y + 64
    device = frame(screen, HEIGHT - top - 90)
    x = (WIDTH - device.width) // 2
    shadow(canvas, x, top, device.size)
    canvas.paste(device, (x, top), device)
    return canvas


def fit(image, size):
    """Scale to the target width, then trim the extra height evenly (only plain background)."""
    width, height = size
    scaled = image.resize((width, round(image.height * width / image.width)), Image.LANCZOS)
    top = (scaled.height - height) // 2
    return scaled.crop((0, top, width, top + height))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('raw_dir', type=Path)
    parser.add_argument('--out', type=Path, default=Path('AppStore/screenshots'))
    args = parser.parse_args()

    written = 0
    for language, texts in COPY.items():
        out_dir = args.out / language
        out_dir.mkdir(parents=True, exist_ok=True)
        for index, name in enumerate(SCREENS):
            raw = args.raw_dir / f'{language}-{name}.png'
            if not raw.exists():
                print(f'skip, missing {raw.name}')
                continue
            image = compose(Image.open(raw).convert('RGB'), *texts[name], index)
            file_name = f'{index + 1:02d}-{name.split("-", 1)[1]}.png'
            image.save(out_dir / file_name)
            for suffix, size in EXTRA_SIZES.items():
                extra_dir = args.out / f'{language}-{suffix}'
                extra_dir.mkdir(parents=True, exist_ok=True)
                fit(image, size).save(extra_dir / file_name)
            written += 1
    print(f'{written} screenshots written to {args.out}/')


if __name__ == '__main__':
    main()
