let app = App()

class Ball {
    var gx:Float = 0.0
    var gy:Float = 0.0
    var vx:Float = Float.random(in: -3.0...3.0)
    var vy:Float = Float.random(in: -3.0...3.0)
    let hx:Float
    let hy:Float
    let image:Image

    init (image:Image) {
        self.image = image
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
        app.drawImageCentered(x:self.gx, y:self.gy, image:self.image)
    }
}

var balls = [Ball]()
class MyGame : Game {

    override func setup() {
        let image = app.loadImage(filename:"images/hello.png")!
        for _ in 1...10 {
            balls.append(Ball(image:image))
        }
    }

    override func update() {
        if app.pressed(KeyCode.left) {
            print("left pressed")
        } else if app.pressed(KeyCode.right) {
            print("right pressed")
        }

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

app.run(width:640, height:480, game:MyGame())
