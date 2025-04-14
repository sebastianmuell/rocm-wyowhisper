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

Rhasspy Team - for maintaining and developing piper and wyoming-piper

muaiyadh - initial git gist for building CTranslate2 with ROCm Support in docker, see https://gist.github.com/muaiyadh/d99923375f5d35b5b08e8369705fa41a

arlo-phoenix - fork of CTranslate2 with ROCm support, see https://github.com/arlo-phoenix/ctranslate2-rocm

justinkb - patched fork of CTranslate2 with ROCm support, see https://github.com/justinkb/CTranslate2-rocm

## License
GPLv3

## Project status
Not actively maintained.
