# Memoria persistente (global, aplica a todos los proyectos)

La memoria global vive en `~/.claude/memory/`. Su índice se carga aquí abajo; cada entrada enlaza a un archivo `.md` con una sola cosa.

@~/.claude/memory/MEMORY.md

## Reglas

- Guarda memoria de forma proactiva, sin esperar a que el usuario lo pida y sin anunciarlo cada vez. Guarda cuando aprendas algo duradero: preferencias o correcciones del usuario, decisiones, contexto de un proyecto que no se pueda sacar del código, problemas conocidos sin resolver, y enfoques que el usuario confirmó.
- No guardes lo que ya está en el repo, el historial de git o un CLAUDE.md, ni lo que solo importa en la conversación actual. Nunca guardes secretos ni credenciales.
- Un hecho por archivo, con frontmatter (`name`, `description`, `metadata.type`: user | feedback | project | reference). Para feedback y project añade **Why:** y **How to apply:**. Enlaza memorias relacionadas con `[[nombre]]`.
- Antes de crear una memoria, mira el índice: si ya existe una sobre lo mismo, actualízala. Si una memoria resulta falsa u obsoleta, corrígela o bórrala.
- Cada vez que crees, renombres o borres una memoria, actualiza `~/.claude/memory/MEMORY.md` (una línea por memoria, sin contenido ahí).
- Al empezar una tarea que dependa de contexto previo, lee los archivos relevantes enlazados desde el índice, no solo el índice. Antes de recomendar algo que una memoria nombra (archivo, función, flag), verifica que sigue existiendo.
- Memorias específicas de un solo proyecto pueden ir en la memoria nativa de ese proyecto; lo que sirva en cualquier proyecto va aquí.
