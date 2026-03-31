# Supabase Asset Audit

## Objetivo

Clasificar los assets de `backend/supabase/` que hoy están fuera del rollout oficial de staging para decidir si deben rescatarse, migrarse al baseline actual o retirarse como candidatos de despliegue.

## Criterio de clasificación

- Rescatar: puede entrar en el baseline actual con cambios menores y sin abrir deriva arquitectónica.
- Migrar: la idea sigue siendo útil, pero el asset actual no es compatible con el esquema, secretos o contratos vigentes.
- Retirar: no debe formar parte del rollout actual y debe tratarse como legado o referencia histórica hasta abrir una tarea específica.

## Resumen ejecutivo

- Rescatar ahora: ninguno.
- Migrar en una tarea futura: `migrations/002_generated_asset_unique.sql`, `functions/generate_asset/`.
- Retirar como candidatos del rollout actual: `migrations/001_initial_schema.sql`, `seed/catalog.sql`, `legacy/functions/ingest_event/`.

La razón principal es que los assets excluidos no comparten el mismo contrato que `migrations/20260331_0001_init_schema.sql`, que hoy define el baseline oficial de staging.

## Clasificación detallada

### `backend/supabase/migrations/001_initial_schema.sql`

Clasificación: retirar.

Motivos:

- usa tablas singulares como `project`, `play_session`, `generated_asset`, `feature_entitlement` y `analytics_event`, mientras el baseline actual usa tablas plurales.
- modela referencias de catálogo por UUID y tablas en base de datos como `template_definition`, `threat_definition`, `event_definition`, `ending_definition` y `atmosphere_preset`, mientras el baseline actual usa identificadores textuales y el contenido del MVP vive principalmente en `content/` y `apps/client_godot/resources/`.
- introduce enums, RLS y nombres de tablas incompatibles con las functions y validaciones del rollout oficial actual.

Decisión:

- no incluir en staging ni reaplicar como migración incremental.
- conservar solo como referencia histórica hasta abrir una tarea explícita de convergencia o eliminación.

### `backend/supabase/migrations/002_generated_asset_unique.sql`

Clasificación: migrar.

Motivos:

- la intención sigue siendo válida: evitar duplicados por proyecto y tipo de asset.
- el asset actual apunta a `public.generated_asset`, pero el baseline actual usa `public.generated_assets`.
- también depende de una futura alineación del contrato de tipos de asset y de la función `generate_asset`.

Decisión:

- no aplicar tal cual.
- rescatar la intención en una migración nueva sobre `public.generated_assets` solo cuando exista una tarea activa para generación de teaser o thumbnails.

### `backend/supabase/seed/catalog.sql`

Clasificación: retirar.

Motivos:

- depende de tablas de catálogo creadas por `001_initial_schema.sql`, que no existen en el baseline actual.
- mezcla una estrategia de catálogos en base de datos con una estrategia actual basada en archivos versionados en `content/`.
- algunos identificadores y contratos no coinciden limpiamente con el estado actual del repo, lo que haría inseguro cargarlo en staging por defecto.

Decisión:

- no incluir en el rollout oficial.
- conservar solo como referencia de modelado de catálogos si en el futuro se decide mover contenido desde archivos a Supabase.

### `backend/supabase/functions/generate_asset/`

Clasificación: migrar.

Motivos:

- la capability sigue siendo compatible con el MVP como teaser o miniatura, pero no es parte del baseline actual de staging.
- la function requiere `SUPABASE_SERVICE_ROLE_KEY`, secreto que el rollout oficial actual no publica.
- consulta tablas singulares `project` y `generated_asset`, incompatibles con el esquema vigente.
- usa tipos de asset `thumbnail`, `teaser_video` y `cover`, mientras el baseline actual usa `teaser`, `thumbnail_square`, `thumbnail_vertical` y `other`.

Decisión:

- no desplegar en staging actual.
- migrar solo dentro de una tarea específica que alinee secretos, nombres de tabla y contrato de `generated_assets`.

### `backend/supabase/legacy/functions/ingest_event/`

Clasificación: retirar.

Motivos:

- resuelve una necesidad real: ingestión de eventos con allow-list y soporte batch.
- hoy duplica la responsabilidad de `functions/ingest_analytics/`, que ya forma parte del rollout oficial.
- depende de `SUPABASE_SERVICE_ROLE_KEY`, secreto ausente del flujo oficial.
- escribe en `analytics_event`, mientras el baseline actual usa `analytics_events` y canaliza la persistencia vía `log_analytics_event`.
- la allow-list y el soporte batch ya fueron migrados al contrato oficial de `functions/ingest_analytics/`.

Decisión:

- no desplegar como function paralela en el baseline actual.
- conservarla solo en `backend/supabase/legacy/functions/ingest_event/` como referencia histórica.

## Recomendación operativa

Para el estado actual del MVP:

1. mantener `20260331_0001_init_schema.sql`, `seed/seed.sql`, `publish_project` e `ingest_analytics` como único baseline oficial de staging.
2. no promover ninguno de los assets excluidos al rollout sin una tarea de convergencia dedicada.
3. tratar `001_initial_schema.sql` y `catalog.sql` como legado documental, no como fuente operativa.
4. tratar `002_generated_asset_unique.sql` y `generate_asset/` como candidatos de migración puntual si reaparece una necesidad de producto o backend respaldada por alcance MVP.

## Próximas tareas recomendadas

1. abrir una tarea de limpieza para mover los assets retirados a una carpeta de legado o eliminarlos si ya no aportan valor.
2. abrir una tarea separada si se quiere recuperar generación de assets, creando una migración y una function nuevas compatibles con `generated_assets`.
3. si se quiere seguir reduciendo ruido del repo, evaluar eliminar `legacy/functions/ingest_event/` una vez quede suficientemente cubierta la referencia histórica en documentación.
