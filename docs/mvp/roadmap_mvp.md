# Roadmap del MVP

## Fase 0 — Definición operativa y spike técnico

### Objetivo
Cerrar las decisiones que reducen ambigüedad antes de producir contenido y código a escala.

### Entregables
- definición cerrada del vertical slice
- matriz de dispositivos objetivo
- modelo base de proyecto y sesión
- decisión de stack: Godot 5.4.1 + Supabase
- definición del teaser v0

### Gate
Existe un documento de alcance cerrado y una base técnica decidida.

## Fase 1 — Vertical slice jugable

### Objetivo
Validar que el flujo crear -> probar funciona dentro de una única plantilla.

### Alcance
- login básico
- 1 plantilla
- 1 amenaza
- 2 eventos
- 1 objetivo
- 1 final
- playtest local
- guardado de borrador
- instrumentación analítica básica de las features de esta fase (project_created, playtest_started/completed)

### Gate
Un usuario interno puede crear una experiencia simple, ejecutarla y terminarla sin bloqueo crítico.

## Fase 2 — Núcleo de creación del MVP

### Objetivo
Completar el editor guiado y el catálogo mínimo del MVP.

### Alcance
- 3 plantillas iniciales
- 3 amenazas base
- 5 eventos del MVP
- 2 finales
- editor por tabs o capas
- validación de proyecto listo para publicar

### Gate
El creador puede terminar una experiencia funcional sin scripting manual.

## Fase 3 — Publicación y juego compartido

### Objetivo
Cerrar el loop principal del producto.

### Alcance
- publicación con enlace único
- slug estable
- apertura de juego desde enlace
- sesión de juego para jugador anónimo
- pantalla de resultado
- compartir resultado
- instrumentación analítica de las features de esta fase (project_published, game_session_started/completed, ending_reached, result_shared)

### Gate
Una experiencia puede enviarse por chat, abrirse, jugarse y completarse desde otro dispositivo.

## Fase 4 — Métricas, teaser y estabilización

### Objetivo
Preparar el soft launch con instrumentación completa y herramientas de monitoreo.

### Alcance
- panel simple de métricas (agrega eventos analíticos ya capturados desde Fase 1)
- teaser automático v0
- autoguardado robusto
- checklist previa a publicación
- QA funcional y de rendimiento

### Gate
Los eventos clave se registran de forma consistente y no hay bloqueos críticos en dispositivos objetivo.

## Fase 5 — Soft launch

### Objetivo
Lanzar una cohorte pequeña y medir comportamiento real.

### Alcance
- onboarding controlado
- cohortes iniciales de creadores y jugadores
- seguimiento de funnels diarios
- priorización de incidencias de producción

### Gate
Hay proyectos publicados que generan al menos 3 partidas únicas en 7 días.
