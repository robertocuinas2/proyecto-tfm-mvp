INFORME DE AUDITORÍA COMPLETO — Tools4Milk MVP
Fecha: 2026-05-28 | Versión analizada: rama main

RESUMEN EJECUTIVO
Estado actual del frontend: Funcional para las operaciones básicas de consulta (dashboard, alertas, tareas, animales, calidad, predicciones). La interfaz está bien estructurada visualmente y utiliza patrones modernos (React Query, Zustand, Tailwind), pero cubre aproximadamente el 40–50% de la capacidad real del backend.

Nivel de conexión con backend/base de datos: Medio-bajo. De los ~50 endpoints disponibles, el frontend consume activamente alrededor de 20. Existen tres módulos completos en el backend (Pedidos, Turnos/Relevos, Incidencias como página dedicada) que no tienen ninguna representación en la interfaz.

Principales carencias funcionales: Ausencia total de páginas para Pedidos, Turnos y Resumenes de Relevo; no hay página de detalle de animal; Incidencias existe en el cliente API pero no tiene pantalla propia; el módulo meteorológico está reducido a un solo dato (temperatura actual); no se puede crear ni asignar tareas desde el frontend.

Principales carencias visuales: La aplicación usa el tema oscuro TV para todas las pantallas, mientras que el HTML de referencia propone un esquema híbrido (sidebar oscuro + contenido claro) para las vistas de control. Las tarjetas de gestión (Management) son demasiado densas para el uso diario. La tabla de animales carece de ficha de detalle. El módulo LeanFarming no implementa las vistas TV/Tablet por zona que define el HTML de referencia.

Riesgos principales: Divergencia de tipos entre modelos frontend y backend (Employee, Incident, Treatment); la página Management limita los listados a 12 ítems sin paginación; las predicciones no se cachean en React Query (se pierden al cambiar de página).

