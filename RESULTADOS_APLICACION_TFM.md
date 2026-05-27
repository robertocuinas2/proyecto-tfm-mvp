# Resultados tecnicos de la aplicacion Tools4 Milk /

## 1. Introduccion al desarrollo realizado

El proyecto analizado corresponde al desarrollo de una aplicacion web orientada a la gestion operativa y al apoyo a la toma de decisiones en una explotacion ganadera de leche. La aplicacion aparece denominada en el repositorio como **Tools4 Milk**. Su finalidad es centralizar informacion relevante de una granja lechera y ofrecer una interfaz digital que sustituya parcialmente registros manuales, pizarras fisicas y sistemas de informacion dispersos.

A partir del codigo existente se ha construido un **MVP o prototipo funcional** con tres bloques tecnicos principales:

| Bloque | Implementacion real observada | Funcion |
|------------------------|------------------------|------------------------|
| Backend | Aplicacion FastAPI en `backend/app/main.py` | Expone API REST, autenticacion JWT con RBAC, datos semilla, meteorologia y endpoints consumidos por el frontend. |
| Frontend | Aplicacion Next.js en `frontend/src/app` | Presenta pantallas de login, dashboard, animales, tareas, alertas, zonas, LeanFarming, calidad, predicciones y gestion de datos maestros. |
| Base de datos | SQLAlchemy con SQLite por defecto y PostgreSQL en Docker | Persiste usuarios, datos meteorologicos y los dominios ganaderos principales: animales, zonas, tareas, alertas, incidencias, lactaciones, tratamientos, empleados y maquinaria. |

El sistema responde al objetivo general del TFM: construir una base tecnica para un sistema digital de apoyo a la decision en granjas lecheras. No obstante, el codigo muestra que la implementacion actual no alcanza todavia toda la arquitectura teorica descrita en el documento del TFM. El prototipo permite demostrar el flujo de uso, la estructura visual, el contrato API-frontend y algunos mecanismos de autenticacion y persistencia, pero varias piezas quedan simuladas, preparadas documentalmente o pendientes de integracion.

El repositorio incluye tambien documentacion tecnica (`README.md`, `IMPLEMENTATION_GUIDE.md`, `FRONTEND_UPDATE_SUMMARY.md`, `COMPLETION_STATUS.md`, `FINAL_CLEANUP_REPORT.md`) que describe una vision mas ambiciosa del sistema. Para este documento se ha priorizado el codigo real por encima de afirmaciones genericas de documentacion, especialmente cuando existe discrepancia entre ambos.

## 2. Relacion entre el planteamiento teorico y la implementacion real

El PDF del TFM plantea una plataforma DSS amplia, con integracion de fuentes heterogeneas, arquitectura de datos poliglota, microservicios, modelos predictivos, pantallas por zona y conectores con sistemas externos como robots DeLaval, AEMET, LIGAL, OVGAN/CEGACOL, ABS, carro TMR y amamantadora automatica. El repositorio implementa una version reducida y demostrativa de esa propuesta.

| Elemento planteado inicialmente | Implementacion actual en el repositorio | Estado | Observaciones |
|------------------|------------------|------------------|------------------|
| Plataforma DSS para explotaciones lecheras | Aplicacion web con dashboard, gestion visual por zonas, tareas, alertas, animales, calidad y predicciones | Implementado parcialmente | Existe flujo frontend-backend funcional, pero con datos de demo y sin integracion completa de fuentes reales. |
| Backend de APIs REST documentadas | FastAPI con routers `auth`, `assistant`, `frontend_core`, `simulation` y `weather`; Swagger en `/docs` | Implementado | La API existe y cubre endpoints internos principales para el frontend. No se han implementado los grupos teoricos `/ingest`, `/data`, `/analytics` y `/dss` como microservicios separados. |
| Arquitectura de microservicios | Una unica aplicacion FastAPI monolitica | Pendiente para futuras versiones | El PDF plantea cuatro microservicios; el codigo actual centraliza todo en una sola API. |
| Persistencia relacional de datos maestros | Modelos SQLAlchemy activos: `Usuario`, `DatosMetereologicos` y modelos `Core*` para animales, zonas, tareas, alertas, incidencias, lactaciones, tratamientos, empleados y maquinaria | Implementado | Los dominios ganaderos principales tienen modelos ORM activos en `backend/app/models/frontend_core.py` y se persisten en BD desde el arranque mediante `ensure_frontend_seed_data()`. |
| PostgreSQL y TimescaleDB | Docker Compose usa PostgreSQL 15; configuracion local por defecto usa SQLite | Implementado parcialmente | PostgreSQL esta preparado para entorno Docker. No se observa uso real de TimescaleDB ni hypertables en el codigo activo. |
| Series temporales de robots, collares, ambiente, TMR y amamantadora | No hay modelos ni endpoints de ingesta para esas fuentes | Pendiente de integracion | La migracion `001_add_performance_indexes.sql` menciona tablas esperadas, pero no define el esquema completo ni esta conectada a modelos activos. |
| Datos meteorologicos AEMET | Modelo `DatosMetereologicos`, router `weather` y servicio `aemet_client` | Simulado / preparado parcialmente | El cliente no consulta la API real; genera registros sinteticos para Villalba, Lugo y los guarda en BD. |
| Autenticacion de usuarios | JWT con `python-jose`, hash de password con `passlib` y usuario demo `admin` | Implementado | Hay login, `me` y refresh. Roles en frontend son seleccionados por UI y no se validan realmente en backend. |
| Gestion de animales | Pantalla `/animals`, pantalla `/management` y endpoints CRUD `/api/v1/animals` | Implementado con persistencia real | Los animales se almacenan en la tabla `core_animals` mediante el modelo ORM `CoreAnimal`, semill a partir de `demo_data.py`. Se pueden crear y actualizar via API. |
| Gestion de zonas | Pantallas `/zones` y `/zones/[id]`, pantalla `/management`, endpoints CRUD de zonas | Implementado con persistencia real | Las zonas se almacenan en la tabla `core_zones`. `POST /zones` y `PUT /zones/{id}` persisten en BD. |
| Gestion de tareas y LeanFarming | Pantallas `/tasks`, `/leanfarming`, modo TV/tablet por zona; endpoints CRUD de tareas | Implementado con persistencia real | Las tareas se almacenan en `core_tasks`. Se puede listar, crear, completar y actualizar; los cambios son persistentes. |
| Incidencias | Formulario de nueva incidencia en modo tablet y endpoints `/incidents` | Implementado con persistencia real | Las incidencias tienen modelo ORM `CoreIncident` con tabla `core_incidents`. Crear incidencia persiste en BD. |
| Alertas multinivel | Pantalla `/alerts`, endpoints de creacion y revision de alertas | Implementado con persistencia real | Las alertas tienen modelo ORM `CoreAlert` con tabla `core_alerts`. Se persisten en BD y pueden simularse mediante el router `simulation`. |
| Predicciones de produccion, composicion y riesgo sanitario | Endpoint `/predictions/{animal_id}` y pantalla `/predictions` | Simulado | El endpoint devuelve valores fijos o demostrativos e incluye `_mock: true`. No hay entrenamiento ni modelos ML reales. |
| Modulo de calidad de leche y leche a la carta | Pantalla `/quality` con composicion, indicadores y graficos | Simulado en frontend | Consume animales del backend, pero los indicadores de calidad se calculan en el cliente con funciones deterministas y valores mock. |
| Integracion con robots DeLaval VMS | No existe conector real | Pendiente de integracion | El PDF lo plantea como fuente principal, pero no hay cliente, credenciales, endpoints ni modelos activos. |
| Integracion con LIGAL, ABS, OVGAN/CEGACOL, SERAGRO | No existe codigo de integracion | Pendiente de integracion | Solo aparece en planteamiento teorico/documental, no en codigo ejecutable. |
| Redis cache para dashboards | Docker Compose incluye Redis y hay scripts de monitorizacion | Preparado estructuralmente | No se observa uso de Redis en los routers activos; solo configuracion y scripts auxiliares. |
| Alembic y migraciones controladas | Existe carpeta `migrations` con un SQL manual de indices | Implementado parcialmente | No hay configuracion Alembic visible. La migracion referencia tablas no creadas por el ORM actual. |
| PWA offline-first | No se observa configuracion PWA/offline en Next.js | Pendiente | El PDF lo plantea, pero el frontend no incluye service worker ni manifest PWA especifico. |
| Validacion con usuarios reales | No hay evidencias en codigo | No determinado / pendiente | Puede haberse realizado fuera del repositorio, pero no es verificable desde el codigo. |

La comparacion muestra que el resultado obtenido es coherente con una fase de MVP: se ha materializado una base funcional para navegar, consultar y operar sobre entidades clave, pero la integracion real de datos, los modelos predictivos y la arquitectura avanzada permanecen como lineas de evolucion.

## 3. Arquitectura general de la aplicacion

La arquitectura real del repositorio es una aplicacion web de tipo cliente-servidor, con un backend FastAPI, un frontend Next.js y una base de datos SQL accesible mediante SQLAlchemy.

Esquema simplificado:

``` text
Usuario
  -> Frontend Next.js
      -> cliente API en frontend/src/lib/api.ts
          -> Backend FastAPI
              -> SQLAlchemy Session
                  -> SQLite local o PostgreSQL en Docker
                      -> tablas core_* (animales, zonas, tareas, alertas...)
                      -> tablas usuarios y datos_metereologicos
              -> servicio meteorologico sintetico
```

Esquema con despliegue Docker:

``` text
Navegador
  -> Nginx :80
      -> /api, /health, /docs, /redoc -> backend FastAPI :8000
      -> resto de rutas -> frontend Next.js :3000
  -> PostgreSQL 15
  -> Redis 7
```

### Backend

El backend se ubica en `backend/app`. Su punto de entrada es `backend/app/main.py`, donde se crea la instancia FastAPI, se configuran CORS, se instalan metadatos OpenAPI y se registran los routers:

- `app.routers.auth`
- `app.routers.assistant`
- `app.routers.frontend_core`
- `app.routers.simulation`
- `app.routers.weather`

Durante el ciclo de vida de la aplicacion, `lifespan()` ejecuta:

1. `validate_production_config()`: valida que la configuracion sea segura si el entorno es `production`.
2. `Base.metadata.create_all(bind=engine)`: crea las tablas ORM si no existen.
3. `ensure_runtime_schema()`: aplica migraciones de columnas en caliente (campo `role` y `debe_cambiar_contrasena` en `usuarios`).
4. `seed_demo_user()`: siembra cinco usuarios demo si no existen.
5. `seed_frontend_data()`: llama a `ensure_frontend_seed_data()` que puebla las tablas `core_*` con los datos de `demo_data.py` si estan vacias.

