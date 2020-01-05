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
    let width:Float = 640.0
    let height:Float = 480.0
    var renderer:Renderer? = nil
    func run(game:Game) {
        do {

            let sdl = try SDL()
            let window = try sdl.createWindow(width: Int(self.width), height: Int(self.height))
            self.renderer = try window.createRenderer()

            var shouldQuit:Bool = false

            setup(game)

            while !shouldQuit {
                while let event = sdl.pollEvent() {
                    switch event {
                    case .quit:
                        shouldQuit = true
                    default:
                        continue
                    }
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
}
