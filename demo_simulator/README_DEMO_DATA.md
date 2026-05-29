# Tools4Milk — Demo Data Simulator

Sistema externo de datos demo para poblar la base de datos PostgreSQL con datos
realistas que permiten demostrar todas las funcionalidades del MVP frontend.

> **Importante:** Estos scripts NO modifican el backend, el frontend, los modelos,
> las migraciones ni los endpoints. Solo operan sobre la base de datos PostgreSQL.

---

## Estructura de archivos

```
demo_simulator/
├── demo_config.py              # Configuración, constantes y listas de datos realistas
├── db.py                       # Utilidades de conexión y validación
├── seed_realistic_demo_data.py # Seed principal: crea la explotación demo
├── run_live_demo_simulator.py  # Simulador vivo: mantiene los datos en movimiento
└── README_DEMO_DATA.md         # Este archivo
```

---

## Requisitos

- Python 3.10+
- SQLAlchemy 2.x (`pip install sqlalchemy`)
- psycopg (`pip install psycopg`) o psycopg2 (`pip install psycopg2-binary`)
- Acceso a la base de datos PostgreSQL de Tools4Milk

### Instalación rápida de dependencias

```bash
pip install "sqlalchemy>=2.0" "psycopg[binary]"
```

---

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `DEMO_MODE` | `false` | **Obligatorio**: debe ser `true` para ejecutar |
| `DATABASE_URL` | `postgresql+psycopg://postgres:postgres@localhost:5432/tools4milk` | URL de conexión |
| `RESET_DEMO_DATA` | `false` | `true` para limpiar datos demo antes de reinsertar |
| `DEMO_ANIMALS` | `120` | Número de animales demo a crear |
| `SIM_INTERVAL_SECONDS` | `30` | Segundos entre ciclos del simulador |

---

## Cómo ejecutar el seed (desde host local)

```bash
# Requisito: el contenedor de base de datos debe estar levantado
docker compose up -d db

# Seed básico (crea todos los datos demo)
DEMO_MODE=true python demo_simulator/seed_realistic_demo_data.py

# Con número personalizado de animales
DEMO_MODE=true DEMO_ANIMALS=80 python demo_simulator/seed_realistic_demo_data.py

# Con DATABASE_URL personalizada
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/tools4milk \
  DEMO_MODE=true python demo_simulator/seed_realistic_demo_data.py
```

---

## Cómo ejecutar el seed (desde Docker — recomendado para producción)

```bash
# Ejecutar el seed dentro del contenedor backend
docker compose exec backend sh -c "
  cd /app &&
  pip install sqlalchemy 'psycopg[binary]' -q &&
  DATABASE_URL=postgresql+psycopg://postgres:postgres@db:5432/tools4milk \
  DEMO_MODE=true \
  python demo_simulator/seed_realistic_demo_data.py
"

# Alternativa: copiar el directorio dentro del contenedor
docker compose cp demo_simulator/ backend:/app/demo_simulator/
docker compose exec backend sh -c "
  DATABASE_URL=postgresql+psycopg://postgres:postgres@db:5432/tools4milk \
  DEMO_MODE=true \
  python /app/demo_simulator/seed_realistic_demo_data.py
"
```

> **Nota:** Dentro de Docker, el host de la base de datos es `db`, no `localhost`.
> Usa siempre `DATABASE_URL=postgresql+psycopg://postgres:postgres@db:5432/tools4milk`
> cuando ejecutes desde dentro del contenedor.

---

## Cómo ejecutar el simulador vivo

El simulador mantiene los datos en movimiento durante una demo: completa tareas,
crea incidencias, resuelve alertas, avanza pedidos, etc.

```bash
# Simulador con intervalo de 30 segundos (default)
DEMO_MODE=true python demo_simulator/run_live_demo_simulator.py

# Simulador más rápido (10 segundos entre ciclos)
DEMO_MODE=true SIM_INTERVAL_SECONDS=10 python demo_simulator/run_live_demo_simulator.py

# Desde Docker
docker compose exec backend sh -c "
  DATABASE_URL=postgresql+psycopg://postgres:postgres@db:5432/tools4milk \
  DEMO_MODE=true SIM_INTERVAL_SECONDS=20 \
  python demo_simulator/run_live_demo_simulator.py
"
```

### Parar el simulador

Presiona `Ctrl+C`. El simulador para limpiamente.

---

## Cómo resetear (limpiar y reinsertar datos demo)

```bash
# Limpiar datos demo y volver a insertar (pide confirmación)
DEMO_MODE=true RESET_DEMO_DATA=true python demo_simulator/seed_realistic_demo_data.py
```

El script pedirá confirmación explícita:
```
⚠️  MODO RESET ACTIVADO
  Escribe SI para confirmar:
```

> **Seguridad:** Solo se borran registros marcados con el prefijo/sufijo demo.
> Nunca se eliminan datos sin marcador demo.

---

## Qué datos crea el seed

