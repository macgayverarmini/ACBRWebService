@echo off
cd ..

echo Construindo ambiente Lazarus (cacheado pela imagem)
REM Constroi com o diretório src como contexto (minúsculo, muito mais rápido!)
docker build -t acbr-webservice-builder src

echo.
echo Compilando projeto montando pasta local diretamente...
docker run --rm -v "%cd%:/workspace" -w "/workspace/src" acbr-webservice-builder bash -c "dos2unix ./build.sh && chmod +x ./build.sh && ./build.sh"

cd src
