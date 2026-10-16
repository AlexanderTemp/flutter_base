"""Regenerate Tradex icons with Pillow; does not run Flutter or build the app."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
NAVY = '#101D32'
SIZE = 1024
image = Image.new('RGB', (SIZE, SIZE), NAVY)
draw = ImageDraw.Draw(image)


def points(values):
    return [(round(x * SIZE / 100), round(y * SIZE / 100)) for x, y in values]


draw.polygon(points([(24, 25), (66, 25), (66, 35), (50, 35),
                     (50, 72), (40, 72), (40, 35), (24, 35)]), fill='#F5F8FC')
for line in [[(55, 69), (64, 58), (71, 63), (81, 48)],
             [(72, 48), (81, 48), (81, 57)]]:
    draw.line(points(line), fill='#62D5B0', width=round(SIZE * .05), joint='curve')
    radius = SIZE * .025
    for x, y in points(line):
        draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill='#62D5B0')


def save(path, size):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path)
    with Image.open(path) as result:
        assert result.size == (size, size), path


save('assets/branding/tradex.png', 1024)
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                      ('xxhdpi', 144), ('xxxhdpi', 192)]:
    save(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
    save(f'android/app/src/main/res/drawable-{density}/tradex_splash.png', size * 2)

for platform in ['ios', 'macos']:
    directory = ROOT / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
    for path in directory.glob('*.png'):
        with Image.open(path) as original:
            size = original.width
        save(path.relative_to(ROOT), size)

for scale, suffix in [(1, ''), (2, '@2x'), (3, '@3x')]:
    save(f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png', 96 * scale)

image.save(ROOT / 'windows/runner/resources/app_icon.ico',
           sizes=[(s, s) for s in [16, 24, 32, 48, 64, 128, 256]])
print('Tradex icons generated and PNG dimensions checked.')
