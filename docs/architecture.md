# 🛠️ Arquitectura Modular: pws-down

Este documento describe la estructura y el flujo de ejecución de **pws-down**, una capa de personalización para PowerShell (Pwsh) optimizada para **latencia cero** y **extensibilidad modular**.

## 1. Filosofía de Diseño
* **Zero-Exe:** Evitar la llamada a archivos `.exe` externos (como `git.exe` o `python.exe`) durante la renderización del prompt para eliminar el lag.
* **Pre-compilación en memoria:** El orden de los elementos del prompt se compila en un "Plan de Ejecución" durante el arranque de la terminal. El bucle principal solo dispara referencias directas en RAM, evitando la búsqueda de comandos con cada 'Enter'.
* **Aislamiento de Lógica:** Cada funcionalidad (hora, rama git, versión de software) reside en su propio archivo independiente.
* **Layout Declarativo:** El orden y la visibilidad de los elementos se definen en un archivo de configuración, no en el código del prompt.

---

## 2. Estructura de Directorios

```text
pws-down/
├── init.ps1           # Motor central: Cargador, Controlador 'pws' y Compilador del prompt.
├── config/
│   └── settings.json  # Estado global y orden de los módulos (Layout).
└── modules/           # Lógica pura de componentes.
    ├── time.ps1       # Retorna [HH:mm:ss].
    ├── duration.ps1   # Retorna latencia del último comando.
    ├── path.ps1       # Retorna ruta actual formateada.
    ├── git.ps1        # Retorna rama actual vía lectura de archivos .git.
    └── software.ps1   # Retorna versiones desde el Registro de Windows.
```

---

## 3. Componentes del Sistema

### A. El Motor Central (`init.ps1`)
Es el corazón del sistema unificado. Realiza tres tareas principales:
1. **Dot-Sourcing:** Carga los scripts de `modules/` en memoria.
2. **Controlador:** Aloja la función `pws` para la interacción manual del usuario.
3. **Prompt:** Define el símbolo del sistema que el usuario ve.

### B. El Motor de Layout (`settings.json`)
Controla qué se muestra y en qué orden.
```json
{
  "Enabled": true,
  "Layout": ["Time", "Duration", "Path", "Git"],
  "Symbols": { "indicator": "❯❯", "error": "✘ ❯❯" }
}
```

### C. El Plan de Ejecución (`$global:PwsExecutionPlan`)
Es un array en memoria RAM que almacena objetos de tipo `FunctionInfo`. En lugar de buscar cómo se llama una función cada vez que el usuario presiona Enter, el sistema simplemente recorre este array y dispara los bloques de memoria pre-validados.

### D. Módulos Estándar (`modules/*.ps1`)
Cada archivo debe exportar una función con el prefijo `Get-Pws`. 
* **Contrato:** La función debe retornar un `[string]` (puede incluir secuencias de escape ANSI para color) o un string vacío si no hay datos que mostrar.

---

## 4. Flujo de Ejecución (Lifecycle)

El ciclo de vida ahora está dividido en dos fases para garantizar máxima velocidad:

### Fase 1: Arranque (Startup)
1. El perfil de PowerShell invoca a `init.ps1`.
2. **Registro:** Se cargan las funciones de `modules/` en el scope global.
3. **Compilación:** Se lee `settings.json` y se construye `$global:PwsExecutionPlan` validando qué funciones existen realmente.

### Fase 2: Bucle del Prompt (Runtime - Latencia 0ms)
Al presionar Enter:
1. Se captura inmediatamente el éxito/error del comando anterior (`$?`).
2. Se recorre el array `$global:PwsExecutionPlan` invocando cada función directamente desde la memoria RAM.
3. **Bloque Identificable:** Se concatena el indicador final (`>>`) de forma independiente a los módulos.
4. Se entrega el string final a la consola.

---

## 5. Gestión de Estado: El comando `pws`

El comando `pws` actúa como la interfaz de usuario para configurar la terminal en tiempo real y **recompilar el plan de ejecución** al vuelo sin reiniciar.

| Comando | Acción |
| :--- | :--- |
| `pws --activate` | Enciende el motor, guarda el estado y refresca el prompt. |
| `pws --disable` | Apaga el motor y muestra un prompt básico de emergencia. |
| `pws --minimal` | Sobreescribe el `Layout` a su versión reducida, guarda en JSON y **recompila en memoria al instante**. |
| `pws --full` | Restaura el layout completo con todos los módulos y recompila. |
| `pws --update` | Escanea el registro silenciosamente buscando software (ej. Python) y guarda en caché. |

---

## 6. Extensibilidad: Cómo agregar un módulo
Para agregar una nueva funcionalidad (ejemplo: mostrar el nivel de batería):

1. Crear `pws-down/modules/battery.ps1`.
2. Definir la función: `function Get-PwsBattery { ... }`.
3. Agregar `"Battery"` al array `Layout` en `settings.json`.
4. Ejecutar `pws --full` (o abrir una nueva terminal) para obligar al sistema a re-compilar el plan de ejecución y añadir tu módulo.

---

> **Nota de Rendimiento:** El uso de `[System.IO.File]::ReadAllText()` dentro de los módulos es preferible sobre `Get-Content` o `git.exe` para mantener la latencia individual del módulo siempre por debajo de **1ms**.
