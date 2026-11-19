"""Gera os ícones do Corre (Android e web) a partir das cores do design system.

Uso: python scripts/gerar_icones.py
"""
import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent / "app"
BRAND = (14, 124, 102)
ACCENT = (242, 169, 59)


def font(size: int) -> ImageFont.FreeTypeFont:
    for name in ("arialbd.ttf", "seguisb.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def icon(size: int, maskable: bool = False) -> Image.Image:
    """Quadrado arredondado verde com "c" branco e ponto amarelo."""
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    radius = 0 if maskable else int(s * 0.22)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=radius, fill=BRAND)
    inset = 0.18 if maskable else 0.0
    f = font(int(s * (0.62 - inset)))
    text = "c"
    box = d.textbbox((0, 0), text, font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    r = s * (0.075 - inset * 0.1)
    gap = s * 0.035
    total = w + gap + 2 * r
    x = (s - total) / 2 - box[0]
    y = (s - h) / 2 - box[1]
    d.text((x, y), text, font=f, fill="white")
    cx, cy = x + box[2] + gap + r, y + box[3] - r
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ACCENT)
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    android = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    res = ROOT / "apps/courier/android/app/src/main/res"
    for density, px in android.items():
        icon(px).save(res / f"mipmap-{density}" / "ic_launcher.png")

    for app in ("ds_sample", "panel", "courier"):
        web = ROOT / "apps" / app / "web"
        if not web.exists():
            continue
        icon(32).save(web / "favicon.png")
        icon(192).save(web / "icons/Icon-192.png")
        icon(512).save(web / "icons/Icon-512.png")
        icon(192, maskable=True).save(web / "icons/Icon-maskable-192.png")
        icon(512, maskable=True).save(web / "icons/Icon-maskable-512.png")
    print("ícones gerados")


if __name__ == "__main__":
    main()
