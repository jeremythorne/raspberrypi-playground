import CSDL

func getError() ->String {
    if let u = SDL_GetError() {
        let string = String(cString: u)
        return string
    }
    return ""
}


enum SDLError: Error {
	case error(message:String)
}

class SDL {
    init() throws {
        if SDL_Init(SDL_INIT_VIDEO) < 0 {
            throw SDLError.error(message:"couldn't init " + getError())
        }
    }

    func createWindow(width:Int, height:Int) throws -> Window {
        return try Window(width:width, height:height)
    }

    func pollEvent(event:inout Event) -> Bool {
        var sdl_event = SDL_Event()
        if SDL_PollEvent(&sdl_event) == 1 {
            event.type = SDL_EventType(sdl_event.type)
        }
    }

    deinit {
        SDL_Quit()
    }
}

class Window {
    var window:OpaquePointer?
    init(width:Int, height:Int) throws {
        self.window = SDL_CreateWindow("hello",
                                       0,//SDL_WINDOWPOS_UNDEFINED,
                                       0,//SDL_WINDOWPOS_UNDEFINED,
                                       Int32(width),
                                       Int32(height),
                                       0)
        if self.window == nil {
            throw SDLError.error(message: "couldn't create window")
        }
    }

    func createRenderer() throws -> Renderer {
        return try Renderer(window:self.window)
    }

    deinit {
        SDL_DestroyWindow(self.window)
    }
}

class Event {
    var type = SDL_FIRSTEVENT
    func isQuit() -> Bool {
        return self.type == SDL_QUIT
    }
}

class Texture {
    var width:Int = 0
    var height:Int = 0
    var texture:OpaquePointer? = nil
    deinit {
        SDL_DestroyTexture(self.texture)
    }
}

class Renderer {
    var renderer:OpaquePointer?

    init(window:OpaquePointer?) throws {
        self.renderer = SDL_CreateRenderer(window, -1, 0)
        if self.renderer == nil {
            throw SDLError.error(message: "couldn't create renderer")
        }
    }

    func clear() {
        SDL_RenderClear(self.renderer)
    }

    func flip() {
        SDL_RenderPresent(self.renderer)
    }
    
    func loadImage(filename:String) -> Texture? {
        do {
            let png = try PNG(filename:filename)
            let texture = SDL_CreateTexture(self.renderer, UInt32(SDL_PIXELFORMAT_RGBA8888),
                                            Int32(SDL_TEXTUREACCESS_STATIC),
                                            png.width,
                                            png.height)
            if texture == nil {
                print("failed to create texture")
                return nil
            }
            var rect = SDL_Rect()
            rect.x = 0
            rect.y = 0
            rect.w = Int32(png.width)
            rect.h = Int32(png.height)
            if (SDL_UpdateTexture(texture, rect, png.pixels, png.width * 4) != 0) {
                print("failed to set texture pixels")
                return nil
            }
            return Texture(width:png.width, height:png.height, texture:texture)
        } catch PNG.error.error(let message) {
            print ("error loading \(filename):", message)
            return nil
        }
    }

    deinit {
        SDL_DestroyRenderer(self.renderer)
    }
}