### Frontend

El frontend se ubica en `frontend/src`. Utiliza el App Router de Next.js:

- `frontend/src/app/page.tsx`: pantalla de login.
- `frontend/src/app/(app)/dashboard/page.tsx`: dashboard operativo.
- `frontend/src/app/(app)/animals/page.tsx`: listado de animales.
- `frontend/src/app/(app)/tasks/page.tsx`: tareas.
- `frontend/src/app/(app)/alerts/page.tsx`: alertas.
- `frontend/src/app/(app)/zones/page.tsx`: zonas.
- `frontend/src/app/(app)/zones/[id]/page.tsx`: detalle de zona con modo TV/tablet.
- `frontend/src/app/(app)/quality/page.tsx`: calidad de leche.
- `frontend/src/app/(app)/predictions/page.tsx`: predicciones.
- `frontend/src/app/(app)/leanfarming/page.tsx`: tablero LeanFarming.
- `frontend/src/app/(app)/management/page.tsx`: gestion de datos maestros (animales, zonas, lactaciones, tratamientos, empleados, maquinaria).

La comunicacion con el backend se centraliza en `frontend/src/lib/api.ts`, que construye peticiones HTTP hacia `API_BASE_URL` y `API_V1_URL`.

### Base de datos

La configuracion de base de datos reside en `backend/app/database.py`. Se utiliza SQLAlchemy 2 con `create_engine`, `SessionLocal` y una clase base declarativa `Base`. El archivo `backend/app/config.py` define `database_url` con valor por defecto `sqlite:///./tfm_mvp.db`, mientras que `docker-compose.yml` inyecta `postgresql+psycopg://postgres:password@db:5432/tfm_mvp`.

### Separacion de responsabilidades

| Capa | Responsabilidad | Ficheros principales |
|------------------------|------------------------|------------------------|
| Configuracion | Variables de entorno, CORS, credenciales y parametros de servicios | `backend/app/config.py`, `frontend/src/lib/config.ts`, `docker-compose.yml` |
| API backend | Rutas REST y contratos de respuesta | `backend/app/routers/*.py`, `backend/app/schemas/api.py` |
| Persistencia | Conexion SQLAlchemy y modelos activos | `backend/app/database.py`, `backend/app/models/*.py` |
| Datos de demostracion | Datos semilla de animales, zonas, tareas, lactaciones, tratamientos, empleados y maquinaria; se persisten en BD al arranque | `backend/app/demo_data.py`, `backend/app/services/frontend_seed.py` |
| Seguridad | Hash de contrasenas, emision y validacion de JWT | `backend/app/security.py` |
| UI frontend | Paginas, componentes, graficos, formularios | `frontend/src/app`, `frontend/src/components` |
| Estado cliente | Sesion, token, usuario y zona activa | `frontend/src/store/app-store.ts` |
| Despliegue | Contenedores, proxy inverso, healthchecks | `Dockerfile`, `docker-compose.yml`, `nginx/nginx.conf` |

## 4. Stack tecnologico utilizado

| Capa del sistema | Tecnologia utilizada | Funcion dentro del proyecto | Justificacion de uso |
|------------------|------------------|------------------|------------------|
| Lenguaje backend | Python 3.12 en Docker | Implementacion de API y logica servidor | Ecosistema maduro para APIs, datos y futura analitica. |
| Framework backend | FastAPI `0.115.6` | API REST, documentacion OpenAPI, validacion | Adecuado para prototipos DSS con contratos claros y documentacion automatica. |
| Servidor ASGI | Uvicorn `0.34.0` | Ejecucion de FastAPI | Estadar habitual para FastAPI. |
| ORM | SQLAlchemy `2.0.36` | Modelado y acceso a BD | Permite trabajar con SQLite y PostgreSQL mediante una capa comun. |
| Driver PostgreSQL | `psycopg[binary]` | Conexion con PostgreSQL | Usado por `DATABASE_URL` de Docker. |
| Validacion backend | Pydantic 2 y pydantic-settings | Esquemas de entrada/salida y configuracion | Integracion natural con FastAPI. |
| Seguridad | `passlib[bcrypt]`, `bcrypt`, `python-jose` | Hash de contrasenas y JWT | Base de autenticacion para usuarios. |
| Cliente HTTP backend | `httpx` | Previsto para integraciones externas y scripts | La dependencia esta instalada; el cliente AEMET actual no consulta HTTP real. |
| Datos sinteticos | `faker>=24.0` | Dependencia declarada para generacion de datos sinteticos | En el codigo activo no se observa uso directo de `Faker`; los datos demo aparecen hardcodeados o generados por funciones propias. |
| Testing backend | Pytest, pytest-asyncio, FastAPI TestClient | Tests de API, autenticacion y meteorologia | Permite validar contratos backend-frontend. |
| Base de datos local | SQLite | Desarrollo local por defecto | Facilita arranque sin infraestructura. |
| Base de datos Docker | PostgreSQL 15 Alpine | Persistencia en entorno contenedorizado | Mas cercano a un entorno real de despliegue. |
| Cache preparada | Redis 7 Alpine | Cache potencial para dashboards | Incluido en Docker y scripts, pero no usado por routers activos. |
| Frontend | Next.js `16.2.6` | Aplicacion web con App Router | Permite frontend React moderno con rutas por pagina. |
| UI | React `19.2.6`, Tailwind CSS `4.3.0`, lucide-react | Componentes, estilos e iconografia | Facilita interfaz modular, visual y responsive. |
| Estado cliente | Zustand `5.0.13` | Token, usuario, rol seleccionado, zona activa | Estado ligero y suficiente para MVP. |
| Datos cliente | TanStack React Query `5.100.14` | Fetching, cache, refetch periodico | Adecuado para dashboards y pantallas que se actualizan. |
| Tipado frontend | TypeScript `6.0.3` | Tipos de entidades y contratos API | Reduce errores en comunicacion frontend-backend. |
| Proxy inverso | Nginx Alpine | Enruta API y frontend en puerto 80 | Simplifica acceso en despliegue local con Docker Compose. |
| Contenedores | Docker y Docker Compose | Orquestacion de backend, frontend, db, redis y nginx | Reproducibilidad del entorno. |
| Linting | ESLint 9 con config Next | Control de calidad frontend | Disponible mediante `npm run lint`. |

## 5. Backend

### 5.1 Framework y punto de entrada

El backend esta construido con FastAPI. El punto de entrada es `backend/app/main.py`. En ese fichero se definen:

- La aplicacion `FastAPI(title="Tools4Milk API", version="1.0.0")`.
- El middleware CORS con origenes procedentes de `settings.cors_origins`.
- El endpoint `/health`.
- La inclusion de routers.
- La personalizacion del esquema OpenAPI mediante `install_openapi(app)`.
- El `lifespan` que crea tablas y un usuario demo.

### 5.2 Estructura de carpetas backend

``` text
backend/
  app/
    main.py
    config.py
    database.py
    security.py
    demo_data.py
    openapi.py
    time_utils.py
    models/
      __init__.py
      usuario.py
      datos_metereologicos.py
      frontend_core.py        <- modelos ORM Core* para dominios ganaderos
    routers/
      auth.py
      assistant.py            <- asistente operativo con flag enable_assistant
      frontend_core.py
      simulation.py           <- simulacion de actividad operativa con flag enable_simulation
      weather.py
    schemas/
      api.py
    services/
      aemet_client.py
      assistant_service.py    <- logica del asistente
      frontend_seed.py        <- seed de tablas core_* al arranque
      simulation_service.py   <- generacion de tareas, alertas e incidencias simuladas
  migrations/
    001_add_performance_indexes.sql
  scripts/
    setup_redis.*
    apply_postgres_indexes.*
    performance_test.py
    monitor_redis.py
  sql/
    schema.sql
    seeds.sql
  tests/
    test_api_smoke.py
    test_autenticacion.py
    test_frontend_contracts.py
    test_openapi_docs.py
    test_aemet_integration.py
```

### 5.3 Configuracion

La clase `Settings` de `backend/app/config.py` define la configuracion principal:

| Variable | Valor por defecto | Uso |
|------------------------|------------------------|------------------------|
| `database_url` | `sqlite:///./tfm_mvp.db` | Conexion SQLAlchemy local. |
| `database_echo` | `False` | Log SQL. |
| `environment` | `development` | Entorno reportado. |
| `debug` | `True` | Modo debug. |
| `secret_key` | `tools4milk-dev-secret-change-me` | Firma JWT. |
| `algorithm` | `HS256` | Algoritmo JWT. |
| `access_token_expire_minutes` | `60` | Duracion del token. |
| `aemet_api_key` | cadena vacia | Preparado para AEMET. |
| `aemet_municipio_id` | `27065` | Municipio por defecto. |
| `aemet_estacion_id` | cadena vacia | Estacion meteorologica AEMET. |
| `enable_simulation` | `True` | Activa el router y servicio de simulacion de actividad operativa. |
| `simulation_max_tasks` | `80` | Limite de tareas generadas por simulacion. |
| `simulation_max_alerts` | `40` | Limite de alertas generadas por simulacion. |
| `simulation_max_incidents` | `60` | Limite de incidencias generadas por simulacion. |
| `enable_assistant` | `False` | Activa el router del asistente operativo. |
| `cors_origins` | localhost frontend | CORS. |

En `docker-compose.yml`, el backend usa PostgreSQL, Redis y origenes CORS adaptados a Nginx.

### 5.4 Modelos de datos activos

#### `Usuario`

Modelo definido en `backend/app/models/usuario.py`.

| Campo | Tipo | Descripcion |
|----|----|----|
| `id` | UUID | Clave primaria. |
| `username` | String(80), unico, indexado | Identificador de login. |
| `email` | String(255), unico, indexado | Correo del usuario. |
| `hashed_password` | String(255) | Password hasheada. |
| `role` | String(40), indexado | Rol del usuario: `admin`, `operario`, `alimentacion`, `veterinario`. |
| `activo` | Boolean | Permite bloquear usuarios. |
| `debe_cambiar_contrasena` | Boolean | Flag de seguridad. |
| `fecha_creacion` | DateTime timezone | Alta del usuario. |

Este modelo soporta la autenticacion y el control de acceso por rol (RBAC) del prototipo. El campo `role` es validado en los endpoints del backend mediante la dependencia `require_roles()` de `security.py`.

