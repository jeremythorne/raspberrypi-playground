import SDL


class App {
    var renderer:Renderer? = nil
    func run() {
        do {

            let sdl = try SDL()
            let window = try sdl.createWindow(width: 640, height: 480)
            self.renderer = try window.createRenderer()

            var shouldQuit:Bool = false

            while !shouldQuit {
                var event = SDL_Event()
                while sdl.pollEvent(event:&event) {
                    let type = SDL_EventType(event.type)
                    shouldQuit = type == SDL_QUIT
                }

                update()
                render()
            }
        } catch SDLError.error(let message) {
            print ("error:", message)
        } 
        catch {
            print("unknown error")
        }
    }

    func update() {
    }

    func render() {
        self.renderer!.clear()
        self.renderer!.flip()
    }
}
