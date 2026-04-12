# 🛠️ Arquitectura Modular: pws-down — Edición Mejorada

## 1. Filosofía de Diseño

La arquitectura se sostiene sobre los cuatro pilares originales, reforzados con cuatro nuevas reglas que eliminan tensiones internas de rendimiento.

**Pilares Originales**

* **Zero-Exe:** Evitar la llamada a archivos `.exe` externos durante la renderización del prompt.
* **Pre-compilación en memoria:** El Plan de Ejecución se construye una sola vez en el arranque.
* **Aislamiento de Lógica:** Cada funcionalidad reside en su propio archivo independiente.
* **Layout Declarativo:** El orden visual se define en configuración, no en código del prompt.

**Nuevas Reglas Filosóficas**

**Regla 1 — Dos Clases de Módulos**

* **Síncronos:** datos que cambian con cada comando (hora, path, git). Viven en el plan de ejecución principal.
* **Snapshot:** datos que cambian raramente (versiones de software, batería). Se actualizan en un runspace paralelo al arranque y escriben a variables globales pre-inicializadas. El prompt solo lee esa variable; nunca bloquea.

**Regla 2 — JSON es Fuente de Verdad en Frío**

`settings.json` se lee exactamente una vez: en el arranque. Después, el estado vive exclusivamente en memoria como un objeto tipado `[PSCustomObject]`. Guardar en disco es una operación de persistencia explícita, nunca parte del ciclo de recompilación.

**Regla 3 — El Prompt Escribe, No Construye**

Concatenar strings con `+=` genera N objetos intermedios en memoria en cada keypress. El plan de ejecución almacena scriptblocks que escriben directamente a un `StringBuilder`. Un solo objeto mutable, cero allocations intermedias.

```powershell
$sb = [System.Text.StringBuilder]::new()
foreach ($block in $global:PwsExecutionPlan) { [void]$sb.Append((&$block)) }
$sb.ToString()
```

**Regla 4 — Separación Dato / Presentación**

Cada módulo retorna un objeto estructurado `{ Value; Style }`, no un string ANSI. Un renderer central aplica el color. Esto permite cambiar temas sin tocar lógica de negocio y reutilizar datos en modos alternativos.

---

## 2. Estructura de Directorios

```text
pws-down/
├── init.ps1                # Motor central: Cargador, Controlador y Compilador.
├── renderer.ps1            # Nuevo: aplica estilos ANSI a objetos { Value; Style }.
├── config/
│   └── settings.json       # Fuente de verdad en frío. Solo se lee en Startup.
└── modules/
    ├── sync/               # Módulos síncronos — evaluados en cada prompt.
    │   ├── time.ps1
    │   ├── duration.ps1
    │   ├── path.ps1
    │   └── git.ps1         # Usa FileSystemWatcher en lugar de escalar el árbol.
    └── snapshot/           # Módulos snapshot — actualizados en runspace paralelo.
        ├── software.ps1
        └── battery.ps1
```

---

## 3. Componentes del Sistema

### A. Motor Central (`init.ps1`)

Ahora realiza cuatro tareas en el arranque:

1. **Dot-Sourcing:** Carga los scripts de `modules/` en memoria.
2. **Estado en memoria:** Deserializa `settings.json` a un `[PSCustomObject]` global. El archivo no se toca más.
3. **Compilación del plan:** Construye `$global:PwsExecutionPlan` con scriptblocks de módulos síncronos.
4. **Runspace paralelo:** Lanza los módulos snapshot en background; escriben a `$global:PwsSnapshot` al completar.

### B. Motor de Layout (`settings.json`)

Incluye ahora `SnapshotLayout` como sección separada:

```json
{
  "Enabled": true,
  "Layout": ["Time", "Duration", "Path", "Git"],
  "SnapshotLayout": ["Software", "Battery"],
  "Symbols": { "indicator": "❯❯", "error": "✘ ❯❯" },
  "Theme": "default"
}
```

### C. Plan de Ejecución (`$global:PwsExecutionPlan`)

Array en RAM que almacena **scriptblocks** (no `FunctionInfo`). Cada bloque escribe directamente al `StringBuilder` del renderer. Cero búsquedas de nombre, cero allocations intermedias.

### D. Renderer Central (`renderer.ps1`)

Nuevo componente. Recibe objetos `{ Value; Style }` de cada módulo y aplica las secuencias ANSI según el tema activo. El tema puede cambiarse en tiempo real sin modificar ningún módulo.

### E. Módulos Síncronos (`modules/sync/*.ps1`)

