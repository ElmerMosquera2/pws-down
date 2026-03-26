# PWS: El Prompt Definitivo de Latencia Cero para PowerShell ⚡

PWS es una configuración avanzada para el prompt de PowerShell diseñada bajo una regla de oro estricta: **Latencia Cero (0ms) al presionar Enter**. 

Ofrece una interfaz rica y "ostentosa" sin sacrificar rendimiento. Almacena su configuración localmente para que PowerShell vuele mientras mantienes todo el control.

---

## ⚙️ Instalación

1. Abre tu terminal de PowerShell.
2. Ejecuta `notepad $PROFILE`.
3. Pega el código completo del `script/configuration.pws.txt` y guarda el archivo.
4. Recarga la configuración escribiendo: `. $PROFILE`.

---

## 🛠️ Guía de Comandos (CLI)

### 🔄 Escaneo de Software
| Comando | Descripción |
| :--- | :--- |
| `pws -u` / `pws --update` | Escanea el sistema en busca de versiones de software (ej. Python, g++) y actualiza la caché local al instante. |

### 🚀 Control de Módulos (Activar / Desactivar)
Usa `-a` (`--activate`) para encender características o `-d` (`--disable`) para apagarlas selectivamente.

| Comando de Activación | Comando de Desactivación | Qué hace |
| :--- | :--- | :--- |
| `pws -a -o` (Ostentoso) | N/A | **Enciende todo.** (Modo global). |
| `pws -a -m` (Minimalista)| N/A | **Apaga todo.** Solo muestra ruta, usuario y Git. |
| `pws -a -l` (`--locals`) | `pws -d -l` | Reloj en tiempo real y cronómetro del último comando. |
| `pws -a -i` (`--installs`)| `pws -d -i` | Muestra las versiones de tus lenguajes en caché. |
| `pws -a -AU` (`--AutoUpdate`)| `pws -d -AU` | Actualiza la caché en segundo plano al iniciar PS. |

*(Nota: Al activar o desactivar un módulo con `-l` o `-i`, el prompt pasará automáticamente a modo "Custom").*

### 💾 Gestión de Perfiles (Config)
PWS te permite guardar tu combinación favorita de módulos como predeterminada, para que siempre puedas regresar a ella si "rompes" o cambias temporalmente tu configuración. Usa el comando `-c` (`--config`).

| Comando | Sintaxis Alternativa | Descripción |
| :--- | :--- | :--- |
| `pws -c -ap` | `pws --config --actually--push` | **Fijar Actual:** Toma tu configuración actual (ej. Solo activaste `-l` y `-AU`) y la guarda como tu nuevo estado predeterminado. |
| `pws -c -dp` | `pws --config --default--push` | **Restaurar:** Borra los cambios temporales y restaura el prompt al estado que guardaste con `-ap`. (Si nunca guardaste uno, restaura los valores de fábrica). |

---

## 💡 Ejemplos de Flujo de Trabajo

**1. Crear tu setup perfecto y fijarlo:**
> `pws -a -m` (Empiezas limpio)
> `pws -a -l` (Añades cronómetro)
> `pws -a -AU` (Añades escaneo silencioso al inicio)
> `pws -c -ap` (¡Boom! Guardado como tu estado predeterminado)

**2. Una sesión rápida "Ostentosa" temporal:**
> `pws -a -o` (Enciendes todo para presumir o depurar rápido)
> *...trabajas un rato...*
> `pws -c -dp` (Regresas a tu configuración perfecta guardada en el paso 1)

---

## 🎨 Leyenda Visual
* 🟢 **Verde Claro:** Usuario
* 🔵 **Cian Claro:** Ruta actual (`~` = Home)
* 🟡 **Amarillo:** Rama de Git actual
* ⚡ **Rayo:** El comando tomó ms
* ⏱️ **Reloj Naranja:** El comando tomó > 1s
