# Tools4Milk — Estado del Frontend (MVP)

> Última actualización: Fase 13 — Refinamiento y auditoría MVP
> Build: **24/24 páginas** · TypeScript: **0 errores**

---

## Rutas implementadas

| Ruta | Estado | Notas |
|---|---|---|
| `/` | ✅ Login | Mejorado en Fase 7. Clock real. Demo users marcados como dev. |
| `/dashboard` | ✅ Completo | KPIs, gráficos, acciones rápidas, enlaces TV/Informe |
| `/report` | ✅ Completo | Informe semanal con selector de periodo y filtrado client-side |
| `/animals` | ✅ Completo | Filtros, búsqueda, paginación, cards enlazables |
| `/animals/[id]` | ✅ Completo | Ficha con lactaciones, tratamientos, alertas, incidencias |
| `/quality` | ✅ Completo | Calidad de leche con Leche a la Carta, links a animales |
| `/predictions` | ✅ Completo | React Query por animal, stats reactivos |
| `/alerts` | ✅ Completo | Lookup animal legible, acciones de resolución |
| `/incidents` | ✅ Completo | CRUD, filtros client-side, `?new=1` |
| `/orders` | ✅ Completo | Workflow de estados, CRUD, `?new=1` |
| `/tasks` | ✅ Completo | Filtro por zona, creación de tarea, `?new=1` |
| `/shifts` | ✅ Completo | Turnos y asignaciones de empleados |
| `/handover` | ✅ Completo | Listado de relevos con link a tablet |
| `/handover/tablet` | ✅ Completo | Flujo tablet de cambio de turno |
| `/zones` | ✅ Completo | Tema claro, KPIs, maquinaria y incidencias por zona |
| `/zones/[id]` | ✅ Completo | 3 modos: Gestión / TV / Tablet |
| `/leanfarming` | ✅ Completo | Tema oscuro, contexto operativo (turno, alertas, incidencias) |
| `/management` | ✅ Completo | CRUD de 6 entidades con paginación y toasts |
| `/settings` | ✅ Completo | Config de zona (persistida), config local TV/tablet |
| `/integration` | ✅ Admin only | Estado del backend, weather, módulos |
| `/audit-log` | ✅ Admin only | Filtros, expandible, uso de `can("view_audit_log")` |
| `/profile` | ✅ Completo | Capacidades agrupadas, modo trabajador local |
| `/tv` | ✅ Completo | TV global fullscreen, sin sidebar |
| `/tv/shifts` | ✅ Completo | TV turnos con employee lookup real |

---

## Módulos funcionales

### Tema claro (gestión)
Todas las páginas de gestión usan tokens `app.*` definidos en `globals.css`.

### Tema oscuro (TV/operativo)
- `/tv`, `/tv/shifts` — fullscreen sin sidebar
- `/leanfarming` — operativo oscuro mantenido intencionalmente
- `/zones/[id]` modo TV y Tablet — oscuro

### Sistema de toasts
`ToastProvider` global en `AppProviders`. Hook `useToast()` disponible en toda la app.

Cobertura: incidents, orders (crear y cambiar estado), tasks (crear/completar), alerts (resolver), handover (crear relevo), shifts (crear turno/asignación), settings (guardar zona/config local), management (6 entidades).

### Permisos visuales
- Hook `usePermissions()` en `lib/use-permissions.ts`
- Capabilities declaradas en `lib/role-capabilities.ts`
- Sidebar filtra: Gestión (view_management), Configuración (manage_settings), Integración (view_integration), Audit Log (view_audit_log)
- `AccessDenied` component reutilizable

### Modo trabajador local
Store Zustand en `lib/active-worker-store.ts`. **Solo local/visual.** No afecta JWT ni backend.

---

## Módulos pendientes de backend