Contrato actualizado: cada función `Get-Pws*` retorna un `[PSCustomObject]` con las propiedades `Value` (string puro) y `Style` (identificador de estilo). Retorna `$null` si no hay datos que mostrar.

### F. Módulo Git Mejorado (`modules/sync/git.ps1`)

La detección de repositorio usa `FileSystemWatcher` sobre el directorio actual. Al cambiar de path, el watcher invalida la caché; el módulo no escala el árbol de directorios en cada prompt. Latencia garantizada < 0.1ms en prompts sucesivos dentro del mismo repo.

---

## 4. Flujo de Ejecución (Lifecycle)

### Fase 1: Arranque (Startup)

1. El perfil de PowerShell invoca `init.ps1`.
2. **Registro:** Funciones de `modules/` cargadas al scope global.
3. **Estado:** `settings.json` deserializado a objeto en memoria. El archivo no se vuelve a leer.
4. **Compilación:** Se construye `PwsExecutionPlan` con scriptblocks de módulos síncronos validados.
5. **Runspace paralelo:** Módulos snapshot se lanzan en background y escriben a `$global:PwsSnapshot`.

### Fase 2: Bucle del Prompt (Runtime — Latencia 0ms)

1. Se captura inmediatamente `$?` del comando anterior.
2. `StringBuilder` inicializado. Se recorre `PwsExecutionPlan`; cada bloque escribe directamente.
3. Renderer aplica ANSI a los objetos `{ Value; Style }` sin lógica adicional en el prompt.
4. Variables snapshot se leen directamente desde RAM.
5. String final entregado a la consola.

---

## 5. Gestión de Estado: El Comando `pws`

Opera exclusivamente sobre el objeto en memoria. Solo sincroniza con `settings.json` cuando el usuario lo solicita explícitamente con `--save`.

| Comando | Acción |
| :--- | :--- |
| `pws --activate` | Enciende el motor, inicializa el estado en RAM y refresca el prompt. |
| `pws --disable` | Apaga el motor y muestra un prompt básico de emergencia. |
| `pws --minimal` | Sobreescribe `Layout` en memoria y recompila el plan al instante. |
| `pws --full` | Restaura el layout completo y recompila. |
| `pws --update` | Dispara un nuevo runspace snapshot para actualizar versiones en caché. |
| `pws --save` | **Nuevo:** persiste el estado actual en memoria a `settings.json`. |
| `pws --theme <nombre>` | **Nuevo:** cambia el tema del renderer sin reiniciar la terminal. |

---

## 6. Extensibilidad: Cómo Agregar un Módulo

**Módulo Síncrono (ejemplo: nivel de batería en tiempo real)**

1. Crear `modules/sync/battery.ps1`.
2. Definir: `function Get-PwsBattery { }` retornando `[PSCustomObject]@{ Value = ...; Style = 'battery' }`.
3. Agregar `"Battery"` al array `Layout` en `settings.json`.
4. Ejecutar `pws --full` para recompilar el plan.

**Módulo Snapshot (ejemplo: versión de Node.js)**

1. Crear `modules/snapshot/node.ps1`.
2. Definir: `function Get-PwsNode { }` que escribe a `$global:PwsSnapshot.Node`.
3. Agregar `"Node"` al array `SnapshotLayout` en `settings.json`.
4. El sistema lo lanzará automáticamente en background en el próximo arranque.

---

## 7. Comparativa: Arquitectura Original vs. Mejorada

| Principio Original | Principio Mejorado |
| :--- | :--- |
| Módulos homogéneos en un solo plan | Dos clases: síncronos (prompt) vs. snapshot (background) |
| JSON como fuente de verdad en runtime | JSON solo en frío; estado en RAM como objeto tipado |
| Módulos retornan strings ANSI | Módulos retornan `{ Value; Style }`; renderer central colorea |
| Concatenación de strings con `+=` | `StringBuilder` con writes directos. Cero allocations intermedias. |
| Git escala el árbol en cada prompt | `FileSystemWatcher` invalida caché por evento de directorio |
| `pws --update` es manual | Runspace snapshot automático y no bloqueante en startup |
| Sin separación dato/color | `renderer.ps1` como componente independiente y reemplazable |

---

> **Nota de Rendimiento:** Con la incorporación de `StringBuilder` en el renderer y el runspace paralelo para snapshots, el objetivo de latencia del bucle principal baja a **< 0.5ms** en condiciones normales, frente al objetivo original de < 1ms por módulo.