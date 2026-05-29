AUDITORÍA TÉCNICA — Tools4Milk MVP — Base de Datos y Backend
Basada en: database/init.sql, backend/app/models/tools4milk.py, servicios, repositorios, demo_data.py, migraciones.
Sin modificar ningún archivo.

1. Listado completo de tablas detectadas
1.1 Esquema principal Tools4Milk (25 tablas)
Las tablas operadas por el backend actual son las del esquema tools4milk.py. La tabla usuarios viene de las migraciones.

#	Tabla	Modelo SQLAlchemy	Descripción
1	zonas	Zona	Zonas físicas de la explotación
2	empleados	Empleado	Personal con rol operativo
3	maquinaria	Maquinaria	Equipos y máquinas por zona
4	animales	Animal	Registro maestro del censo
5	lactaciones	Lactacion	Ciclos de lactación por animal
6	tratamientos_activos	TratamientoActivo	Tratamientos veterinarios activos
7	eventos_sanitarios	EventoSanitario	Historial sanitario
8	incidencias	Incidencia	Incidencias operativas
9	alertas_umbrales	AlertaUmbral	Configuración de umbrales de alerta
10	alertas	Alerta	Alertas generadas
11	tareas_catalogo	TareaCatalogo	Tipos de tarea disponibles
12	tareas_recurrentes	TareaRecurrente	Programaciones recurrentes
13	tareas_ejecuciones	TareaEjecucion	Instancias de tareas planificadas
14	turnos	Turno	Turnos de trabajo
15	asignaciones_turno	AsignacionTurno	Empleados asignados a turno/zona
16	pedidos	Pedido	Pedidos de suministros
17	resumenes_relevo	ResumenRelevo	Documentación de cambio de turno
18	lecturas_meteorologia	LecturaMeteo	Series temporales meteo
19	lecturas_robot_ordeno	LecturaRobotOrdeno	Lecturas por ordeño individual
20	lecturas_carro_mezclador	LecturaCarroMezclador	Lecturas del carro TMR
21	eventos_reproductivos	EventoReproductivo	Celos, inseminaciones, partos
22	eventos_sanitarios_recria	EventoSanitarioRecria	Scores sanitarios de terneros
23	genomica	Genomica	Análisis genéticos
24	boxes_recria	BoxRecria	Boxes individuales de terneros
25	audit_log	AuditLog	Registro de auditoría (trigger automático)
1.2 Tablas pre-pobladas por init.sql
Estas tablas ya tienen datos al inicializar la BD:

Tabla	Registros pre-insertados
zonas	5 zonas fijas (Nave, Becerrero, Enfermería, Oficina, General)
maquinaria	5 máquinas (3 robots VMS, carro TMR, amamantadora)
tareas_catalogo	7 tipos de tarea
tareas_recurrentes	4 planificaciones recurrentes
alertas_umbrales	7 umbrales configurados
1.3 Tablas legacy (core_*)
Existen en migraciones (0001_core_frontend.sql) pero no son leídas por los routers actuales. No deben poblarse con datos nuevos.

2. Campos y relaciones detalladas
zonas
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí (PK)	uuid_generate_v4()	—
nombre	VARCHAR(100)	Sí	—	—
codigo	VARCHAR(30)	Sí	—	—
descripcion	TEXT	No	—	—
tiene_pantalla_tv	BOOLEAN	Sí	FALSE	—
tiene_tablet	BOOLEAN	Sí	FALSE	—
Restricciones: UNIQUE(nombre), UNIQUE(codigo). Los 5 registros pre-insertados usan codigo corto (sala_ordeno, becerrero, etc.).

empleados
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí (PK)	auto	—
nombre	VARCHAR(100)	Sí	—	—
apellidos	VARCHAR(150)	Sí	—	—
rol	rol_empleado ENUM	Sí	—	—
cualificaciones	TEXT[]	No	{}	—
telefono	VARCHAR(20)	No	—	—
email	VARCHAR(150)	No	—	—
activo	BOOLEAN	Sí	TRUE	—
fecha_alta	DATE	Sí	CURRENT_DATE	—
fecha_baja	DATE	No	—	—
CHECK: fecha_baja IS NULL OR fecha_baja >= fecha_alta

