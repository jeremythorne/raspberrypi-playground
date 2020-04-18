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
import LIBPNG

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
     0.0, 1.0,  1.0, 1.0, 1.0,  0.0, 1.0, 
     0.0, 0.0,  1.0, 1.0, 1.0,  0.0, 0.0, 
     1.0, 1.0,  1.0, 1.0, 1.0,  1.0, 1.0, 
     1.0, 0.0,  1.0, 1.0, 1.0,  1.0, 0.0, 
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

struct Image {
    var width:Int = 0
    var height:Int = 0
    var texture:GLuint = 0
}

class App {

    var width:Float = 0.0
    var height:Float = 0.0
    var program:GLuint = 0
    var scale_location:GLint = 0 
    var offset_location:GLint = 0

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
        var fp: UnsafeMutablePointer<FILE>? = nil
        filename.withCString {cs in fp = fopen(cs, "rb")}
        if fp == nil {
            print("failed to open", filename)
            return nil
        }
        defer {
            fclose(fp)
        }
        var png = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if png == nil {
            print("couldn't create struct to read PNG")
            return nil
        }
        var info = png_create_info_struct(png)
        if info == nil {
            print("couldn't create info struct to read PNG")
            return nil
        }
        defer {
            png_destroy_read_struct(&png, &info, nil)
        }

        var image = Image()
        png_init_io(png, fp)
        png_read_info(png, info)
        image.width = Int(png_get_image_width(png, info))
        image.height = Int(png_get_image_height(png, info))
        let color_type = png_get_color_type(png, info)
        let bit_depth = png_get_bit_depth(png, info)

        print("image:", image.width, image.height)

        if bit_depth == 16 {
            png_set_strip_16(png)
        }
        
        if color_type == PNG_COLOR_TYPE_PALETTE {
            png_set_palette_to_rgb(png)
        }

        if color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8 {
            png_set_expand_gray_1_2_4_to_8(png)
        }

        if png_get_valid(png, info, PNG_INFO_tRNS) == 0 {
            png_set_tRNS_to_alpha(png)
        }

        if [PNG_COLOR_TYPE_RGB,
            PNG_COLOR_TYPE_GRAY,
            PNG_COLOR_TYPE_PALETTE].contains(Int32(color_type)) {
                png_set_filler(png, 0xff, PNG_FILLER_AFTER)
        }

        if [PNG_COLOR_TYPE_GRAY,
            PNG_COLOR_TYPE_GRAY_ALPHA].contains(Int32(color_type)) {
                png_set_gray_to_rgb(png)
        }

        png_read_update_info(png, info)

        var bytes = [UInt8]()
        let rowbytes = png_get_rowbytes(png, info)
        bytes.reserveCapacity(image.height * rowbytes)
        var row_pointers = [Optional<UnsafeMutablePointer<UInt8>>]()
        row_pointers.reserveCapacity(image.height)
        let p = UnsafeMutablePointer<UInt8>(mutating:bytes)
        // inverted loop so we invert image for GL
        for index in stride(from: image.height-1, to: 0, by:-1) {
            row_pointers.append(p + index * rowbytes)
        }

        print("reading image")
        let orp = Optional(UnsafeMutablePointer(mutating:row_pointers))
        png_read_image(png, orp)

        image.texture = loadTexture(width:image.width, height:image.height, bytes:&bytes)
        return image
    }

    func drawRectCentered(x:Float, y:Float, w:Float, h:Float) {
        var scale: [GLfloat] = [ w * 2.0 / self.width, h * 2.0 / self.height ]
        var offset: [GLfloat] = [ ( (x - w / 2.0) * 2.0 / self.width ) - 1.0,
                                  ( (y - h / 2.0) * 2.0 / self.height ) - 1.0 ]
        glUseProgram(self.program)
        glUniform2fv(self.scale_location, 1, &scale)
        glUniform2fv(self.offset_location, 1, &offset)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
    }

    func drawImageCentered(x:Float, y:Float, image:Image) {
        let w = Float(image.width)
        let h = Float(image.height)
        var scale: [GLfloat] = [ w * 2.0 / self.width, h * 2.0 / self.height ]
        var offset: [GLfloat] = [ ( (x - w / 2.0) * 2.0 / self.width ) - 1.0,
                                  ( (y - h / 2.0) * 2.0 / self.height ) - 1.0 ]
        glUseProgram(self.program)
        glUniform2fv(self.scale_location, 1, &scale)
        glUniform2fv(self.offset_location, 1, &offset)
        glBindTexture(GLenum(GL_TEXTURE_2D), image.texture)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }
}

