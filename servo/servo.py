import time, math
import wiringpi as wi

wi.wiringPiSetupGpio()
wi.pinMode(18, wi.GPIO.PWM_OUTPUT)
wi.pwmSetMode(wi.GPIO.PWM_MODE_MS)
wi.pwmSetClock(192)
wi.pwmSetRange(2000)

d = 0.005
x = 0
while True:
    #61 - 275 seems safe
    l = 61
    h = 275
    m = (h+l)/2
    w = (h - l)/2
    pulse = int(m + w*math.sin(x*3.141/180.0))
    print x, pulse
    wi.pwmWrite(18, pulse)
    time.sleep(d)
    x += 1
