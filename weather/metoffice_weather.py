#!/usr/bin/python3

import requests

app_id = open("/home/pi/metofficekey.txt").read().strip()

location="350107" #Anglesey Abbey
url_base="http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json/"

url = "{}{}?res=3hourly&key={}".format(url_base, location, app_id)
print(url)
r = requests.get(url)
if r.status_code != 200:
    print("error {}: {}".format(r.status_code, r.text))
j = r.json()

weather_types = {
        "NA" : "Not available",
        "0"  : "Clear night",
        "1"  : "Sunny day",
        "2"  : "Partly cloudy (night)",
        "3"  : "Partly cloudy (day)",
        "4"  : "Not used",
        "5"  : "Mist",
        "6"  : "Fog",
        "7"  : "Cloudy",
        "8"  : "Overcast",
        "9"  : "Light rain shower (night)",
        "10" : "Light rain shower (day)",
        "11" : "Drizzle",
        "12" : "Light rain",
        "13" : "Heavy rain shower (night)",
        "14" : "Heavy rain shower (day)",
        "15" : "Heavy rain",
        "16" : "Sleet shower (night)",
        "17" : "Sleet shower (day)",
        "18" : "Sleet",
        "19" : "Hail shower (night)",
        "20" : "Hail shower (day)",
        "21" : "Hail",
        "22" : "Light snow shower (night)",
        "23" : "Light snow shower (day)",
        "24" : "Light snow",
        "25" : "Heavy snow shower (night)",
        "26" : "Heavy snow shower (day)",
        "27" : "Heavy snow",
        "28" : "Thunder shower (night)",
        "29" : "Thunder shower (day)",
        "30" : "Thunder",
        }


loc = j['SiteRep']['DV']['Location']
city = loc['name']
now = loc['Period'][0]
temp = now['Rep'][0]['F'] # F = Feels like
weather = weather_types[now['Rep'][0]['W']]
date_txt = now['value']
print("the weather forecast for {} for the next three hours ({}) is {}, temp {} C".format(city, date_txt, weather, temp))