| Entidad | Cantidad | Marcador demo |
|---|---|---|
| Empleados | 12 | Email `@tools4milk.demo` |
| Maquinaria | ~12 (5 ya existen) | Campo `notas` con `[DEMO]` |
| Animales | 120 (configurable) | Crotal `DEM-XXXX` |
| Lactaciones | ~80-100 activas e históricas | Campo `notas` con `[DEMO]` |
| Tratamientos activos | 8-15 | Animal marcado |
| Turnos (14 días) | ~28 | Campo `notas` con `[DEMO]` |
| Asignaciones de turno | ~100 | Asociadas a turnos demo |
| Tareas ejecuciones | 55-75 | Campo `notas` con `[DEMO]` |
| Incidencias | 18-25 | Título con `[DEMO]` |
| Alertas | 22-35 | Título con `[DEMO]` |
| Pedidos | 11 | Insumo con `[DEMO]` |
| Resúmenes de relevo | 5-10 | Notas con `[DEMO]` |
| Lecturas meteorológicas | 72 | `estacion_id = DEMO_LUGO_01` |

### Datos pre-existentes (init.sql — no se duplican)

| Entidad | Registros | Acción |
|---|---|---|
| Zonas | 5 | Se reusan (no se insertan nuevas) |
| Maquinaria | 5 | Se asignan zonas |
| Catálogo de tareas | 7 | Se usan para crear ejecuciones |
| Tareas recurrentes | 4 | Se usan como referencia |
| Umbrales de alerta | 7 | Se referencian en alertas |

---

## Qué hace el simulador en cada ciclo

Cada `SIM_INTERVAL_SECONDS` segundos ejecuta aleatoriamente 1-2 de estas acciones:

| Acción | Probabilidad | Descripción |
|---|---|---|
| Completar tarea | Alta | Marca como completada una tarea pendiente |
| Marcar vencida | Siempre | Marca vencidas tareas con > 2h de retraso |
| Crear tarea | Media | Crea nueva tarea planificada en futuro |
| Añadir lectura meteo | Media | Inserta lectura meteorológica |
| Resolver alerta | Media | Resuelve la alerta más antigua |
| Avanzar pedido | Media | Mueve un pedido al siguiente estado |
| Avanzar incidencia | Media | Avanza estado de incidencia abierta |
| Crear alerta | Media-baja | Crea alerta nueva |
| Crear incidencia | Baja | Crea incidencia ocasional |
| Crear turno siguiente | Baja | Crea turnos de mañana si no existen |
| Crear relevo | Muy baja | Crea resumen de relevo si es hora de cambio |

---

## Cómo verificar en la aplicación

Después del seed, navega a estas pantallas:

| Pantalla | Qué deberías ver |
|---|---|
| `/dashboard` | KPIs con datos reales: animales, tareas, alertas, producción |
| `/animals` | 120 animales con estados distribuidos |
| `/animals/DEM-0001` | Ficha con lactaciones, tratamientos, alertas |
| `/quality` | Animales en producción con lactaciones activas |
| `/tasks` | Tareas en varios estados: programadas, retrasadas, ejecutadas |
| `/alerts` | Alertas activas y resueltas |
| `/incidents` | Incidencias en varios estados |
| `/orders` | Pedidos en distintas etapas del workflow |
| `/shifts` | Turnos de las últimas 2 semanas con empleados |
| `/handover` | Resúmenes de relevo recientes |
| `/zones` | Zonas con maquinaria asignada y tareas |
| `/zones/[id]` | Modo gestión con incidencias, maquinaria, meteo |
| `/leanfarming` | Tareas agrupadas por zona con turno actual |
| `/tv` | TV global con alertas, turnos y zonas con estado |
| `/tv/shifts` | Tablero de turnos con nombres de empleados |
| `/integration` | Panel de estado con temperatura actual |
| `/report` | Informe semanal con datos reales del período |

---

## Limitaciones conocidas

1. **Calidad de leche (grasa/proteína/RCS):** El modelo `lactaciones` no tiene
   columnas para estos campos. La página `/quality` mostrará "N/D" para composición
   aunque existan lactaciones. Es una limitación del esquema actual, no del seed.

2. **Alertas nivel "crítica":** No se usa este valor porque no está en el enum
   PostgreSQL `nivel_alerta`. Se usa "alta" como máximo nivel.

3. **Estado animal "crianza":** No existe en el enum DB. Solo se usan:
   `produccion`, `seca`, `recria`, `gestante`, `baja`.

4. **Seed idempotente:** Puede ejecutarse múltiples veces. Detecta datos demo
   ya existentes y los omite (no duplica).

---

## Riesgos y precauciones

- **Nunca ejecutar sin `DEMO_MODE=true`** — el script abortará sin esa variable.
- **Verificar DATABASE_URL** antes de ejecutar en producción.
- **El reset es irreversible** — solicita confirmación explícita.
- Los datos demo solo se borran con `RESET_DEMO_DATA=true` y confirmación.
- No confundir `db` (host Docker) con `localhost` (host local).

---

## Flujo recomendado para una demostración

```bash
# 1. Levantar la aplicación
docker compose up -d

# 2. Crear datos demo (ejecutar una vez)
DEMO_MODE=true python demo_simulator/seed_realistic_demo_data.py

# 3. Iniciar el simulador vivo en una terminal aparte
DEMO_MODE=true SIM_INTERVAL_SECONDS=20 python demo_simulator/run_live_demo_simulator.py

# 4. Acceder a la aplicación en http://localhost
#    Usuario demo: admin / testpass123

# 5. Al finalizar la demo, parar el simulador con Ctrl+C
```