1. TABLA DE COBERTURA FRONTEND-BACKEND
Entidad/Modelo	Campos relevantes	Endpoint principal	¿Existe en frontend?	Pantalla/Componente	Info mostrada	Info pendiente	Acción recomendada	Prioridad
Usuario	username, email, role, activo	/auth/me, /auth/login	Sí	Login, Sidebar, Store	username, role	email, activo, debe_cambiar_contrasena	Añadir perfil de usuario	Baja
Zona	nombre, codigo, tiene_tv, tiene_tablet	/zones	Sí (parcial)	Zones (en Management), LeanFarming	nombre, codigo	descripcion, tipo, activa	Separar en página propia con tabla	Media
Empleado	nombre, apellidos, rol, cualificaciones, telefono, email	/employees	Sí (parcial)	Management > Empleados	nombre, apellidos, role	telefono, email, cualificaciones, fecha_alta	Ampliar formulario; corregir tipo rol	Alta
Maquinaria	nombre, tipo, zona_id, estado, proxima_revision	/machinery	Sí (parcial)	Management > Maquinaria	nombre, tipo, estado	marca, modelo, numero_serie, fecha_instalacion	Añadir campos faltantes en formulario	Media
Animal	crotal, nombre, raza, estado, estado_reproductivo, fecha_nacimiento	/animals	Sí	Animals, Management, Quality, Predictions	crotal, nombre, raza, estado, edad, entrada	madre_id (árbol genealógico), fecha_baja, motivo_baja	Añadir página de detalle por animal	Alta
Lactacion	animal_id, numero, fecha_parto, produccion_total_kg, fecha_secado	/lactations	Sí (parcial)	Quality, Management	produccion_promedio, grasa, proteina, rcs	numero lactacion, fecha_secado, produccion_total_kg	Mostrar número y secuencia de lactación	Media
TratamientoActivo	animal_id, farmaco, dosis, fecha_fin_prevista, activo, checkboxes	/treatments	Sí (parcial)	Management > Tratamientos	medicamento (mapeo incorrecto), activo	farmaco (nombre real del campo), prescrito_por, checkboxes, periodo_retirada	Corregir mapeo medicamento→farmaco	Alta
EventoSanitario	animal_id, tipo_patologia, farmaco, resuelto, coste	No consumido	No	—	Nada	Todo	Pendiente de confirmar prioridad	Media
Incidencia	tipo, severidad, estado, titulo, zona_id, maquinaria_id	/incidents	Sin página dedicada	— (API client existe)	Nada visible	Todo	Crear página /incidents	Alta
AlertaUmbral	codigo, metrica, operador, valor_umbral, nivel_alerta	No consumido	No	—	Nada	Gestión de umbrales	Pantalla de configuración de alertas	Media
Alerta	nivel, titulo, mensaje, animal_id, activa, ts_generacion	/alerts	Sí	Alerts	severidad, tipo_alerta, descripcion, recomendacion	titulo (vs descripcion), zona_id, ts_resolucion, resuelta_por	Mostrar título y zona	Media
TareaCatalogo	codigo, nombre, descripcion, cualificacion_requerida	No consumido directamente	Parcial (sub-objeto en Task)	Tasks, LeanFarming	nombre, categoria	cualificacion_requerida, duracion_estimada_min	Mostrar duración estimada y cualificación	Baja
TareaRecurrente	catalogo_id, zona_id, frecuencia_expr	No consumido	No	—	Nada	Configuración de tareas recurrentes	Pendiente	Baja
TareaEjecucion	estado, ts_planificada, ts_fin, empleado_id, zona_id	/tasks	Sí	Tasks, LeanFarming, Dashboard	estado, nombre, fecha, zona	empleado asignado (empleado_id), ts_inicio, ts_fin, notas de ejecución	Mostrar empleado responsable y tiempos reales	Media
Turno	fecha, tipo_turno, hora_inicio, hora_fin	/turnos	No	—	Nada	Todo	Crear página /shifts	Alta
AsignacionTurno	turno_id, empleado_id, zona_id, rol	/asignaciones-turno	No	—	Nada	Todo	Incluir en página de turnos	Alta
Pedido	insumo, cantidad, estado, solicitante_id, coste_estimado	/pedidos	No	—	Nada	Todo	Crear página /orders	Alta
ResumenRelevo	turno_saliente_id, incidencias_abiertas, tareas_pendientes	/resumenes-relevo	No	—	Nada	Todo	Incluir en LeanFarming o página propia	Media
AuditLog	ts, tabla_afectada, operacion, datos_anteriores	/audit-log	No	—	Nada	Todo (solo admin)	Crear vista en Gestión para admin	Media
LecturaMeteo	ts, temperatura_c, humedad, precipitacion, viento	/weather/current, /weather/forecast	Parcial	Dashboard (1 dato)	temperatura_actual, descripcion	humedad, precipitacion, viento, forecast 7 días	Expandir widget meteorológico	Media
LecturaRobotOrdeno	produccion_kg, conductividad, scc, alerta_robot	No consumido	No	—	Nada	Lecturas por robot y por animal	Pendiente de confirmar diseño	Baja
EventoReproductivo	tipo, fecha, detalles	No consumido	No	—	Nada	Historial reproductivo por animal	Incluir en ficha de animal	Media
EventoSanitarioRecria	scores (neumonía, diarrea), peso_kg	No consumido	No	—	Nada	Seguimiento de terneros	Pendiente	Baja
Genomica	fecha_extraccion, laboratorio, resultados_ref	No consumido	No	—	Nada	Resultados genómicos	Pendiente	Baja
BoxRecria	box_numero, ternero_id, activo, alertas_box	No consumido	No	—	Nada	Estado de boxes y alertas	Pendiente	Baja
2. AUDITORÍA POR PANTALLA/COMPONENTE
2.1 Login Page (/)
Aspecto	Detalle
Función actual	Formulario de credenciales + botones de demo users + health check
Datos que usa	POST /auth/login, GET /health
Datos que debería usar	Igual
Problemas detectados	Los botones de demo users rellenan el formulario pero muestran contraseñas en texto plano en tooltips
Mejoras funcionales	Mostrar versión de la API; indicar estado del backend con color
Mejoras visuales	El HTML de referencia tiene una pantalla de login con KPIs de la explotación visibles antes de entrar — más rica visualmente
Riesgo de modificación	Bajo
2.2 Dashboard (/dashboard)
Aspecto	Detalle
Función actual	8 KPIs + tendencia de lactaciones + donut de tareas + alertas recientes + accesos rápidos
Datos que usa	/dashboard/summary, /alerts?limit=5, /lactations/quality/summary, /lactations?activa=true&limit=120, /weather/current
Datos que debería usar	Añadir: /weather/forecast (próximos 3 días), /weather/correlation/impact (impacto en producción), incidencias abiertas críticas
Problemas detectados	1) La tendencia de producción usa fechas de inicio de lactación, no lecturas diarias reales (no hay endpoint de lecturas diarias de robot). 2) No hay sección de incidencias en el dashboard. 3) El KPI "Producción" muestra produccion_promedio de la calidad pero en el card pone "L" como si fuera total. 4) El tiempo real es 30s pero el weather se refresca cada 10 min, creando inconsistencia.
Mejoras funcionales	Añadir conteo de incidencias abiertas; añadir widget de previsión meteorológica; añadir KPI de pedidos pendientes de aprobación
Mejoras visuales	El HTML de referencia propone un layout más rico con panel de zona activa y acciones rápidas en primer plano
Riesgo de modificación	Medio (muchas queries, invalidaciones cruzadas)
2.3 Animals Page (/animals)
Aspecto	Detalle
Función actual	Grid de animales con filtro por estado, búsqueda por crotal/nombre, paginación
Datos que usa	/animals?estado=...&skip=...&limit=50
Datos que debería usar	Igual para listado; añadir /animals/{id} para ficha de detalle
Problemas detectados	1) Las tarjetas no son clicables — no hay página de detalle. 2) No se muestra estado_reproductivo de forma destacada para animales en producción. 3) madre_id no está disponible ni se enlaza. 4) No hay acceso a historial de lactaciones ni tratamientos desde la tarjeta del animal. 5) El filtro de estado "crianza" está presente pero el HTML de referencia no lo distingue como estado relevante para la explotación.
Mejoras funcionales	Crear /animals/[id] con lactaciones, tratamientos, alertas y eventos del animal. Añadir botón "generar alerta" por animal (POST /alerts/generate/{animal_id}).
Mejoras visuales	Añadir indicador visual de estado reproductivo (icono/badge distinto a estado productivo)
Riesgo de modificación	Bajo (página standalone)
2.4 Alerts Page (/alerts)
Aspecto	Detalle
Función actual	Lista de alertas con filtro por severidad, acciones de resolución
Datos que usa	/alerts?skip=...&limit=pageSize&severidad=..., PATCH /alerts/{id}
Datos que debería usar	Añadir /alerts/critical para resaltar críticas en cabecera; cruzar con /animals/{id} para mostrar nombre del animal
Problemas detectados	1) En el detalle expandido, animal_id se muestra como UUID crudo — el usuario no sabe qué animal es. 2) Solo hay 3 estadísticas (críticas, altas, total) — falta "medias". 3) No hay filtro por "baja" en los tabs aunque existe el valor. 4) No hay indicación visual de si la alerta proviene de una predicción (confianza_prediccion) o de una lectura real. 5) La paginación convive con una query que pide limit=500 para estadísticas — doble fetching.
Mejoras funcionales	Resolver el cruce de animal_id → nombre/crotal. Añadir campo de notas del operario al resolver. Permitir filtrar por estado (pendiente/revisada/resuelta).
Mejoras visuales	Mostrar crotal del animal junto al UUID. Distinguir visualmente alertas de predicción vs alertas de lectura real.
Riesgo de modificación	Medio (mutations e invalidaciones en cascada)
2.5 Tasks Page (/tasks)
Aspecto	Detalle
Función actual	Lista de tareas filtrada por estado (programada/retrasada/ejecutada), acción de completar
Datos que usa	/tasks?estado=...&skip=...&limit=pageSize+1
Datos que debería usar	Añadir filtro por zona_id; mostrar nombre del empleado asignado (empleado_id)
Problemas detectados	1) No existe la opción de crear nuevas ejecuciones de tarea desde esta pantalla (POST /tasks). 2) No hay filtro por zona visible — LeanFarming lo resuelve parcialmente pero no paginado. 3) El estado "cancelada" y "pausada" no tienen tab propio. 4) tarea_catalogo.zona_aplicable se muestra como texto libre, no se cruza con las zonas reales. 5) No se muestran los campos de resultado ni observaciones de las tareas ejecutadas.
Mejoras funcionales	Añadir modal de creación de tarea. Añadir filtro por zona en la barra de filtros. Mostrar observaciones/resultado en tareas ejecutadas.
Mejoras visuales	Añadir barra de progreso de tiempo hasta fecha programada para tareas "programada"
Riesgo de modificación	Bajo-Medio
2.6 LeanFarming Page (/leanfarming)
Aspecto	Detalle
Función actual	Vista Kanban/grid de zonas con tareas agrupadas, view toggle zonas/lista, completar tareas
Datos que usa	/zones, /tasks?limit=500
Datos que debería usar	Igual, más /turnos y /resumenes-relevo para el tablero de turnos que define el HTML de referencia
Problemas detectados	1) La vista está limitada a 6 tareas por zona al expandir (priorityTasks.slice(0, 6)). 2) No hay acceso a los turnos del día ni al cambio de turno. 3) El enlace "Ver zona completa" apunta a /zones/${id} pero esa ruta no existe como página dedicada. 4) No hay indicador del empleado asignado por zona en el turno actual. 5) El HTML de referencia tiene un "Tablero de Turnos" (TV 1920×1080) y un "Cambio de Turno" (tablet 768×1024) que no están implementados.
Mejoras funcionales	Integrar sección de turno activo con empleados asignados. Añadir acceso al resumen de relevo. Eliminar el límite de 6 tareas o añadir paginación interna.
Mejoras visuales	El HTML de referencia propone un tablero tipo TV con información de zona en formato pantalla grande — distinto al layout de tarjetas actual
Riesgo de modificación	Medio
2.7 Quality Page (/quality)
Aspecto	Detalle
Función actual	KPIs de calidad, vista por animal con score, métricas de composición e indicadores
Datos que usa	/animals?estado=produccion&skip=..., /lactations?activa=true&limit=500, /lactations/quality/summary
Datos que debería usar	Añadir histórico de RCS por animal para tendencia; /weather/correlation/impact para correlación clima-calidad
Problemas detectados	1) El score de calidad es calculado en el frontend con lógica propia — no existe un endpoint de score en el backend (correcto, pero es duplicación de lógica). 2) No se muestra el número de lactación (numero_lactacion) en las tarjetas de animal. 3) La tendencia del gráfico SparkArea usa fecha_inicio de lactación como eje X — no tiene sentido como tendencia temporal. 4) No hay comparativa entre animales. 5) La sección "Leche a la Carta" del HTML de referencia (filtro por grasa/proteína para pedidos de leche) no está implementada.
Mejoras funcionales	Mostrar número de lactación. Implementar "Leche a la Carta" básico como filtro de composición.
Mejoras visuales	Añadir mini-gráfico de tendencia de RCS por animal individual
Riesgo de modificación	Bajo
2.8 Predictions Page (/predictions)
Aspecto	Detalle
Función actual	Grid de animales en producción con tarjetas de predicción cargadas bajo demanda
Datos que usa	/animals?estado=produccion&skip=..., GET /predictions/{animalId}
Datos que debería usar	Igual
Problemas detectados	1) Las predicciones no se almacenan en React Query — se pierden al cambiar de página o refrescar. 2) El flag _mock: true en AnimalPrediction no se indica visualmente al usuario. 3) loadPage() hace múltiples llamadas paralelas sin control de rate-limiting. 4) Los campos produccion_minima_predicha y produccion_maxima_predicha existen en el tipo pero no se muestran (rango de confianza). 5) Los riesgos específicos (riesgos_especificos) se omiten — solo se muestran los factores de riesgo en texto.
Mejoras funcionales	Cachear predicciones en React Query con queryKey: ["prediction", animalId]. Mostrar indicador de mock. Mostrar rango min/max de producción.
Mejoras visuales	Añadir icono/badge diferenciador cuando la predicción es mock
Riesgo de modificación	Bajo-Medio
2.9 Management Page (/management)
Aspecto	Detalle
Función actual	Panel unificado de CRUD para 6 entidades: Animals, Zones, Lactations, Treatments, Employees, Machinery
Datos que usa	Todos los endpoints de las 6 entidades
Datos que debería usar	Igual; ampliar formularios con campos faltantes; separar en sub-páginas
Problemas detectados	1) Los listados de previsualización están limitados a .slice(0, 12) — con 100+ animales el 90% es invisible. 2) Employee.role usa los roles de usuario del sistema (`admin
Mejoras funcionales	Corregir mapeo de Employee.rol. Eliminar zona_principal_id. Añadir paginación a los listados. Dividir en sub-páginas dedicadas.
Mejoras visuales	Tabla en lugar de tarjetas mini para los listados; columnas sortables
Riesgo de modificación	Alto — correcciones de tipo podrían romper llamadas API existentes si los campos no coinciden
2.10 Zones Page (/zones)
No tiene página dedicada propia — las zonas se gestionan dentro de Management. El link /zones/{id} en LeanFarming apunta a una ruta que no existe.

2.11 Assistant (flotante, todas las páginas)
Aspecto	Detalle
Función actual	Chat para acciones NLP vía POST /assistant/message con flujo de confirmación
Datos que usa	/assistant/message
Problemas detectados	Sin página de historial; sin indicación de si está habilitado o no (ENABLE_ASSISTANT); las acciones disponibles no están documentadas para el usuario
Riesgo de modificación	Bajo
3. HUECOS FUNCIONALES
Datos que existen en backend pero NO se muestran en ninguna pantalla
Dato faltante	Entidad	Endpoint disponible	Impacto
Estado y workflow de pedidos de suministros	Pedido	/pedidos, /pedidos/{id}/estado	Alto — core operativo
Gestión de turnos diarios (mañana/tarde)	Turno + AsignacionTurno	/turnos, /asignaciones-turno	Alto — core LeanFarming
Resumen de cambio de turno	ResumenRelevo	/resumenes-relevo	Alto — documentación operativa
Incidencias abiertas (avería, sanidad...)	Incidencia	/incidents	Alto — seguimiento de problemas
Histórico de eventos reproductivos	EventoReproductivo	Sin endpoint directo	Medio
Eventos sanitarios veterinarios	EventoSanitario	Sin endpoint directo	Medio
Previsión meteorológica 7 días	LecturaMeteo	/weather/forecast	Medio
Impacto del clima en producción	LecturaMeteo	/weather/correlation/impact	Medio
Log de auditoría	AuditLog	/audit-log	Medio (solo admin)
Umbrales de alerta configurables	AlertaUmbral	Sin endpoint CRUD	Baja (configuración)
Datos de robot de ordeño (conductividad, SCC real-time)	LecturaRobotOrdeno	Sin endpoint listado	Baja
Seguimiento de terneros en boxes	BoxRecria + EventoSanitarioRecria	Sin endpoint listado	Baja
Datos genómicos	Genomica	Sin endpoint listado	Baja
Endpoints del backend no consumidos desde el frontend

POST  /weather/sync                    — Sincronización AEMET
GET   /weather/forecast                — Previsión 7 días
GET   /weather/historical              — Histórico meteorológico
GET   /weather/correlation/impact      — Impacto clima-producción
GET   /alerts/critical                 — Sólo críticas
GET   /turnos                          — Listado de turnos
POST  /turnos                          — Crear turno
GET   /asignaciones-turno              — Asignaciones de turno
POST  /asignaciones-turno              — Asignar empleado a turno
GET   /resumenes-relevo                — Listado de relevos
POST  /resumenes-relevo                — Crear resumen de relevo
GET   /pedidos                         — Listado de pedidos
GET   /pedidos/{id}                    — Detalle de pedido
POST  /pedidos                         — Crear pedido
PUT   /pedidos/{id}                    — Actualizar pedido
PATCH /pedidos/{id}/estado             — Cambiar estado del pedido
GET   /audit-log                       — Log de auditoría
GET   /simulation/status               — Estado de simulación
POST  /simulation/tick                 — Ejecutar tick de simulación
GET   /predictions/production/{id}     — Predicción solo producción
GET   /predictions/composition/{id}    — Predicción solo composición
GET   /predictions/health-risk/{id}    — Predicción solo riesgo sanitario
4. AUDITORÍA VISUAL Y UX/UI
4.1 Diseño general
Aspecto	Estado actual	Evaluación
Coherencia visual	Consistente en todas las pantallas (mismo tema oscuro)	Bien
Jerarquía de información	Buena en dashboard; débil en Management	Mejorable
Uso de espacios	Adecuado; padding px-6 py-6 uniforme	Bien
Claridad de navegación	Sidebar limpio con 9 ítems; faltan Incidencias y Pedidos	Mejorable
Consistencia entre pantallas	Alta — mismo PageHeader, KpiCard, StatusBadge	Bien
Legibilidad	Alta — tipografías Space Grotesk + DM Sans, buen contraste	Bien
Responsive	Grid adaptativo (md/xl breakpoints), funcional en escritorio	Bien
Feedback tras acciones	Loading states y error states presentes; sin toast de éxito	Mejorable
4.2 Comparación con el HTML de referencia
Paleta del HTML de referencia:

Token	HTML Referencia	Frontend actual	¿Coincide?
Background principal (light)	#F2F5F3	app.bg: #EEF3F0 (definido, no usado)	No usado
Surface (light)	#FFFFFF	app.surface: #FFFFFF (definido, no usado)	No usado
Background (dark TV)	#1a1a1a (body)	tv.bg: #030A05	Más oscuro
Sidebar dark	#0D1A10	tv.surface: #102117	Similar
Accent verde (primario)	#1B5E3B	brand.DEFAULT: #17663D	Similar
Accent verde (highlight)	#34D471	tv.accent: #35E479	Casi idéntico
Border light	#DDE8E1	app.border: #D9E6DE	Similar
Text dark	#0D1A10	app.text: #101B14	Casi idéntico
Fuente heading	Space Grotesk	Space Grotesk	✅
Fuente body	DM Sans	DM Sans	✅
Border-radius tarjetas	14px	rounded-lg (8px por defecto Tailwind)	Diferente
Border tarjetas (light)	1.5px solid #DDE8E1	border border-tv-border	Diferente grosor
Diferencia clave: El HTML de referencia propone un esquema dual — pantallas de control de día (fondo claro #F2F5F3) y pantallas TV/tablet (fondo oscuro #030A05). El frontend actual aplica el tema oscuro de TV a todas las pantallas, incluyendo las vistas de gestión y control que el diseñador concibió en claro.

Los tokens de color para el tema claro (app.bg, app.surface, app.border, app.text, app.dim) están definidos en el Tailwind config pero no se usan en ningún componente.

4.3 Elementos del HTML de referencia no implementados
Artboard del HTML	Descripción	En frontend?	Nota
TV View (por zona)	Dashboard 1920×1080 con KPIs, alertas y tareas de zona	No	Requiere endpoint de contexto por zona
Tablet View (por zona)	UI 768×1024 táctil por zona	No	Ruta /zones/[id]/tablet
Control Center	Panel central 1440×900 tipo sala de control	No	Diferente al dashboard actual
Predictions Dashboard	1440×900 con análisis por zona + gráficos ricos	Parcial	Predictions page básica existe
Tablero de Turnos (TV)	1920×1080 con turnos, asignaciones, tareas por empleado	No	Depende de /turnos
Cambio de Turno (tablet)	768×1024 con resumen de relevo y confirmación	No	Depende de /resumenes-relevo
Calidad Dashboard	1440×900 con gráficos de composición y tendencias	Parcial	Quality page existe pero más básica
Leche a la Carta	Filtro avanzado de leche por composición	No	Vista diferenciada de Quality
Animal Ficha (tablet)	Búsqueda y ficha rápida de animal por crotal	No	/animals/[id] no existe
Crear Incidencia (tablet)	Flujo guiado de reporte de incidencia	No	No hay página de incidencias
Completar Tarea (tablet)	Flujo de confirmación de tarea con checklist	No	Solo botón simple actualmente
Revisar Alerta (tablet)	Flujo de revisión de alerta con notas	Parcial	Existe en Alerts page pero sin flujo guiado
Gestión Global (inventario+pedidos)	1440×900 con pedidos e inventario	No	No hay página de pedidos
Informe Semanal	Generación de informe semanal PDF/vista	No	No existe
Configurar pantalla de zona	Panel de configuración TV/tablet por zona	No	Zonas se configuran en Management
Login screen rico	Login con KPIs visibles y estado de explotación	Parcial	Login básico, algunas métricas en pantalla
5. LISTA DE CAMBIOS RECOMENDADOS
Prioridad Alta — Necesarios para representar correctamente el backend
A1. Corregir mapeo de tipos críticos en Management

Employee.rol debe usar el enum del backend (encargado|auxiliar|veterinario|mecanico), no el enum de usuario del sistema.
Eliminar campo zona_principal_id del formulario de empleado (no existe en backend).
Renombrar Treatment.medicamento → farmaco en el payload enviado al backend.
Verificar que Incident.estado: "en_proceso" coincide con backend ("en_gestion").
Riesgo si no se hace: Las creaciones/ediciones podrían fallar silenciosamente o guardar datos incorrectos.
A2. Crear página de detalle de Animal (/animals/[id])

Mostrar ficha completa: datos básicos, lactaciones históricas, tratamientos activos, alertas del animal.
Consumir: GET /animals/{id}, GET /lactations?animal_id=id, GET /treatments?animal_id=id, GET /alerts/{animal_id}.
A3. Crear página de Incidencias (/incidents)

Listado paginado con filtros por tipo, zona, estado.
Creación de incidencias (CRUD básico).
Añadir "Incidencias" al sidebar.
Consumir: GET /incidents, POST /incidents, PUT /incidents/{id}.
A4. Crear página de Pedidos (/orders)

Listado de pedidos con workflow de estados (solicitado→aprobado→en_transito→recibido→cancelado).
Formulario de creación de pedido.
Añadir "Pedidos" al sidebar.
Consumir: GET /pedidos, POST /pedidos, PUT /pedidos/{id}, PATCH /pedidos/{id}/estado.
A5. Mostrar nombre/crotal del animal en Alertas

En AlertCard (modo expandido), cruzar alert.animal_id con el listado de animales para mostrar crotal_oficial + nombre en lugar del UUID.
A6. Corregir límite de 12 registros en Management

Los listados de previsualización necesitan paginación o tabla scrollable. El .slice(0, 12) oculta la mayoría de los datos con censo real.
Prioridad Media — Importantes para mejorar experiencia y coherencia
M1. Integrar Turnos/Relevos en LeanFarming

Añadir sección de "Turno activo" en la cabecera de LeanFarming con empleados asignados.
Añadir acceso al último ResumenRelevo disponible.
Consumir: GET /turnos, GET /asignaciones-turno, GET /resumenes-relevo.
M2. Expandir widget meteorológico

En Dashboard, mostrar además de temperatura: humedad, descripción, previsión próximas 24h.
Consumir: GET /weather/forecast (ya definido en api client).
Añadir página /weather o sección expandida con histórico.
M3. Añadir sección de Incidencias al Dashboard

Añadir KPI de incidencias abiertas (junto con las alertas pendientes).
Consumir: GET /incidents?limit=5&estado=abierta.
M4. Cachear predicciones en React Query

Cambiar la gestión de estado de predicciones de useState local a useQuery con queryKey: ["prediction", animalId].
Resultado: predicciones persistentes al navegar entre páginas.
M5. Añadir filtro por zona en Tasks Page

Añadir selector de zona junto al filtro de estado.
Ya soportado por el backend: GET /tasks?zona_id=....
M6. Añadir Audit Log para admin

Vista de tabla con los registros del log de auditoría.
Filtros por tabla, acción, fecha.
Solo visible para role=admin.
Consumir: GET /audit-log.
M7. Mostrar número de lactación y campos reproductivos en animales

En AnimalCard, añadir indicador de número de lactación actual y días en leche.
En AnimalQualityCard, mostrar numero_lactacion.
M8. Corregir ruta rota en LeanFarming

El enlace "Ver zona completa" apunta a /zones/{id} que no existe como ruta. Redirigir a /leanfarming con zona preseleccionada o crear /zones/[id].
Prioridad Baja — Refinamiento estético y mejoras opcionales
B1. Toasts de feedback tras acciones exitosas

Actualmente las mutaciones no informan al usuario del éxito (solo del error). Añadir notificación breve (toast) al completar tareas, resolver alertas, guardar registros.
B2. Aplicar tema claro a vistas de control/gestión

Según el HTML de referencia, las pantallas de control de día (Management, Dashboard) podrían usar el tema claro (app.bg, app.surface). Los tokens ya están definidos en Tailwind pero sin usar.
Pendiente de confirmar: el usuario debe decidir si quiere mantener el tema oscuro uniforme o usar el diseño híbrido del HTML de referencia.
B3. Aumentar border-radius a 14px en tarjetas principales

El HTML de referencia usa borderRadius: 14px para las tarjetas. El frontend usa rounded-lg (8px).
B4. Indicador visual de predicciones mock

Añadir badge/icono cuando prediction._mock === true.
B5. Añadir panel de simulación para admin

Botón de "Ejecutar tick" y estado de simulación.
Consumir: GET /simulation/status, POST /simulation/tick.
B6. Baja pestaña "baja" en filtros de Animals

El tab "Baja" en Animals actualmente no es clicable como filtro activo de alertas.
6. PLAN DE IMPLEMENTACIÓN POR FASES
Fase 1 — Correcciones críticas de tipo y datos (sin tocar páginas existentes)
Corregir Employee.rol → enum correcto.
Eliminar zona_principal_id del payload de empleado.
Corregir medicamento → farmaco en treatment payload.
Verificar Incident.estado values contra backend.
Eliminar .slice(0, 12) en Management y añadir paginación básica.
Mostrar crotal/nombre de animal en Alert cards.
Estimado: 1-2 jornadas | Riesgo: Bajo si se prueba tras cada cambio.
Fase 2 — Mejoras a pantallas existentes (sin crear páginas nuevas)
Ampliar Dashboard con KPI de incidencias y widget de previsión meteorológica.
Ampliar Tasks con filtro por zona.
Cachear predicciones en React Query.
Corregir enlace roto /zones/{id} en LeanFarming.
Añadir feedback de éxito (toast) en mutaciones.
Estimado: 2-3 jornadas | Riesgo: Bajo-Medio.
Fase 3 — Nuevas páginas de entidades sin cobertura
Crear /animals/[id] (ficha de animal con historial).
Crear /incidents (listado y CRUD de incidencias).
Crear /orders (gestión de pedidos con workflow).
Añadir enlaces al sidebar.
Estimado: 3-4 jornadas | Riesgo: Bajo (páginas nuevas aisladas).
Fase 4 — Integración de módulo de turnos en LeanFarming
Sección de turno activo en LeanFarming.
Acceso a ResumenRelevo.
Creación y asignación de turnos básica.
Estimado: 2-3 jornadas | Riesgo: Medio (interacción con lógica existente de LeanFarming).
Fase 5 — Mejoras visuales y refinamiento
Evaluar aplicación del tema claro en pantallas de control.
Ajustar border-radius a 14px en tarjetas.
Añadir Audit Log para admin.
Panel de configuración de alertas (umbrales).
Informe semanal básico.
Estimado: 3-5 jornadas | Riesgo: Bajo.
7. RIESGOS Y PRECAUCIONES
Partes que NO se deben tocar sin análisis adicional
Componente	Motivo
store/app-store.ts — lógica de auth/hydrate	Afecta al flujo de login/logout en todas las páginas
lib/api.ts — funciones de fetch con token	Cambios romperían todas las llamadas API
app/(app)/layout.tsx — routing guard	Cambios pueden bloquear o desproteger rutas
lib/config.ts — URLs base	Un cambio incorrecto rompe todas las llamadas
Mutations de alerts (PATCH /alerts/{id})	Invalidan múltiples QueryKeys; probar después de modificar
Cambios que podrían romper llamadas API existentes
Renombrar medicamento → farmaco en el formulario de tratamiento: probar POST /treatments y PUT /treatments/{id} tras el cambio.
Cambiar Employee.role al enum correcto: probar POST /employees tras el cambio; podría fallar si el backend no acepta los nuevos valores.
Cualquier cambio en los queryKey de React Query invalidará el caché y forzará re-fetches — verificar que los refetch intervals no causen throttling.
Información pendiente de confirmar antes de modificar
¿El backend Empleado.rol acepta exactamente encargado|auxiliar|veterinario|mecanico? — Verificar en backend/app/models/ o el SQL de la BD antes de cambiar el formulario.
¿La ruta /zones/[id] debe crearse como página dedicada? — El link existe en LeanFarming pero el diseño no está definido.
¿La preferencia del usuario es tema oscuro uniforme o esquema híbrido claro/oscuro según el HTML de referencia? — Pendiente de confirmar (Prioridad B2).
¿El endpoint GET /incidents devuelve objetos con severidad o prioridad? — El tipo frontend usa prioridad, el modelo backend usa severidad. Verificar el schema de respuesta real.
¿Existen endpoints para EventoReproductivo, EventoSanitario, BoxRecria y Genomica? — No están expuestos en los routers registrados. Si deben mostrarse en la ficha de animal, requieren nuevos endpoints en backend (fuera del scope de este sprint de frontend).
Qué probar después de cada fase
Fase 1: Login con cada demo user → gestionar un empleado → crear un tratamiento → verificar que no hay errores 422 en la consola.
Fase 2: Dashboard refetch a los 30s sin error → Tasks con filtro por zona → Predictions con recarga de página.
Fase 3: Crear incidencia → verificar que aparece en listado → crear pedido → cambiar estado del pedido.
Fase 4: Crear turno → asignar empleado → ver resumen en LeanFarming.
Este informe cubre el estado completo del proyecto a fecha 2026-05-28. La prioridad inmediata es la Fase 1 (correcciones de tipo), que no requiere diseño nuevo y reduce el riesgo de datos incorrectos en producción.