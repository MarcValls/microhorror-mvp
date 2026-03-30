# Cliente Unity

## Propósito
Contener el runtime 3D del juego y el editor jugable del MVP.

## Alcance inicial
- shell de aplicación móvil
- navegación principal
- selector de plantilla
- editor por capas
- playtest local
- runtime de sesión
- pantalla final de resultado

## Estructura sugerida

```text
apps/client_unity/
├── README.md
├── Assets/
│   ├── Art/
│   ├── Audio/
│   ├── Prefabs/
│   ├── Scenes/
│   ├── Scripts/
│   ├── ScriptableObjects/
│   └── UI/
├── Packages/
└── ProjectSettings/
```

## Reglas iniciales
- priorizar ScriptableObjects y configuración por datos
- evitar lógica específica por plantilla dentro del runtime común
- mantener el editor como sistema de presets y módulos, no como editor libre
- medir rendimiento en dispositivos medios desde el primer vertical slice
