# pws-down ⚡

**pws-down** es un framework de personalización para el prompt de PowerShell (Pwsh) diseñado con una filosofía estricta de **"Zero-Exe" (Cero Ejecutables) y Arquitectura Modular**.

Su objetivo es ofrecer un prompt rico en información (Git, tiempos de ejecución, versiones de software) con **latencia 0ms**. En lugar de invocar procesos externos lentos como `git.exe` o `python --version`, utiliza llamadas nativas de .NET, lectura de archivos directas y consultas al Registro de Windows.

## ✨ Características Principales

  * **Ultra Rápido (Pre-compilado):** Utiliza un plan de ejecución en memoria RAM. No busca comandos ni evalúa el sistema al presionar `Enter`; solo dispara funciones ya cargadas para garantizar latencia 0ms.
  * **Diseño Modular:** Cada funcionalidad vive en su propio archivo (`.ps1`). Si un módulo se rompe, el resto del prompt sigue funcionando de manera independiente.
  * **Configurable al Vuelo:** Cambia el orden, activa o desactiva módulos instantáneamente mediante comandos o el archivo `settings.json` sin necesidad de tocar el código base.
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

El controlador principal del entorno está integrado nativamente y se invoca con el comando `pws`. Puedes usarlo para gestionar el estado y la cantidad de información de tu terminal en tiempo real:

  * `pws -activate` : Enciende el motor de `pws-down` en RAM.
  * `pws -disable`  : Apaga el motor y vuelve a un prompt básico de emergencia.
  * `pws -minimal`  : Cambia el layout a una versión reducida (oculta hora y software) y recompila al instante en RAM.
  * `pws -full`     : Activa todos los módulos visuales configurados.
  * `pws -update`   : Dispara una recolección en background de la información de snapshots (batería, software).
  * `pws -theme <N>`: Cambia el tema de colores en vivo (ej. `pws -theme default`).
  * `pws -reload`   : Recarga los archivos de los módulos sin necesidad de reiniciar la terminal.
  * `pws -save`     : Persiste tus cambios actuales de memoria en el archivo de configuración `settings.json`.

## 🧩 Estructura del Proyecto

```text
pws-down/
├── init.ps1           # Motor central: Cargador, Controlador y Prompt pre-compilado en RAM.
├── renderer.ps1       # Motor visual: Aplica temas y colores a los datos crudos.
├── config/
│   └── settings.json  # Define el orden (Layout/SnapshotLayout) y el Theme visual.
└── modules/           # Directorios de funcionalidades
    ├── sync/          # Módulos evaluados en cada prompt (time, path, git, duration).
    └── snapshot/      # Módulos evaluados en background (battery, software).
```

## ⚙️ Cómo Personalizar y Crear Módulos

La ventaja de la Arquitectura de `pws-down` es que separarás la obtención de datos de la parte visual.

1.  Crea un script en `modules/sync/`, por ejemplo `wifi.ps1`.
2.  Define una función que empiece obligatoriamente por el prefijo `Get-Pws` y que retorne un `PSCustomObject` con dato y estilo:
    ```powershell
    function Get-PwsWifi {
        return [PSCustomObject]@{ Value = "📶 100%"; Style = "battery_full" }
    }
    ```
3.  Abre `config/settings.json` y añade `"Wifi"` al arreglo `"Layout"`.
4.  Ejecuta `pws -reload` y luego `pws -full`. El motor compilará el módulo de forma instantánea y el `renderer` coloreará el valor mediante el estilo elegido.