#### `DatosMetereologicos`

Modelo definido en `backend/app/models/datos_metereologicos.py`. El nombre del modelo y de la tabla aparece con la grafia `metereologicos`, no `meteorologicos`.

| Campo | Tipo | Descripcion |
|------------------------|------------------------|------------------------|
| `id` | Integer autoincremental | Clave primaria. |
| `fecha_hora` | DateTime | Momento de la medicion. |
| `temperatura_media`, `temperatura_maxima`, `temperatura_minima` | Float | Temperaturas. |
| `humedad_relativa` | Float | Humedad. |
| `precipitacion` | Float | Lluvia. |
| `velocidad_viento` | Float | Viento. |
| `presion_atmosferica` | Float | Presion. |
| `estado_cielo` | String | Descripcion del cielo. |
| `ubicacion` | String | Por defecto, Villalba, Lugo. |
| `latitud`, `longitud` | Float | Coordenadas. |
| `fuente` | String | Fuente declarada. |

El modelo incluye propiedades derivadas: `es_lluvia`, `es_dia_frio`, `es_dia_calido`, `es_viento_fuerte` y `humedad_alta`.

#### Modelos del dominio ganadero (`backend/app/models/frontend_core.py`)

Ademas de los dos modelos anteriores, el archivo `frontend_core.py` define nueve modelos ORM con sus respectivas tablas en base de datos:

| Modelo | Tabla | Campos principales |
|------------------|------------------|------------------|
| `CoreAnimal` | `core_animals` | `id`, `crotal_oficial`, `nombre`, `sexo`, `fecha_nacimiento`, `raza`, `estado`, `estado_reproductivo`, `fecha_entrada`, `fecha_baja` |
| `CoreZone` | `core_zones` | `id`, `nombre`, `codigo`, `descripcion`, `tipo`, `tiene_pantalla_tv`, `tiene_tablet`, `activa` |
| `CoreTask` | `core_tasks` | `id`, `tarea_catalogo_id`, `tarea_catalogo` (JSON), `zona_id`, `fecha_programada`, `estado`, `ejecutado_por`, `checklist_datos`, `es_urgente`, `requiere_seguimiento` |
| `CoreAlert` | `core_alerts` | `id`, `animal_id`, `tipo_alerta`, `severidad`, `descripcion`, `recomendacion`, `estado`, `revisada`, `confianza_prediccion`, `veterinario_responsable` |
| `CoreIncident` | `core_incidents` | `id`, `tipo`, `zona_id`, `animal_id`, `descripcion`, `prioridad`, `estado`, `fecha_creacion`, `reportado_por` |
| `CoreLactation` | `core_lactations` | `id`, `animal_id`, `numero_lactacion`, `dias_transcurridos`, `produccion_promedio`, `grasa_promedio`, `proteina_promedio`, `rcs_promedio`, `activa` |
| `CoreTreatment` | `core_treatments` | `id`, `animal_id`, `medicamento`, `dosis`, `via_administracion`, `fecha_inicio`, `periodo_retirada_dias`, `activo`, `veterinario` |
| `CoreEmployee` | `core_employees` | `id`, `nombre`, `apellidos`, `role`, `zona_principal_id`, `activo` |
| `CoreMachinery` | `core_machinery` | `id`, `nombre`, `tipo`, `zona_id`, `estado`, `proxima_revision`, `observaciones` |

Todos estos modelos se crean en BD al arrancar la aplicacion y se pueblan con datos semilla desde `demo_data.py` mediante `ensure_frontend_seed_data()` si las tablas estan vacias.

### 5.5 Esquemas y validadores

Los esquemas Pydantic se encuentran en `backend/app/schemas/api.py`. Incluyen:

- `LoginRequest`
- `TokenResponse`
- `UserResponse`
- `AuthResponse`
- `AlertCreate`
- `AlertUpdate`
- `AlertsResponse`

Estos esquemas formalizan principalmente autenticacion y alertas. Otros endpoints devuelven `dict[str, Any]` o listas de diccionarios, por lo que su contrato es menos estricto.

### 5.6 Routers y logica implementada

#### Router de autenticacion: `backend/app/routers/auth.py`

