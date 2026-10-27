#!/usr/bin/env python3
"""Builds the App Store screenshots (6.9-inch iPhone, 1320×2868) from raw simulator screens.

Usage:  python3 scripts/make_store_screenshots.py <raw-dir> [--out AppStore/screenshots]

<raw-dir> holds the screens exported from StoreScreenshotTests (en-1-home.png, en-2-log.png…).
Every screenshot gets its own layout and background so the five never look alike:
  1 home     hero gradient, white centred title, one large phone
  2 log      cream, phone tilted to the right, a zoomed card of the food tiles on the left
  3 results  pale amber, two overlapping phones (blood results + history)
  4 learn    mint, phone zoomed in and running off the bottom edge
  5 welcome  deep raspberry, the app icon floating over the phone
Colors follow Irovi/DesignSystem/Palette.swift. Requires Pillow (pip3 install pillow).
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

WIDTH, HEIGHT = 1320, 2868
EXTRA_SIZES = {'6.5': (1284, 2778), '6.3': (1206, 2622)}  # older 6.5" slot; 6.3" "Dynamic Island (medium display)" slot
MARGIN = 96
FONT_FILE = '/System/Library/Fonts/SFNS.ttf'
ICON = Path('AppStore/AppIcon-1024.png')

IRON, IRON_DEEP = (217, 58, 53), (168, 18, 74)
RASPBERRY_DARK = (110, 12, 52)
CREAM, IRON_SOFT = (255, 247, 244), (253, 228, 225)
AMBER_SOFT, MINT = (254, 240, 217), (221, 243, 230)
TEXT, SUBTEXT = (42, 27, 31), (111, 90, 96)
WHITE = (255, 255, 255)

COPY = {
    'home': ('Your iron day\nat a glance', 'Food, streaks and blood results in one place'),
    'log': ('Log iron-rich food\nin a few taps', 'Six food groups and two simple habits'),
    'results': ('Results and history,\ntogether', 'Hemoglobin, ferritin and every day you logged'),
    'learn': ('Learn the basics', 'Short reads with trusted sources'),
    'welcome': ('No account.\nJust your plate.', 'Everything stays on your iPhone'),
}


# ---------- type ----------

def font(size, style):
    face = ImageFont.truetype(FONT_FILE, size)
    face.set_variation_by_name(style)
    return face


def fitted_font(lines, style, size, max_width):
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


def headline(draw, title, subtitle, color, subcolor, align='left', top=150):
    """Draws the title and subtitle; returns the y below them."""
    max_width = WIDTH - 2 * MARGIN
    title_lines = title.split('\n')
    title_font = fitted_font(title_lines, 'Bold', 112, max_width)
    y = top
    for line in title_lines:
        x = MARGIN if align == 'left' else (WIDTH - title_font.getlength(line)) / 2
        draw.text((x, y), line, font=title_font, fill=color)
        y += int(title_font.size * 1.14)
    y += 18
    sub_font = font(48, 'Regular')
    for line in wrap(subtitle, sub_font, max_width):
        x = MARGIN if align == 'left' else (WIDTH - sub_font.getlength(line)) / 2
        draw.text((x, y), line, font=sub_font, fill=subcolor)
        y += 62
    return y


# ---------- pieces ----------

def gradient(size, start, end, diagonal=True):
    w, h = size
    base = Image.new('RGB', size, start)
    top = Image.new('RGB', size, end)
    mask = Image.new('L', size)
    draw = ImageDraw.Draw(mask)
    steps = w + h if diagonal else h
    for i in range(steps):
        value = int(255 * i / max(steps - 1, 1))
        if diagonal:
            draw.line([(i, 0), (0, i)], fill=value, width=2)
        else:
            draw.line([(0, i), (w, i)], fill=value)
    return Image.composite(top, base, mask)


def frame(screen, height):
    """iPhone-style frame (with the Dynamic Island) around a screenshot."""
    bezel = 24
    scale = (height - 2 * bezel) / screen.height
    sw, sh = round(screen.width * scale), height - 2 * bezel
    screen = screen.resize((sw, sh), Image.LANCZOS)
    radius = round(165 * scale)
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


def place(canvas, layer, x, y, shadow=True, angle=0):
    """Pastes an RGBA layer (optionally rotated) with a soft drop shadow."""
    if angle:
        layer = layer.rotate(angle, resample=Image.BICUBIC, expand=True)
    if shadow:
        alpha = layer.split()[3]
        blur = Image.new('RGBA', layer.size, (40, 10, 20, 0))
        blur.putalpha(alpha.point(lambda a: int(a * 0.45)))
        pad = 80
        shadow_layer = Image.new('RGBA', (layer.width + 2 * pad, layer.height + 2 * pad), (0, 0, 0, 0))
        shadow_layer.paste(blur, (pad, pad))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(36))
        canvas.paste(shadow_layer, (int(x - pad + 10), int(y - pad + 36)), shadow_layer)
    canvas.paste(layer, (int(x), int(y)), layer)


def card(screen, box, width, radius=44, border=10):
    """A zoomed piece of the screen as a floating rounded card."""
    w, h = screen.size
    piece = screen.crop((int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h)))
    piece = piece.resize((width, round(piece.height * width / piece.width)), Image.LANCZOS)
    out = Image.new('RGBA', (piece.width + 2 * border, piece.height + 2 * border), (0, 0, 0, 0))
    ImageDraw.Draw(out).rounded_rectangle((0, 0, out.width - 1, out.height - 1), radius=radius + border, fill=WHITE + (255,))
    mask = Image.new('L', piece.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, piece.width - 1, piece.height - 1), radius=radius, fill=255)
    out.paste(piece, (border, border), mask)
    return out


def blob(draw, box, fill):
    draw.ellipse(box, fill=fill)


# ---------- layouts ----------

def layout_home(screens):
    canvas = gradient((WIDTH, HEIGHT), IRON, IRON_DEEP)
    overlay = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    blob(d, (-260, 1900, 700, 2860), (255, 255, 255, 22))
    blob(d, (900, 380, 1560, 1040), (255, 255, 255, 18))
    canvas.paste(overlay, (0, 0), overlay)
    y = headline(ImageDraw.Draw(canvas), *COPY['home'], WHITE, (255, 236, 236), align='center')
    device = frame(screens['1-home'], HEIGHT - y - 150)
    place(canvas, device, (WIDTH - device.width) / 2, y + 70)
    return canvas


def layout_log(screens):
    canvas = Image.new('RGB', (WIDTH, HEIGHT), CREAM)
    d = ImageDraw.Draw(canvas)
    blob(d, (520, 900, 1700, 2400), IRON_SOFT)
    y = headline(d, *COPY['log'], TEXT, SUBTEXT)
    screen = screens['2-log']
    device = frame(screen, 2050)
    place(canvas, device, WIDTH - device.width + 40, y + 120, angle=-5)
    # Zoomed food tiles (first two rows of the grid) floating over the left edge.
    tiles = card(screen, (0.03, 0.335, 0.97, 0.585), 720)
    place(canvas, tiles, 60, y + 760, angle=4)
    return canvas


def layout_results(screens):
    canvas = Image.new('RGB', (WIDTH, HEIGHT), AMBER_SOFT)
    d = ImageDraw.Draw(canvas)
    blob(d, (-300, 1500, 760, 2560), (252, 226, 186))
    y = headline(d, *COPY['results'], TEXT, SUBTEXT)
    back = frame(screens['4-history'], 1780)
    front = frame(screens['3-blood'], 1900)
    place(canvas, back, WIDTH - back.width - 10, y + 90, angle=-6)
    place(canvas, front, 40, y + 420, angle=5)
    return canvas


def layout_learn(screens):
    canvas = Image.new('RGB', (WIDTH, HEIGHT), MINT)
    d = ImageDraw.Draw(canvas)
    blob(d, (820, -260, 1600, 520), (200, 233, 213))
    y = headline(d, *COPY['learn'], TEXT, SUBTEXT, align='center')
    device = frame(screens['5-learn'], 2700)  # runs off the bottom edge on purpose
    place(canvas, device, (WIDTH - device.width) / 2, y + 90)
    return canvas


def layout_welcome(screens):
    canvas = gradient((WIDTH, HEIGHT), RASPBERRY_DARK, IRON_DEEP)
    overlay = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    blob(d, (-200, 600, 520, 1320), (255, 255, 255, 16))
    blob(d, (860, 2100, 1640, 2880), (255, 255, 255, 16))
    canvas.paste(overlay, (0, 0), overlay)
    y = headline(ImageDraw.Draw(canvas), *COPY['welcome'], WHITE, (255, 224, 234), align='center')
    device = frame(screens['6-welcome'], HEIGHT - y - 260)
    dx = (WIDTH - device.width) / 2
    place(canvas, device, dx, y + 210)
    if ICON.exists():
        size = 250
        icon = Image.open(ICON).convert('RGBA').resize((size, size), Image.LANCZOS)
        mask = Image.new('L', (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=56, fill=255)
        icon.putalpha(mask)
        place(canvas, icon, dx + device.width - size + 70, y + 70, angle=-8)
    return canvas


LAYOUTS = [
    ('01-home', layout_home),
    ('02-log', layout_log),
    ('03-results', layout_results),
    ('04-learn', layout_learn),
    ('05-welcome', layout_welcome),
]


def fit(image, size):
    """Scale to the target width, then trim the extra height evenly."""
    width, height = size
    scaled = image.resize((width, round(image.height * width / image.width)), Image.LANCZOS)
    top = (scaled.height - height) // 2
    return scaled.crop((0, top, width, top + height))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('raw_dir', type=Path)
    parser.add_argument('--out', type=Path, default=Path('AppStore/screenshots'))
    args = parser.parse_args()

    screens = {}
    for path in args.raw_dir.glob('en-*.png'):
        screens[path.stem[3:]] = Image.open(path).convert('RGB')
    needed = ['1-home', '2-log', '3-blood', '4-history', '5-learn', '6-welcome']
    missing = [n for n in needed if n not in screens]
    if missing:
        raise SystemExit(f'missing raw screens: {missing}')

    out_dir = args.out / 'en'
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, layout in LAYOUTS:
        image = layout(screens).convert('RGB')
        image.save(out_dir / f'{name}.png')
        for suffix, size in EXTRA_SIZES.items():
            extra_dir = args.out / f'en-{suffix}'
            extra_dir.mkdir(parents=True, exist_ok=True)
            fit(image, size).save(extra_dir / f'{name}.png')
    print(f'{len(LAYOUTS)} screenshots written to {args.out}/')


if __name__ == '__main__':
    main()
