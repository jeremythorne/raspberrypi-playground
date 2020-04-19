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
        gx = app.width / 2.0
        gy = app.height / 2.0
        hx = Float(image.width) / 2.0
        hy = Float(image.height) / 2.0
    }

    func update() {
        gx += vx
        gy += vy
        if gx > app.width - hx {
            gx = app.width - hx
            vx = -vx
        } else if gx < hx {
            gx = hx
            vx = -vx
        }

        if gy > app.height - hy {
            gy = app.height - hy
            vy = -vy
        } else if gy < hy {
            gy = hy
            vy = -vy
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
        print("image read")
        balls.forEach { $0.setup() }
    }

    override func update() {
        balls.forEach { $0.update() }
    }

    override func draw() {
        balls.forEach { $0.draw() }
    }
}

print("Hello, world!")

app.run(game:MyGame())