Expone:

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/refresh`

La autenticacion valida el usuario contra la tabla `usuarios`, verifica password con `verify_password()` y emite JWT con `create_access_token()`. El backend siembra automaticamente cinco usuarios demo, todos con password `testpass123`:

| Usuario | Email | Rol |
|---------|-------|-----|
| `admin` | `admin@tools4milk.local` | `admin` |
| `roberto.castro` | `roberto.castro@tools4milk.local` | `admin` |
| `operario.zona` | `operario.zona@tools4milk.local` | `operario` |
| `laura.fernandez` | `laura.fernandez@tools4milk.local` | `alimentacion` |
| `dr.mendez` | `dr.mendez@tools4milk.local` | `veterinario` |

Los usuarios visibles en la pantalla de login del frontend coinciden con estos usuarios sembrados, por lo que todos funcionan para iniciar sesion.

#### Control de acceso por rol: `backend/app/security.py`

La funcion `require_roles(*allowed_roles)` genera dependencias FastAPI que validan el campo `role` del usuario autenticado. El router `frontend_core` define grupos de acceso:

- `AdminOnly`: solo `admin`.
- `AnimalManager`: `admin`, `veterinario`.
- `TaskManager`: `admin`, `operario`, `alimentacion`.
- `ClinicalManager`: `admin`, `veterinario`.
- `QualityManager`: `admin`, `veterinario`, `alimentacion`.
- `OperationsManager`: `admin`, `operario`, `alimentacion`.

El RBAC es real y se aplica en backend: intentar crear un animal con un usuario de rol `operario` devuelve HTTP 403.

#### Router del asistente: `backend/app/routers/assistant.py`

Expone:

- `POST /api/v1/assistant/message`

Permite enviar mensajes al asistente operativo interno. Requiere autenticacion y que la variable de configuracion `enable_assistant` este activa (`False` por defecto). Si esta desactivado, devuelve HTTP 403. La logica esta implementada en `backend/app/services/assistant_service.py`.

#### Router principal del frontend: `backend/app/routers/frontend_core.py`

Agrupa la mayoria de endpoints que consume el frontend:

- Dashboard.
- Animales.
- Zonas.
- Tareas.
- Lactaciones.
- Alertas.
- Predicciones.
- Incidencias.
- Tratamientos.
- Empleados.
- Maquinaria.

Su rasgo tecnico mas importante es que todas las entidades ganaderas se sirven desde tablas ORM reales (`core_animals`, `core_zones`, `core_tasks`, `core_alerts`, `core_incidents`, `core_lactations`, `core_treatments`, `core_employees`, `core_machinery`). Los datos iniciales proceden de `backend/app/demo_data.py` (listas `ANIMALS`, `ZONES`, `TASKS`, `ALERTS`, `LACTATIONS`, `TREATMENTS`, `EMPLOYEES`, `MACHINERY`), pero se persisten en BD al arranque. Las operaciones de escritura (crear animal, completar tarea, crear alerta, registrar incidencia) son durables y sobreviven al reinicio del proceso.

#### Router de simulacion: `backend/app/routers/simulation.py`

Expone:

- `GET /api/v1/simulation/status`
- `POST /api/v1/simulation/tick`

Requiere rol `admin`. Genera actividad operativa simulada (tareas, alertas e incidencias) en la base de datos hasta los limites configurados (`simulation_max_tasks`, `simulation_max_alerts`, `simulation_max_incidents`). Permite demostrar el sistema con datos variados sin tener que insertar manualmente. El endpoint esta protegido por la variable `enable_simulation` (`True` por defecto).

#### Router meteorologico: `backend/app/routers/weather.py`

Expone endpoints para clima actual, prevision, historico, sincronizacion e impacto:

- `GET /api/v1/weather/current`
- `GET /api/v1/weather/forecast`
- `GET /api/v1/weather/historical`
- `POST /api/v1/weather/sync`
- `GET /api/v1/weather/correlation/impact`

`weather_current()` consulta la tabla `datos_metereologicos` y devuelve el registro mas reciente. Si no hay datos, devuelve valores por defecto. `weather_sync()` llama a `aemet_client.sincronizar_datos(db)`.

#### Servicio AEMET: `backend/app/services/aemet_client.py`

El servicio actual no consume la API publica real de AEMET. Genera siete registros meteorologicos sinteticos para Villalba, Lugo, con fuente declarada como `AEMET`, y los inserta si no existen registros para esas fechas. Esta implementacion es util para validar:

- Modelo meteorologico.
- Escritura en BD.
- Endpoint de sincronizacion.
- Flujo frontend-backend futuro.

No obstante, la integracion real con AEMET queda pendiente.

### 5.7 Tabla de endpoints REST

| Metodo | Ruta | Descripcion | Entidad afectada | Entrada esperada | Salida esperada | Estado |
|-----------|-----------|-----------|-----------|-----------|-----------|-----------|
| GET | `/health` | Healthcheck de la API | Sistema | Ninguna | Estado API/BD/entorno | Implementado |
| POST | `/api/v1/auth/login` | Login y emision de JWT | Usuario | `username`, `password` | Usuario y token | Implementado |
| GET | `/api/v1/auth/me` | Usuario autenticado | Usuario | Bearer token | Usuario | Implementado |
| POST | `/api/v1/auth/refresh` | Renovacion de token | Usuario | Bearer token | Token nuevo | Implementado |
| POST | `/api/v1/assistant/message` | Mensaje al asistente operativo | Asistente | `message`, `confirmed`, `draft` | Respuesta del asistente | Implementado (desactivado por defecto) |
| GET | `/api/v1/dashboard/summary` | Resumen de KPIs | Alertas, tareas, animales, tratamientos | Ninguna | Diccionario de KPIs | Implementado con consultas reales a BD |
| GET | `/api/v1/animals` | Lista de animales | Animales | `skip`, `limit`, `estado` | Lista de animales | Implementado con persistencia real |
| POST | `/api/v1/animals` | Crear animal | Animales | JSON animal | Animal creado | Implementado (rol admin/veterinario) |
| GET | `/api/v1/animals/active-count` | Conteo de animales activos | Animales | Ninguna | Entero | Implementado, consulta real a BD |
| GET | `/api/v1/animals/{animal_id}` | Detalle de animal | Animales | ID | Animal | Implementado con persistencia real |
| PUT | `/api/v1/animals/{animal_id}` | Actualizar animal | Animales | JSON parcial | Animal actualizado | Implementado (rol admin/veterinario) |
| GET | `/api/v1/animals/search/by-crotal/{crotal}` | Busqueda por crotal | Animales | Crotal | Animal | Implementado con persistencia real |
| GET | `/api/v1/zones` | Lista de zonas | Zonas | Ninguna | Lista de zonas | Implementado con persistencia real |
| POST | `/api/v1/zones` | Crear zona | Zonas | JSON libre | Zona creada | Implementado (rol admin), persistente |
| GET | `/api/v1/zones/{zone_id}` | Detalle de zona | Zonas | ID | Zona | Implementado con persistencia real |
| PUT | `/api/v1/zones/{zone_id}` | Actualizar zona | Zonas | JSON parcial | Zona actualizada | Implementado (rol admin) |
| GET | `/api/v1/tasks` | Lista de tareas | Tareas | `skip`, `limit`, `estado`, `zona_id` | Lista de tareas | Implementado con persistencia real |
| POST | `/api/v1/tasks` | Crear tarea | Tareas | JSON tarea | Tarea creada | Implementado (rol admin/operario/alimentacion) |
| GET | `/api/v1/tasks/{task_id}` | Detalle de tarea | Tareas | ID | Tarea | Implementado con persistencia real |
| PUT | `/api/v1/tasks/{task_id}` | Actualizar/completar tarea | Tareas | JSON parcial | Tarea actualizada | Implementado, persistente |
| GET | `/api/v1/lactations` | Lista de lactaciones | Lactaciones | `skip`, `limit`, `animal_id`, `activa` | Lista de lactaciones | Implementado con persistencia real |
| POST | `/api/v1/lactations` | Crear lactacion | Lactaciones | JSON lactacion | Lactacion creada | Implementado (rol admin/veterinario/alimentacion) |
| PUT | `/api/v1/lactations/{lactation_id}` | Actualizar lactacion | Lactaciones | JSON parcial | Lactacion actualizada | Implementado |
| GET | `/api/v1/alerts/critical` | Alertas alta/critica | Alertas | Ninguna | `AlertsResponse` | Implementado con persistencia real |
| GET | `/api/v1/alerts` | Lista de alertas | Alertas | `skip`, `limit`, `severidad` | `AlertsResponse` | Implementado con persistencia real |
| POST | `/api/v1/alerts` | Crear alerta | Alertas | `AlertCreate` | Alerta | Implementado, persistente |
| GET | `/api/v1/alerts/detail/{alert_id}` | Detalle de alerta | Alertas | ID | Alerta | Implementado con persistencia real |
| PATCH | `/api/v1/alerts/{alert_id}` | Revisar/resolver alerta | Alertas | `AlertUpdate` | Alerta actualizada | Implementado, persistente |
| GET | `/api/v1/alerts/{animal_id}` | Alertas por animal | Alertas | Animal ID | `AlertsResponse` | Implementado con persistencia real |
| POST | `/api/v1/alerts/generate/{animal_id}` | Generar alertas | Alertas | Animal ID | `{generated: 0}` | Stub |
| GET | `/api/v1/predictions/{animal_id}` | Prediccion integral | Predicciones | Animal ID | Produccion, composicion, riesgo | Mock |
| GET | `/api/v1/predictions/production/{animal_id}` | Prediccion de produccion | Predicciones | Animal ID | Bloque produccion | Mock |
| GET | `/api/v1/predictions/composition/{animal_id}` | Prediccion de composicion | Predicciones | Animal ID | Bloque composicion | Mock |
| GET | `/api/v1/predictions/health-risk/{animal_id}` | Riesgo sanitario | Predicciones | Animal ID | Bloque riesgo | Mock |
| GET | `/api/v1/incidents` | Lista de incidencias | Incidencias | `skip`, `limit` | Lista de incidencias | Implementado con persistencia real |
| POST | `/api/v1/incidents` | Crear incidencia | Incidencias | JSON libre | Incidencia creada | Implementado, persistente |
| GET | `/api/v1/incidents/{incident_id}` | Detalle de incidencia | Incidencias | ID | Incidencia | Implementado |
| PUT | `/api/v1/incidents/{incident_id}` | Actualizar incidencia | Incidencias | JSON libre | Incidencia actualizada | Implementado |
| GET | `/api/v1/treatments` | Lista de tratamientos | Tratamientos | `skip`, `limit`, `animal_id`, `activo` | Lista de tratamientos | Implementado con persistencia real |
| POST | `/api/v1/treatments` | Crear tratamiento | Tratamientos | JSON tratamiento | Tratamiento creado | Implementado (rol admin/veterinario) |
| PUT | `/api/v1/treatments/{treatment_id}` | Actualizar tratamiento | Tratamientos | JSON parcial | Tratamiento actualizado | Implementado |
| GET | `/api/v1/employees` | Lista de empleados | Empleados | Ninguna | Lista de empleados | Implementado con persistencia real (3 empleados sembrados) |
| GET | `/api/v1/machinery` | Lista de maquinaria | Maquinaria | `skip`, `limit` | Lista de maquinaria | Implementado con persistencia real (2 maquinas sembradas) |
| GET | `/api/v1/simulation/status` | Estado de la simulacion | Simulacion | Ninguna | Conteo de entidades | Implementado (rol admin) |
| POST | `/api/v1/simulation/tick` | Ejecutar tick de simulacion | Simulacion | `intensity` (1-5) | Resumen de entidades creadas | Implementado (rol admin) |
| GET | `/api/v1/weather/current` | Clima actual | Meteorologia | Ninguna | Datos actuales o fallback | Implementado parcialmente |
| GET | `/api/v1/weather/forecast` | Prevision | Meteorologia | Ninguna | Lista vacia | Stub |
| GET | `/api/v1/weather/historical` | Historico | Meteorologia | `dias_atras` | Lista vacia | Stub |
| POST | `/api/v1/weather/sync` | Sincronizar meteorologia | Meteorologia | Ninguna | Registros insertados | Simulado con datos sinteticos |
| GET | `/api/v1/weather/correlation/impact` | Impacto clima-produccion | Meteorologia/produccion | `dias_adelante` | Lista vacia | Stub |

### 5.8 Manejo de errores

El backend utiliza `HTTPException` en casos como:

- Login incorrecto.
- Usuario inactivo.
- Token invalido.
- Animal, zona, tarea o alerta no encontrada.
- Resumen de calidad no disponible.

El frontend captura errores HTTP en `frontend/src/lib/api.ts`, intenta leer `payload.detail` y lanza `Error(detail)` para que React Query lo gestione.

### 5.9 Tests backend

El directorio `backend/tests` contiene pruebas para:

- Contrato health y dashboard.
- Contratos que consume el frontend.
- Flujo de alertas.
- Autenticacion.
- Integracion meteorologica simulada.
- OpenAPI.

Los tests utilizan SQLite en memoria y sustituyen `get_db` mediante `dependency_overrides`.

## 6. Base de datos

### 6.1 Motor y acceso a datos

El sistema esta preparado para dos modos:

| Modo | Motor | Configuracion |
|------------------------|------------------------|------------------------|
| Desarrollo local por defecto | SQLite | `sqlite:///./tfm_mvp.db` en `backend/app/config.py` |
| Docker Compose | PostgreSQL 15 Alpine | `DATABASE_URL=postgresql+psycopg://postgres:password@db:5432/tfm_mvp` |

SQLAlchemy actua como ORM. La creacion de tablas se realiza con `Base.metadata.create_all()` al arrancar la aplicacion.

### 6.2 Modelos/tablas activas

| Modelo | Tabla | Finalidad | Campos principales | Papel en la aplicacion |
|------------|------------|------------|------------|------------|
| `Usuario` | `usuarios` | Gestion de usuarios autenticables | `id`, `username`, `email`, `hashed_password`, `role`, `activo`, `fecha_creacion` | Soporta login, JWT, RBAC y usuario actual. |
| `DatosMetereologicos` | `datos_metereologicos` | Registro de meteorologia | `fecha_hora`, temperaturas, humedad, precipitacion, viento, presion, ubicacion, fuente | Permite clima actual y sincronizacion simulada. |
| `CoreAnimal` | `core_animals` | Gestion del ganado | `crotal_oficial`, `nombre`, `raza`, `estado`, `estado_reproductivo` | Base de datos de animales con CRUD persistente. |
| `CoreZone` | `core_zones` | Gestion de zonas de la granja | `nombre`, `codigo`, `tipo`, `tiene_pantalla_tv`, `tiene_tablet` | Organiza el espacio fisico de la explotacion. |
| `CoreTask` | `core_tasks` | Gestion de tareas operativas | `tarea_catalogo_id`, `zona_id`, `estado`, `fecha_programada`, `es_urgente` | Soporte al modo TV/tablet y LeanFarming. |
| `CoreAlert` | `core_alerts` | Sistema de alertas | `animal_id`, `tipo_alerta`, `severidad`, `estado`, `revisada` | Alertas persistentes gestionables desde frontend. |
| `CoreIncident` | `core_incidents` | Registro de incidencias | `tipo`, `zona_id`, `animal_id`, `prioridad`, `estado` | Incidencias operativas persistidas. |
| `CoreLactation` | `core_lactations` | Datos de lactacion | `animal_id`, `produccion_promedio`, `grasa_promedio`, `proteina_promedio`, `rcs_promedio` | Base para calidad de leche y seguimiento productivo. |
| `CoreTreatment` | `core_treatments` | Tratamientos veterinarios | `animal_id`, `medicamento`, `dosis`, `periodo_retirada_dias`, `activo` | Trazabilidad sanitaria del ganado. |
| `CoreEmployee` | `core_employees` | Empleados de la explotacion | `nombre`, `apellidos`, `role`, `zona_principal_id` | Vinculacion de tareas y zonas a personas. |
| `CoreMachinery` | `core_machinery` | Maquinaria e instalaciones | `nombre`, `tipo`, `zona_id`, `estado`, `proxima_revision` | Inventario de equipamiento con estado. |

### 6.3 Datos semilla

Los datos iniciales provienen de `backend/app/demo_data.py`, que exporta listas Python: `ANIMALS`, `ZONES`, `TASKS`, `ALERTS`, `LACTATIONS`, `TREATMENTS`, `EMPLOYEES` y `MACHINERY`. Al arrancar la aplicacion, `ensure_frontend_seed_data()` comprueba si cada tabla `core_*` esta vacia y, en ese caso, la puebla desde esas listas. A partir de ese momento, los datos viven en la base de datos y cualquier modificacion (completar tarea, crear alerta, registrar incidencia) es persistente.