maquinaria
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí (PK)	auto	—
nombre	VARCHAR(100)	Sí	—	—
tipo	tipo_maquinaria ENUM	Sí	—	—
zona_id	UUID	No	—	→ zonas.id ON DELETE SET NULL
marca / modelo	VARCHAR(100)	No	—	—
numero_serie	VARCHAR(100)	No	—	UNIQUE
fecha_instalacion	DATE	No	—	—
activa	BOOLEAN	Sí	TRUE	—
notas	TEXT	No	—	—
animales
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí (PK)	auto	—
crotal_oficial	VARCHAR(20)	Sí	—	UNIQUE
nombre	VARCHAR(80)	No	—	—
sexo	sexo_animal ENUM	Sí	'hembra'	—
fecha_nacimiento	DATE	Sí	—	—
raza	VARCHAR(80)	No	—	—
estado	estado_animal ENUM	Sí	'recria'	—
estado_reproductivo	estado_reproductivo ENUM	No	—	—
madre_id	UUID	No	—	→ animales.id (autorreferencia)
fecha_entrada	DATE	Sí	CURRENT_DATE	—
fecha_baja / motivo_baja	DATE / VARCHAR	No	—	—
CHECK: fecha_baja IS NULL OR fecha_baja >= fecha_nacimiento

lactaciones
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí (PK)	auto	—
animal_id	UUID	Sí	—	→ animales.id
numero	SMALLINT	Sí	—	—
fecha_parto	DATE	Sí	—	—
fecha_secado	DATE	No	—	—
produccion_total_kg	NUMERIC(8,2)	No	—	—
notas	TEXT	No	—	—
UNIQUE(animal_id, numero) — CHECK: fecha_secado IS NULL OR fecha_secado > fecha_parto

⚠️ CRÍTICO para demo: Esta tabla NO tiene campos de grasa_promedio, proteina_promedio, rcs_promedio ni produccion_promedio. El servicio lactations_service.serialize() devuelve siempre None para esos campos. La página /quality mostrará "N/D" en composición aunque existan lactaciones.

tratamientos_activos
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí	auto	—
animal_id	UUID	Sí	—	→ animales.id
evento_sanitario_id	UUID	No	—	→ eventos_sanitarios.id
farmaco	VARCHAR(200)	Sí	—	—
dosis / via_administracion	VARCHAR	No	—	—
dias_tratamiento	SMALLINT	Sí	—	CHECK > 0
fecha_inicio / fecha_fin_prevista	DATE	Sí	—	—
fecha_fin_real	DATE	No	—	—
activo	BOOLEAN	Sí	TRUE	—
checkboxes	JSONB	Sí	[]	—
prescrito_por	UUID	No	—	→ empleados.id
incidencias
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí	auto	—
tipo	tipo_incidencia ENUM	Sí	—	—
severidad	nivel_severidad ENUM	Sí	'media'	—
estado	estado_incidencia ENUM	Sí	'abierta'	—
titulo	VARCHAR(200)	Sí	—	—
descripcion	TEXT	No	—	—
zona_id	UUID	No	—	→ zonas.id
maquinaria_id	UUID	No	—	→ maquinaria.id
animal_id	UUID	No	—	→ animales.id
reportado_por / asignado_a	UUID	No	—	→ empleados.id
ts_apertura	TIMESTAMPTZ	Sí	NOW()	—
ts_cierre	TIMESTAMPTZ	No	—	—
acciones	JSONB	Sí	[]	—
alertas
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí	auto	—
umbral_id	UUID	No	—	→ alertas_umbrales.id
nivel	nivel_alerta ENUM (DB) / String (modelo)	Sí	—	—
titulo	VARCHAR(200)	Sí	—	—
mensaje	TEXT	No	—	—
origen_tabla / origen_id	VARCHAR / UUID	No	—	—
animal_id	UUID	No	—	→ animales.id
zona_id	UUID	No	—	→ zonas.id
activa	BOOLEAN	Sí	TRUE	—
ts_generacion	TIMESTAMPTZ	Sí	NOW()	—
ts_resolucion	TIMESTAMPTZ	No	—	—
resuelta_por	UUID	No	—	→ empleados.id
⚠️ IMPORTANTE: La DB tiene enum nivel_alerta ('baja', 'media', 'alta') pero el modelo SQLAlchemy usa String(20), por lo que se puede insertar "critica" sin error desde Python. El frontend espera severidad: "baja" | "media" | "alta" | "critica".

