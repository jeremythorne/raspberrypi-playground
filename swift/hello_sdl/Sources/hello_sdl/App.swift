import SDL

class Game {
    func setup () {
    }

    func update () {
    }

    func draw () {
    }
}

class Image {
    var width:Int = 0
    var height:Int = 0
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

            while !shouldQuit {
                var event = SDL_Event()
                while sdl.pollEvent(event:&event) {
                    let type = SDL_EventType(event.type)
                    shouldQuit = type == SDL_QUIT
                }

                update(game:game)
                draw(game:game)
            }
        } catch SDLError.error(let message) {
            print ("error:", message)
        } 
        catch {
            print("unknown error")
        }
    }

    func update(game:Game) {
        game.update()
    }

    func draw(game:Game) {
        self.renderer!.clear()
        game.draw()
        self.renderer!.flip()
    }
    
    func loadImage(filename:String) -> Image? {
        return nil
    }
    
    func drawImageCentered(x:Float, y:Float, image:Image) {
    }
}
