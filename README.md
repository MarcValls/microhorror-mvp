# microhorror-mvp

Repositorio de trabajo para el MVP de una plataforma móvil de microexperiencias de terror en primera persona.

## Objetivo del repositorio

Aterrizar el PRD en un plan ejecutable y una estructura base de producto, cliente y backend orientada a validar este loop:

crear -> publicar -> jugar -> compartir

## Decisión de alcance del MVP

El MVP no busca resolver comunidad profunda ni herramientas avanzadas de creación. Se centra en una prueba concreta:

- un creador puede construir una experiencia breve desde una plantilla cerrada
- puede publicarla con un enlace compartible
- otras personas pueden jugarla y completar una sesión real
- el sistema captura métricas suficientes para validar uso y repetición

## Estructura inicial

```text
.
├── README.md
├── .editorconfig
├── .gitignore
├── apps/
│   └── client_godot/
├── backend/
│   └── supabase/
├── content/
├── docs/
│   ├── architecture/
│   ├── mvp/
│   └── product/
└── planning/
```

## Documentos clave

- `docs/product/scope_mvp.md`: alcance cerrado del MVP
- `docs/mvp/roadmap_mvp.md`: fases, hitos y gates
- `docs/mvp/backlog_p0.md`: backlog prioritario de implementación
- `docs/mvp/acceptance_criteria.md`: definición de terminado
- `docs/architecture/system_overview.md`: arquitectura de alto nivel
- `docs/architecture/data_model.md`: entidades principales
- `docs/architecture/analytics_events.md`: instrumentación del producto
- `planning/sprint_01.md`: primer sprint recomendado

## Stack propuesto

- Cliente: Godot 5.4.1
- Backend: Supabase
- Contenido: configuración data-driven
- Distribución inicial: app móvil con publicación por enlace

## Orden recomendado de ejecución

1. vertical slice jugable
2. creación guiada completa del MVP
3. publicación compartible
4. juego real desde enlace
5. teaser básico y métricas
6. soft launch

## Estado

Bootstrap inicial del repositorio completado con documentación de producto y arquitectura.