tareas_catalogo (pre-poblada)
Campo	Tipo	Obligatorio	Default
id	UUID	Sí	auto
codigo	VARCHAR(60)	Sí	—
nombre	VARCHAR(150)	Sí	—
descripcion	TEXT	No	—
cualificacion_requerida	TEXT	No	—
duracion_estimada_min	INTEGER	No	—
activa	BOOLEAN	Sí	TRUE
Ya contiene: lavado_robot, desinfeccion_camas, limpieza_bebederos, preparacion_racion, revision_terneros, control_tratamientos, recogida_muestras.

tareas_ejecuciones
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí	auto	—
catalogo_id	UUID	Sí	—	→ tareas_catalogo.id
recurrente_id	UUID	No	—	→ tareas_recurrentes.id
empleado_id	UUID	No	—	→ empleados.id
zona_id	UUID	No	—	→ zonas.id
maquinaria_id	UUID	No	—	→ maquinaria.id
estado	estado_tarea ENUM	Sí	'pendiente'	—
ts_planificada	TIMESTAMPTZ	Sí	—	—
ts_inicio / ts_fin	TIMESTAMPTZ	No	—	—
notas	TEXT	No	—	—
creado_en	TIMESTAMPTZ	Sí	NOW()	—
⚠️ MAPEO DE ESTADO: El estado en DB usa enum distinto al frontend:

DB pendiente ↔ Frontend programada
DB vencida ↔ Frontend retrasada
DB completada ↔ Frontend ejecutada
DB cancelada ↔ Frontend cancelada
turnos
Campo	Tipo	Obligatorio	Default	Restricción
id	UUID	Sí	auto	—
fecha	DATE	Sí	—	UNIQUE con tipo_turno
tipo_turno	tipo_turno ENUM	Sí	—	'manana' | 'tarde'
hora_inicio / hora_fin	TIME	Sí	—	—
notas	TEXT	No	—	—
asignaciones_turno
Campo	Tipo	Obligatorio	FK
id	UUID	Sí	—
turno_id	UUID	Sí	→ turnos.id ON DELETE CASCADE
empleado_id	UUID	Sí	→ empleados.id
zona_id	UUID	No	→ zonas.id
rol	VARCHAR(80)	No	—
UNIQUE(turno_id, empleado_id)

pedidos
Campo	Tipo	Obligatorio	Default	FK
id	UUID	Sí	auto	—
insumo	VARCHAR(200)	Sí	—	—
cantidad	NUMERIC(10,2)	Sí	—	CHECK > 0
unidad	VARCHAR(30)	No	—	—
estado	estado_pedido ENUM	Sí	'solicitado'	—
solicitante_id	UUID	No	—	→ empleados.id
ts_solicitud	TIMESTAMPTZ	Sí	NOW()	—
ts_aprobacion / ts_recepcion	TIMESTAMPTZ	No	—	—
proveedor	VARCHAR(150)	No	—	—
coste_estimado / coste_real	NUMERIC(10,2)	No	—	—
lecturas_meteorologia (PK compuesta)
Campo	Tipo	Obligatorio	Nota
ts	TIMESTAMPTZ	Sí (PK)	—
estacion_id	VARCHAR(20)	Sí (PK)	—
temperatura_c	NUMERIC(4,1)	No	—
humedad_relativa	NUMERIC(4,1)	No	—
precipitacion_mm	NUMERIC(5,1)	No	—
viento_km_h	NUMERIC(5,1)	No	—
direccion_viento	SMALLINT	No	—
radiacion_wm2	NUMERIC(6,1)	No	—
indice_thermo_humedad	NUMERIC (GENERATED)	—	Solo lectura, calculado
resumenes_relevo
Campo	Tipo	Obligatorio	FK
id	UUID	Sí	—
turno_saliente_id	UUID	Sí	→ turnos.id
turno_entrante_id	UUID	Sí	→ turnos.id
ts_generacion	TIMESTAMPTZ	Sí	—
incidencias_abiertas / tareas_pendientes / alertas_pendientes	JSONB	Sí	[]
notas_saliente	TEXT	No	—
confirmado_por	UUID	No	→ empleados.id
ts_confirmacion	TIMESTAMPTZ	No	—
CHECK: turno_saliente_id <> turno_entrante_id