### 6.4 SQL y migraciones

Los ficheros `backend/sql/schema.sql` y `backend/sql/seeds.sql` existen pero estan vacios. Por tanto, no hay un esquema SQL completo inicializable desde esos ficheros.

La migracion `backend/migrations/001_add_performance_indexes.sql` define indices y alteraciones para tablas como:

- `alertas`
- `animales`
- `lactaciones`
- `tareas_ejecuciones`
- `incidencias`
- `tratamientos_activos`
- `eventos_reproductivos`
- `datos_metereologicos`

Sin embargo, esas tablas no estan definidas por modelos SQLAlchemy activos, salvo `datos_metereologicos`. La migracion parece proceder de una fase de diseno o de una version mas amplia del modelo, pero no puede considerarse plenamente integrada con el codigo actual.

### 6.5 Datos sinteticos y Faker

El contexto del TFM indica que, ante la imposibilidad de acceder a datos reales estructurados, se han utilizado datos sinteticos generados con Faker. En el repositorio analizado:

- La dependencia `faker>=24.0` esta declarada en `backend/requirements.txt`.
- No se ha localizado ningun uso directo de `Faker` mediante busqueda textual en el codigo.
- Los datos de animales, zonas y tareas se encuentran definidos manualmente en `backend/app/demo_data.py`.
- Los datos meteorologicos son generados por codigo propio en `AemetClient.sincronizar_datos()`.

Por tanto, la descripcion academica mas precisa es que **el proyecto esta preparado para trabajar con datos sinteticos y declara Faker como dependencia**, pero **en la version del repositorio analizada no se observa un seeder activo que utilice directamente Faker**. Si existieron scripts externos o no versionados para generar datos con Faker, no se han podido verificar a partir del repositorio.

### 6.6 Valor metodologico de los datos sinteticos

El uso de datos sinteticos en esta fase no debe interpretarse unicamente como una debilidad. Permite:

- Validar el modelo conceptual de entidades.
- Comprobar contratos entre frontend y backend.
- Disenar pantallas de consulta y accion.
- Simular flujos de tareas, alertas, predicciones y calidad.
- Probar paginacion, filtros, estados y refresco automatico.
- Preparar una transicion posterior hacia fuentes reales.

Sus limitaciones son claras: no permiten evaluar rendimiento predictivo real, no validan la calidad del dato del sector, no reflejan toda la variabilidad biologica y operacional de una granja, y no sustituyen una validacion con usuarios y datos reales.

## 7. Frontend

### 7.1 Framework y estructura

El frontend esta construido con Next.js 16, React 19 y TypeScript. Utiliza Tailwind CSS para estilos, lucide-react para iconos, TanStack React Query para fetching y Zustand para estado local.

Estructura principal:

``` text
frontend/src/
  app/
    layout.tsx
    page.tsx
    globals.css
    (app)/
      layout.tsx
      dashboard/page.tsx
      animals/page.tsx
      tasks/page.tsx
      alerts/page.tsx
      zones/page.tsx
      zones/[id]/page.tsx
      quality/page.tsx
      predictions/page.tsx
      leanfarming/page.tsx
      management/page.tsx     <- gestion de datos maestros (animales, zonas, lactaciones, etc.)
  components/
    charts/MiniCharts.tsx
    common/Pagination.tsx
    common/ErrorBoundary.tsx
    providers/app-providers.tsx
    ui/*.tsx
  features/
    auth/login-screen.tsx
  lib/
    api.ts
    types.ts
    config.ts
    pagination.ts
    permissions.ts            <- permisos por rol para el frontend
  store/
    app-store.ts
  proxy.ts
```

### 7.2 Sistema de rutas

| Ruta frontend | Fichero | Funcion |
|------------------------|------------------------|------------------------|
| `/` | `app/page.tsx` | Muestra `LoginScreen`. |
| `/dashboard` | `app/(app)/dashboard/page.tsx` | KPIs y resumen operativo. |
| `/animals` | `app/(app)/animals/page.tsx` | Listado y filtros de animales. |
| `/tasks` | `app/(app)/tasks/page.tsx` | Tareas por estado y marcado como completadas. |
| `/alerts` | `app/(app)/alerts/page.tsx` | Alertas por severidad y acciones de revision. |
| `/zones` | `app/(app)/zones/page.tsx` | Vista general de zonas. |
| `/zones/[id]` | `app/(app)/zones/[id]/page.tsx` | Detalle de zona con modo TV/tablet. |
| `/quality` | `app/(app)/quality/page.tsx` | Calidad de leche y composicion. |
| `/predictions` | `app/(app)/predictions/page.tsx` | Predicciones por animal. |
| `/leanfarming` | `app/(app)/leanfarming/page.tsx` | Gestion LeanFarming por zona o lista global. |
| `/management` | `app/(app)/management/page.tsx` | Gestion de datos maestros: crear y editar animales, zonas, lactaciones, tratamientos, empleados y maquinaria. |

El archivo `frontend/src/proxy.ts` protege rutas mediante cookie `t4m_token`. Si el usuario accede a una ruta protegida sin token, redirige a `/`. Si accede a `/` con token, redirige a `/dashboard`.

### 7.3 Cliente API

`frontend/src/lib/api.ts` centraliza las llamadas HTTP. Sus caracteristicas:

- Construye URLs usando `API_BASE_URL` y `API_V1_URL`. La URL por defecto es `http://localhost:8000` (variable de entorno `NEXT_PUBLIC_API_URL`).
- Lee token desde `localStorage` (`t4m_token`).
- Anade cabecera `Authorization: Bearer`.
- Serializa JSON.
- Gestiona errores HTTP leyendo `detail`.
- Expone metodos por dominio: auth, dashboard, zones, alerts, tasks, animals, incidents, treatments, employees, lactations, predictions, weather y machinery.

`frontend/src/lib/permissions.ts` define la logica de permisos por rol en el cliente. Exporta `hasPermission(role, permission)` y `roleLabel(role)` para controlar que acciones puede realizar cada rol en la interfaz.

### 7.4 Estado cliente

`frontend/src/store/app-store.ts` usa Zustand para:

- `activeZoneId`
- `token`
- `user`
- `selectedRole`
- hidratacion desde `localStorage`
- guardado de cookie para proteccion de rutas
- logout

El rol (`admin`, `veterinario`, `operario`, `alimentacion`) se guarda en el campo `role` del usuario en la base de datos y se incluye en el token JWT. En el frontend, `permissions.ts` usa el rol para mostrar u ocultar acciones. En el backend, `require_roles()` en `security.py` valida el rol antes de ejecutar las operaciones de escritura.

### 7.5 Componentes visuales principales

| Componente | Fichero | Funcion |
|------------------------|------------------------|------------------------|
| `LoginScreen` | `features/auth/login-screen.tsx` | Login, seleccion de rol, estado de API y presentacion inicial. |
| `AppProviders` | `components/providers/app-providers.tsx` | Provee React Query y configuracion global. |
| `Pagination` | `components/common/Pagination.tsx` | Navegacion por paginas. |
| `ErrorBoundary` | `components/common/ErrorBoundary.tsx` | Captura errores React. |
| `SparkArea` | `components/charts/MiniCharts.tsx` | Grafico SVG de tendencia. |
| `DonutStat` | `components/charts/MiniCharts.tsx` | Indicador circular porcentual. |
| UI base | `components/ui` | Boton, tarjeta, badge, alert, input y spinner. |

### 7.6 Pantallas y valor funcional

#### Login

Muestra una interfaz de acceso con seleccion de rol funcional y estado de la API. Consume `/health` y `POST /auth/login`. Incluye usuarios de prueba visibles en UI, aunque no coinciden necesariamente con usuarios sembrados en backend.

Datos utilizados: backend real para health y login; KPIs decorativos/estaticos en el panel visual.

#### Dashboard

Consume:

- `api.dashboardSummary()`
- `api.alerts({ limit: 5 })`

Muestra tarjetas KPI de alertas, tareas, animales y tratamientos; graficos de tendencia y cumplimiento; alertas recientes y estado de tareas. Tiene refresco automatico cada 30 segundos.

Datos utilizados: resumen de API basado en listas demo y algunos graficos con series fijas en frontend.

#### Animales

Consume `api.animals()` con filtros `estado`, `skip` y `limit`. Muestra tarjetas con crotal, nombre, raza, edad aproximada, estado y fecha de entrada. Permite busqueda local por crotal o nombre y filtrado por estado.

Datos utilizados: tabla `core_animals` en BD; datos semilla de tres animales.

#### Tareas

Consume `api.tasks()` y `api.completeTask()`. Permite filtrar por `programada`, `retrasada` o `ejecutada`. Las tareas se pueden marcar como completadas mediante `PUT /tasks/{task_id}`.

Datos utilizados: tabla `core_tasks` en BD. Las actualizaciones son persistentes entre reinicios del backend.

#### Alertas

Consume `api.alerts()` y `api.reviewAlert()`. Muestra alertas por severidad y permite marcarlas como revisadas, resueltas o falsas alarmas. Incluye expansion de detalle y recomendacion.

Datos utilizados: tabla `core_alerts` en BD. Sin alertas iniciales; se crean via API o mediante el router de simulacion.

#### Zonas

Consume zonas, tareas y alertas. Presenta tarjetas de zona con estado derivado de tareas retrasadas, contadores de tareas y badges de TV/tablet. El estado de zona se calcula en frontend.

Datos utilizados: tablas `core_zones`, `core_tasks` y `core_alerts` en BD.

#### Detalle de zona

Ofrece dos modos:

- **TV**: vista de solo lectura, con alertas, tareas, hora actual y resumen visual.
- **Tablet**: acciones rapidas, seleccion de tareas, observaciones, completar tarea y modal de nueva incidencia.

Datos utilizados: tareas y alertas de BD. La creacion de incidencia persiste en la tabla `core_incidents`.

#### LeanFarming

Consume zonas y tareas. Organiza tareas por zona, calcula estado operativo, muestra progreso y permite completar tareas. Tambien ofrece lista global por estado.

Datos utilizados: tablas `core_zones` y `core_tasks` en BD. Sin scheduler automatico ni asignacion real por empleado.

#### Calidad de leche

Consume animales en produccion y genera tarjetas de composicion, indicadores de calidad, puntuacion de calidad y graficos. Los valores de grasa, proteina, lactosa, celulas somaticas, recuento bacteriano, pH y temperatura son mock o calculos deterministas en frontend.

