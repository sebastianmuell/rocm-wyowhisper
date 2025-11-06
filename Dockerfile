# Dockerfile for building CTranslate2 with ROCm support
# wyoming-faster-whisper preinstalled, ready to serve home assistant
# Source: https://gist.github.com/muaiyadh/d99923375f5d35b5b08e8369705fa41a
# Source: https://github.com/rhasspy/wyoming-faster-whisper.git
# Source: https://github.com/arlo-phoenix/ctranslate2-rocm / https://github.com/justinkb/CTranslate2-rocm

FROM CI_REGISTRY/git/rocm-base:latest

# Set working directory for build
ARG WDIR=/build
WORKDIR $WDIR/
COPY src/*.patch $WDIR/

# Compile ctranslate2
ARG PARALLEL=8
RUN git clone https://github.com/justinkb/CTranslate2-rocm.git ctranslate2 && \
    cd $WDIR/ctranslate2 && git checkout $(git branch -a --sort=-committerdate | head -1 | cut -d/ -f3-) && \
    git apply $WDIR/ctranslate2.patch && \
    git submodule init && git submodule update && \
     CLANG_CMAKE_CXX_COMPILER=amdclang++ HIPCXX=amdclang++ HIP_PATH="$(hipconfig -R)" \
        cmake -S . -B build \
          -DGPU_TARGETS="$ROCM_ARCH" -DCMAKE_HIP_ARCHITECTURES="$ROCM_ARCH" \
          -DWITH_CUDA=OFF -DWITH_CUDNN=ON -DWITH_HIP=ON -DWITH_MKL=OFF -DWITH_DNNL=OFF \
          -DOPENMP_RUNTIME=COMP -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON -DENABLE_CPU_DISPATCH=OFF && \
    cmake --build build -- -j ${PARALLEL} && \
    cd $WDIR/ctranslate2/build && \
    cmake --install . --prefix /usr/local && \
    cp libctranslate2.so /usr/local/lib/ && \
    ldconfig && \
    cd $WDIR/ctranslate2/python && \
    python3 -m pip install -r install_requirements.txt --no-cache-dir && \
    sed -i 's|include_dirs = \[pybind11.get_include()\]|include_dirs = [pybind11.get_include(), "../include"]|' setup.py && \
    sed -i 's|library_dirs = \[\]|library_dirs = ["/usr/local/lib"]|' setup.py && \
    python setup.py bdist_wheel && \
    python3 -m pip install dist/*.whl --no-cache-dir && \
    bash -c "rm -rf $WDIR/ctranslate2 /tmp/* /var/tmp/* /root/* /root/.[^.]*"

# Install faster-whisper
RUN git clone https://github.com/SYSTRAN/faster-whisper.git && \
    cd faster-whisper && \
    sed -i 's#onnxruntime#onnxruntime_migraphx#' requirements.txt && \
    sed -i 's#, to_cpu=to_cpu##' faster_whisper/transcribe.py && \
    python3 -m pip install . --no-cache-dir && \
    bash -c "rm -rf $WDIR/faster-whisper /tmp/* /var/tmp/* /root/* /root/.[^.]*"

# Install wyoming-faster-whisper
RUN git clone https://github.com/rhasspy/wyoming-faster-whisper.git && \
    cd $WDIR/wyoming-faster-whisper && \
    sed -i 's#"faster-whisper.*##' pyproject.toml && \
    python3 -m pip install . --no-cache-dir && \
    bash -c "rm -rf $WDIR/wyoming-faster-whisper /tmp/* /var/tmp/* /root/* /root/.[^.]*"

# Set ENV
ENV URI="tcp://0.0.0.0:10300"
ENV DLDIR=/opt/llm-dl
ENV MODEL=small
ENV LANG=de
ENV BEAM=7
ENV DEV=cuda
ENV COMP=int8_float16

# Set VOLUME
VOLUME $DLDIR

# Set WORKDIR
WORKDIR $DLDIR

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