3. Enums y valores válidos
Enum	Valores
rol_empleado	encargado, auxiliar, veterinario, mecanico
tipo_maquinaria	robot_ordeno, carro_mezclador, amamantadora, bomba, otro
estado_tarea (DB)	pendiente, en_curso, completada, vencida, cancelada
tipo_turno	manana, tarde
estado_pedido	solicitado, aprobado, en_transito, recibido, cancelado
tipo_incidencia	averia_maquinaria, infraestructura, sanidad_animal, calidad_leche, alimentacion, pedidos
nivel_severidad (incidencias)	baja, media, alta
estado_incidencia	abierta, en_gestion, resuelta, cerrada
nivel_alerta	baja, media, alta (el modelo usa String, se puede insertar "critica")
estado_animal (DB)	produccion, seca, recria, gestante, baja
estado_reproductivo (DB)	vacia, en_celo, inseminada, confirmada_gestante, parto_reciente
tipo_evento_repro	celo, inseminacion, diagnostico_gestacion, aborto, parto, secado
tipo_patologia	mastitis, cojera, metritis, cetosis, desplazamiento_abomaso, neumonia, diarrea, otra
sexo_animal	hembra, macho
Discrepancias frontend vs. backend:

Frontend espera Animal.estado: "crianza" → NO existe en DB enum. Lo más cercano es recria.
Frontend espera Alert.severidad: "critica" → NO es valor del enum DB, pero se puede insertar como String.
Estado "gestante" y "seca" existen en DB pero no en el tipo frontend.
Estado reproductivo "lactante" y "prenada" del demo_data.py NO son valores válidos del enum DB.
4. Clasificación funcional de tablas
Grupo 1: Tablas maestras (deben poblarse primero)
Tabla	Rol	Ya pre-poblada
zonas	Referencia geográfica base	✅ 5 zonas
empleados	Personal con rol operativo	❌ (demo data usa core_employees)
maquinaria	Equipos físicos	✅ 5 máquinas (sin zona asignada)
animales	Censo de ganado	❌
tareas_catalogo	Tipos de tarea disponibles	✅ 7 tipos
Grupo 2: Tablas operativas (datos del día a día)
Tabla	Dependencias
tareas_ejecuciones	tareas_catalogo, zonas, empleados
incidencias	zonas, maquinaria, animales, empleados
alertas	animales, zonas, empleados, alertas_umbrales
pedidos	empleados
turnos	—
asignaciones_turno	turnos, empleados, zonas
resumenes_relevo	turnos, empleados
Grupo 3: Tablas históricas / seguimiento
Tabla	Dependencias
lactaciones	animales
tratamientos_activos	animales, empleados, eventos_sanitarios
eventos_sanitarios	animales, empleados
eventos_reproductivos	animales, empleados
eventos_sanitarios_recria	animales, empleados
lecturas_meteorologia	—
lecturas_robot_ordeno	maquinaria, animales, lactaciones
lecturas_carro_mezclador	empleados
audit_log	Auto-generado por trigger
Grupo 4: Tablas de configuración
Tabla	Contenido
alertas_umbrales	✅ 7 umbrales pre-configurados
tareas_recurrentes	✅ 4 programaciones pre-configuradas
Grupo 5: Tablas sin uso visible directo en frontend
Tabla	Estado
genomica	Sin endpoint activo en frontend
boxes_recria	Sin endpoint activo en frontend
lecturas_carro_mezclador	Sin endpoint activo en frontend
eventos_reproductivos	Sin endpoint activo en frontend
eventos_sanitarios_recria	Sin endpoint activo en frontend
5. Matriz tabla → pantalla frontend
Pantalla	Tablas necesarias	Datos imprescindibles	Datos opcionales
/dashboard	animales, tareas_ejecuciones, alertas, tratamientos_activos, lecturas_meteorologia	Tareas (varios estados), alertas activas	Meteo actual
/report	Todas las anteriores + incidencias, pedidos, lactaciones	Tareas, alertas, incidencias, pedidos	Calidad, meteo
/animals	animales	Mínimo 10-20 animales con estados variados	Raza, nombre
/animals/[id]	animales, lactaciones, tratamientos_activos, alertas, incidencias	Animal con lactación y tratamiento	Incidencias por animal
/quality	animales, lactaciones	Animales en estado=produccion, lactaciones con fecha_parto	produccion_total_kg (único campo de calidad disponible)
/predictions	animales, lactaciones, tratamientos_activos, alertas	Animales en producción	—
/alerts	alertas, animales	Alertas con nivel y activa=true	umbral_id
/incidents	incidencias, zonas, animales	Incidencias con zona y tipo	Maquinaria, empleado
/orders	pedidos	Pedidos con distintos estados	Solicitante, costes
/tasks	tareas_ejecuciones, tareas_catalogo, zonas	Tareas en distintos estados, con zona	Empleado asignado
/shifts	turnos, asignaciones_turno, empleados, zonas	Turnos del día actual y pasados	—
/handover	resumenes_relevo, turnos	Algunos resúmenes de relevo	—
/handover/tablet	resumenes_relevo, turnos, incidencias, tareas_ejecuciones, alertas, empleados	Turno actual, empleados asignados	—
/zones	zonas, tareas_ejecuciones, incidencias, maquinaria	Zonas con tareas e incidencias	—
/zones/[id]	zonas, tareas_ejecuciones, incidencias, maquinaria, asignaciones_turno, empleados	Tareas e incidencias por zona	Maquinaria
/tv	alertas, incidencias, tareas_ejecuciones, zonas, turnos, asignaciones_turno, empleados, lecturas_meteorologia, lactaciones	Alertas críticas, turnos, zonas con estado	Meteo
/tv/shifts	turnos, asignaciones_turno, empleados, zonas, tareas_ejecuciones, incidencias, alertas	Turnos del día con asignaciones	—
/leanfarming	zonas, tareas_ejecuciones, tareas_catalogo, incidencias, alertas, turnos, asignaciones_turno, empleados	Tareas por zona, turno activo	Incidencias, alertas
/management	Todas las tablas maestras	Animales, zonas, empleados, maquinaria	Lactaciones, tratamientos
/settings	zonas	Zonas con tiene_tv/tablet	—
/integration	lecturas_meteorologia	Al menos 1 lectura reciente	—
/audit-log	audit_log	Registros de auditoría	—
/profile	usuarios (auth JWT)	Usuario autenticado	—
6. Prioridad demo por tabla
Tabla	Prioridad	Razón
zonas	Alta	Pre-poblada; base de todo
empleados	Alta	Necesaria para turnos, asignaciones, alertas
animales	Alta	Centra Dashboard, Animals, Quality, TV
tareas_ejecuciones	Alta	Dashboard, LeanFarming, Tasks, TV, Report
alertas	Alta	Dashboard, TV, Alerts, Report
incidencias	Alta	Zones, TV, Incidents, Report
pedidos	Alta	Orders, Dashboard, Report
turnos	Alta	Shifts, Handover, TV Shifts, LeanFarming
asignaciones_turno	Alta	Shifts, TV Shifts, Zones
lecturas_meteorologia	Media	WeatherPanel, TV, Integration
lactaciones	Media	Quality, Animals/[id], Dashboard
tratamientos_activos	Media	Animals/[id], Dashboard, Management
maquinaria	Media	Zones, Management (ya hay 5 sin zona)
resumenes_relevo	Media	Handover, Handover tablet
tareas_catalogo	Alta	Pre-poblada; base de tareas
tareas_recurrentes	Baja	Pre-pobladas; sin pantalla directa
alertas_umbrales	Baja	Pre-pobladas; sin pantalla de edición
eventos_sanitarios	Baja	Solo ficha animal, sin lista propia
eventos_reproductivos	Baja	Sin pantalla activa
lecturas_robot_ordeno	Baja	Sin uso en frontend actual
lecturas_carro_mezclador	Baja	Sin uso en frontend actual
eventos_sanitarios_recria	Baja	Sin pantalla activa
genomica	Baja	Sin pantalla activa
boxes_recria	Baja	Sin pantalla activa
audit_log	Baja	Auto-generado; se llena solo con operaciones
7. Volumen recomendado de datos demo
Entidad	Cantidad propuesta	Justificación
Zonas	5 existentes (reusar) + 2-3 nuevas	Init.sql ya tiene 5; añadir Enfermería, Paridera, Almacén
Empleados	10-12	2 encargados, 3 auxiliares, 2 veterinarios, 2 mecánicos, 1 extra
Maquinaria	8-12 (5 ya existen)	Asignar zonas a las 5 existentes + 3-7 nuevas con zona
Animales	80-120	50-70 en producción, 15-20 secas, 15-25 recría, 5 baja
Lactaciones	60-80 (activas e históricas)	~1.2 por animal en producción + historial 1-3 anteriores
Tratamientos activos	8-15	5-8 activos (mastitis, cojera), 3-7 cerrados
Eventos sanitarios	10-20	Historial veterinario, solo si se quiere enriquecer /animals/[id]
Tareas ejecuciones	50-80	20-30 programadas/retrasadas, 20-30 completadas, 5-10 canceladas
Incidencias	15-25	5-8 abiertas, 5-8 en gestión, 5 resueltas
Alertas	20-35	3-5 nivel "critica", 10-15 nivel "alta", 5-15 nivel "media/baja"
Pedidos	10-15	2-3 por cada estado del workflow
Turnos	14-21 días (28-42 registros)	2 turnos/día durante 2-3 semanas
Asignaciones turno	3-6 por turno	~2-4 empleados por turno con zona asignada
Resúmenes de relevo	5-10	Historial reciente de cambios de turno
Lecturas meteo	30-90 lecturas	1 por hora durante 3-7 días
Lecturas robot ordeño	200-500	Solo si se quiere poblar, bajo impacto visual
8. Orden de inserción recomendado

