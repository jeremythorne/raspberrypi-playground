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

var cube: [[[GLbyte]]] = [
     [ // front
     [0, 0, 1,  1, 1],
     [1, 0, 1,  0, 1], 
     [1, 1, 1,  0, 0], 
     [0, 1, 1,  1, 0], 
     ], 

     [ //left
     [0, 0, 0,  2, 1],
     [0, 0, 1,  1, 1], 
     [0, 1, 1,  1, 0], 
     [0, 1, 0,  2, 0], 
     ], 

     [ // back
     [1, 0, 0,   3, 1],
     [0, 0, 0,   2, 1], 
     [0, 1, 0,   2, 0], 
     [1, 1, 0,   3, 0], 
     ], 

     [ //right
     [1, 0, 1,  4, 1],
     [1, 0, 0,  3, 1], 
     [1, 1, 0,  3, 0], 
     [1, 1, 1,  4, 0], 
     ], 

     [ // bottom
     [0, 0, 0,  5, 0], 
     [1, 0, 0,  6, 0], 
     [1, 0, 1,  6, 1],
     [0, 0, 1,  5, 1], 
     ], 

     [ //top
     [0, 1, 1,  4, 0], 
     [1, 1, 1,  5, 0],
     [1, 1, 0,  5, 1], 
     [0, 1, 0,  4, 1], 
     ]
]

var normals: [[GLfloat]] = [
     [ 0,  0,  1], 
     [-1,  0,  0], 
     [ 0,  0, -1], 
     [ 1,  0,  0], 
     [0,  -1,  0], 
     [0,   1,  0], 
]

var vertex_shader_text = "#version 110\n"
+ "attribute vec3 pos;\n"
+ "attribute vec2 tex_coord;\n"
+ "uniform vec3 normal;\n"
+ "uniform mat4 mvp;\n"
+ "varying vec2 vtex_coord;\n"
+ "varying float vsky;\n"
+ "varying float v;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_Position = mvp * vec4(pos, 1.0);\n"
+ "  vec4 p = mvp * vec4(pos, 1.0);\n"
+ "  v = p.y / p.w;\n"
+ "  vtex_coord = tex_coord / vec2(6.0, 3.0);\n"
+ "  vsky = max(0.0, dot(normal, vec3(0.8, 0.7, 1.0)));\n"
+ "}\n"

var fragment_shader_text = "#version 110\n"
+ "varying vec2 vtex_coord;\n"
+ "varying float vsky;\n"
+ "varying float v;\n"
+ "uniform sampler2D image;\n"
+ "void main()\n"
+ "{\n"
+ "  vec4 tex = texture2D(image, vtex_coord);\n"
+ "  vec3 ambient = vec3(0.2, 0.2, 0.2);\n"
+ "  gl_FragColor = vec4(vec3(1.0 + v), 0.0) + vec4((ambient + vsky) * tex.xyz, tex.w);\n"
+ "}\n"

class Game {
    func setup () {
    }

    func update () {
    }

    func draw () {
    }
}

struct Image {
    var width:Int = 0
    var height:Int = 0
    var texture:GLuint = 0
}

class Mat4 {
    var a = [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0 ]

    func mult(_ b:Mat4) {
        let c = [
            a[0] * b.a[0] + a[1] * b.a[4] + a[2] * b.a[8] + a[3] * b.a[12],
            a[0] * b.a[1] + a[1] * b.a[5] + a[2] * b.a[9] + a[3] * b.a[13],
            a[0] * b.a[2] + a[1] * b.a[6] + a[2] * b.a[10] + a[3] * b.a[14],
            a[0] * b.a[3] + a[1] * b.a[7] + a[2] * b.a[11] + a[3] * b.a[15],

            a[4] * b.a[0] + a[5] * b.a[4] + a[6] * b.a[8] +  a[7] * b.a[12],
            a[4] * b.a[1] + a[5] * b.a[5] + a[6] * b.a[9] +  a[7] * b.a[13],
            a[4] * b.a[2] + a[5] * b.a[6] + a[6] * b.a[10] + a[7] * b.a[14],
            a[4] * b.a[3] + a[5] * b.a[7] + a[6] * b.a[11] + a[7] * b.a[15],

            a[8] * b.a[0] + a[9] * b.a[4] + a[10] * b.a[8] +  a[11] * b.a[12],
            a[8] * b.a[1] + a[9] * b.a[5] + a[10] * b.a[9] +  a[11] * b.a[13],
            a[8] * b.a[2] + a[9] * b.a[6] + a[10] * b.a[10] + a[11] * b.a[14],
            a[8] * b.a[3] + a[9] * b.a[7] + a[10] * b.a[11] + a[11] * b.a[15],

            a[12] * b.a[0] + a[13] * b.a[4] + a[14] * b.a[8] +  a[15] * b.a[12],
            a[12] * b.a[1] + a[13] * b.a[5] + a[14] * b.a[9] +  a[15] * b.a[13],
            a[12] * b.a[2] + a[13] * b.a[6] + a[14] * b.a[10] + a[15] * b.a[14],
            a[12] * b.a[3] + a[13] * b.a[7] + a[14] * b.a[11] + a[15] * b.a[15],
        ]
        a = c
    }

