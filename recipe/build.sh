#!/bin/bash
if [ "$(uname)" == "Linux" ]; then
    # Required to avoid "warning: libexpat.so.1, needed by ...libGL.so" and subsequent undefined references
    export LDFLAGS="${LDFLAGS} -Wl,--allow-shlib-undefined"
fi

cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH="${PREFIX}" -DCMAKE_INSTALL_LIBDIR="lib" ./cmake
make -j${CPU_COUNT}
make install

# Don't install the cmake files for 2 reasons:
#   1 - cmake already provides a FindGLEW.cmake
#   2 - the generated file contains hardcoded paths to /usr/lib, to reference the files
#       GL.so and GLU.so libraries.
#       Other distros don't use this nomenclature (eg.: Ubuntu) making these files unsuitable for use
#       in other distros other than redhat/centos.
if [ -d "${PREFIX}/lib/cmake/glew/" ]; then
    rm -rf $PREFIX/lib/cmake/glew/
fi
