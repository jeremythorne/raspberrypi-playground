class Game {
    func setup () {
    }

    func update () {
    }

    func draw () {
    }
}

class Image {
    var width:Int
    var height:Int
    var texture:Texture

    init (width: Int, height: Int, texture: Texture) {
        self.width = width
        self.height = height
        self.texture = texture
    }
}

class App {
    var width:Float = 0.0
    var height:Float = 0.0
    var sdl:SDL? = nil
    var keyboard:Keyboard? = nil
    var renderer:Renderer? = nil
    var shouldQuit:Bool = false

    init() {
        do {
            self.sdl = try SDL()
            self.keyboard = Keyboard()
        } catch SDLError.error(let message) {
            print ("error:", message)
        }
        catch {
            print("unknown error")
        }
    }

    func run(width:Int, height:Int, game:Game) {
        guard let sdl = self.sdl else {
            return
        }
        self.width = Float(width)
        self.height = Float(height)
        do {
            let window = try sdl.createWindow(width: width, height: height)
            self.renderer = try window.createRenderer()

            self.shouldQuit = false

            setup(game)

            while !self.shouldQuit {
                while let event = sdl.pollEvent() {
                    switch event {
                    case .quit:
                        self.shouldQuit = true
                    default:
                        continue
                    }
                }
                if pressed(KeyCode.escape) {
                    self.shouldQuit = true
                }
                if self.shouldQuit {
                    break
                }
                update(game)
                draw(game)
            }
        } catch SDLError.error(let message) {
            print ("error:", message)
        }
        catch {
            print("unknown error")
        }
    }

    func setup(_ game:Game) {
        game.setup()
    }

    func update(_ game:Game) {
        game.update()
    }

    func draw(_ game:Game) {
        guard let renderer = self.renderer else {
            return
        }
        renderer.clear()
        game.draw()
        renderer.flip()
    }
    
    func loadImage(filename:String) -> Image? {
        guard let renderer = self.renderer else {
            print("no renderer")
            return nil
	    }
        guard let texture = renderer.loadImage(filename:filename) else {
            print("failed to load \(filename)")
            return nil
        }
        return Image(width:texture.width, height:texture.height, texture:texture)
    }
    
    func drawImageCentered(x:Float, y:Float, image:Image?) {
        guard let renderer = self.renderer else {
            return
        }
        guard let im = image else {
            return
        }
        renderer.drawCentered(x:Int(x), y:Int(y), texture:im.texture)
    }

    func pressed(_ key:KeyCode) -> Bool {
        guard let keyboard = self.keyboard else {
            return false
        }
        return keyboard.pressed(key)
    }
}
