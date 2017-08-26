#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <fcntl.h>
#include <gbm.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

struct egl_s {
    int fd;
    struct gbm_device * gbm;
    EGLDisplay display;
    EGLConfig config;
    EGLContext context;
} egl;


struct {
    unsigned int w, h;
    unsigned int fbo;
    unsigned int fb_texture;
    unsigned int texture;
    unsigned int vbo;
    unsigned int vertex_shader;
    unsigned int fragment_shader;
    unsigned int program;
    int a_vertex_location;
    int t_tex_location;
    unsigned char * in_pixels;
    unsigned char * pixels;
} gl;

bool init_egl() {
    bool r;
    egl.fd = open("/dev/dri/renderD128", O_RDWR);
    if(egl.fd <= 0) return false;

    egl.gbm = gbm_create_device(egl.fd);
    if(egl.gbm == NULL) return false;
    
    egl.display = eglGetPlatformDisplay(EGL_PLATFORM_GBM_MESA, egl.gbm, NULL);
    if(egl.display == NULL) return false;

    r = eglInitialize(egl.display, NULL, NULL);
    if(!r) return false;

    static const EGLint config_attribs[] = {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE
    };
    EGLint count;
    r = eglChooseConfig(egl.display, config_attribs, &egl.config, 1, &count);
    if(!r) return false;
    r = eglBindAPI(EGL_OPENGL_ES_API);
    if(!r) return false;

    static const EGLint attribs[]  = {
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE
    };
    egl.context = eglCreateContext(egl.display, egl.config, 
                    EGL_NO_CONTEXT, attribs);
    if(egl.context == EGL_NO_CONTEXT) return false;

    r = eglMakeCurrent(egl.display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl.context);
    if(!r) return false;

    return true;
}

bool check_gl_error(const char * str) {
    int status = glGetError();
    if(status != GL_NO_ERROR) {
        printf("GL error %s %x\n", str, status);
        return false;
    }
    return true;
}

bool init_gl(void) {
    //Framebuffer
    glGenFramebuffers(1, &gl.fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, gl.fbo);

    gl.w = gl.h = 256;

    glGenTextures(1, &gl.fb_texture);
    glBindTexture(GL_TEXTURE_2D, gl.fb_texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gl.w, gl.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
                    GL_TEXTURE_2D, gl.fb_texture, 0);

    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        printf("framebuffer incomplete\n");
        return false;
    }
    //Viewport
    glViewport(0, 0, gl.w, gl.h);

    if(!check_gl_error("framebuffer"))
        return false;

    //vertices, vbo
    const float vertices[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f
    };
    glGenBuffers(1, &gl.vbo);
    glBindBuffer(GL_ARRAY_BUFFER, gl.vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    //texture, data, params, active, 
    
    glGenTextures(1, &gl.texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gl.texture);
    gl.in_pixels = malloc(gl.w*gl.h*4);
    unsigned char * data = gl.in_pixels;
    for(int y = 0; y < gl.h; y++) {
        for(int x = 0; x < gl.w; x++) {
            int offset = (x + gl.w * y) * 4;
            data[offset] =     (x & 0xff);
            data[offset + 1] = (y & 0xff);
            data[offset + 2] =  128;
            data[offset + 3] = 0xff;
        }
    }
    stbi_write_png("in.png", gl.w, gl.h, 4, gl.in_pixels, gl.w*4);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    if(!check_gl_error("texture"))
        return false;

    //program, shader source, compile, link, check, vertex attrib
    gl.program = glCreateProgram();
    const char * vertex_shader_source = 
        "attribute vec2 a_vertex;\n"
        "varying highp vec2 v_texcoord;\n"
        "void main(void) {\n"
        "   v_texcoord = a_vertex;\n"
        "   gl_Position = vec4(a_vertex * 2.0f - vec2(1.0f, 1.0f), 0.5f, 1.0f);\n"
        "}\n";
    const char * fragment_shader_source =
        "uniform sampler2D t_tex;\n"
        "varying highp vec2 v_texcoord;\n"
        "void main(void) {\n"
        "   gl_FragColor = texture2D(t_tex, v_texcoord);\n"
        //"   gl_FragColor = vec4(v_texcoord, 0.25f, 1.0f);\n"
        "}\n";
    gl.vertex_shader = glCreateShader(GL_VERTEX_SHADER);
    gl.fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(gl.vertex_shader, 1, (const char **)&vertex_shader_source, NULL); 
    glShaderSource(gl.fragment_shader, 1, (const char **)&fragment_shader_source, NULL);
    
    int status;
    char buf[256];
    GLsizei len;
    glCompileShader(gl.vertex_shader);
    glGetShaderiv(gl.vertex_shader, GL_COMPILE_STATUS, &status);
    if(status != GL_TRUE) {
        glGetShaderInfoLog(gl.vertex_shader, sizeof(buf), &len, buf);
        printf("failed to compile vertex shader\n%s\n", buf);
        return false;
    }
    glCompileShader(gl.fragment_shader);
    glGetShaderiv(gl.fragment_shader, GL_COMPILE_STATUS, &status);
    if(status != GL_TRUE) {
        glGetShaderInfoLog(gl.fragment_shader, sizeof(buf), &len, buf);
        printf("failed to compile fragment shader\n%s\n", buf);
        return false;
    }
    glAttachShader(gl.program, gl.vertex_shader);
    glAttachShader(gl.program, gl.fragment_shader);
    glLinkProgram(gl.program);

    glGetProgramiv(gl.program, GL_LINK_STATUS, &status);
    if(status != GL_TRUE) {
        glGetProgramInfoLog(gl.program, sizeof(buf), &len, buf);
        printf("failed to link program\n%s\n", buf);
        return false;
    }

    gl.a_vertex_location = glGetAttribLocation(gl.program, "a_vertex");
    if(gl.a_vertex_location == -1) {
        printf("failed to get attrib location for a_vertex\n");
        return false;
    }

    glVertexAttribPointer(gl.a_vertex_location, 2, GL_FLOAT, GL_FALSE, 8, 0);
    glEnableVertexAttribArray(gl.a_vertex_location);
    gl.t_tex_location = glGetUniformLocation(gl.program, "t_tex");
    if(gl.t_tex_location == -1) {
        printf("failed to get sampler location for t_tex\n");
    }
    glUseProgram(gl.program);
    glUniform1i(gl.t_tex_location, 0);

    if(!check_gl_error("program"))
        return false;
    
    gl.pixels = malloc(gl.w*gl.h*4);

    return true;
}

