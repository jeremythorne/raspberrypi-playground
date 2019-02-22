#!/usr/bin/python3

from font_fredoka_one import FredokaOne
from PIL import ImageFont, Image, ImageDraw
import os.path
import requests
import sys
inky_available = False

try:
    from inky import InkyPHAT
    inky_available = True
except ImportError:
    print("can't import InkyPHAT")

"""Fetch and render weather to image"""


class Weather:
    """class to fetch and print/render Met Office Data Point weather"""

    def __init__(self):

        self.app_id = open("/home/pi/metofficekey.txt").read().strip()

        self.location = "350107"  # Anglesey Abbey
        self.url_base = "http://datapoint.metoffice.gov.uk/" +\
                        "public/data/val/wxfcs/all/json/"

    def fetch(self):
        """use Met Office DataPoint API to fetch 3 hourly forecast"""
        url = "{}{}?res=3hourly&key={}".format(
                self.url_base, self.location, self.app_id)
        print(url)
        r = requests.get(url)
        if r.status_code != 200:
            print("error {}: {}".format(r.status_code, r.text))
            self.error = True
            return
        self.error = False
        j = r.json()

        weather_types = {
                "NA":("Not available", "", ""),
                "0": ("Clear", "night", "sunny"),
                "1": ("Sunny", "day", "sunny"),
                "2": ("Partly cloudy", "night", "cloudy"),
                "3": ("Partly cloudy", "day", "cloudy"),
                "4": ("Not used", "", ""),
                "5": ("Mist", "", "fog"),
                "6": ("Fog", "", "fog"),
                "7": ("Cloudy", "", "cloudy"),
                "8": ("Overcast", "", "cloudy"),
                "9": ("Light rain shower", "night", "rain"),
                "10": ("Light rain shower", "day", "rain"),
                "11": ("Drizzle", "", "rain"),
                "12": ("Light rain", "", "rain"),
                "13": ("Heavy rain shower", "night", "rain"),
                "14": ("Heavy rain shower", "day", "rain"),
                "15": ("Heavy rain", "", "rain"),
                "16": ("Sleet shower", "night", "rain"),
                "17": ("Sleet shower", "day", "rain"),
                "18": ("Sleet", "", "rain"),
                "19": ("Hail shower", "night", "rain"),
                "20": ("Hail shower", "day", "rain"),
                "21": ("Hail", "", "rain"),
                "22": ("Light snow shower", "night", "snow"),
                "23": ("Light snow shower", "day", "snow"),
                "24": ("Light snow", "", "snow"),
                "25": ("Heavy snow shower", "night", "snow"),
                "26": ("Heavy snow shower", "day", "snow"),
                "27": ("Heavy snow", "", "snow"),
                "28": ("Thunder shower", "night", "thunder"),
                "29": ("Thunder shower", "day", "thunder"),
                "30": ("Thunder", "", "thunder"),
                }

        loc = j['SiteRep']['DV']['Location']
        self.city = loc['name']
        now = loc['Period'][0]
        self.temp = now['Rep'][0]['T']  # F = Feels like

        todays_temps = [int(rep['T']) for rep in now['Rep']]
        tomorrows_temps = [int(rep['T']) for rep in loc['Period'][1]['Rep']]
        max_temp = max(todays_temps)
        min_temp = min(todays_temps + tomorrows_temps[0:3])

        self.max_temp = str(max_temp)
        self.min_temp = str(min_temp)
        W = now['Rep'][0]['W']
        self.weather = weather_types[W][0]
        self.icon = weather_types[W][2]
        t = j['SiteRep']['DV']['dataDate']
        date, time = t.split("T")
        time = time[:-1]
        self.date_txt = "{} {}".format(date, time)
        print("""the weather forecast for {} ({})
        is {}, temp {} ({}/{}) C""".format(
            self.city,
            self.date_txt,
            self.weather,
            self.temp,
            self.min_temp,
            self.max_temp))

    def _draw(self, img, props):
        big_font = ImageFont.truetype(FredokaOne, 30)
        font = ImageFont.truetype(FredokaOne, 20)
        mini_font = ImageFont.truetype(FredokaOne, 16)
        W, H = props.WIDTH, props.HEIGHT
        black = props.BLACK
        white = props.WHITE
        red = props.RED
        draw = ImageDraw.Draw(img)
        draw.rectangle([(0, 0), (W, H)], white)
        icon_name = self.icon + ".png"
        if os.path.exists(icon_name):
            icon = Image.open(icon_name)
            img.paste(icon, (W//2, 0))
        else:
            draw.arc(
                [W * 0.8, H/2 - W/2, W * 0.8 + W, H/2 + W/2],
                0, 360, fill=black)
        if self.error:
            draw.text((10, 10), "couldn't get forecast")
            return
        offy = 10
        draw.text((10, offy), self.date_txt, font=mini_font, fill=red)
        w, h = mini_font.getsize(self.date_txt)
        offy += h + 5
        draw.text((10, offy), self.weather, font=font, fill=red)
        w, h = font.getsize(self.weather)
        offy += h + 5
        temp_str = "{}°".format(self.temp)
        draw.text((10, offy), temp_str, font=big_font, fill=red)
        w, h = big_font.getsize(temp_str)
        mxw, mxh = mini_font.getsize(self.max_temp)
        mnw, mnh = mini_font.getsize(self.min_temp)
        draw.text((10 + w + 10, offy - 2), self.max_temp,
                  font=mini_font, fill=red)
        draw.text((10 + w + 10 + mxw / 2 - mnw / 2, offy + h - mnh + 3),
                  self.min_temp, font=mini_font, fill=red)

    def draw_inky(self):
        inky_display = InkyPHAT("red")
        img = Image.new("P", (inky_display.WIDTH, inky_display.HEIGHT))
        self._draw(img, inky_display)
        inky_display.set_image(img)
        inky_display.show()

    def draw(self, filename):
        """render weather to image"""
        class Props:
            WIDTH = 212
            HEIGHT = 104
            BLACK = (0, 0, 0)
            WHITE = (255, 255, 255)
            RED = (255, 0, 0)
        props = Props()
        img = Image.new("RGB", (props.WIDTH, props.HEIGHT))
        self._draw(img, props)
        img.save(filename)


def main():
    output_image = sys.argv[1] if len(sys.argv) > 1 else "weather.png"
    weather = Weather()
    try:
        weather.fetch()
    except Exception as e:
        print("Exceptiion:{}".format(e))
        weather.error = True
    if output_image == "inky" and inky_available:
        weather.draw_inky()
    else:
        weather.draw(output_image)


if __name__ == "__main__":
    main()
