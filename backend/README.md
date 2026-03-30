# Backend

## Propósito
Contener la base de backend para autenticación, proyectos, publicación, métricas y assets generados.

## Stack propuesto
- Supabase Auth
- Supabase Postgres
- Supabase Storage
- Supabase Edge Functions

## Responsabilidades
- identidad y perfiles
- persistencia de proyectos
- publicación y slugs
- registro de sesiones y eventos
- assets generados como miniaturas o teaser v0
- feature flags para free y premium

## Estructura sugerida

```text
backend/
├── README.md
└── supabase/
    ├── functions/
    ├── migrations/
    └── seed/
```

## Primera entrega esperada
- esquema inicial de tablas
- policies mínimas
- función de publicación
- función de ingestión de eventos
- función de generación o registro de assets derivados