bool upload(void) {
    if(!gl.in_pixels) return false;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gl.w, gl.h, 0, GL_RGBA,
            GL_UNSIGNED_BYTE, gl.in_pixels);
    if(!check_gl_error("upload"))
        return false;
    return true;
 }

bool render(void) {
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    //triangle strip
    glUseProgram(gl.program);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    if(!check_gl_error("render"))
        return false;

    return true;
}

void print_pixel(unsigned char *data) {
    printf("%02x %02x %02x %02x", data[0], data[1], data[2], data[3]);
}

bool read_pixels(void) {
    if(!gl.pixels) return false;
    glReadPixels(0, 0, gl.w, gl.h, GL_RGBA, GL_UNSIGNED_BYTE, gl.pixels);

    if(!check_gl_error("readpixels"))
        return false;

    return true;
}

bool save() {
    stbi_write_png("out.png", gl.w, gl.h, 4, gl.pixels, gl.w*4);
    return true;
}

void close_gl(void) {
    if(gl.pixels)
        free(gl.pixels);
    if(gl.in_pixels)
        free(gl.in_pixels);
    if(gl.texture)
        glDeleteTextures(1, &gl.texture);
    if(gl.fbo)
        glDeleteFramebuffers(1, &gl.fbo);
    if(gl.fb_texture)
        glDeleteTextures(1, &gl.fb_texture);
    if(gl.program)
        glDeleteProgram(gl.program);
    if(gl.vertex_shader)
        glDeleteShader(gl.vertex_shader);
    if(gl.fragment_shader)
        glDeleteShader(gl.fragment_shader);
}

void close_egl(void) {
    if(egl.context != EGL_NO_CONTEXT)
        eglDestroyContext(egl.display, egl.context);
    if(egl.display != NULL)
        eglTerminate(egl.display);
    if(egl.gbm != NULL)
        gbm_device_destroy(egl.gbm);
    if(egl.fd >= 0)
        close(egl.fd); 
}

int main(void) {
    if(!init_egl()) goto end;
    if(!init_gl()) goto end;
    for(int i = 0; i < 10000; i++) {
        if(!upload()) goto end;
        if(!render()) goto end;
        if(!read_pixels()) goto end;
    }
    save();
end:
    close_gl();
    close_egl();
    return 0;
}
