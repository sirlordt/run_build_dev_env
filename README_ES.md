# Script de Configuración de Entorno de Desarrollo C++

Este script (`build_cpp_dev_env.sh`) configura un entorno de desarrollo C++ completo utilizando Distrobox con soporte para Docker.

## Características

- Verifica si Distrobox y Docker están instalados y los instala si es necesario
- Crea un contenedor Ubuntu 22.04 con soporte para Docker
- Instala herramientas de desarrollo dentro del contenedor (incluyendo Docker)
- Crea un proyecto demo de C++ en ~/Desktop/projects/cpp/cpp_demo
- Registra toda la salida en un archivo de log con marca de tiempo
- Proporciona integración con Docker para containerizar tus aplicaciones C++
- Configura el asistente de IA Claude con instrucciones personalizadas para el mantenimiento de la documentación
- Configura la instalación automática de extensiones de VSCode

## Uso

1. Ejecutar el script de configuración:
   ```
   ./build_cpp_dev_env.sh
   ```
   
   El script automáticamente registra toda la salida en un archivo con el formato:
   ```
   build_cpp_dev_env-YYYY-MM-DD-HH-MM-SS_Z.log
   ```
   donde YYYY-MM-DD-HH-MM-SS_Z es la marca de tiempo cuando se inició el script.

2. Si algo sale mal y necesitas limpiar el entorno:
   ```
   ./build_cpp_dev_env.sh --cleanup
   ```
   Esto detendrá y eliminará el contenedor distrobox.

3. Para eliminar todos los archivos de log:
   ```
   ./build_cpp_dev_env.sh --clean-logs
   ```
   Esto eliminará todos los archivos de log generados por el script.

4. Para especificar un nombre de contenedor personalizado:
   ```
   ./build_cpp_dev_env.sh --container-name mi_entorno_cpp
   ```
   Esto creará un contenedor con el nombre especificado en lugar del predeterminado "cpp_dev_env".

5. Puedes combinar múltiples opciones:
   ```
   ./build_cpp_dev_env.sh --cleanup --clean-logs --container-name mi_entorno_cpp
   ```

6. Después de completar la configuración, entra al contenedor y navega al proyecto:
   ```
   distrobox enter cpp_dev_env
   cd ~/Desktop/projects/cpp/cpp_demo
   ```

5. Consulta el README.md del proyecto para obtener más información sobre cómo compilar y ejecutar la aplicación.

## Scripts del Proyecto

Los siguientes scripts están diseñados para ser utilizados dentro del entorno Distrobox y en una carpeta de proyecto C++ (como cpp_demo) que es auto-generada por el script run_build_dev_env.sh:

- **build.sh**: Automatiza el proceso de compilación de aplicaciones C++ dentro de la carpeta del proyecto. Maneja la configuración de CMake, la compilación y puede ser utilizado para ejecutar la aplicación.

- **build.dist.sh**: Se utiliza para construir contenedores Docker a partir de tus aplicaciones C++. Este script crea un Dockerfile basado en tu proyecto y construye una imagen Docker que contiene tu aplicación.

- **helper.sh**: Un script de utilidad para compilar, ejecutar e inspeccionar contenedores creados a partir de tu aplicación C++. Proporciona comandos convenientes para gestionar los contenedores Docker.

- **create_cpp_project_from_template.sh**: Crea nuevos proyectos C++ a partir de plantillas. Este script puede ser utilizado para crear nuevos proyectos basados en existentes, facilitando el inicio de nuevas aplicaciones con una estructura consistente.

- **inject_cline_custom_instructions.sh**: Configura el asistente de IA Claude con instrucciones personalizadas para mantener la documentación del proyecto. Este script establece un patrón de "Banco de Memoria" para la documentación, asegurando una transferencia de conocimiento y mantenimiento de documentación consistentes.

Para utilizar estos scripts, debes:
1. Estar dentro del contenedor Distrobox (`distrobox enter cpp_dev_env`)
2. Navegar a una carpeta de proyecto C++ (por ejemplo, `cd ~/Desktop/projects/cpp/cpp_demo`)
3. Ejecutar el script deseado (por ejemplo, `./build.sh`)

## Opciones para build_cpp_dev_env.sh

- `--cleanup`: Limpia el entorno distrobox (detiene y elimina el contenedor)
- `--clean-logs`: Elimina todos los archivos de log generados por el script
- `--container-name NOMBRE`: Establece el nombre del contenedor (predeterminado: cpp_dev_env)
- `--remove-old-container`: Fuerza la eliminación del contenedor antiguo si existe con el mismo nombre
- `--clean-container-home`: Elimina todos los archivos del contenedor compartidos con el host
- Sin opciones: Configura el entorno de desarrollo C++ con soporte para Docker

## Registro de Cambios

Se mantiene un archivo [ChangeLog.md](ChangeLog.md) para seguir los cambios del proyecto. Consúltalo para obtener detalles sobre las últimas actualizaciones y mejoras.

## Uso del Script Wrapper

El script `run_build_dev_env.sh` es un wrapper que ejecuta el script de construcción y captura su salida en un archivo de log:

```
./run_build_dev_env.sh --cpp [argumentos_adicionales]
```

Opciones:
- `--cpp`: Parámetro requerido para especificar que deseas ejecutar el script de configuración del entorno C++
- `--clear-logs`: Limpia los archivos de log sin crear un nuevo archivo de log
- Cualquier otro argumento se pasa directamente al script build_cpp_dev_env.sh

Ejemplo:
```
./run_build_dev_env.sh --cpp --container-name nombre_personalizado
```
