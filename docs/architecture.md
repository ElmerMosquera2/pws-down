# 🛠️ Arquitectura Modular: pws-down

Este documento describe la estructura y el flujo de ejecución de **pws-down**, una capa de personalización para PowerShell (Pwsh) optimizada para **latencia cero** y **extensibilidad modular**.

## 1. Filosofía de Diseño
* **Zero-Exe:** Evitar la llamada a archivos `.exe` externos (como `git.exe` o `python.exe`) durante la renderización del prompt para eliminar el lag.
* **Aislamiento de Lógica:** Cada funcionalidad (hora, rama git, versión de software) reside en su propio archivo.
* **Layout Declarativo:** El orden y la visibilidad de los elementos se definen en un archivo de configuración, no en el código del prompt.

---

## 2. Estructura de Directorios

```text
pws-down/
├── init.ps1           # Punto de entrada. Carga módulos y define el prompt.
├── config/
│   └── settings.json  # Estado global y orden de los módulos (Layout).
├── modules/           # Lógica pura de componentes.
│   ├── time.ps1       # Retorna [HH:mm:ss].
│   ├── duration.ps1   # Retorna latencia del último comando.
│   ├── git.ps1        # Retorna rama actual vía lectura de archivos .git.
│   └── software.ps1   # Retorna versiones desde el Registro de Windows.
└── controller.ps1     # Definición de la función 'pws' para gestión de estado.
```

---

## 3. Componentes del Sistema

### A. El Cargador (`init.ps1`)
Es el encargado de preparar la sesión de PowerShell. Realiza el **Dot-Sourcing** de todos los scripts en `modules/` para que las funciones estén disponibles en memoria RAM, evitando lecturas de disco repetitivas.

### B. El Motor de Layout (`settings.json`)
Controla qué se muestra y en qué orden.
```json
{
  "Enabled": true,
  "Layout": ["time", "duration", "path", "git"],
  "Symbols": { "indicator": "❯❯", "error": "✘" }
}
```

### C. Módulos Estándar (`modules/*.ps1`)
Cada archivo debe exportar una función con el prefijo `Get-Pws`. 
* **Contrato:** La función debe retornar un `[string]` (puede incluir secuencias de escape ANSI para color) o un string vacío si no hay datos que mostrar.

---

## 4. Flujo de Ejecución (Lifecycle)

1.  **Arranque:** El perfil de PowerShell invoca a `init.ps1`.
2.  **Registro:** Se cargan las funciones de `modules/` en el scope global.
3.  **Bucle del Prompt:** Al presionar Enter:
    * Se captura el éxito/error del comando anterior (`$?`).
    * Se recorre el array `Layout` de `settings.json`.
    * Para cada elemento, se ejecuta `Get-Pws<Nombre>`.
    * **Bloque Identificable:** Se concatena el indicador final (`>>`) de forma independiente a los módulos.
4.  **Renderizado:** Se entrega el string final a la consola.

---

## 5. Gestión de Estado: El comando `pws`

El comando `pws` actúa como la interfaz de usuario para configurar la terminal en tiempo real.

| Comando | Acción |
| :--- | :--- |
| `pws --activate` | Cambia `Enabled` a `true` y refresca el prompt. |
| `pws --minimal` | Sobreescribe el `Layout` en el JSON a una versión reducida. |
| `pws --config` | Abre el archivo `settings.json` para edición manual. |

---

## 6. Extensibilidad: Cómo agregar un módulo
Para agregar una nueva funcionalidad (ejemplo: mostrar el nivel de batería):

1.  Crear `pws-down/modules/battery.ps1`.
2.  Definir la función: `function Get-PwsBattery { ... }`.
3.  Agregar `"battery"` al array `Layout` en `settings.json`.
4.  Reiniciar la terminal o ejecutar `. ./init.ps1`.

---

> **Nota de Rendimiento:** El uso de `[System.IO.File]::ReadAllText()` dentro de los módulos es preferible sobre `Get-Content` para mantener la latencia por debajo de los **1ms**.