PASO 1 — Ya pre-poblado (verificar antes de insertar)
  1a. zonas           (5 registros en init.sql — pueden existir conflictos de UNIQUE nombre/codigo)
  1b. maquinaria      (5 registros sin zona_id — actualizar zona_id al insertar zonas)
  1c. tareas_catalogo (7 registros)
  1d. tareas_recurrentes (4 registros)
  1e. alertas_umbrales (7 registros)

PASO 2 — Tablas maestras sin datos
  2.  empleados       (sin FK externas; usar rol_empleado enum real)
  3.  animales        (auto-referencia madre_id: insertar madres primero)

PASO 3 — Tablas que dependen de maestras
  4.  lactaciones     (→ animales)
  5.  eventos_sanitarios (→ animales, empleados)
  6.  tratamientos_activos (→ animales, eventos_sanitarios?, empleados)
  7.  eventos_reproductivos (→ animales, empleados) [opcional]

PASO 4 — Tablas operativas
  8.  turnos          (sin FK; UNIQUE fecha+tipo_turno)
  9.  asignaciones_turno (→ turnos, empleados, zonas)
 10.  tareas_ejecuciones (→ tareas_catalogo, zonas, empleados, maquinaria?)
 11.  incidencias      (→ zonas, maquinaria, animales, empleados)
 12.  alertas          (→ animales, zonas, empleados, alertas_umbrales?)
 13.  pedidos          (→ empleados)

