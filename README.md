# Wyowhisper ROCm

Faster Whisper with ROCm support for accelerating inference on amd gpu.

## Build
docker build -t wyowhisper-rocm .

## Usage
docker run -d --restart on-failure \
 -v /opt/llm-dl:/opt/llm-dl \
 --network=host \
 --device=/dev/kfd \
 --device=/dev/dri \
 --group-add=video \
 --group-add=render \
 --ipc=host \
 --security-opt seccomp=unconfined \
 wyowhisper-rocm

## Contributing
Always welcome.

## Acknowledgment
ROCm Team - for maintaining rocm/dev-ubuntu-24.04 on docker hub

Rhasspy Team - for maintaining and developing wyoming-faster-whisper

muaiyadh - initial github gist for building CTranslate2 with ROCm Support in docker, see https://gist.github.com/muaiyadh/d99923375f5d35b5b08e8369705fa41a

arlo-phoenix - fork of CTranslate2 with ROCm support, see https://github.com/arlo-phoenix/ctranslate2-rocm

justinkb - patched fork of CTranslate2 with ROCm support, see https://github.com/justinkb/CTranslate2-rocm

## License
This repository contains **custom configurations** (Dockerfile, docker-compose.yml, and GitLab CI files) licensed under **GPLv3**.

As with all Docker images, this image is built on top of other software that may be under different licenses:

- The **base Ubuntu image** includes software under various licenses (e.g., GPL, BSD, MIT).
- The **ROCm libraries** are included and subject to their own licenses (check `/opt/rocm/share/doc/<component-name>` for details).
- Various **Python pip packages** are included and subject to their own licenses (check each package's repository for details).
- The **`justinkb/CTranslate2-rocm`** project is included as a dependency and is subject to its own license (check its repository for details).
- The **`SYSTRAN/faster-whisper`** project is included as a dependency and is subject to its own license (check its repository for details).
- The **`rhasspy/wyoming-faster-whisper`** project is included as a dependency and is subject to its own license (check its repository for details).

**As with any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with all relevant licenses for the software contained within.**

## Project status
Not actively maintained.
