# 🤝 Guía de Contribución para PWS

¡Hola! Qué excelente que quieras sumar tu código a este proyecto. PWS está diseñado para ser la herramienta definitiva para la terminal de PowerShell, y toda ayuda para hacerla más poderosa y "ostentosa" es bienvenida.

## 🧠 El Paradigma Principal: La Regla de los 0ms

Al igual que cuando optimizas el manejo de memoria, los punteros o las operaciones a nivel de bits en proyectos críticos de C++, en PWS tenemos una regla de oro inquebrantable: **La función del `prompt` no puede tener lag.**

Cualquier característica nueva que propongas debe renderizarse en 0ms.

* ❌ **Prohibido:** Invocar ejecutables externos (ej. `git.exe`, `python`, `node`, `npm`) directamente dentro de la función `prompt`. Esto genera cuellos de botella.
* ✅ **Permitido:** Utilizar clases nativas de .NET (`[System.IO.File]`), secuencias de escape ANSI directas y lectura de variables globales en la memoria RAM. 
* 💡 **El Truco:** Si necesitas consultar información externa (como la versión de un lenguaje o el estado de un contenedor), debes agregar esa lógica a la función controladora `pws` para que se guarde en la caché (`~/.pws_config.json`) y el prompt simplemente lea el resultado almacenado.

## 🐛 Reporte de Errores (Bugs)

Si encuentras que PWS explota, muestra caracteres extraños o se desconfigura, por favor abre un *Issue* incluyendo:
1. Tu sistema operativo y versión.
2. Tu versión de PowerShell (ejecuta `$PSVersionTable.PSVersion`).
3. El contenido actual de tu archivo de caché `~/.pws_config.json` (oculta cualquier ruta personal si es necesario).
4. Los pasos exactos para reproducir el problema.

## ✨ Sugerencia de Características (Features)

¿Tienes una idea para detectar nuevas tecnologías (Docker, CMake, Rust, Node) o añadir un nuevo módulo visual? ¡Abre un *Issue* para discutirlo! Explica tu idea, cómo beneficiaría al flujo de trabajo y cómo planeas integrarla sin romper el paradigma de latencia cero.

## 🛠️ Entorno de Desarrollo y Pull Requests

Para enviar tu código, sigue estos pasos:

1. Haz un **Fork** del repositorio.
2. Crea una rama descriptiva para tu cambio: `git checkout -b feature/soporte-nodejs` o `fix:correccion-regex-git`.
3. Haz tus modificaciones y pruébalas localmente en tu propio archivo `$PROFILE`. 
   > *Prueba de fuego:* Mantén presionada la tecla `Enter` en tu terminal. El texto debe fluir sin el más mínimo tartamudeo. Si la terminal parpadea o se congela, el código necesita más optimización.
4. Haz **Commit** de tus cambios usando [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/) (ej. `feat: añade detección automática de Go`, `fix: resuelve error cuando la carpeta HEAD no existe`).
5. Haz **Push** a tu rama y abre el **Pull Request**.

¡Gracias por ayudar a construir la terminal más rápida y elegante posible! 🚀