| Módulo | Estado | Requiere |
|---|---|---|
| Gestión de usuarios | ⏳ Pendiente | `GET/POST /users` backend |
| Vinculación usuario↔empleado | ⏳ Pendiente | `POST /auth/select-worker` backend |
| Tendencia diaria de producción | ⏳ Pendiente | `GET /lactations/{id}/readings` backend |
| Filtro de incidencias por zona/animal (server-side) | ⏳ Pendiente | Parámetros en `GET /incidents` |
| Catálogo de tareas (endpoint propio) | ⏳ Pendiente | `GET /tareas-catalogo` backend |
| WebSocket/SSE para alertas en tiempo real | ⏳ Pendiente | Backend WS |
| Exportación PDF del informe | ⏳ Pendiente | Librería + decidir approach |

---

## Permisos por rol (sistema de auth JWT)

| Capacidad | admin | veterinario | operario | alimentacion |
|---|---|---|---|---|
| Audit Log | ✅ | ❌ | ❌ | ❌ |
| Integración API | ✅ | ❌ | ❌ | ❌ |
| Configuración | ✅ | ❌ | ❌ | ❌ |
| Gestión | ✅ | ✅ | ✅ | ✅ |
| Todos los demás | ✅ | parcial | parcial | parcial |

Ver `lib/role-capabilities.ts` para el mapa completo de capacidades.

---

## Decisiones de diseño importantes

1. **Sidebar filtrado** — Solo las 4 rutas admin se ocultan. Rutas operativas siempre visibles para evitar accidentes.
2. **Filtrado client-side en incidencias** — El endpoint `GET /incidents` no tiene filtros servidor. Se cargan 100-200 y se filtra local.
3. **Catálogo de tareas** — Sin endpoint propio; se extraen tipos únicos de las tareas ya cargadas como workaround.
4. **Tema LeanFarming** — Mantenido oscuro intencionalmente (pantalla operativa de TV/tablet).
5. **Workers locales** — El modo trabajador es experimental y visual solamente.
6. **Forecast meteorológico** — El endpoint devuelve lecturas históricas, no predicción real. Etiquetado como "Datos de sensores locales".

---

## Cómo ejecutar validaciones

```bash
cd frontend
npx tsc --noEmit   # TypeScript check
npm run build       # Build de producción
```

---

## TODOs técnicos importantes en código

- `lib/active-worker-store.ts` — TODO Phase 13: cuando exista `POST /auth/select-worker`
- `app/(app)/profile/page.tsx` — TODO: cuando backend exponga vinculación usuario↔empleado
- `app/(app)/quality/page.tsx` — TODO: tendencia real requiere endpoint de lecturas diarias
- `app/(app)/tasks/page.tsx` — TODO: añadir `GET /tareas-catalogo` cuando exista en backend
- `lib/tv-constants.ts` — TODO: sustituir polling por WebSocket/SSE cuando backend lo soporte

---

## Estructura de directorios relevante

```
src/
├── app/
│   ├── (app)/         # Rutas protegidas (con sidebar)
│   │   ├── layout.tsx # Sidebar con permisos visuales
│   │   ├── dashboard/
│   │   ├── animals/[id]/
│   │   ├── audit-log/
│   │   ├── handover/tablet/
│   │   ├── profile/
│   │   ├── settings/
│   │   └── zones/[id]/
│   ├── tv/             # Rutas TV (sin sidebar, tema oscuro)
│   │   ├── page.tsx    # TV global
│   │   └── shifts/
│   └── page.tsx        # Login
├── components/
│   ├── ui/             # PageHeader, KpiCard, PanelCard, EmptyState, Toast...
│   ├── tv/             # TvShell, TvClock, TvKpiCard, TvPanel, TvRefreshStatus
│   └── common/         # Pagination
├── lib/
│   ├── api.ts          # Cliente API completo
│   ├── types.ts        # Tipos TypeScript
│   ├── role-capabilities.ts  # Sistema de permisos declarativo
│   ├── use-permissions.ts    # Hook de permisos
│   ├── active-worker-store.ts # Store modo trabajador (local)
│   └── tv-constants.ts       # Intervalos de polling TV
└── store/
    └── app-store.ts    # Auth store (Zustand)
```