Datos utilizados: animales de API mas datos simulados en UI.

#### Predicciones

Consume animales en produccion y permite cargar predicciones por animal mediante `api.predictions(animal.id)`. Muestra produccion prevista, composicion, riesgo sanitario, confianza y graficos.

Datos utilizados: endpoint mock con `_mock: true`.

## 8. Funcionalidades implementadas

### 8.1 Autenticacion y sesion

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `login-screen.tsx`, `app-store.ts`, `proxy.ts`, `permissions.ts` |
| Modelos implicados | `Usuario` (incluye campo `role`) |
| Endpoints | `POST /auth/login`, `GET /auth/me`, `POST /auth/refresh` |
| Estado | Implementado con RBAC |
| Datos utilizados | Cinco usuarios sembrados en BD con roles distintos |
| Limitaciones | Secreto JWT por defecto no apto para produccion; sin gestion de usuarios desde la UI; sin recuperacion de contrasena. |
| Mejoras futuras | Gestion de usuarios desde panel admin, caducidad segura, recuperacion de contrasena, auditoria de accesos. |

### 8.2 Dashboard operativo

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `dashboard/page.tsx`, `MiniCharts.tsx` |
| Modelos implicados | `CoreAlert`, `CoreTask`, `CoreAnimal`, `CoreTreatment` |
| Endpoints | `/dashboard/summary`, `/alerts` |
| Estado | Implementado con consultas reales a BD |
| Datos utilizados | Consultas SQLAlchemy sobre tablas `core_*`; algunos graficos de tendencia usan series fijas en frontend |
| Limitaciones | KPIs productivos no proceden de mediciones de sensores ni robots reales. |
| Mejoras futuras | KPIs conectados a lecturas reales de robots, calidad, alimentacion y clima. |

### 8.3 Gestion de animales

Permite listar animales, buscar por crotal o nombre en la pagina actual y filtrar por estado. Los animales representan vacas en produccion y recria, con campos como crotal oficial, nombre, sexo, fecha de nacimiento, raza, estado y estado reproductivo.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `animals/page.tsx`, `management/page.tsx`, `Pagination.tsx` |
| Modelos implicados | `CoreAnimal` (tabla `core_animals`) |
| Endpoints | `/animals`, `/animals/{id}`, `/animals/search/by-crotal/{crotal}`, `POST /animals`, `PUT /animals/{id}` |
| Estado | Implementado con persistencia real |
| Datos utilizados | Tres animales semilla (Luna, Nube, Brisa); se pueden crear nuevos via `/management` |
| Limitaciones | Sin historial sanitario detallado ni eventos reproductivos persistentes. Sin integracion con sensores o robots. |
| Mejoras futuras | Relaciones con eventos reproductivos, integracion con robots de ordeno, historial medico completo. |

### 8.4 Gestion de trabajadores

Existe un endpoint `/employees` que devuelve un operario demo. En frontend no se ha identificado una pantalla especifica de gestion de empleados o turnos.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `management/page.tsx` |
| Modelos implicados | `CoreEmployee` (tabla `core_employees`) |
| Endpoints | `/employees`, `POST /employees`, `PUT /employees/{id}` |
| Estado | Implementado con persistencia real |
| Datos utilizados | Tres empleados sembrados (Roberto Castro, Laura Fernandez, Dr. Mendez) |
| Limitaciones | Sin turnos, asignaciones de tareas a empleado especifico ni gestion horaria. |
| Mejoras futuras | Modelos `turnos`, `asignaciones_turno`, relacion directa con tareas ejecutadas. |

### 8.5 Gestion de tareas

Permite listar tareas por estado, ver detalle, actualizar tareas y marcarlas como ejecutadas. Es una de las funcionalidades mas completas del MVP.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `tasks/page.tsx`, `leanfarming/page.tsx`, `zones/[id]/page.tsx`, `management/page.tsx` |
| Modelos implicados | `CoreTask` (tabla `core_tasks`) |
| Endpoints | `/tasks`, `/tasks/{id}`, `POST /tasks`, `PUT /tasks/{id}` |
| Estado | Implementado con persistencia real |
| Datos utilizados | Dos tareas semilla; el router de simulacion puede generar tareas adicionales |
| Limitaciones | Sin scheduler automatico, sin recurrencias, sin asignacion formal a empleado especifico. |
| Mejoras futuras | Catalogo de tareas recurrentes, scheduler, asignacion por turno. |

### 8.6 Gestion de incidencias

El modo tablet de zona incluye un formulario para registrar una incidencia con tipo, prioridad y descripcion. El backend devuelve un objeto con ID y estado `abierta`.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `zones/[id]/page.tsx` |
| Modelos implicados | `CoreIncident` (tabla `core_incidents`) |
| Endpoints | `/incidents`, `/incidents/{id}`, `POST /incidents`, `PUT /incidents/{id}` |
| Estado | Implementado con persistencia real |
| Datos utilizados | Incidencias creadas por usuario o generadas por el router de simulacion |
| Limitaciones | Sin adjuntos, sin historial de estados, sin notificaciones. |
| Mejoras futuras | Adjuntos, notificaciones, flujo de estados, relacion con maquinaria y trazabilidad. |

### 8.7 Gestion de alertas

El sistema permite crear, listar, filtrar por severidad y revisar alertas. La estructura de alerta incluye animal, tipo, severidad, descripcion, recomendacion, estado y confianza de prediccion.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `alerts/page.tsx`, `dashboard/page.tsx`, `zones/[id]/page.tsx` |
| Modelos implicados | `CoreAlert` (tabla `core_alerts`) |
| Endpoints | `/alerts`, `/alerts/critical`, `/alerts/detail/{id}`, `/alerts/{id}`, `POST /alerts`, `PATCH /alerts/{id}` |
| Estado | Implementado con persistencia real |
| Datos utilizados | Alertas persistidas en BD; pueden generarse via simulacion |
| Limitaciones | Generacion automatica de alertas (`/generate/{animal_id}`) devuelve cero; sin motor de reglas ni notificaciones push. |
| Mejoras futuras | Motor de reglas, notificaciones, modelos predictivos y auditoria de acciones. |

### 8.8 Gestion de robots o maquinaria

La maquinaria tiene modelo ORM activo y datos semilla. La pantalla de gestion (`/management`) permite ver y editar los registros de maquinaria e instalaciones.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `management/page.tsx` |
| Modelos implicados | `CoreMachinery` (tabla `core_machinery`) |
| Endpoints | `/machinery`, `POST /machinery`, `PUT /machinery/{id}` |
| Estado | Implementado con persistencia real |
| Datos utilizados | Dos maquinas sembradas (robot de ordeno, mezclador unifeed) |
| Limitaciones | Sin conector real con robots, sin telemetria, sin tickets de averia. |
| Mejoras futuras | Conector DeLaval, telemetria en tiempo real, tickets de mantenimiento. |

### 8.9 Calidad de leche

La pantalla de calidad permite explorar composicion y parametros de calidad por animal en produccion. Sirve como demostrador del concepto de "leche a la carta", pero no implementa todavia simulador de racion ni prediccion real de perfil lipidico.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `quality/page.tsx`, `MiniCharts.tsx` |
| Modelos implicados | Animales demo |
| Endpoints | `/animals?estado=produccion` |
| Estado | Simulado en frontend |
| Datos utilizados | Valores mock y calculos deterministas |
| Limitaciones | Sin datos LIGAL, NIRS, perfil de acidos grasos ni raciones. |
| Mejoras futuras | Integracion con control lechero, laboratorio, TMR y modelos de composicion. |

### 8.10 Predicciones

La pantalla de predicciones permite cargar predicciones por animal con produccion esperada, composicion y riesgo sanitario. El endpoint devuelve datos mock.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `predictions/page.tsx` |
| Modelos implicados | Ninguno ML activo |
| Endpoints | `/predictions/{animal_id}` y subrutas |
| Estado | Mock |
| Datos utilizados | Respuesta fija/sintetica del backend |
| Limitaciones | Sin entrenamiento, sin dataset real, sin metricas, sin SHAP, sin versionado de modelos. |
| Mejoras futuras | Pipeline ML, validacion temporal, MLflow/Azure ML o alternativa local, explicabilidad. |

### 8.11 Meteorologia

La meteorologia es una de las pocas areas con modelo persistente real. El sistema puede guardar registros sinteticos y consultarlos.

| Aspecto | Descripcion |
|------------------------------------|------------------------------------|
| Componentes implicados | `api.weather()` preparado en frontend, router `weather.py` |
| Modelos implicados | `DatosMetereologicos` |
| Endpoints | `/weather/current`, `/weather/sync`, `/weather/forecast`, `/weather/historical`, `/weather/correlation/impact` |
| Estado | Implementado parcialmente |
| Datos utilizados | Generacion sintetica con fuente AEMET |
| Limitaciones | Sin llamada real a API AEMET; forecast/historical/impact devuelven listas vacias. |
| Mejoras futuras | Cliente AEMET real, normalizacion, historico, correlacion clima-produccion. |

## 9. Flujo de funcionamiento de la aplicacion

### 9.1 Flujo desde el punto de vista del usuario

1.  El usuario accede a `/`.
2.  La pantalla de login comprueba `/health` para mostrar si la API esta disponible.
3.  El usuario selecciona un rol visual y envia usuario/contrasena.
4.  El frontend llama a `POST /api/v1/auth/login`.
5.  Si el login es correcto, guarda token y usuario en `localStorage`, crea cookie `t4m_token` y navega a `/dashboard`.
6.  Las rutas protegidas quedan accesibles mientras exista cookie/token.
7.  El usuario puede navegar a pantallas operativas: dashboard, animales, tareas, alertas, zonas, LeanFarming, calidad y predicciones.
8.  Las pantallas consultan datos mediante React Query y se refrescan en intervalos en algunos casos.

### 9.2 Flujo tecnico de consulta

Ejemplo: listado de animales.

``` text
Pantalla /animals
  -> useQuery(["animals", estadoFilter, page])
      -> api.animals({ skip, limit, estado })
          -> GET /api/v1/animals
              -> frontend_core.animals()
                  -> filtra ANIMALS por estado
                  -> aplica paginacion
              -> respuesta JSON
      -> React Query cachea respuesta
  -> componente AnimalCard renderiza tarjetas
```

### 9.3 Flujo tecnico de modificacion

Ejemplo: completar tarea.

