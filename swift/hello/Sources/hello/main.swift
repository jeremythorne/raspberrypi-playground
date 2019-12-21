import GL
import GLFW

func error_callback(error: Int32, description: Optional<UnsafePointer<Int8>>) {
    if let u = description {
        let string = String(cString: u)
        print(error, string)
    }
}

func main() {
    print("Hello, world!")

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
    glfwMakeContextCurrent(window)
    if let vendor = glGetString(GLenum(GL_VENDOR)) {
        print("GL vendor:", String(cString: vendor))
    }

    while glfwWindowShouldClose(window) == 0 {
        glClearColor(1.0, 1.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glfwSwapBuffers(window)
        glfwPollEvents()
    }

}

main()
