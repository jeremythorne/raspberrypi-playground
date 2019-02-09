#!/usr/bin/python3

import requests

app_id = open("/home/pi/openweatherkey.txt").read().strip()

#http://api.openweathermap.org/data/2.5/forecast?lat=52.24784&lon=0.16282&units=metric&APPID=6fd6805c481584b7b9a4c917fb28e0cd

lat="52.24784"
lon="0.16282"
url_base="http://api.openweathermap.org/data/2.5/"

url = "{0}forecast?lat={1}&lon={2}&units=metric&APPID={3}".format(url_base, lat, lon, app_id)

r = requests.get(url)
j = r.json()
city = j['city']['name']
now = j['list'][0]
temp = now['main']['temp']
weather = now['weather'][0]['description']
print("the weather forecast for {0} for the next three hours is {1}, temp {2} C".format(city, weather, temp))
