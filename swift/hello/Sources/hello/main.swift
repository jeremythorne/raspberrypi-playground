let app = App()

var gx:Float = 0.0
var gy:Float = 0.0
var vx:Float = 3.0
var vy:Float = 2.0
let hs:Float = 50.0

class MyGame : Game {

    override func setup() {
        gx = app.width / 2.0
        gy = app.height / 2.0
    }

    override func update() {
        gx += vx
        gy += vy
        if gx > app.width - hs {
            gx = app.width - hs
            vx = -vx
        } else if gx < hs {
            gx = hs
            vx = -vx
        }

        if gy > app.height - hs {
            gy = app.height - hs
            vy = -vy
        } else if gy < hs {
            gy = hs
            vy = -vy
        }
    }

    override func draw() {
        app.drawRectCentered(x:gx, y:gy, w: 2.0 * hs, h: 2.0 * hs)
    }
}

print("Hello, world!")

app.run(game:MyGame())