    func projection(right:Double, aspect:Double, near:Double, far:Double) {
        for i in 0..<16 {
            a[i] = 0
        }
        let top = right / aspect
        a[0] = near / right
        a[5] = near / top
        a[10] = -(far + near) / (far - near)
        a[11] = -2 * far * near / (far - near)
        a[14] = -1
    }

    func translate(_ x:Double, _ y:Double, _ z:Double) {
        a[12] = x
        a[13] = y
        a[14] = z
    }

    func rotatey(rad:Double) {
        a[0] = sin(rad)
        a[2] = cos(rad)
        a[8] = -cos(rad)
        a[10] = sin(rad)
    }

    func toGL() -> [GLfloat] {
        let glf:[GLfloat] = [
            GLfloat(a[0]),  GLfloat(a[1]),  GLfloat(a[2]),  GLfloat(a[3]),
            GLfloat(a[4]),  GLfloat(a[5]),  GLfloat(a[6]),  GLfloat(a[7]),
            GLfloat(a[8]),  GLfloat(a[9]),  GLfloat(a[10]), GLfloat(a[11]),
            GLfloat(a[12]), GLfloat(a[13]), GLfloat(a[14]), GLfloat(a[15])
        ]
        return glf
    }
}

enum State {
    case demo
    case play
}

class App {

    var width:Float = 0.0
    var height:Float = 0.0
    let worldWidth = 64
    let worldHeight = 16
    let worldDepth = 64
    let near = 1.0
    let far = 32.0
    var program:GLuint = 0
    var pos_location:GLint = 0
    var normal_location:GLint = 0 
    var tex_coord_location:GLint = 0
    var mvp_location:GLint = 0 
    var vertex_buffer: [GLuint] = [0, 0, 0, 0, 0, 0]
    var vertices:[[GLbyte]] = [[], [], [], [], [], []]
    var window_o:OpaquePointer?
    var game_o:Game? = nil
    var map = [[Int]]()
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

        guard let vertex_shader = 
            compileShader(text: vertex_shader_text,
                          shader_type:GLenum(GL_VERTEX_SHADER)) else {
                return false
        }

        guard let fragment_shader = 
            compileShader(text: fragment_shader_text,
                          shader_type:GLenum(GL_FRAGMENT_SHADER)) else {
                return false
        }

