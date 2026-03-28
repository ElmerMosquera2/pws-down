# pws-down ⚡

**pws-down** es un framework de personalización para el prompt de PowerShell (Pwsh) diseñado con una filosofía estricta de **"Zero-Exe" (Cero Ejecutables) y Arquitectura Modular**.

Su objetivo es ofrecer un prompt rico en información (Git, tiempos de ejecución, versiones de software) con **latencia 0ms**. En lugar de invocar procesos externos lentos como `git.exe` o `python --version`, utiliza llamadas nativas de .NET, lectura de archivos directas y consultas al Registro de Windows.

## ✨ Características Principales

  * **Ultra Rápido:** Sin parpadeos ni lag al presionar `Enter`.
  * **Diseño Modular:** Cada funcionalidad vive en su propio archivo (`.ps1`). Si un módulo se rompe, el resto del prompt sigue funcionando de manera independiente.
  * **Configurable al Vuelo:** Cambia el orden, activa o desactiva módulos instantáneamente mediante un archivo `settings.json` sin necesidad de tocar el código base.
  * **Cero Ejecutables:** Lee el archivo `.git/HEAD` directamente como texto para inferir la rama y consulta el Registro para las versiones de software.

## 🚀 Instalación

1.  Copia la carpeta raíz `pws-down` en tu directorio de usuario (`$HOME`).
2.  Abre tu perfil de PowerShell ejecutando:
    ```powershell
    notepad $PROFILE
    ```
3.  Añade la siguiente línea al final del archivo para cargar el ecosistema al iniciar la terminal:
    ```powershell
    . $HOME\pws-down\init.ps1
    ```
4.  Reinicia tu terminal o abre una nueva pestaña.

## 🛠️ Uso y Comandos

El controlador principal del entorno es el comando `pws`. Puedes usarlo para gestionar el estado y la cantidad de información de tu terminal en tiempo real:

  * `pws --activate` : Enciende el motor de `pws-down`.
  * `pws --disable` : Apaga el motor y vuelve a un prompt básico de emergencia.
  * `pws --minimal` : Cambia el layout a una versión reducida (ideal para concentrarse, oculta hora y software).
  * `pws --full` : Activa todos los módulos visuales definidos en tu configuración.
  * `pws --update` : Escanea el sistema de forma silenciosa para actualizar la caché de versiones de software instaladas.

## 🧩 Estructura del Proyecto

```text
pws-down/
├── init.ps1           # Cargador principal. Hace el dot-sourcing de los módulos.
├── controller.ps1     # Lógica del comando de gestión manual 'pws'.
├── config/
│   └── settings.json  # Define el orden (Layout), símbolos y estado de los módulos.
└── modules/           # Directorio de funcionalidades aisladas.
    ├── time.ps1       # Retorna la hora actual.
    ├── duration.ps1   # Calcula la latencia del último comando ejecutado.
    ├── path.ps1       # Formatea el directorio actual.
    ├── git.ps1        # Lee la rama actual de Git de forma nativa.
    └── software.ps1   # Muestra versiones cacheadas (Python, C++).
```

## ⚙️ Cómo Personalizar y Crear Módulos

La ventaja de la arquitectura de `pws-down` es que añadir nueva información al prompt no requiere modificar el núcleo.

1.  Crea un script en la carpeta `modules/`, por ejemplo `bateria.ps1`.
2.  Define una función que empiece obligatoriamente por el prefijo `Get-Pws` y que retorne un bloque de texto (puede incluir colores ANSI):
    ```powershell
    function Get-PwsBateria {
        return "`e[92m🔋 100%`e[0m "
    }
    ```
3.  Abre `config/settings.json` y añade `"Bateria"` (el nombre sin el prefijo) al arreglo `"Layout"` en la posición exacta donde quieras que aparezca.
4.  Abre una nueva terminal. El motor detectará e inyectará tu nuevo módulo automáticamente.
