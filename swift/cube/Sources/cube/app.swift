// borrows ideas from
// www.swiftgl.org - OpenGL tutorial in Swift
// www.glfw.org - cross platform GL window toolkit
// github.com/sakrist/Swift_OpenGL_Example - iOS, Linux, Android OpenGL is Swift 
// pygame-zero.readthedocs.io - simple python game framework
// gist.github.com/niw/5963798 - libpng code
// https://www.songho.ca/opengl/gl_projectionmatrix.html
// https://gamedev.stackexchange.com/questions/17171/for-voxel-rendering-what-is-more-efficient-pre-made-vbo-or-a-geometry-shader
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

func key_callback(window: Optional<OpaquePointer>,
                  key: Int32, scancode: Int32,
                  action: Int32, mods: Int32)
{
     if key == GLFW_KEY_ESCAPE && action == GLFW_PRESS {
        glfwSetWindowShouldClose(window, GLFW_TRUE)
     }
}

var cube: [[[GLbyte]]] = [
     [
     [1, 1, 1,  0, 0], 
     [1, 0, 1,  0, 1], 
     [0, 1, 1,  1, 0], 
     [0, 0, 1,  1, 1]
     ], 

     [
     [0, 1, 0,  2, 0], 
     [0, 0, 0,  2, 1],
     [0, 1, 1,  1, 0], 
     [0, 0, 1,  1, 1], 
     ], 

     [
     [0, 1, 0,   2, 0], 
     [0, 0, 0,   2, 1], 
     [1, 1, 0,   3, 0], 
     [1, 0, 0,   3, 1]
     ], 

     [
     [1, 1, 1,  4, 0], 
     [1, 0, 1,  4, 1],
     [1, 1, 0,  3, 0], 
     [1, 0, 0,  3, 1], 
     ], 

     [
     [0, 0, 1,  5, 1], 
     [0, 0, 0,  5, 0], 
     [1, 0, 1,  1, 1],
     [1, 0, 0,  1, 0], 
     ], 

     [
     [0, 1, 0,  4, 1], 
     [0, 1, 1,  4, 0], 
     [1, 1, 0,  5, 1], 
     [1, 1, 1,  5, 0],
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
+ "void main()\n"
+ "{\n"
+ "  gl_Position = mvp * vec4(pos, 1.0);\n"
+ "  vtex_coord = tex_coord / vec2(6.0, 1.0);\n"
+ "  vsky = dot(normal, vec3(0.8, 0.7, 1.0));\n"
+ "}\n"

var fragment_shader_text = "#version 110\n"
+ "varying vec2 vtex_coord;\n"
+ "varying float vsky;\n"
+ "uniform sampler2D image;\n"
+ "void main()\n"
+ "{\n"
+ "  vec4 tex = texture2D(image, vtex_coord);\n"
+ "  gl_FragColor = vec4(vsky * tex.xyz, tex.w);\n"
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

class App {

    var width:Float = 0.0
    var height:Float = 0.0
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
        glCullFace(GLenum(GL_BACK))
        //glEnable(GLenum(GL_CULL_FACE))
        self.width = Float(iwidth)
        self.height = Float(iheight)
        glClearColor(0.8, 0.8, 1.0, 1.0)
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))


        let image = app.loadImage(filename:"images/hello.png")!
        glBindTexture(GLenum(GL_TEXTURE_2D), image.texture)
        
        game_o?.setup()

        for i in 0..<6 {
            glGenBuffers(1, &vertex_buffer[i])
            print("vertex_buffer", vertex_buffer[i])
        }

        print("A GLbyte is \(MemoryLayout<GLbyte>.size) bytes") 

        vertices = [[], [], [], [], [], []]
        for z in -16..<16 {
            print(z)
            for x in -16..<16 {
                addCube(x:x, y:Int.random(in:(-4)...(-1)), z:z)
            }
        }
        uploadCubes()

        let err = glGetError()
        if err != 0 {
            print("GL error:", err)
            return false
        }
        return true
    }

    func loop()
    {
        print("go")

        func update()
        {
            game_o?.update()
        }

        var rad = 0.0
        func draw()
        {
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
            game_o?.draw()
            rad += 0.1
            drawCubes(rotate:rad, x:0, y:0, z:0)
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

    func addCube(x:Int, y:Int, z:Int)
    {
        for i in 0..<6 {
            var verts = [[GLbyte]]()
            for j in 0..<4 {
                let v = cube[i][j]
                verts.append([v[0] + GLbyte(x), v[1] + GLbyte(y), v[2] + GLbyte(z), v[3], v[4]])
            }

            for j in [0, 1, 2, 2, 1, 3] {
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
        let mvp = Mat4()
        mvp.rotatey(rad:rotate)
        mvp.translate(x - 0.5, y - 0.5, z)
        let p = Mat4()
        p.projection(right:near, aspect:Double(width / height), near:near, far:far)
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

