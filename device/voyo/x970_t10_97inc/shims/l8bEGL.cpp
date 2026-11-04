#include <EGL/egl.h>

const char* eglQueryStringImplementationANDROID(EGLDisplay dpy, EGLint name) {
    return eglQueryString(dpy, name);
}
