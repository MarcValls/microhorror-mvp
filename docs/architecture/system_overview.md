# System overview

## Arquitectura propuesta

### Cliente
- Godot 5.4.1 como cliente principal para runtime 3D y editor jugable
- interfaz de edición basada en presets, sliders, toggles y selectores
- playtest integrado desde el proyecto

### Backend
- Supabase para auth, base de datos, storage y funciones ligeras
- tablas orientadas a proyectos, sesiones, assets generados y perfiles
- feature flags para límites de planes

### Contenido
- catálogo data-driven de plantillas, amenazas, eventos, finales y presets visuales
- separación clara entre definiciones de contenido y proyectos creados por usuarios

### Publicación
- cada proyecto publicado genera un slug o identificador estable
- el enlace resuelve a una vista ligera que abre la experiencia en la app

### Analítica
- instrumentación desde día uno para eventos de activación, publicación y consumo
- agregados simples por proyecto y por creador

## Principios técnicos
- plantillas cerradas antes que libertad total
- bajo coste de producción por nueva plantilla
- optimización agresiva para móvil medio
- configuración por datos para evitar lógica manual por proyecto
- backend delgado y fácilmente observable

## Decisiones iniciales
- no gameplay web completo en fase MVP
- no importación libre de assets
- no editor espacial libre
- no comunidad profunda hasta validar el loop principal
