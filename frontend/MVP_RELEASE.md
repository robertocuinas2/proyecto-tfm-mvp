# Tools4Milk — MVP Candidate Release

> Estado: **Estable para demostración**
> Build: **24/24 páginas** · TypeScript: **0 errores**
> Última revisión: Estabilización MVP (Fase 13+)

---

## ✅ Verificación final de release

| Verificación | Estado |
|---|---|
| TypeScript `--noEmit` | ✅ 0 errores |
| Build producción 24/24 | ✅ Limpio |
| Corrupción UTF-8 visible | ✅ Corregida (solo queda en comentarios, no renderizada) |
| Rutas TV/tablet | ✅ Funcionales |
| Sidebar con permisos visuales | ✅ Correcto |
| Sistema de toasts | ✅ Cobertura completa |
| Tema claro/oscuro separado | ✅ Sin contaminación cruzada |
| Autenticación JWT | ✅ Intacta |
| Links del sidebar | ✅ Todos válidos |

---

## Limitaciones conocidas del MVP

### Funcionalidad pendiente de backend

| Limitación | Workaround actual | Endpoint necesario |
|---|---|---|
| Catálogo de tareas | Se extraen tipos únicos de las tareas cargadas | `GET /tareas-catalogo` |
| Filtro de incidencias por zona/animal (servidor) | Filtrado client-side sobre 100-200 registros | Parámetros `zona_id`, `animal_id` en `GET /incidents` |
| Tendencia diaria de producción real | Se muestra distribución por lactación (no es tendencia temporal) | `GET /lactations/{id}/readings` |
| Gestión de usuarios admin | No implementado | `GET/POST/PUT /users` |
| Vinculación usuario↔empleado real | Modo trabajador local/visual solo | `POST /auth/select-worker` |
| WebSocket/SSE para alertas en tiempo real | Polling (15-60s según tipo de dato) | Endpoint WS del backend |
| Forecast meteorológico real | Muestra lecturas históricas de sensores | AEMET sincronizado via `POST /weather/sync` |
| Exportación PDF del informe | No implementado | N/A (librería frontend) |

### Limitaciones de datos

- **Informe semanal**: Filtra client-side sobre los últimos 100-300 registros. Si hay más datos históricos, el periodo seleccionado puede ser incompleto.
- **Incidencias por zona**: Máximo 100-200 registros cargados; incidencias más antiguas pueden no aparecer en vista de zona.
- **Historial de lecturas de robot**: No hay endpoint de lecturas diarias; los gráficos de tendencia muestran distribución por lactación.

### Limitaciones de permisos

- Los permisos son **visuales** (ocultan enlaces en sidebar). Un usuario con la URL directa puede acceder a páginas admin; la restricción real está en el backend vía JWT.
- El "Modo trabajador local" en `/profile` es experimental: no afecta JWT, solo es visual.

---

## Guía de demostración

### Credenciales de demo

Disponibles en la pantalla de login bajo **"Acceso de demostración"**:

| Usuario | Rol | Contraseña |
|---|---|---|
| `admin` | Administrador (acceso total) | `testpass123` |
| `roberto.castro` | Gestor admin | `testpass123` |
| `operario.zona` | Operario de zona | `testpass123` |
| `laura.fernandez` | Responsable nutrición | `testpass123` |
| `dr.mendez` | Veterinario | `testpass123` |

### Flujo de demo recomendado (15 minutos)

#### 1. Pantalla de login (1 min)
- Mostrar login con reloj en tiempo real
- Seleccionar rol "Gestor / Administrador"
- Click en `admin` en el panel de demo
- Entrar al sistema

#### 2. Dashboard — Vista ejecutiva (2 min)
- Mostrar los 8 KPIs principales
- Destacar los accesos rápidos: "Nueva tarea", "Nueva incidencia", "TV Global"
- Click en "TV Global" para mostrar la pantalla TV

#### 3. TV Global — Vista operativa (2 min)
- Mostrar el tablero fullscreen sin sidebar
- Destacar: alertas críticas, estado de zonas, turno actual
- Volver con el botón "← Gestión"

#### 4. Animales — Ficha de animal (2 min)
- Ir a `/animals`
- Click en cualquier animal
- Mostrar ficha: datos básicos, lactaciones, tratamientos, alertas

#### 5. LeanFarming — Vista operativa (1 min)
- Mostrar tablero de tareas por zona (tema oscuro)
- Destacar el contexto operativo: turno, incidencias, alertas

#### 6. Zones — Modos de zona (2 min)
- Ir a `/zones`
- Click en cualquier zona → modo Gestión (tema claro con maquinaria)
- Cambiar a modo TV (tema oscuro)
- Cambiar a modo Tablet (botones grandes)

#### 7. Informe semanal (1 min)
- Ir a `/report`
- Cambiar periodo a "Últimos 30 días"
- Mostrar secciones de tareas, incidencias, calidad

#### 8. Permisos — Perfil y sidebar (1 min)
- Ir a `/profile`
- Mostrar capacidades agrupadas por rol
- Cerrar sesión y entrar como `operario.zona`
- Mostrar que Audit Log / Integración desaparecen del sidebar

#### 9. Creación rápida — Toast feedback (1 min)
- Ir a `/incidents?new=1`
- Crear una incidencia de prueba
- Mostrar el toast de éxito

#### 10. Dashboard final (1 min)
- Volver al Dashboard
- Mostrar accesos a TV Turnos, Perfil, Informe

---

## Resumen de arquitectura frontend

```
Next.js 16 App Router (TypeScript)
├── Tailwind CSS 4 con tokens app.* (claro) y tv.* (oscuro)
├── TanStack React Query v5 (data fetching + cache)
├── Zustand v5 (auth store + worker store)
├── Sistema de toasts propio (sin dependencias externas)
└── 24 rutas: 20 gestión + 2 TV + 2 tablet/móvil
```

### Roles del sistema
`admin` | `veterinario` | `operario` | `alimentacion`

### Tokens de tema
- Gestión: `app-bg`, `app-surface`, `app-border`, `app-text`, `app-dim`
- TV/Operativo: `tv-bg`, `tv-surface`, `tv-accent`, `tv-dim`
- Semánticos: `state-critica`, `state-atencion`, `state-ok`, `state-info`

---

## Recomendaciones de backend para siguiente sprint

### Prioridad alta (desbloquean funcionalidad visible)

1. **`GET /tareas-catalogo`** — Permite mostrar tipos de tarea reales en el modal de creación.
2. **Filtros `zona_id`/`animal_id` en `GET /incidents`** — Permite filtrado servidor en ficha de zona y animal.
3. **`GET /weather/sync` documentado** — Para que los paneles de meteorología muestren datos reales (AEMET).

### Prioridad media (mejoran experiencia)

4. **`GET/POST /users`** (admin) — Permite gestión real de usuarios.
5. **Vinculación `usuario_id` en empleados** — Permite el modo trabajador real.
6. **`GET /lactations/{id}/readings`** — Permite tendencias reales en gráficos de calidad.

### Prioridad baja (funcionalidad avanzada)

7. **WebSocket/SSE para alertas** — Sustituir polling por eventos push.
8. **`PATCH /animals/{id}/baja`** — Simplificar el flujo de dar de baja animales.
