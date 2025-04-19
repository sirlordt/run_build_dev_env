# Script de Configuración de Entorno de Desarrollo C++

Este script (`build_cpp_dev_env.sh`) configura un entorno de desarrollo C++ completo utilizando Distrobox con soporte para Docker.

## Características

- Verifica si Distrobox y Docker están instalados y los instala si es necesario
- Crea un contenedor Ubuntu 22.04 con soporte para Docker
- Instala herramientas de desarrollo dentro del contenedor (incluyendo Docker)
- Crea un proyecto demo de C++ en ~/Desktop/projects/cpp/cpp_demo
- Registra toda la salida en un archivo de log con marca de tiempo
- Proporciona integración con Docker para containerizar tus aplicaciones C++

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
