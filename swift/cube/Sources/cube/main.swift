let app = App()

var image = Image()

class Ball {
    var gx:Float = 0.0
    var gy:Float = 0.0
    var gz:Float = -2.5
    var vx:Float = Float.random(in: -0.1...0.1)
    var vy:Float = Float.random(in: -0.1...0.1)
    var vz:Float = Float.random(in: -0.1...0.1)

    func setup() {
    }

    func update() {
        gx += vx
        gy += vy
        gz += vz
        if gx > 1.0 || gx < -1.0 {
            vx = -vx
        }
        if gy > 1.0 || gy < -1.0 {
            vy = -vy
        }
        if gz > -1.0 || gz < -5.0 {
            vz = -vz
        } 

    }

    func draw() {
        app.drawImageCentered(x:gx, y:gy, z:gz, image:image)
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