        program = glCreateProgram()
        glAttachShader(program, vertex_shader)
        glAttachShader(program, fragment_shader)
        glLinkProgram(program)
        var link_status:GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &link_status)
        if link_status != GLboolean(GL_TRUE) {
            print("failed to link GL program")
            return false
        }

        pos_location = GLint(glGetAttribLocation(program, "pos"))
        tex_coord_location = GLint(glGetAttribLocation(program, "tex_coord"))
        normal_location = GLint(glGetUniformLocation(program, "normal"))
        mvp_location = GLint(glGetUniformLocation(program, "mvp")) 

        print("program attribute locations", pos_location,tex_coord_location)

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


        let image = app.loadImage(filename:"images/hello.png")!
        glBindTexture(GLenum(GL_TEXTURE_2D), image.texture)
        
        makeWorld(width:worldWidth, depth:worldDepth, height:worldHeight)

        game_o?.setup()

        let err = glGetError()
        if err != 0 {
            print("GL error:", err)
            return false
        }
        return true
    }

    func heightMap(width:Int, depth:Int, height:Int) -> [[Int]]
    {
        func is_power_of_two(_ a:Int) -> Bool
        {
            return a > 0 && (a & (a - 1)) == 0
        }

        assert(is_power_of_two(width - 1))
        assert(width == depth)
        // this algorithm only works if width and depth are 2^n + 1
        var h = [[Int]](repeating:[Int](repeating:0, count: depth), count: width)
        func diamondSquare(s:Int, n:Int)
        {
            let m = s / 2
            let n2 = n / 2
            for x in stride(from: 0, to: width - s, by: s) {
                for y in stride(from: 0, to: depth - s, by: s) {
                    h[x + m][y + m] = max(1, min(height, (h[x][x] + 
                                                          h[x + s][y + s] +
                                                          h[x + s][y] +
                                                          h[x][y + s]) / 4 + Int.random(in:-n2...n2)))
                    h[x + m][y] = max(1, min(height, (h[x][y] + h[x + s][y]) / 2 + Int.random(in:-n2...n2)))
                    h[x + m][y + s] = max(1, min(height, (h[x][y + s] + h[x + s][y + s]) / 2 + Int.random(in:-n2...n2))) 
                    h[x][y + m] = max(1, min(height, (h[x][y] + h[x][y + s]) / 2 + Int.random(in:-n2...n2)))
                    h[x + s][y + m] = max(1, min(height, (h[x + s][y] + h[x + s][y + s]) / 2 + Int.random(in:-n2...n2)))
            
                }
            }
        }

        var n = height
        h[0][0] = Int.random(in:1...n) 
        h[0][depth - 1] = Int.random(in:1...n) 
        h[width - 1][0] = Int.random(in:1...n) 
        h[width - 1][depth - 1] = Int.random(in:1...n)
        var s = width - 1
        while s > 1 {
            n /= 2
            diamondSquare(s:s, n:n)
            s /= 2
        }
        return h
    }

    func makeWorld(width:Int, depth:Int, height:Int)
    {
        
        var world = [[[Int]]](repeating:[[Int]](repeating:[Int](repeating:0, count: height), count:width), count:depth)

        map = heightMap(width:width + 1, depth:depth + 1, height:height)

        for z in 0..<depth {
            for x in 0..<width {
                var h = map[x][z]
                if h < 6 {
                    h = 6
                    map[x][z] = 6
                }
                for y in 0..<height {
                    let t:Int
                    switch y {
                    case 0..<h:
                        t = 2
                    case h:
                        if h <= 6 {
                            t = 3
                        }else {
                            t = 1
                        }
                    default:
                        t = 0
                    }
                    world[z][x][y] = t
                }
            }
        }

        func occluded(_ x:Int, _ y:Int, _ z:Int) -> Bool {
            if x == 0 || x == (width - 1) || z == 0 || z == (depth - 1) || y == 0 || y == (height - 1) ||
                   world[z - 1][x][y] == 0 ||
                   world[z + 1][x][y] == 0 ||
                   world[z][x - 1][y] == 0 ||
                   world[z][x + 1][y] == 0 ||
                   world[z][x][y - 1] == 0 ||
                   world[z][x][y + 1] == 0 {
                       // not completely occluded
                       return false
            }
            return true
        }

        vertices = [[], [], [], [], [], []]
        var count = 0
        for z in 0..<depth {
            for x in 0..<width {
                for y in 0..<height {
                    if world[z][x][y] != 0 && !occluded(x, y, z) {
                        addCube(x:x, y:y, z:z, type:world[z][x][y])
                        count += 1
                    }
                }
            }
        }
        print("\(count) visible cubes")

        for i in 0..<6 {
            glGenBuffers(1, &vertex_buffer[i])
            print("vertex_buffer", vertex_buffer[i])
        }

        uploadCubes()
    }

    func loop()
    {
        print("go")

        func update()
        {
            game_o?.update()

            switch state {
            case .demo:
                pa += 0.01
                px = Double(worldWidth) / 2 + 40 * cos(pa)
                pz = Double(worldDepth) / 2 + 40 * sin(pa)
                py = Double(worldHeight)
                if keys_pressed[GLFW_KEY_SPACE] ?? false {
                    state = .play
                    px = Double(worldWidth) / 2
                    pz = Double(worldDepth) / 2

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
                px = (min(Double(worldWidth), max(0, px)))
                pz = (min(Double(worldDepth), max(0, pz)))
                py = Double(map[Int(px)][Int(pz)]) + 2.5
            }
        }

        func draw()
        {
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
            game_o?.draw()

            
            drawCubes(rotate:pa, x:px, y:py, z:pz)
        }

        print("starting loop")

        guard let window = window_o else {
            return
        }

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

    func compileShader(text:String, shader_type:GLenum) -> GLuint? {
        let shader = glCreateShader(shader_type)
        text.withCString {cs in
            var cs_opt = Optional(cs)
            glShaderSource(shader, 1, &cs_opt, nil)
        }
        glCompileShader(shader)
        var compile_status:GLint = 0
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compile_status)
        if compile_status != GLboolean(GL_TRUE) {
            print("shader compile failed")
            var buffer = [Int8]()
            buffer.reserveCapacity(256)
            var length: GLsizei = 0
            glGetShaderInfoLog(shader, 256, &length, &buffer)
            print(String(cString: buffer))
            return nil
        }
        return shader
    }

    func loadTexture(width:Int, height:Int, bytes: inout [UInt8]) -> GLuint {
        print("loading texture")
        var texture:GLuint = 0
        glGenTextures(1, &texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)

        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA,
                     Int32(width), Int32(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE),
                     &bytes)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        return texture
    }

    func loadImage(filename:String) -> Image?
    {
        guard let png = try? PNG(filename:filename) else {
            return nil
        }
        var image = Image()
        image.width = png.width
        image.height = png.height
        image.texture = loadTexture(width:image.width, height:image.height, bytes:&png.bytes)
        return image
    }

    func addCube(x:Int, y:Int, z:Int, type:Int)
    {
        // vertex must fix in a byte
        assert(x >= -128 && x < 127)
        assert(y >= -128 && y < 127)
        assert(z >= -128 && z < 127)
        let tv = GLbyte(type - 1)
        for i in 0..<6 {
            var verts = [[GLbyte]]()
            for j in 0..<4 {
                let v = cube[i][j]
                verts.append([v[0] + GLbyte(x), v[1] + GLbyte(y), v[2] + GLbyte(z), v[3], v[4] + tv])
            }

            for j in [0, 1, 2, 0, 2, 3] {
                vertices[i] += verts[j]
            }
        }
    }

    func enableAttrib(loc:GLint, num:Int, off:Int, stride:Int)
    {
        glEnableVertexAttribArray(GLuint(loc))
        glVertexAttribPointer(GLuint(loc), GLint(num), GLenum(GL_BYTE), GLboolean(GL_FALSE),
                                GLsizei(MemoryLayout<GLbyte>.size * stride),
                                           UnsafeRawPointer(bitPattern: MemoryLayout<GLbyte>.size * off))
    }

    func uploadCubes()
    {
        for i in 0..<6 {
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertex_buffer[i])
            glBufferData(GLenum(GL_ARRAY_BUFFER),
                         GLsizeiptr(MemoryLayout<GLbyte>.size * Int(vertices[i].count)),
                                               vertices[i], GLenum(GL_STATIC_DRAW))
        }
    }

    func drawCubes(rotate:Double, x:Double, y:Double, z:Double)
    {
        let m1 = Mat4()
        m1.translate(-x, -y, -z)
        let m2 = Mat4()
        m2.rotatey(rad:rotate)
        m1.mult(m2)
        let p = Mat4()
        p.projection(right:0.2, aspect:Double(width / height), near:near, far:far)
        let mvp = Mat4()
        mvp.mult(m1)
        mvp.mult(p)
        glUseProgram(program)
        var glmat4 = mvp.toGL()
        glUniformMatrix4fv(mvp_location, 1, GLboolean(GL_FALSE), &glmat4)
        for i in 0..<6 {
            glUniform3fv(normal_location, 1, normals[i])
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertex_buffer[i])
            enableAttrib(loc:pos_location, num:3, off:0, stride:5)
            enableAttrib(loc:tex_coord_location, num:2, off:3, stride:5)
            
            glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(vertices[i].count))
        }
    }
}