``` text
Usuario pulsa completar tarea
  -> api.completeTask(taskId)
      -> PUT /api/v1/tasks/{task_id}
          body: estado="ejecutada", fecha_ejecucion, resultado
      -> backend busca CoreTask en base de datos
      -> actualiza campos via SQLAlchemy
      -> db.commit() persiste el cambio
      -> devuelve tarea actualizada
  -> React Query invalida queries de tareas y dashboard
  -> UI refresca contadores
```

Este flujo es persistente: la actualizacion se almacena en la tabla `core_tasks` y sobrevive al reinicio del proceso backend.

### 9.4 Flujo de arranque del proyecto

#### Backend local

Comando de arranque local:

``` bash
cd backend
python -m uvicorn app.main:app --reload --port 8000
```

Al arrancar:

1.  Se cargan `settings`.
2.  Se crea el engine SQLAlchemy.
3.  FastAPI ejecuta `lifespan`.
4.  `validate_production_config()` verifica la configuracion en entorno `production`.
5.  `Base.metadata.create_all()` crea todas las tablas ORM si no existen.
6.  `ensure_runtime_schema()` aplica columnas de migracion en caliente si faltan.
7.  `seed_demo_user()` siembra cinco usuarios demo si no existen.
8.  `seed_frontend_data()` puebla las tablas `core_*` desde `demo_data.py` si estan vacias.

#### Frontend local

``` bash
cd frontend
npm run dev
```

Por defecto, `frontend/src/lib/config.ts` usa `NEXT_PUBLIC_API_URL` o `http://localhost:8000`.

#### Docker Compose

``` bash
docker compose up --build
```

Servicios definidos:

- `db`: PostgreSQL 15.
- `redis`: Redis 7.
- `backend`: FastAPI en puerto interno 8000.
- `frontend`: Next.js en puerto interno 3000.
- `nginx`: proxy en puerto 80.

#### Carga de datos semilla

- Usuarios demo: cinco usuarios creados automaticamente al arranque.
- Animales, zonas, tareas, lactaciones, tratamientos, empleados y maquinaria: persisten en las tablas `core_*` desde el primer arranque.
- Alertas: pueden crearse por API o generarse mediante `POST /api/v1/simulation/tick`.
- Incidencias: pueden crearse por el formulario del modo tablet o via simulacion.
- Meteorologia: se genera al llamar a `POST /api/v1/weather/sync`.

## 10. Integracion con APIs externas

La aplicacion esta concebida para integrarse en el futuro con fuentes externas del sector ganadero, entre ellas:

- Robots de ordeno DeLaval VMS.
- Sistemas de control lechero y calidad de leche.
- Datos meteorologicos de AEMET.
- Sistemas de recria y evaluacion sanitaria.
- Carro mezclador TMR.
- Amamantadora automatica.
- Plataformas externas como LIGAL, OVGAN/CEGACOL, ABS o servicios tecnicos.

En la version actual del repositorio no se han integrado APIs reales. El unico modulo que representa una integracion externa concreta es `AemetClient`, pero su implementacion genera datos sinteticos en lugar de consultar el servicio real.

La ausencia de integraciones reales debe explicarse como una limitacion tecnica y contextual del desarrollo, no como un fallo metodologico aislado. En el sector ganadero existen barreras relevantes:

- Ecosistemas cerrados de fabricantes.
- APIs propietarias con acceso restringido.
- Falta de documentacion publica suficiente.
- Necesidad de permisos, contratos o credenciales.
- Datos no normalizados o distribuidos en sistemas inconexos.
- Dificultades de conectividad en entornos rurales.
- Registros historicos incompletos o no estructurados.

El codigo actual permite validar la forma en que esas integraciones se conectarian con el sistema: endpoints REST, cliente API frontend, modelos persistentes para meteorologia y pantallas de visualizacion. En futuras fases, los datos demo podrian sustituirse progresivamente por conectores reales sin redisenar toda la interfaz.

## 11. Datos sinteticos y justificacion metodologica

Faker es una libreria utilizada para generar datos ficticios pero realistas, como nombres, fechas, identificadores, direcciones, valores numericos o registros de ejemplo. En proyectos de software y ciencia de datos, Faker permite poblar bases de datos de desarrollo cuando no se dispone de datos reales o cuando estos no pueden utilizarse por razones de privacidad, confidencialidad o disponibilidad.

En este proyecto, el uso de datos sinteticos responde a una necesidad metodologica clara: la aplicacion esta orientada a una explotacion lechera real, pero durante la fase de desarrollo no se ha dispuesto de acceso efectivo a APIs externas ni a datasets estructurados completos procedentes de robots, sensores, laboratorio o sistemas ganaderos. La falta de acceso a esos datos no es excepcional, sino representativa de una problematica ampliamente documentada en la digitalizacion del sector: muchos datos existen, pero estan fragmentados, cerrados en plataformas propietarias o registrados con formatos poco interoperables.

La version actual del repositorio utiliza datos sinteticos y de demostracion en varios niveles:

- Animales, zonas, tareas, lactaciones, tratamientos, empleados y maquinaria definidos en `backend/app/demo_data.py` y persistidos en BD al arranque.
- Alertas e incidencias creadas via API o mediante el router de simulacion.
- Predicciones mock con produccion, composicion y riesgo.
- Indicadores de calidad simulados en frontend.
- Datos meteorologicos sinteticos generados por `aemet_client.py`.
- Dependencia `faker` declarada para apoyar la generacion de datos, aunque no se ha encontrado uso directo en el codigo activo.

Estos datos permiten validar la estructura general del sistema:

- Contratos API.
- Tipos TypeScript.
- Paginas y componentes.
- Navegacion.
- Filtros y paginacion.
- Estados de tareas y alertas.
- Pantallas TV/tablet por zona.
- Dashboard y graficos.

La principal ventaja metodologica es que el equipo puede comprobar si el sistema esta bien orientado antes de disponer de fuentes reales. Es decir, permite validar el "molde" funcional y tecnico: si las entidades son comprensibles, si las pantallas responden a necesidades de granja, si la API soporta el flujo esperado y si la arquitectura puede evolucionar hacia datos reales.

Sus limitaciones son tambien importantes:

- No permiten entrenar modelos predictivos validos.
- No permiten medir precision, sensibilidad ni especificidad de alertas.
- No reflejan ruido, errores y ausencias propios de datos reales.
- No validan interoperabilidad real con fabricantes.
- No sustituyen pruebas con usuarios en explotacion.

La transicion a datos reales deberia realizarse de forma progresiva:

1.  Definir contratos de datos para cada fuente.
2.  Crear conectores independientes por proveedor o dispositivo.
3.  Reemplazar datos semilla por importaciones desde fuentes reales de la explotacion.
4.  Implementar validacion de calidad de dato.
5.  Registrar trazabilidad de ingesta.
6.  Mantener datos sinteticos como fixtures de test y entorno demo.
7.  Reentrenar modelos predictivos con historicos reales.
8.  Validar resultados con ganaderos, veterinarios y personal tecnico.

## 12. Estado actual del prototipo

| Componente | Estado actual | Nivel de madurez | Observaciones |
|------------------|------------------|------------------|------------------|
| Backend | API FastAPI funcional con RBAC | Medio-alto | 5 routers activos, CRUD completo de dominios ganaderos, control de acceso por rol. |
| Frontend | Next.js con pantallas operativas y gestion | Medio-alto | Cobertura visual amplia, pantalla de gestion de datos maestros y permisos por rol en cliente. |
| Base de datos | SQLAlchemy con 11 modelos activos | Medio | Todos los dominios ganaderos principales persistidos; datos sinteticos como semilla. |
| Modelos de datos | Tipos frontend y ORM alineados | Medio | TypeScript y modelos ORM cubren las mismas entidades. |
| API interna | Contratos suficientes para MVP con CRUD | Medio-alto | Buen soporte para pantallas; varios endpoints de prediccion y meteorologia avanzada siguen como stubs o mocks. |
| Datos sinteticos | Demo semilla persistida en BD | Medio | Utiles para validar flujos; no equivalen a datos reales de granja. |
| Simulacion operativa | Router de simulacion para generar actividad | Medio | Permite poblar la BD con tareas, alertas e incidencias para demos mas completas. |
| Integracion APIs externas | No integrada | Bajo | Solo AEMET esta preparado parcialmente y simulado. |
| Asistente operativo | Implementado pero desactivado por defecto | Bajo-medio | Router y servicio existen; se activa con `enable_assistant=true`. |
| Dashboards | Implementados visualmente con datos reales de BD | Medio | KPIs consultan tablas `core_*`; graficos de tendencia siguen con series fijas. |
| Gestion de usuarios | Login JWT con RBAC real | Medio | Roles validados en backend; falta administracion desde UI y recuperacion de contrasena. |
| Seguridad/autenticacion | JWT, RBAC y hash de password | Medio | Clave dev por defecto no apta para produccion; `validate_production_config()` lo detecta. |
| Despliegue | Docker Compose y Nginx | Medio | Reproducible localmente; no hay pipeline productivo cloud. |
| Testing | Tests backend existentes | Medio | Hay pruebas de contratos y auth; no se observan tests frontend. |
| Documentacion | README y documentos tecnicos | Medio | Documentacion actualizada para reflejar el estado real del codigo. |
| Redis/cache | Infraestructura preparada | Bajo | Docker y scripts existen, pero routers activos no usan cache. |
| ML | Endpoint mock | Bajo | Sin modelos entrenados ni pipeline. |

## 13. Limitaciones detectadas

1.  **Falta de integracion con APIs reales.** No hay conexion efectiva con DeLaval, LIGAL, OVGAN/CEGACOL, ABS, TMR, amamantadora o sensores. AEMET esta simulado.

2.  **Datos sinteticos como semilla.** Los datos ganaderos parten de un conjunto reducido (3 animales, 3 zonas, 2 tareas, etc.). Permiten validar estructura y UI, pero no representan la variabilidad real de una explotacion.

3.  **Stubs en endpoints de analisis avanzado.** Los endpoints de prediccion de alertas, forecast meteorologico, historico meteorologico e impacto clima-produccion devuelven listas vacias o estructuras minimas.

4.  **Configuracion de seguridad de desarrollo.** El `secret_key` por defecto no es adecuado para produccion. La funcion `validate_production_config()` lo detecta y lanza error si `ENVIRONMENT=production`, pero exige que el operador cambie el valor explicitamente.

5.  **Migracion SQL no alineada con modelos activos.** La migracion `001_add_performance_indexes.sql` referencia tablas de una arquitectura mas amplia que la actualmente activa en SQLAlchemy.

