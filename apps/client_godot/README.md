# Cliente Godot 4.5

## Propósito

Contener el runtime 3D del juego y el editor jugable del MVP, usando Godot 4.5 como motor.

## Versión del motor

- **Godot 4.5** (GDScript)
- Exportación objetivo: Android (móvil medio)

## Alcance inicial

- shell de aplicación móvil
- navegación principal (SceneTree + autoload)
- selector de plantilla
- editor por capas
- playtest local
- runtime de sesión en primera persona
- pantalla final de resultado

## Estructura sugerida

```text
apps/client_godot/
├── README.md
├── project.godot
├── export_presets.cfg
├── .gdignore (para carpetas excluidas del import)
├── assets/
│   ├── art/
│   ├── audio/
│   └── fonts/
├── scenes/
│   ├── main_menu/
│   ├── editor/
│   ├── runtime/
│   └── ui/
├── scripts/
│   ├── autoloads/
│   ├── editor/
│   ├── runtime/
│   └── data/
└── resources/
    ├── templates/
    ├── threats/
    ├── events/
    └── atmosphere/
```

## Convenciones de código

- GDScript como lenguaje principal
- `snake_case` para variables, funciones y nombres de archivo
- `PascalCase` para nombres de nodo y clase
- Resources (`@export`) para configuración data-driven en lugar de lógica hardcodeada
- Autoloads para servicios globales: `GameState`, `BackendClient`, `EventBus`

## Reglas iniciales

- priorizar Resources y configuración por datos (equivalente a ScriptableObjects)
- evitar lógica específica por plantilla dentro del runtime común
- mantener el editor como sistema de presets y módulos, no como editor libre
- medir rendimiento en dispositivos medios desde el primer vertical slice

## Validación manual

- usa `docs/workflows/godot_analytics_validation_checklist.md` para validar instrumentación de playtest y sesión real después de cambios en analytics, runtime o EventBus

