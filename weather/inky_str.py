#!/usr/bin/python3

from font_fredoka_one import FredokaOne
from PIL import ImageFont, Image, ImageDraw
import sys
inky_available = False

try:
    from inky import InkyPHAT
    inky_available = True
except ImportError:
    print("can't import InkyPHAT")

"""render string to inky display"""

class InkyString:

    def _draw(self, img, props, text):
        font = ImageFont.truetype(FredokaOne, 16)
        W, H = props.WIDTH, props.HEIGHT
        black = props.BLACK
        white = props.WHITE
        draw = ImageDraw.Draw(img)
        draw.rectangle([(0, 0), (W, H)], white)
        w, h = font.getsize(text)
        offy = (H - h) / 2
        draw.text((10, offy), text, font=font, fill=black)

    def draw_inky(self, text):
        inky_display = InkyPHAT("black")
        img = Image.new("P", (inky_display.WIDTH, inky_display.HEIGHT))
        self._draw(img, inky_display, text)
        inky_display.set_image(img)
        inky_display.show()


def main():
    text = sys.argv[1] if len(sys.argv) > 1 else "hello"
    if inky_available:
        InkyString().draw_inky(text)


if __name__ == "__main__":
    main()
