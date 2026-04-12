# 🤝 Guía de Contribución para PWS-DOWN

¡Hola! Qué excelente que quieras sumar tu código a este proyecto. **PWS-DOWN** está diseñado para ser la capa de personalización definitiva para PowerShell, siguiendo principios de arquitectura modular y latencia cero. Toda ayuda para hacerla más rápida y elegante es bienvenida.

---

## 🏛️ Arquitectura y Filosofía

### El Principio Fundamental: Latencia Cero en el Prompt

La función `prompt` es el corazón de la experiencia. Cada milisegundo cuenta. **No puede haber lag.**

- ❌ **Prohibido:** Invocar ejecutables externos (`git.exe`, `python.exe`, `node.exe`) dentro de `prompt`.
- ❌ **Prohibido:** Consultas lentas (WMI/CIM sin caché, lectura de archivos grandes).
- ✅ **Permitido:** Clases nativas .NET (`[System.IO.File]::ReadAllText()`), secuencias ANSI directas, lectura de variables globales en RAM.
- 💡 **El Truco:** Si necesitas información externa, créala en el comando `pws` y almacénala en caché. El `prompt` solo lee de memoria.

### La Regla Modular: Cada Funcionalidad en su Archivo

```text
pws-down/
├── init.ps1           # Solo orquestador (no lógica visual)
├── renderer.ps1       # Componente visual que aplica secuencias ANSI
├── config/
│   └── settings.json  # Define Layout síncrono y SnapshotLayout asíncrono
└── modules/
    ├── sync/          # Módulos evaluados <0.5ms (time, path, git, duration)
    └── snapshot/      # Módulos lentos evaluados asíncronamente (software, battery)
```

**Contrato del Módulo:**
- Nombre: `modules/sync/<nombre>.ps1` o `modules/snapshot/<nombre>.ps1`
- Función: `Get-Pws<Nombre>` (exactamente igual al archivo)
- Retorno (Sync): Un `[PSCustomObject]@{ Value = "..."; Style = "..." }` o `$null`
- Escritura (Snapshot): Modifica la tabla en RAM vía `$global:PwsSnapshot.<Nombre> = [PSCustomObject]...`
- Latencia: Los módulos Sync deben fluir instantáneamente. Los Snapshot corren de fondo.

---

## 📝 Estándares de Código

### Commits: Conventional Commits

Usa [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/):

```bash
feat(battery): add real battery level module with 5s cache
fix(git): resolve error when HEAD file doesn't exist
refactor(init): optimize execution plan with typed list
perf(duration): reduce overhead in command timing
docs(contributing): update contribution guidelines
```

### Comandos Git Modernos

En la documentación y ejemplos, usa los comandos modernos:

```bash
# ✅ Recomendado
git switch feature/nueva-funcionalidad
git switch -c feature/nueva-funcionalidad  # crear y cambiar
git restore archivo.ps1
git restore --staged archivo.ps1

# ❌ Evitar (obsoleto)
git checkout feature/nueva-funcionalidad
git checkout -b feature/nueva-funcionalidad
git checkout -- archivo.ps1
git reset HEAD archivo.ps1
```

### PowerShell: Cmdlets Modernos

```powershell
# ✅ Recomendado (PowerShell 7+)
Get-CimInstance -ClassName Win32_Battery
Get-ChildItem -Filter *.ps1

# ❌ Evitar (obsoleto o más lento)
Get-WmiObject -Class Win32_Battery
Get-ChildItem *.ps1  # sin -Filter es más lento
```

---

## 🐛 Reporte de Errores (Bugs)

Si encuentras problemas, abre un *Issue* con:

1. **Sistema operativo** (Windows 10/11 específicamente)
2. **Versión de PowerShell**: `$PSVersionTable.PSVersion`
3. **Configuración actual**: `Get-Content $HOME\pws-down\config\settings.json`
4. **Pasos para reproducir**
5. **Comportamiento esperado vs real**

