# Dockerfile for building CTranslate2 with ROCm support
# wyoming-faster-whisper preinstalled, ready to serve home assistant
# Source: https://gist.github.com/muaiyadh/d99923375f5d35b5b08e8369705fa41a
# Source: https://github.com/rhasspy/wyoming-faster-whisper.git
# Source: https://github.com/arlo-phoenix/ctranslate2-rocm

FROM CI_REGISTRY/git/rocm-base:latest

# Set working directory for build
ARG WDIR=/build
WORKDIR $WDIR/

# Install deps
RUN apt-get -qq update && apt-get -qqy dist-upgrade \
    && apt-get install -qqy --no-install-recommends \
    cmake \
    cmake-curses-gui \
    git \
    ffmpeg \
    libjpeg-dev \
    libpng-dev \
    libomp-dev \
    libopenblas-dev \
    libtbb-dev \
    llvm \
    python3-dev \
    wget \
    && python3 -m pip install --upgrade pip wheel setuptools pytest scipy numpy==1.* numba --no-cache-dir  \
    && bash -c "rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/* /root/.[^.]*"

# Compile ctranslate2
RUN git clone --recurse-submodules https://github.com/arlo-phoenix/CTranslate2-rocm.git ctranslate2 \
    && cd $WDIR/ctranslate2 \
    && sed -i 's#define C10_WARP_SIZE 64#define C10_WARP_SIZE 32#' src/cuda/helpers.h \
    &&  CLANG_CMAKE_CXX_COMPILER=clang++ CXX=clang++ HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
        cmake -S . -B build \
          -DCMAKE_HIP_ARCHITECTURES="$PYTORCH_ROCM_ARCH" -DGPU_TARGETS="$PYTORCH_ROCM_ARCH" -DAMDGPU_TARGETS="$PYTORCH_ROCM_ARCH" \
          -DWITH_CUDA=OFF -DWITH_CUDNN=ON -DWITH_HIP=ON -DWITH_MKL=OFF -DWITH_DNNL=OFF -DOPENMP_RUNTIME=COMP \
          -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON -DGPU_RUNTIME=HIP -DENABLE_CPU_DISPATCH=OFF \
    && cmake --build build -- -j4 \
    && cd $WDIR/ctranslate2/build \
    && cmake --install . --prefix /usr/local \
    && ldconfig \
    && cd $WDIR/ctranslate2/python \
    && python3 -m pip install -r install_requirements.txt --no-cache-dir \
    && sed -i 's|include_dirs = \[pybind11.get_include()\]|include_dirs = [pybind11.get_include(), "../include"]|' setup.py \
    && sed -i 's|library_dirs = \[\]|library_dirs = ["/usr/local/lib"]|' setup.py \
    && cp ../build/libctranslate2.so /usr/local/lib/ \
    && python setup.py bdist_wheel \
    && python3 -m pip install dist/*.whl --no-cache-dir \
    && bash -c "rm -rf $WDIR/ctranslate2 /tmp/* /var/tmp/* /root/* /root/.[^.]*"

# Install faster-whisper
RUN git clone https://github.com/SYSTRAN/faster-whisper.git \
    && cd faster-whisper \
    && sed -i 's#onnxruntime#onnxruntime_rocm#' requirements.txt \
    && python3 -m pip install . --no-cache-dir \
    && bash -c "rm -rf $WDIR/faster-whisper /tmp/* /var/tmp/* /root/* /root/.[^.]*"

# Install wyoming-faster-whisper
RUN git clone https://github.com/rhasspy/wyoming-faster-whisper.git \
    && cd $WDIR/wyoming-faster-whisper \
    && python3 -m pip install . --no-cache-dir \
    && bash -c "rm -rf $WDIR/wyoming-faster-whisper /tmp/* /var/tmp/* /root/* /root/.[^.]*"

# Set ENV
ENV URI="tcp://0.0.0.0:10300"
ENV DLDIR=/opt/llm-dl
ENV MODEL=small
ENV LANG=de
ENV BEAM=7
ENV DEV=auto
ENV COMP=int8

# Set VOLUME
VOLUME $DLDIR

# Set WORKDIR
WORKDIR $DLDIR
RUN rm -rf /build

# Set ENTRYPOINT
ENTRYPOINT ["sh", "-c", "wyoming-faster-whisper --uri \"$URI\" --model $MODEL --data-dir $DLDIR --download-dir $DLDIR --language $LANG --beam-size $BEAM --device $DEV --compute-type $COMP"]

## Build using:
# docker build -t wyowhisper-rocm .

## Start using:
#docker run -d --restart on-failure \
# -v /opt/llm-dl:/opt/llm-dl \
# --network=host \
# --device=/dev/kfd \
# --device=/dev/dri \
# --group-add=video \
# --group-add=render \
# --ipc=host \
# --security-opt seccomp=unconfined \
# wyowhisper-rocm
