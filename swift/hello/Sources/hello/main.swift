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
    -0.6, -0.4, 1.0, 0.0, 0.0,
    0.6,  -0.4, 0.0, 1.0, 0.0,
    0.0,   0.6, 0.0, 0.0, 1.0
]

var vertex_shader_text = "#version 110\n"
+ "attribute vec3 col;\n"
+ "attribute vec2 pos;\n"
+ "varying vec3 color;\n"
+ "void main()\n"
+ "{\n"
+ "  gl_Position = vec4(pos, 0.0, 1.0);\n"
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

    let vertex_shader = glCreateShader(GLenum(GL_VERTEX_SHADER))
    vertex_shader_text.withCString {cs in
        var cs_copy = cs
        //TODO more mangling required on the char **
        //glShaderSource(_shader, 1, &cs_copy, nil)
    }
    glCompileShader(vertex_shader)

    let fragment_shader = glCreateShader(GLenum(GL_VERTEX_SHADER))
    fragment_shader_text.withCString {cs in
        var cs_copy = cs
        //glShaderSource(fragment_shader, 1, &cs_copy, nil)
    }
    glCompileShader(fragment_shader)

    let program = glCreateProgram()
    glAttachShader(program, vertex_shader)
    glAttachShader(program, fragment_shader)
    glLinkProgram(program)

    let pos_location:GLuint = GLuint(glGetAttribLocation(program, "pos"))
    let col_location:GLuint = GLuint(glGetAttribLocation(program, "col"))

    glEnableVertexAttribArray(pos_location)
    glVertexAttribPointer(pos_location, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                            GLsizei(MemoryLayout<GLfloat>.size),
                                       UnsafeRawPointer(bitPattern: 0))
    glEnableVertexAttribArray(col_location)
    glVertexAttribPointer(col_location, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                            GLsizei(MemoryLayout<GLfloat>.size),
                                       UnsafeRawPointer(bitPattern: 2))
    var width: Int32 = 0
    var height: Int32 = 0
    glfwGetFramebufferSize(window, &width, &height)
    glViewport(0, 0, width, height)
    glClearColor(1.0, 1.0, 0.0, 1.0)

    while glfwWindowShouldClose(window) == 0 {
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    
        glUseProgram(program)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)

        glfwSwapBuffers(window)
        glfwPollEvents()
    }

}

print("Hello, world!")
main()