---

## ✨ Sugerencia de Características (Features)

¿Tienes una idea para un nuevo módulo? Abre un *Issue* para discutir:

- ¿Qué información mostraría?
- ¿Cómo se obtiene sin ejecutables externos?
- ¿Latencia estimada?
- ¿Qué iconos/colores usaría?

**Ejemplo de nuevo módulo en Snapshot:**
```powershell
# modules/snapshot/docker.ps1
function Get-PwsDocker {
    # La validación costosa no bloquea el prompt <0.5ms al ejecutarse asincrónicamente.
    # El module lee o espera a docker status localmente.
    if ($global:PwsConfig.Docker.Running) {
        $envContainers = $($global:PwsConfig.Docker.Containers)
        $global:PwsSnapshot.Docker = [PSCustomObject]@{ Value = "🐳 $envContainers"; Style = "docker_green" }
    } else {
        $global:PwsSnapshot.Docker = $null
    }
}
```

---

## 🛠️ Entorno de Desarrollo y Pull Requests

### 1. Prepara tu entorno
```powershell
# Clona tu fork
git clone https://github.com/tu-usuario/pws-down.git
cd pws-down

# Crea una rama descriptiva
git switch -c feature/nuevo-modulo
```

### 2. Desarrolla tu módulo
1. Crea `modules/sync/tu-modulo.ps1` o `snapshot/tu-modulo.ps1`
2. El módulo debe retornar o escribir un `[PSCustomObject]`
3. Prueba localmente:
   ```powershell
   . .\init.ps1
   Get-PwsTuModulo  # prueba manual
   ```

### 3. La Prueba de Fuego
```powershell
# Mantén presionada la tecla Enter
# El prompt debe fluir sin tartamudeo
# Si ves parpadeos o congelamiento, necesita optimización
```

### 4. Actualiza configuración (opcional)
Si tu módulo debe aparecer por defecto:
```json
// config/settings.json
{
  "Layout": ["Time", "Duration", "Software", "Path", "Git", "TuModulo"]
}
```

### 5. Commit y Push
```bash
git add modules/sync/tu-modulo.ps1 config/settings.json
git commit -m "feat(tu-modulo): add module for X functionality

- Implement Get-PwsTuModulo with PSCustomObject
- Uses Style system instead of direct ANSI injection
- Includes color-coded output and dynamic icons"

git push origin feature/nuevo-modulo
```

### 6. Abre Pull Request
- Describe tu cambio
- Menciona si rompe compatibilidad
- Adjunta captura de cómo se ve en el prompt

---

## 📊 Checklist para Nuevos Módulos

Antes de enviar tu PR, verifica:

- [ ] El módulo está en `modules/sync/` o `modules/snapshot/`
- [ ] Retorna o usa objecto `[PSCustomObject]@{ Value = "..."; Style = "..." }`
- [ ] Cero uso directo de secuencias ANSI (delega al `renderer.ps1`)
- [ ] Uso exclusivo de variables del `Snapshot` para tareas pesadas
- [ ] Funciones asiladas con nombres correctos (ej: `Get-PwsCosto`)
- [ ] Documentación con `<# .SYNOPSIS .DESCRIPTION .NOTES #>`
- [ ] Probado en Windows 10/11 con PowerShell 7+

---

## 🚀 Principios que Guían el Proyecto

1. **Zero-Exe:** Nada de `git.exe`, `python.exe` en el prompt
2. **Zero-Latency:** El prompt nunca debe esperar
3. **Modular:** Un archivo por funcionalidad
4. **Declarativo:** El layout se define en JSON, no en código
5. **Pre-compilado:** Plan de ejecución en RAM al inicio
6. **Windows 10/11+:** Enfocado en las versiones modernas
7. **PowerShell 7+:** Aprovechando lo mejor del lenguaje

---

¡Gracias por ayudar a construir la terminal más rápida y elegante posible! 🚀⚡

