// borrows ideas from
// www.swiftgl.org - OpenGL tutorial in Swift
// www.glfw.org - cross platform GL window toolkit
// github.com/sakrist/Swift_OpenGL_Example - iOS, Linux, Android OpenGL is Swift 
// pygame-zero.readthedocs.io - simple python game framework
// gist.github.com/niw/5963798 - libpng code
// https://www.songho.ca/opengl/gl_projectionmatrix.html
// https://gamedev.stackexchange.com/questions/17171/for-voxel-rendering-what-is-more-efficient-pre-made-vbo-or-a-geometry-shader
// https://stackoverflow.com/questions/8142388/in-what-order-should-i-send-my-vertices-to-opengl-for-culling
// https://web.mit.edu/cesium/Public/terrain.pdf - terrain generation

#if os(OSX)
  import OpenGL
#else
  import GL
#endif
import GLFW

func error_callback(error: Int32, description: Optional<UnsafePointer<Int8>>)
{
    if let u = description {
        let string = String(cString: u)
        print(error, string)
    }
}

var keys_pressed = [Int32:Bool]()

func key_callback(window: Optional<OpaquePointer>,
                  key: Int32, scancode: Int32,
                  action: Int32, mods: Int32)
{
    if (action == GLFW_REPEAT ||
        action == GLFW_PRESS) {
        keys_pressed[key] = true
    } else {
        keys_pressed[key] = nil
    }

    if key == GLFW_KEY_ESCAPE && action == GLFW_PRESS {
        glfwSetWindowShouldClose(window, GLFW_TRUE)
    }
}

class Game {
    func setup () {
    }

    func update () {
    }

    func draw () {
    }
}

enum State {
    case demo
    case play
}

class App {

    var width:Float = 0.0
    var height:Float = 0.0
    var world = World()
    let near = 1.0
    let far = 32.0
    var window_o:OpaquePointer?
    var game_o:Game? = nil
    var state = State.demo
    var px:Double = 0
    var py:Double = 0
    var pz:Double = 0
    var pa:Double = 0
        
    deinit
    {
        if let window = window_o {
            glfwDestroyWindow(window)
        }
        glfwTerminate()
    }

    func run(game:Game)
    {
        game_o = game
        if !setup() {
            return
        }

        loop()
    }

    func setup() -> Bool
    {
        glfwSetErrorCallback(error_callback)

        if 0 == glfwInit() {
            print("glfwInit failed")
            return false
        }

        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0)
        glfwWindowHint(GLFW_DEPTH_BITS, 24)
        window_o = glfwCreateWindow(640, 480, "hello", nil, nil)
        guard let window = window_o else {
            print("failed to create window")
            return false
        }

        print("window pointer:", window)

        glfwSetKeyCallback(window, key_callback)

        glfwMakeContextCurrent(window)

        if let vendor = glGetString(GLenum(GL_VENDOR)) {
            print("GL vendor:", String(cString: vendor))
        }
        if let version = glGetString(GLenum(GL_VERSION)) {
            print("GL version:", String(cString: version))
        }

        var depth_bits:GLint = 0
        glGetIntegerv(GLenum(GL_DEPTH_BITS), &depth_bits)
        print("depth bits:", depth_bits)

        glfwSwapInterval(1)

        var iwidth: Int32 = 0
        var iheight: Int32 = 0
        glfwGetFramebufferSize(window, &iwidth, &iheight)
        glViewport(0, 0, iwidth, iheight)
        glEnable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_CULL_FACE))
        self.width = Float(iwidth)
        self.height = Float(iheight)
        glClearColor(0.8, 0.8, 1.0, 1.0)
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))

        if !world.setup() {
            return false
        }

        game_o?.setup()

        let err = glGetError()
        if err != 0 {
            print("GL error:", err)
            return false
        }
        return true
    }

    func update()
    {
        game_o?.update()

        switch state {
        case .demo:
            pa += 0.01
            px = Double(world.worldWidth) / 2 + 40 * cos(pa)
            pz = Double(world.worldDepth) / 2 + 40 * sin(pa)
            py = Double(world.worldHeight)
            if keys_pressed[GLFW_KEY_SPACE] ?? false {
                state = .play
                px = Double(world.worldWidth) / 2
                pz = Double(world.worldDepth) / 2

            }
        case .play:
            if keys_pressed[GLFW_KEY_LEFT]  ?? false {
                pa -= 0.01
            } else if keys_pressed[GLFW_KEY_RIGHT]  ?? false {
                pa += 0.01
            }
            if keys_pressed[GLFW_KEY_UP]  ?? false {
                px -= 0.1 * cos(pa)
                pz -= 0.1 * sin(pa)
            } else if keys_pressed[GLFW_KEY_DOWN]  ?? false {
                px += 0.1 * cos(pa)
                pz += 0.1 * sin(pa)
            }
            px = (min(Double(world.worldWidth), max(0, px)))
            pz = (min(Double(world.worldDepth), max(0, pz)))
            py = Double(world.map[Int(px)][Int(pz)]) + 2.5
        }
    }

    func draw()
    {
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        game_o?.draw()

        let m1 = Mat4()
        m1.translate(-px, -py, -pz)
        let m2 = Mat4()
        m2.rotatey(rad:pa)
        m1.mult(m2)
        let p = Mat4()
        p.projection(right:0.2, aspect:Double(width / height), near:near, far:far)
        let vp = Mat4()
        vp.mult(m1)
        vp.mult(p)

        world.draw(vp:vp)
    }

    func loop()
    {
        print("go")

        guard let window = window_o else {
            return
        }

        print("starting loop")
        while glfwWindowShouldClose(window) == 0 {
            update()
        
            draw()
            
            let err = glGetError()
            if err != 0 {
                print("GL error:", err)
            }

            glfwSwapBuffers(window)
            glfwPollEvents()
        }
        print("finished loop")
    }
}