6.  **Ausencia de pipeline ML real.** Las predicciones son demostrativas y no existen entrenamiento, evaluacion ni versionado de modelos.

7.  **Calidad de leche simulada en cliente.** La pantalla es util como demostrador, pero no consume datos reales de laboratorio ni de composicion.

8.  **Falta de pruebas frontend.** No se han identificado tests automatizados de componentes, rutas o flujos de usuario.

9.  **Despliegue productivo no cerrado.** Existe Docker Compose, pero no se observa infraestructura cloud, CI/CD ni configuracion productiva completa.

10. **Validacion con usuarios reales no verificable.** El repositorio no aporta evidencias de pruebas en explotacion.

Estas limitaciones son coherentes con un MVP academico y no invalidan el valor del trabajo. Delimitan con precision que se ha construido y que queda por desarrollar.

## 14. Trabajo futuro

Las lineas de mejora mas relevantes son:

| Linea futura | Descripcion |
|------------------------------------|------------------------------------|
| Datos reales | Sustituir progresivamente los datos semilla de `demo_data.py` por importaciones desde fuentes reales de la explotacion. |
| Turnos y planificacion | Crear modelos `turnos`, `asignaciones_turno` y scheduler de tareas recurrentes. |
| Uso formal de Faker | Incorporar scripts reproducibles de seed con Faker para entornos de desarrollo y test. |
| APIs externas | Desarrollar conectores para robots de ordeno, calidad de leche, meteorologia real, TMR y otros sistemas. |
| AEMET real | Implementar llamadas HTTP a AEMET usando `AEMET_API_KEY`, normalizacion y almacenamiento historico. |
| Robots DeLaval | Integrar lecturas de ordeño, produccion, conductividad, grasa, proteina, lactosa, rechazos y alarmas. |
| Calidad de leche | Integrar datos LIGAL/NIRS y modelar perfil composicional. |
| Leche a la carta | Implementar simulador de racion y prediccion de perfil lipidico. |
| Analitica avanzada | Entrenar modelos de produccion, composicion y riesgo sanitario con datos reales. |
| Explicabilidad | Incorporar interpretabilidad local/global, por ejemplo SHAP, cuando existan modelos reales. |
| Alertas | Definir motor de reglas y notificaciones por severidad. |
| Roles y permisos | Implementar RBAC para administrador, veterinario, operario y alimentacion. |
| PWA/tablet | Convertir frontend en PWA real con soporte offline y optimizacion tactil. |
| Redis | Usar cache en endpoints de dashboard y pantallas de zona. |
| Tests | Ampliar test backend y anadir tests frontend/E2E. |
| Despliegue | Definir pipeline CI/CD, variables seguras, backups y monitorizacion. |
| Validacion con usuarios | Realizar pruebas en granja, recoger feedback y ajustar la interfaz. |

## 15. Conclusion tecnica

La aplicacion desarrollada constituye una base funcional para un sistema digital de apoyo a la gestion de explotaciones lecheras. El proyecto ha materializado una arquitectura web con backend, frontend, autenticacion, API REST, base de datos, pantallas operativas y flujos demostrativos para animales, tareas, alertas, zonas, calidad, predicciones y LeanFarming.

El valor principal del resultado no esta en haber completado ya toda la plataforma DSS descrita teoricamente, sino en haber construido un prototipo navegable y extensible que demuestra como podria organizarse la informacion de una granja lechera en una interfaz unica. La aplicacion permite validar el enfoque de gestion visual por zonas, el uso de dashboards, la digitalizacion de tareas y la preparacion de endpoints para futuros datos reales.

Al mismo tiempo, el analisis del codigo obliga a una conclusion equilibrada: la version actual es un MVP. Los dominios ganaderos principales ya tienen persistencia real en base de datos, autenticacion con control de acceso por rol y CRUD funcional, pero los datos siguen siendo sinteticos o de demostracion, las integraciones externas no estan implementadas y los modelos predictivos son simulados. Para alcanzar todo su potencial como DSS, el sistema necesita conectarse a fuentes reales, importar datos historicos de la explotacion, entrenar modelos con esos datos y validarse en condiciones de uso real.

En terminos academicos, el resultado obtenido es una prueba de arquitectura y de experiencia de usuario que sienta las bases para una herramienta completa de apoyo a la decision en ganaderia de leche. La aplicacion muestra que el planteamiento es tecnicamente viable, aunque su madurez funcional depende de la siguiente fase: pasar de datos sinteticos y contratos internos a datos reales, conectores robustos y evaluacion en explotacion.

## 16. Anexos tecnicos

### 16.1 Arbol de carpetas relevante

``` text
proyecto-tfm-mvp/
  README.md
  docker-compose.yml
  nginx/
    nginx.conf
  backend/
    Dockerfile
    requirements.txt
    pytest.ini
    .env.example
    app/
      main.py
      config.py
      database.py
      security.py
      demo_data.py
      openapi.py
      time_utils.py
      models/
        __init__.py
        usuario.py
        datos_metereologicos.py
        frontend_core.py
      routers/
        auth.py
        assistant.py
        frontend_core.py
        simulation.py
        weather.py
      schemas/
        api.py
      services/
        aemet_client.py
        assistant_service.py
        frontend_seed.py
        simulation_service.py
    migrations/
    scripts/
    sql/
    tests/
  frontend/
    Dockerfile
    package.json
    next.config.ts
    tailwind.config.ts
    src/
      app/
        (app)/
          management/page.tsx
          ...otras paginas
      components/
      features/
      hooks/
      lib/
        api.ts
        config.ts
        pagination.ts
        permissions.ts
        types.ts
      store/
      proxy.ts
```

### 16.2 Tabla resumida de modelos activos

| Modelo | Tabla | Persistido | Observaciones |
|------------------|------------------|------------------|------------------|
| `Usuario` | `usuarios` | Si | Soporta autenticacion y RBAC. Incluye campo `role`. |
| `DatosMetereologicos` | `datos_metereologicos` | Si | Datos climaticos sinteticos y consulta actual. |
| `CoreAnimal` | `core_animals` | Si | Semilla: Luna, Nube, Brisa. CRUD completo via API. |
| `CoreZone` | `core_zones` | Si | Semilla: Sala de ordeno, Paridera, Recria. |
| `CoreTask` | `core_tasks` | Si | Semilla: 2 tareas. Se pueden crear y completar. |
| `CoreAlert` | `core_alerts` | Si | Sin semilla inicial; se crean via API o simulacion. |
| `CoreIncident` | `core_incidents` | Si | Sin semilla inicial; se crean desde modo tablet o API. |
| `CoreLactation` | `core_lactations` | Si | Semilla: 2 lactaciones activas (Luna, Nube). |
| `CoreTreatment` | `core_treatments` | Si | Semilla: 1 tratamiento activo (Nube). |
| `CoreEmployee` | `core_employees` | Si | Semilla: Roberto Castro, Laura Fernandez, Dr. Mendez. |
| `CoreMachinery` | `core_machinery` | Si | Semilla: Robot de ordeno, Mezclador unifeed. |

### 16.3 Dependencias principales

#### Backend

``` text
fastapi
uvicorn[standard]
sqlalchemy
psycopg[binary]
pydantic
pydantic-settings
python-dotenv
httpx
faker
bcrypt
passlib[bcrypt]
python-jose[cryptography]
pytest
pytest-asyncio
redis
```

#### Frontend

``` text
next
react
react-dom
@tanstack/react-query
zustand
lucide-react
typescript
tailwindcss
eslint
```

### 16.4 Comandos de ejecucion

#### Backend local

``` bash
cd backend
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

#### Frontend local

``` bash
cd frontend
npm install
npm run dev
```

#### Docker

``` bash
docker compose up --build
```

### 16.5 Variables de entorno relevantes

| Variable | Funcion |
|------------------------------------|------------------------------------|
| `DATABASE_URL` | URL de conexion a base de datos. |
| `DATABASE_ECHO` | Log SQL. |
| `ENVIRONMENT` | Entorno (`development` / `production`). |
| `DEBUG` | Modo debug. |
| `SECRET_KEY` | Firma de JWT. |
| `AEMET_API_KEY` | Clave prevista para AEMET. |
| `AEMET_MUNICIPIO_ID` | Municipio meteorologico. |
| `AEMET_ESTACION_ID` | Estacion meteorologica. |
| `ENABLE_SIMULATION` | Activa el router de simulacion operativa (`True` por defecto). |
| `SIMULATION_MAX_TASKS` | Limite de tareas simuladas (80 por defecto). |
| `SIMULATION_MAX_ALERTS` | Limite de alertas simuladas (40 por defecto). |
| `SIMULATION_MAX_INCIDENTS` | Limite de incidencias simuladas (60 por defecto). |
| `ENABLE_ASSISTANT` | Activa el router del asistente operativo (`False` por defecto). |
| `CORS_ORIGINS` | Origenes permitidos. |
| `NEXT_PUBLIC_API_URL` | URL publica de la API para frontend (por defecto `http://localhost:8000`). |
| `NEXT_PUBLIC_ENABLE_ASSISTANT` | Activa la UI del asistente en el frontend. |

### 16.6 Observaciones tecnicas relevantes

- El backend y frontend estan suficientemente conectados para demostrar un flujo completo de autenticacion, gestion y consulta con datos reales de BD.
- La mayor diferencia entre el planteamiento teorico y el codigo actual esta en la integracion de fuentes externas (robots, LIGAL, AEMET real) y en los modelos predictivos.
- Los dominios ganaderos principales (animales, zonas, tareas, alertas, incidencias, lactaciones, tratamientos, empleados, maquinaria) tienen persistencia real en base de datos desde el arranque.
- El archivo `backend/sql/schema.sql` esta vacio: la base de datos se crea desde SQLAlchemy (`Base.metadata.create_all()`), no desde un script SQL completo.
- La migracion de indices (`001_add_performance_indexes.sql`) referencia tablas de una arquitectura mas amplia que la actualmente activa. Se puede aplicar manualmente cuando el esquema avance.
- Redis esta preparado en infraestructura (Docker Compose y scripts), pero no se usa en endpoints activos.
- Las predicciones y la calidad de leche son demostradores de interfaz y contrato, no modelos analiticos validados con datos reales.
- El router de simulacion permite generar actividad operativa variada en la BD para demostraciones y pruebas sin necesidad de datos reales.
- El asistente operativo esta implementado pero desactivado por defecto; se activa mediante `ENABLE_ASSISTANT=true`.
