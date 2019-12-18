import pygame
import random

WIDTH=800
HEIGHT=300

class Mountain():
    def __init__(self, colour, height_range, velocity):
        self.v = velocity
        self.surface = pygame.Surface((WIDTH, HEIGHT), flags=pygame.SRCALPHA)
        points = [(i * 40, HEIGHT - random.randrange(*height_range)) for i in range(0, 1 + WIDTH // 40)]
        points [-1] = (points[-1][0], points[0][1])
        pa = pygame.PixelArray(self.surface)
        for i in range(0, len(points)):
            a = points[i]
            b = points[(i + 1) % len(points)]
            if b[1] < a[1]:
                c = (colour[0] * 7 // 8, colour[1] * 7 //8, colour[2] * 7 // 8)
            else:
                c = colour
            for x in range(a[0], a[0] + 40):
                if x < WIDTH:
                    y = int(a[1] + (b[1] - a[1]) * ((x - a[0]) / 40.0))
                    pa[x,y:-1] = c
        self.x = 0

    def update(self):
        self.x -= self.v
        if self.x < -WIDTH:
            self.x += WIDTH

    def draw(self):
        screen.blit(self.surface, (self.x, 0))
        screen.blit(self.surface, (self.x + WIDTH, 0))

class Ball():

    def __init__(self):
        self.xv =1
        self.yv =1
        self.x = WIDTH / 2
        self.y = HEIGHT / 2

    def update(self):
        self.x += self.xv
        self.y += self.yv
        if self.x > WIDTH:
            self.x = WIDTH
            self.xv = -self.xv
        elif self.x < 0:
            self.x = 0
            self.xv = -self.xv

        if self.y > HEIGHT:
            self.y = HEIGHT
            self.yv = -self.yv
        elif self.y < 0:
            self.y = 0
            self.yv = -self.yv

    def draw(self):
        screen.draw.circle((self.x, self.y), 30, 'white')

def update():
    for b in back:
        b.update()
    ball.update()

f = 0
def draw():
    global f
    if f == 0:
        print(back[0].surface)
        print(screen.surface)
    screen.clear()
    screen.fill((100, 0, 0))
    for b in back:
        b.draw()
    ball.draw()
    f += 1

ball = Ball()
back = [Mountain((100, 100, 100), (HEIGHT // 2, HEIGHT * 2 // 3), 1),
        Mountain((160, 160, 160), (HEIGHT // 3, HEIGHT // 2), 2)]
