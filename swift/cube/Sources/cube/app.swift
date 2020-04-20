// borrows ideas from
// www.swiftgl.org - OpenGL tutorial in Swift
// www.glfw.org - cross platform GL window toolkit
// github.com/sakrist/Swift_OpenGL_Example - iOS, Linux, Android OpenGL is Swift 
// pygame-zero.readthedocs.io - simple python game framework
// gist.github.com/niw/5963798 - libpng code
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

var vertices: [GLfloat] = [
     0.0, 1.0, 1.0,  0.0, 0.0, 
     0.0, 0.0, 1.0,  0.0, 1.0, 
     1.0, 1.0, 1.0,  1.0, 0.0, 
     1.0, 0.0, 1.0,  1.0, 1.0, 
]

var vertex_shader_text = "#version 110\n"
+ "attribute vec3 pos;\n"
+ "attribute vec2 tex_coord;\n"
+ "uniform mat4 mvp;\n"
+ "varying vec2 vtex_coord;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_Position = mvp * vec4(pos, 1.0);\n"
+ "  vtex_coord = tex_coord;\n"
+ "}\n"

var fragment_shader_text = "#version 110\n"
+ "varying vec2 vtex_coord;\n"
+ "uniform sampler2D image;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_FragColor = texture2D(image, vtex_coord);\n"
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

class App {

    var width:Float = 0.0
    var height:Float = 0.0
    var program:GLuint = 0
    var mvp_location:GLint = 0 

    func run(game:Game)
    {

        glfwSetErrorCallback(error_callback)

        if 0 == glfwInit() {
            print("glfwInit failed")
            return
        }

        defer {
           glfwTerminate()
        }

        guard let window = glfwCreateWindow(640, 480, "hello", nil, nil) else {
            print("failed to create window")
            return
        }

        defer {
            glfwDestroyWindow(window)
        }

        print("window pointer:", window)

        glfwSetKeyCallback(window, key_callback)

        glfwMakeContextCurrent(window)
        if let vendor = glGetString(GLenum(GL_VENDOR)) {
            print("GL vendor:", String(cString: vendor))
        }

        glfwSwapInterval(1)

        var vertex_buffer: GLuint = 0
        glGenBuffers(1, &vertex_buffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertex_buffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * Int(vertices.count)),
                                               vertices, GLenum(GL_STATIC_DRAW))



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

        guard let vertex_shader = 
            compileShader(text: vertex_shader_text,
                          shader_type:GLenum(GL_VERTEX_SHADER)) else {
                return
        }

        guard let fragment_shader = 
            compileShader(text: fragment_shader_text,
                          shader_type:GLenum(GL_FRAGMENT_SHADER)) else {
                return
        }

        self.program = glCreateProgram()
        glAttachShader(self.program, vertex_shader)
        glAttachShader(self.program, fragment_shader)
        glLinkProgram(self.program)
        var link_status:GLint = 0
        glGetProgramiv(self.program, GLenum(GL_LINK_STATUS), &link_status)
        if link_status != GLboolean(GL_TRUE) {
            print("failed to link GL program")
            return
        }

        let pos_location = GLint(glGetAttribLocation(self.program, "pos"))
        let tex_coord_location = GLint(glGetAttribLocation(self.program, "tex_coord"))
        self.mvp_location = GLint(glGetUniformLocation(self.program, "mvp")) 

        print("program attribute locations", pos_location,tex_coord_location)

        glEnableVertexAttribArray(GLuint(pos_location))
        glVertexAttribPointer(GLuint(pos_location), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                                GLsizei(MemoryLayout<GLfloat>.size) * 5,
                                           UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(tex_coord_location))
        glVertexAttribPointer(GLuint(tex_coord_location), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                                GLsizei(MemoryLayout<GLfloat>.size) * 5,
                                           UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        
        var iwidth: Int32 = 0
        var iheight: Int32 = 0
        glfwGetFramebufferSize(window, &iwidth, &iheight)
        glViewport(0, 0, iwidth, iheight)
        self.width = Float(iwidth)
        self.height = Float(iheight)
        glClearColor(1.0, 1.0, 0.0, 1.0)
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))

        print("GL error:", glGetError())

        game.setup()

        func update() {
            game.update()
        }

        func draw() {
            game.draw()
        }

        print("starting loop")

        while glfwWindowShouldClose(window) == 0 {
            update()
        
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
            draw()

            glfwSwapBuffers(window)
            glfwPollEvents()
        }
        print("finished loop")
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

        //var bytes: [UInt8] = [
        //       0, 0, 0, 0xff,  0xff, 0xff, 0xff, 0xff,
        //    0xff, 0, 0, 0xff,     0, 0xff,    0, 0xff
        //]
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA,
                     Int32(width), Int32(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE),
                     &bytes)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        return texture
    }

    func loadImage(filename:String) -> Image? {
        guard let png = try? PNG(filename:filename) else {
            return nil
        }
        var image = Image()
        image.width = png.width
        image.height = png.height
        image.texture = loadTexture(width:image.width, height:image.height, bytes:&png.bytes)
        return image
    }

    func drawImageCentered(x:Float, y:Float, image:Image) {
        let w = Float(image.width)
        let h = Float(image.height)
        var mvp: [GLfloat] = [
            w * 2.0 / width, 0.0, 0.0, x / width,
            0.0, h * 2.0 / height, 0.0, y / height,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        ]
        glUseProgram(self.program)
        glUniformMatrix4fv(self.mvp_location, 1, GLboolean(GL_TRUE), &mvp)
        glBindTexture(GLenum(GL_TEXTURE_2D), image.texture)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }
}