PASO 5 — Tablas que dependen de operativas
 14.  resumenes_relevo (→ turnos×2, empleados)

PASO 6 — Series temporales
 15.  lecturas_meteorologia (PK compuesta ts+estacion_id)
 16.  lecturas_robot_ordeno (→ maquinaria, animales, lactaciones) [opcional]
9. Reglas de realismo
Animales
Crotales: formato ES-YYYY-XXXXX (ej: ES-2021-00001) con prefijo [DEMO] en notas para identificación
Distribución por estado (para rebaño de ~100 animales): 55% producción, 15% seca, 20% recría, 8% gestante, 2% baja
Edad coherente: animales en producción nacidos entre 2018-2023; recría 2023-2025; no asignar lactación a animales menores de 24 meses
Estado reproductivo coherente con estado animal: producción → vacia, en_celo, inseminada, confirmada_gestante, parto_reciente; recría → NULL
Madre_id: usar solo si el script ya tiene animales más viejos con IDs conocidos
Lactaciones
Producción total: rango 4.500-12.000 kg para lactación completa; activa = fecha_secado IS NULL
Número de lactación coherente con edad: vaca de 4 años → máx 2-3 lactaciones; 7 años → 4-5
Solo 1 lactación activa por animal; las anteriores con fecha_secado pasada
⚠️ produccion_promedio, grasa, proteina, rcs no tienen columna en la tabla — el script no puede poblarlos directamente. Se puede usar el campo notas como JSONB serializado si se necesitan para el demo, pero el servicio no los leerá.
Tareas ejecuciones
Retrasadas: ts_planificada en las últimas 12-48 horas, estado = vencida (→ frontend retrasada)
Programadas: ts_planificada entre ahora y las próximas 12 horas, estado = pendiente
Ejecutadas: ts_planificada en el pasado, ts_fin IS NOT NULL, estado = completada
Distribución por zona: zonas con TV/tablet deben tener más tareas para demo visual
catalogo_id debe existir: siempre referenciar un ID real del catálogo pre-insertado
Incidencias
averia_maquinaria → siempre vincular maquinaria_id y zona_id
sanidad_animal → siempre vincular animal_id
calidad_leche → vincular zona_id (sala de ordeño)
infraestructura → solo zona_id
severidad: máx. 20% "alta", 50% "media", 30% "baja"
4-6 en estado "abierta", 3-5 "en_gestion", resto "resuelta"
Alertas
nivel: para que /dashboard muestre las métricas correctas, usar "alta" y "media" principalmente; puede usarse "critica" como string (el modelo lo acepta aunque no esté en enum)
activa=TRUE para alertas pendientes, activa=FALSE + ts_resolucion para las resueltas
animal_id obligatorio para alertas de tipo sanitario o reproductivo
zona_id para alertas operativas/de maquinaria
Pedidos
Workflow progresivo: insertar pedidos en distintos estados: 2-3 solicitado, 2-3 aprobado, 2 en_transito, 2-3 recibido, 1 cancelado
ts_aprobacion solo si estado >= aprobado; ts_recepcion solo si estado = recibido
Insumos realistas: "Pienso de inicio terneros", "Ácido láctico 85%", "Pezoneras VMS", "Paja de trigo", "Leche en polvo maternizadora"
Turnos y asignaciones
Solo 2 tipos: manana (06:00-14:00) y tarde (14:00-22:00)
UNIQUE(fecha, tipo_turno): máximo 2 turnos por día
Cada turno: 2-4 asignaciones con zona distinta
rol en asignación: texto libre (ej: "responsable_ordeno", "auxiliar_becerrero")
Meteorología (Lugo/Galicia)
Temperatura: 8-18°C (invierno/primavera), Numeric(4,1) → ej: 12.4
Humedad: 70-95%, muy elevada
Precipitacion: 0-15 mm, con lluvia frecuente
Viento: 5-25 km/h
Frecuencia: 1 lectura cada hora, estacion_id = 'VILLALBA_01'
indice_thermo_humedad se calcula automáticamente (campo GENERATED) — no insertar
10. Estrategia futura de simulador vivo
Tabla	Acción simulada	Frecuencia	Reglas
tareas_ejecuciones	Completar tareas pendientes	Cada 2-4 min	Solo tareas en estado pendiente; set ts_fin=NOW(), estado→completada
tareas_ejecuciones	Crear nueva tarea	Cada 5-10 min	Seleccionar catálogo random + zona aleatoria, ts_planificada = ahora + 30-120 min
tareas_ejecuciones	Marcar como vencida	Cada 10 min	Si ts_planificada < NOW() - 2h y estado=pendiente → estado=vencida
alertas	Crear alerta nueva	Cada 15-30 min	Con nivel aleatorio (más "media" que "alta"), animal o zona aleatoria
alertas	Resolver alerta	Cada 20 min	Marcar activa=FALSE, ts_resolucion=NOW(), resuelta_por = empleado random
incidencias	Crear incidencia	Cada 30-60 min	Tipo y severidad random con vínculos coherentes
incidencias	Avanzar estado	Cada 20-40 min	abierta → en_gestion → resuelta
pedidos	Avanzar workflow	Cada 30 min	solicitado→aprobado→en_transito→recibido con timestamps
lecturas_meteorologia	Añadir lectura	Cada 60 min	Temperatura y humedad con variación leve respecto a la anterior
turnos	Generar turno del día siguiente	1 vez/día	Crear 2 turnos (mañana/tarde) si no existen
asignaciones_turno	Asignar empleados al nuevo turno	Al crear turno	3-4 asignaciones con zonas distintas
resumenes_relevo	Crear resumen al cambio de turno	2 veces/día	Al cruzar las 14:00: crear relevo entre turno mañana saliente y tarde entrante
11. Riesgos y precauciones
Riesgos técnicos
Riesgo	Descripción	Mitigación
Doble schema	Existen tablas core_* (legacy) y las tablas reales. Un seed incorrecto puede insertar en las tablas equivocadas	El script solo debe operar sobre las tablas de tools4milk.py (sin prefijo core_)
Enums en DB vs. String en modelo	Algunos campos (ej: nivel de alertas) son String(20) en el modelo pero nivel_alerta ENUM en la DB. Insertar "critica" directamente en PostgreSQL viola el enum	Usar nivel solo con baja/media/alta; la inserción desde SQLAlchemy puede bypasear el enum si se hace vía texto
Estado animal sin "crianza"	El frontend espera "crianza" pero la DB solo tiene recria. Un seed que inserte estado='crianza' violará el enum	Usar solo los valores del enum: produccion, seca, recria, gestante, baja
Estado reproductivo inválido	El demo_data.py usa "lactante" y "prenada" que NO son valores válidos del enum DB	Usar solo: vacia, en_celo, inseminada, confirmada_gestante, parto_reciente
GENERATED columns	indice_thermo_humedad y desviacion_pct son columnas GENERATED ALWAYS AS STORED — no se pueden insertar	El script no debe incluir estos campos en INSERT
PK compuesta en series temporales	lecturas_meteorologia tiene PK (ts, estacion_id). Insertar con el mismo ts+estacion viola la PK	Asegurar timestamps únicos
UNIQUE turnos	UNIQUE(fecha, tipo_turno) — solo 1 mañana y 1 tarde por día	Verificar antes de insertar
Audit log trigger	Cada INSERT/UPDATE/DELETE en tablas auditadas genera un registro en audit_log automáticamente	Los datos demo generarán audit logs; no es un problema, pero el audit log crecerá
Integridad referencial	FK a animales.madre_id → self-join. Si se insertan madres e hijas en el mismo batch, ordenar por generación	El script debe insertar madres antes que crías
tareas_catalogo ya existe	El init.sql ya inserta los 7 tipos. Si el script intenta insertar los mismos codigo, violará el UNIQUE	Usar ON CONFLICT DO NOTHING o verificar existencia
Medidas de seguridad recomendadas

# Variables de entorno del script
DEMO_MODE = os.getenv("DEMO_MODE", "false").lower() == "true"
RESET_DEMO_DATA = os.getenv("RESET_DEMO_DATA", "false").lower() == "true"
DATABASE_URL = os.getenv("DATABASE_URL")  # nunca hardcodear

# Marcadores de datos demo
DEMO_TAG = "[DEMO]"  # prefijo en campo notas donde aplique
CROTAL_PREFIX = "DEM"  # crotales como "DEM-001" a "DEM-120"

# Guardas obligatorias
if not DEMO_MODE:
    print("ERROR: ejecuta con DEMO_MODE=true")
    sys.exit(1)

if RESET_DEMO_DATA:
    # Pedir confirmación explícita
    confirm = input("¿Estás seguro? Esto borrará datos demo. (escribe 'SI'): ")
    if confirm != "SI":
        sys.exit(0)
    # Backup antes de limpiar
    backup_demo_tables()
    clean_demo_tables()  # solo filas con notas LIKE '[DEMO]%' o crotal LIKE 'DEM-%'