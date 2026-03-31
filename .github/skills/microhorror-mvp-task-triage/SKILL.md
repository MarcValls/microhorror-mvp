---
name: microhorror-mvp-task-triage
description: 'Clasifica y encuadra tareas para microhorror-mvp. Use when a request needs MVP scope check, loop impact analysis, agent routing, affected paths, docs updates, or a concrete task brief before implementation.'
argument-hint: 'Describe la tarea o cambio que quieres encuadrar dentro del MVP'
user-invocable: true
---

# Microhorror MVP Task Triage

## Qué resuelve

Convierte una petición ambigua o amplia en una tarea ejecutable para este repositorio sin romper el alcance del MVP y deja preparado el handoff al especialista correcto.

La skill ayuda a:

- comprobar si la petición ya existe total o parcialmente en docs o código
- clasificar si la petición es P0, P1, post-MVP o fuera de alcance
- identificar la fase del loop impactada: crear, publicar, jugar o compartir
- enrutar la tarea al agente o dominio correcto
- delimitar rutas afectadas y contratos que pueden cambiar
- decidir qué documentación debe actualizarse en la misma tarea
- producir un brief accionable antes de implementar
- preparar un handoff claro cuando la ejecución deba pasar a otro agente

## Cuándo usarla

Usa esta skill cuando:

- la tarea toca varias áreas o no está claro por dónde empezar
- quieres validar si una idea respeta el alcance del MVP
- necesitas decidir entre orchestrator, product, Godot, Supabase backend, Supabase deployment o content
- quieres transformar una petición en un task brief concreto
- quieres transformar una petición en un task brief concreto y derivarla con contexto suficiente
- hay riesgo de cambiar contratos entre docs, cliente, backend o contenido data-driven

No la uses para:

- cambios pequeños y obvios confinados a un único archivo
- una implementación ya perfectamente definida con rutas y agente claros

## Procedimiento

1. Resume la petición en una frase operativa.

2. Verifica el estado actual antes de encuadrar la tarea.
   - Revisa backlog, docs y código para confirmar si la capacidad ya existe, está parcial, duplicada o contradice el contrato actual.
   - Si ya existe parcialmente, reformula la tarea como gap, bug, alineación de contrato o validación pendiente.

3. Comprueba el encaje con el MVP.
   - Mantén el foco en el loop crear -> publicar -> jugar -> compartir.
   - Rechaza o difiere ideas de motor generalista, editor espacial libre, scripting arbitrario, gameplay web completo o comunidad profunda.

4. Clasifica la prioridad.
   - P0: desbloquea creación guiada, playtest, publicación por enlace, apertura desde enlace, sesión jugable o analítica básica.
   - P1: mejora el loop ya validado sin ser prerequisito inmediato.
   - Post-MVP: añade amplitud, social profundo, tooling abierto o complejidad no necesaria para validar la hipótesis.

5. Marca la fase principal del loop.
   - Creación
   - Publicación
   - Juego
   - Compartir

6. Enruta al dominio dominante.
   - Orchestrator: tarea ambigua, transversal o con contratos entre áreas.
   - Product scope guardian: dudas de alcance, prioridad, acceptance criteria o roadmap.
   - Godot client: escenas, scripts, UX de creación guiada, runtime, playtest o hooks de analítica en cliente.
   - Supabase backend: schema, migraciones, RLS, functions, publication flow o contratos backend.
   - Supabase deployment: rollout remoto, secretos, scripts, apply de migraciones y validación post-deploy.
   - Content: templates, threats, events, endings, presets y payloads restringidos.

7. Identifica rutas afectadas.
   - Cliente: apps/client_godot/
   - Backend: backend/supabase/migrations/, backend/supabase/functions/, backend/supabase/seed/
   - Deployment: backend/supabase/scripts/, backend/supabase/.env.example, docs/workflows/supabase_deployment_runbook.md, Makefile
   - Content: content/
   - Arquitectura y producto: docs/

8. Detecta cambios de contrato y documentación obligatoria.
   - Actualiza docs si cambia un data model, payload, state machine, evento analítico, flujo de usuario, convención arquitectónica o paso de despliegue.
   - Los destinos más probables son:
     - docs/architecture/data_model.md
     - docs/architecture/analytics_events.md
     - docs/architecture/system_overview.md
     - docs/product/scope_mvp.md
     - docs/product/user_flows.md
     - docs/mvp/acceptance_criteria.md
     - docs/workflows/supabase_deployment_runbook.md
     - backend/supabase/README.md

9. Produce la salida con esta estructura.
   - Contexto
   - Análisis
   - Cambios o propuesta
   - Riesgos o validaciones
   - Conclusión

10. Si la tarea debe pasar a otro agente, prepara el handoff.
   - Usa como base docs/workflows/task_brief_template.md para encuadrar la tarea.
   - Usa como base docs/workflows/handoff_template.md para entregar al agente destino.
   - El handoff debe incluir prioridad, dominio, agente destino, rutas afectadas, acción solicitada, resultado esperado y validaciones.

## Plantilla de salida

### Contexto

- Petición resumida:
- Hipótesis MVP afectada:
- Fase del loop principal:

### Análisis

- Estado actual: no existe, parcial, duplicado o desalineado
- Clasificación: P0, P1, post-MVP o rechazo
- Dominio principal:
- Rutas afectadas:
- Dependencias o supuestos:

### Cambios o propuesta

- Entregable mínimo que mueve el MVP
- Qué se incluye ahora
- Qué se excluye explícitamente
- Documentación a actualizar si aplica

### Riesgos o validaciones

- Riesgo principal de alcance
- Validaciones técnicas necesarias
- Señales de que la tarea quedó demasiado grande

### Conclusión

- Recomendación final en una o dos frases

## Plantilla de handoff

## Resumen de la tarea

- Objetivo operativo:

## Clasificación

- Prioridad:
- Dominio principal:
- Agente destino:

## Documentación y referencias

- README.md
- docs/product/scope_mvp.md
- docs/architecture/system_overview.md
- Otras rutas específicas según el dominio

## Entradas entregadas

- Alcance definido
- Rutas afectadas identificadas
- Riesgos principales anotados
- Dependencias técnicas o funcionales anotadas

## Acción solicitada

- Qué debe resolver exactamente el agente destino

## Resultado esperado

- Qué condición observable define que la tarea quedó resuelta

## Riesgos y validaciones

- Riesgos principales
- Validaciones mínimas

## Reglas de decisión

- Prefiere siempre el cambio más pequeño que preserve arquitectura data-driven.
- Si la capacidad ya existe, no abras una tarea de implementación nueva; abre una de corrección, consolidación o validación.
- Si una tarea mezcla implementación y decisión de producto, decide primero el encuadre de producto.
- Si deployment y backend aparecen juntos, usa deployment solo si el trabajo dominante es rollout; si cambia schema o contratos, backend manda.
- Si una propuesta exige tocar docs y código para mantener coherencia, ambas partes forman parte de la misma tarea.
- Si el siguiente paso depende de otro agente, no transfieras una petición vaga; transfiere una tarea ya acotada.

## Criterios de completitud

Considera la tarea bien encuadrada cuando queden explícitos:

- prioridad y fase del loop
- agente o dominio principal
- rutas afectadas
- inclusiones y exclusiones
- docs a revisar
- handoff listo si cambia de agente
- validaciones mínimas antes de cerrar