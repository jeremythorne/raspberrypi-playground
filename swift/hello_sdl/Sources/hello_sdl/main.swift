let app = App()

var image = Image()

class Ball {
    var gx:Float = 0.0
    var gy:Float = 0.0
    var vx:Float = Float.random(in: -3.0...3.0)
    var vy:Float = Float.random(in: -3.0...3.0)
    var hx:Float = 0.0
    var hy:Float = 0.0

    func setup() {
        self.gx = app.width / 2.0
        self.gy = app.height / 2.0
        self.hx = Float(image.width) / 2.0
        self.hy = Float(image.height) / 2.0
    }

    func update() {
        self.gx += self.vx
        self.gy += self.vy
        if self.gx > app.width - self.hx {
            self.gx = app.width - self.hx
            self.vx = -self.vx
        } else if self.gx < self.hx {
            self.gx = self.hx
            self.vx = -self.vx
        }

        if self.gy > app.height - self.hy {
            self.gy = app.height - self.hy
            self.vy = -self.vy
        } else if self.gy < self.hy {
            self.gy = self.hy
            self.vy = -self.vy
        }
    }

    func draw() {
        app.drawImageCentered(x:self.gx, y:self.gy, image:image)
    }
}

var balls = [Ball]()
for _ in 1...10 {
    balls.append(Ball())
}

class MyGame : Game {

    override func setup() {
        image = app.loadImage(filename:"images/hello.png")!
        for ball in balls {
            ball.setup()
        }
    }

    override func update() {
        for ball in balls {
            ball.update()
        }
    }

    override func draw() {
        for ball in balls {
            ball.draw()
        }
    }
}

print("Hello, world!")

app.run(game:MyGame())
