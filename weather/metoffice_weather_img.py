#!/usr/bin/python3

from font_fredoka_one import FredokaOne
from PIL import ImageFont, Image, ImageDraw
import requests

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
                "NA": "Not available",
                "0": ("Clear", "night"),
                "1": ("Sunny", "day"),
                "2": ("Partly cloudy", "night"),
                "3": ("Partly cloudy", "day"),
                "4": ("Not used", ""),
                "5": ("Mist", ""),
                "6": ("Fog", ""),
                "7": ("Cloudy", ""),
                "8": ("Overcast", ""),
                "9": ("Light rain shower", "night"),
                "10": ("Light rain shower", "day"),
                "11": ("Drizzle", ""),
                "12": ("Light rain", ""),
                "13": ("Heavy rain shower", "night"),
                "14": ("Heavy rain shower", "day"),
                "15": ("Heavy rain", ""),
                "16": ("Sleet shower", "night"),
                "17": ("Sleet shower", "day"),
                "18": ("Sleet", ""),
                "19": ("Hail shower", "night"),
                "20": ("Hail shower", "day"),
                "21": ("Hail", ""),
                "22": ("Light snow shower", "night"),
                "23": ("Light snow shower", "day"),
                "24": ("Light snow", ""),
                "25": ("Heavy snow shower", "night"),
                "26": ("Heavy snow shower", "day"),
                "27": ("Heavy snow", ""),
                "28": ("Thunder shower", "night"),
                "29": ("Thunder shower", "day"),
                "30": ("Thunder", ""),
                }

        loc = j['SiteRep']['DV']['Location']
        self.city = loc['name']
        now = loc['Period'][0]
        self.temp = now['Rep'][0]['F']  # F = Feels like

        min_temp = int(self.temp)
        max_temp = min_temp
        for rep in now['Rep']:
            F = int(rep['F'])
            max_temp = F if F > max_temp else max_temp
            min_temp = F if F < min_temp else min_temp

        self.max_temp = str(max_temp)
        self.min_temp = str(min_temp)
        W = now['Rep'][0]['W']
        self.weather = weather_types[W][0]
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

    def draw(self, filename):
        """render weather to image"""
        big_font = ImageFont.truetype(FredokaOne, 30)
        font = ImageFont.truetype(FredokaOne, 20)
        mini_font = ImageFont.truetype(FredokaOne, 16)
        W, H = 212, 104
        white = (255, 255, 255)
        red = (255, 0, 0)
        img = Image.new("RGB", (W, H))
        draw = ImageDraw.Draw(img)
        draw.arc(
                [W * 0.8, H/2 - W/2, W * 0.8 + W, H/2 + W/2],
                0, 360, fill=red)
        if self.error:
            draw.text((10, 10), "couldn't get forecast")
            img.save(filename)
            return
        offy = 10
        draw.text((10, offy), self.date_txt, font=mini_font, fill=white)
        w, h = mini_font.getsize(self.date_txt)
        offy += h + 5
        draw.text((10, offy), self.weather, font=font, fill=white)
        w, h = font.getsize(self.weather)
        offy += h + 5
        temp_str = "{}°".format(self.temp)
        draw.text((10, offy), temp_str, font=big_font, fill=white)
        w, h = big_font.getsize(temp_str)
        mxw, mxh = mini_font.getsize(self.max_temp)
        mnw, mnh = mini_font.getsize(self.min_temp)
        draw.text((10 + w + 10, offy - 2), self.max_temp,
                  font=mini_font, fill=white)
        draw.text((10 + w + 10 + mxw / 2 - mnw / 2, offy + h - mnh + 3),
                  self.min_temp, font=mini_font, fill=white)
        img.save(filename)


def main():
    weather = Weather()
    weather.fetch()
    weather.draw("weather.png")


if __name__ == "__main__":
    main()
