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
     0.0,  1.0, 0.0, 1.0, 0.0,
     0.0,  0.0, 1.0, 0.0, 0.0,
     1.0,  1.0, 0.0, 0.0, 1.0,
     1.0,  0.0, 0.0, 0.0, 1.0,
]

var vertex_shader_text = "#version 110\n"
+ "attribute vec3 col;\n"
+ "attribute vec2 pos;\n"
+ "uniform vec2 scale;\n"
+ "uniform vec2 offset;\n"
+ "varying vec3 color;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_Position = vec4(pos * scale + offset, 0.0, 1.0);\n"
+ "  color = col;\n"
+ "}\n"

var fragment_shader_text = "#version 110\n"
+ "varying vec3 color;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_FragColor = vec4(color, 1.0);\n"
+ "}\n"

func main()
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
            return 0
        }
        return shader
    }

    let vertex_shader = compileShader(text: vertex_shader_text, shader_type:GLenum(GL_VERTEX_SHADER))

    let fragment_shader = compileShader(text: fragment_shader_text, shader_type:GLenum(GL_FRAGMENT_SHADER))

    let program = glCreateProgram()
    glAttachShader(program, vertex_shader)
    glAttachShader(program, fragment_shader)
    glLinkProgram(program)
    var link_status:GLint = 0
    glGetProgramiv(program, GLenum(GL_LINK_STATUS), &link_status)
    if link_status == GLboolean(GL_TRUE) {
        print("linked")
    }

    let pos_location = GLuint(glGetAttribLocation(program, "pos"))
    let col_location = GLuint(glGetAttribLocation(program, "col"))
    let scale_location = GLint(glGetUniformLocation(program, "scale")) 
    let offset_location = GLint(glGetUniformLocation(program, "offset")) 

    glEnableVertexAttribArray(pos_location)
    glVertexAttribPointer(pos_location, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                            GLsizei(MemoryLayout<GLfloat>.size) * 5,
                                       UnsafeRawPointer(bitPattern: 0))
    glEnableVertexAttribArray(col_location)
    glVertexAttribPointer(col_location, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                            GLsizei(MemoryLayout<GLfloat>.size) * 5,
                                       UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 2))
    var iwidth: Int32 = 0
    var iheight: Int32 = 0
    glfwGetFramebufferSize(window, &iwidth, &iheight)
    glViewport(0, 0, iwidth, iheight)
    let width = Float(iwidth)
    let height = Float(iheight)
    glClearColor(1.0, 1.0, 0.0, 1.0)

    func drawRectCentered(x:Float, y:Float, w:Float, h:Float) {
        var scale: [GLfloat] = [ w * 2.0 / width, h * 2.0 / height ]
        var offset: [GLfloat] = [ ( (x - w / 2.0) * 2.0 / width ) - 1.0,
                                  ( (y - h / 2.0) * 2.0 / height ) - 1.0 ]
        glUseProgram(program)
        glUniform2fv(scale_location, 1, &scale)
        glUniform2fv(offset_location, 1, &offset)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
    }

    var gx:Float = width / 2.0
    var gy:Float = height / 2.0
    var vx:Float = 3.0
    var vy:Float = 2.0
    let hs:Float = 50.0
    func update() {
        gx += vx
        gy += vy
        if gx > width - hs {
            gx = width - hs
            vx = -vx
        } else if gx < hs {
            gx = hs
            vx = -vx
        }

        if gy > height - hs {
            gy = height - hs
            vy = -vy
        } else if gy < hs {
            gy = hs
            vy = -vy
        }
    }

    func draw() {
        drawRectCentered(x:gx, y:gy, w: 2.0 * hs, h: 2.0 * hs)
    }

    print("starting loop")

    while glfwWindowShouldClose(window) == 0 {
        update()
    
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    
        draw()

        glfwSwapBuffers(window)
        glfwPollEvents()
    }

}


print("Hello, world!")
main()
