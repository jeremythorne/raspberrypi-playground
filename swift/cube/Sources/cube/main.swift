let app = App()

var image = Image()

class Ball {
    var gx:Float = 0.0
    var gy:Float = -2.0
    var gz:Float = 0
    var vy:Float = Float.random(in: -0.05...0.05)

    func setup() {
    }

    func update() {
        gy += vy
        if gy > -1.0 || gy < -3.0 {
            vy = -vy
        }
    }

    func draw() {
        app.drawImageCentered(x:gx, y:gy, z:gz, image:image)
    }
}

var balls = [Ball]()
for z in 0..<16 {
    for x in -8..<8 {
        let b = Ball()
        b.gx = Float(x)
        b.gz = Float(-16 + z)
        balls.append(b)
    }
}

class MyGame : Game {

    override func setup() {
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
