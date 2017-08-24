#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <fcntl.h>
#include <gbm.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>

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
    unsigned int texture;
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

bool init_gl(void) {
    //Framebuffer
    glGenFramebuffers(1, &gl.fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, gl.fbo);

    gl.w = gl.h = 256;

    glGenTextures(1, &gl.texture);
    glBindTexture(GL_TEXTURE_2D, gl.texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gl.w, gl.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
                    GL_TEXTURE_2D, gl.texture, 0);

    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        return false;

    //Viewport
    glViewport(0, 0, gl.w, gl.h);

    //TODO
    //vertices, vbo, vertex attrib
    //program, shader source, compile, link, check
    //texture, data, params, active, 


    return true;
}

bool render(void) {
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    //TODO
    //triangle strip
    return true;
}

bool read_pixels(void) {
    unsigned char * data = malloc(gl.w*gl.h*4);
    if(!data) return false;
    glReadPixels(0, 0, gl.w, gl.h, GL_RGBA, GL_UNSIGNED_BYTE, data);
    printf("%02x %02x %02x %02x", data[0], data[1], data[2], data[3]);
    free(data);
    return true;
}

void close_gl(void) {
    if(gl.texture)
        glDeleteTextures(1, &gl.texture);
    if(gl.fbo)
        glDeleteFramebuffers(1, &gl.fbo);
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
    if(!render()) goto end;
    if(!read_pixels()) goto end;

end:
    close_gl();
    close_egl();
    return 0;
}
