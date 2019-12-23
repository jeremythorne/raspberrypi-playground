// borrows ideas from
// www.swiftgl.org - OpenGL tutorial in Swift
// www.glfw.org - cross platform GL window toolkit
// github.com/sakrist/Swift_OpenGL_Example - iOS, Linux, Android OpenGL is Swift 
// pygame-zero.readthedocs.io - simple python game framework

import GL
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
     0.0, 1.0,  1.0, 0.0, 0.0,  0.0, 1.0, 
     0.0, 0.0,  1.0, 0.0, 0.0,  0.0, 0.0, 
     1.0, 1.0,  1.0, 0.0, 0.0,  1.0, 1.0, 
     1.0, 0.0,  1.0, 0.0, 0.0,  1.0, 0.0, 
]

var vertex_shader_text = "#version 110\n"
+ "attribute vec3 col;\n"
+ "attribute vec2 pos;\n"
+ "attribute vec2 tex_coord;\n"
+ "uniform vec2 scale;\n"
+ "uniform vec2 offset;\n"
+ "varying vec3 vcolor;\n"
+ "varying vec2 vtex_coord;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_Position = vec4(pos * scale + offset, 0.0, 1.0);\n"
+ "  vcolor = col;\n"
+ "  vtex_coord = tex_coord;\n"
+ "}\n"

var fragment_shader_text = "#version 110\n"
+ "varying vec3 vcolor;\n"
+ "varying vec2 vtex_coord;\n"
+ "uniform sampler2D image;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_FragColor = vec4(vcolor, 1.0) * texture2D(image, vtex_coord);\n"
+ "}\n"

class Game {
    func setup () {
    }

    func update () {
    }

    func draw () {
    }
}

class App {

    var width:Float = 0.0
    var height:Float = 0.0
    var program:GLuint = 0
    var scale_location:GLint = 0 
    var offset_location:GLint = 0
    var texture:GLuint = 0

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

        func loadTexture() -> GLuint {
            var texture:GLuint = 0
            glGenTextures(1, &texture)
            glBindTexture(GLenum(GL_TEXTURE_2D), texture)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)

            var bytes: [UInt8] = [
                   0, 0, 0, 0xff,  0xff, 0xff, 0xff, 0xff,
                0xff, 0, 0, 0xff,     0, 0xff,    0, 0xff
            ]
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA,
                         2, 2, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE),
                         &bytes)
            glBindTexture(GLenum(GL_TEXTURE_2D), 0)
            return texture
        }

        self.texture = loadTexture()
        print ("texture", self.texture)

        func compileShader(text:String, shader_type:GLenum) -> GLuint {
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
                return 0
            }
            return shader
        }

        let vertex_shader = compileShader(text: vertex_shader_text, shader_type:GLenum(GL_VERTEX_SHADER))

        let fragment_shader = compileShader(text: fragment_shader_text, shader_type:GLenum(GL_FRAGMENT_SHADER))

        self.program = glCreateProgram()
        glAttachShader(self.program, vertex_shader)
        glAttachShader(self.program, fragment_shader)
        glLinkProgram(self.program)
        var link_status:GLint = 0
        glGetProgramiv(self.program, GLenum(GL_LINK_STATUS), &link_status)
        if link_status == GLboolean(GL_TRUE) {
            print("linked")
        }

        let pos_location = GLint(glGetAttribLocation(self.program, "pos"))
        let col_location = GLint(glGetAttribLocation(self.program, "col"))
        let tex_coord_location = GLint(glGetAttribLocation(self.program, "tex_coord"))
        self.scale_location = GLint(glGetUniformLocation(self.program, "scale")) 
        self.offset_location = GLint(glGetUniformLocation(self.program, "offset")) 

        print("program attribute locations", pos_location, col_location, tex_coord_location)

        glEnableVertexAttribArray(GLuint(pos_location))
        glVertexAttribPointer(GLuint(pos_location), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                                GLsizei(MemoryLayout<GLfloat>.size) * 7,
                                           UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(col_location))
        glVertexAttribPointer(GLuint(col_location), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                                GLsizei(MemoryLayout<GLfloat>.size) * 7,
                                           UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 2))
        glEnableVertexAttribArray(GLuint(tex_coord_location))
        glVertexAttribPointer(GLuint(tex_coord_location), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                                GLsizei(MemoryLayout<GLfloat>.size) * 7,
                                           UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 5))
        
        var iwidth: Int32 = 0
        var iheight: Int32 = 0
        glfwGetFramebufferSize(window, &iwidth, &iheight)
        glViewport(0, 0, iwidth, iheight)
        self.width = Float(iwidth)
        self.height = Float(iheight)
        glClearColor(1.0, 1.0, 0.0, 1.0)

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

    func drawRectCentered(x:Float, y:Float, w:Float, h:Float) {
        var scale: [GLfloat] = [ w * 2.0 / self.width, h * 2.0 / self.height ]
        var offset: [GLfloat] = [ ( (x - w / 2.0) * 2.0 / self.width ) - 1.0,
                                  ( (y - h / 2.0) * 2.0 / self.height ) - 1.0 ]
        glUseProgram(self.program)
        glUniform2fv(self.scale_location, 1, &scale)
        glUniform2fv(self.offset_location, 1, &offset)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }

}

