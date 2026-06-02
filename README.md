# TFM-Roberto
Tools4 Milk
Tools4 Milk es una plataforma digital de apoyo a la toma de decisiones para explotaciones lecheras. El proyecto nace en el marco del Trabajo Final de Master "Arquitectura inteligente de datos y modelos predictivos para la produccion de leche a la carta", orientado a mejorar la gestion productiva, sanitaria, alimentaria y operativa de una granja lechera mediante el uso integrado de datos.

La aplicacion se plantea como una herramienta practica para transformar la informacion dispersa de la explotacion en indicadores comprensibles, alertas utiles y recomendaciones accionables para el personal ganadero.

Contexto
El sector lacteo europeo y gallego se encuentra en un momento de transformacion. Las explotaciones afrontan presiones economicas, ambientales, regulatorias, laborales y de mercado que obligan a producir de forma mas eficiente, sostenible y diferenciada.

Galicia ocupa una posicion estrategica dentro del sector lacteo espanol y europeo, pero su modelo productivo esta evolucionando hacia menos explotaciones, de mayor tamano y con una mayor necesidad de gestion basada en datos. En este escenario, herramientas como Tools4 Milk buscan ayudar a que las granjas puedan aprovechar mejor la informacion que ya generan en su actividad diaria.

Problema que aborda
Las explotaciones lecheras tecnificadas producen una gran cantidad de datos: robots de ordeno, collares de actividad, sensores ambientales, registros de alimentacion, datos sanitarios, controles de calidad de leche y anotaciones operativas del dia a dia.

Sin embargo, gran parte de esa informacion permanece fragmentada en sistemas separados, hojas de calculo, aplicaciones no conectadas o pizarras fisicas. Esta dispersion dificulta detectar problemas a tiempo, interpretar tendencias, coordinar al equipo y tomar decisiones con una vision completa de la explotacion.

Tools4 Milk parte de esa necesidad: reunir la informacion relevante en una plataforma unica y convertirla en conocimiento util para la gestion diaria.

Propuesta del proyecto
La plataforma propone un sistema DSS orientado a explotaciones lecheras de tamano medio-alto. Su objetivo no es sustituir el criterio del ganadero, sino reforzarlo con informacion integrada, actualizada y presentada de forma clara.

Tools4 Milk se organiza en torno a cinco grandes areas funcionales:

Produccion: seguimiento de la produccion de leche, tendencias por animal o grupo, desviaciones y predicciones de rendimiento.
Calidad de leche: analisis de indicadores composicionales, alertas de calidad y apoyo al concepto de leche a la carta.
Alimentacion: control de raciones, desviaciones en mezclas, consumo de insumos y relacion entre dieta y resultados productivos.
Salud y reproduccion: seguimiento de animales, tratamientos, recria, eventos sanitarios y alertas relevantes para la toma de decisiones.
LeanFarming: digitalizacion de tareas, incidencias, turnos, pedidos y pantallas visuales por zona para mejorar la organizacion operativa.
Leche a la carta
Uno de los ejes diferenciales del proyecto es el concepto de leche a la carta. La idea consiste en relacionar la alimentacion de los animales con la calidad composicional de la leche, especialmente con su perfil lipidico.

El objetivo es que la explotacion pueda anticipar como determinados cambios en la racion pueden influir en el producto final. Esto abre la puerta a una leche con caracteristicas nutricionales mas especificas, verificables y adaptadas a oportunidades de mercado de mayor valor anadido.

LeanFarming
Tools4 Milk incorpora el enfoque Lean aplicado al contexto ganadero. El punto de partida son las pizarras fisicas que muchas explotaciones utilizan para coordinar tareas, incidencias, tratamientos, pedidos y relevos de turno.

El modulo LeanFarming traslada esa gestion visual al entorno digital, manteniendo su sencillez operativa pero anadiendo actualizacion automatica, trazabilidad y priorizacion de alertas. La informacion se adapta a cada zona de la granja para que cada persona vea lo que necesita en el momento y lugar adecuados.

Caso de estudio
El proyecto se ha disenado tomando como referencia una explotacion lechera gallega situada en Villalba, Lugo. Se trata de una granja representativa del modelo intensivo de tamano medio-alto, con robots de ordeno, personal organizado en turnos y una gestion diaria apoyada en varias pizarras fisicas distribuidas por la explotacion.

Este caso real permite que el diseno de la aplicacion responda a necesidades concretas del trabajo diario: cambios de turno, seguimiento de animales, control de incidencias, organizacion por zonas, alertas sanitarias, rutinas de alimentacion y toma de decisiones productivas.

Principios de diseno
Tools4 Milk se apoya en varios principios transversales:

Accionabilidad: cada indicador debe ayudar a decidir o actuar, no limitarse a mostrar datos.
Gestion visual: la informacion debe ser clara, jerarquizada y adaptada al contexto de uso.
Integracion: la plataforma busca reunir datos dispersos para evitar decisiones basadas en informacion incompleta.
Trazabilidad: los registros relevantes deben conservar su historial para facilitar seguimiento, auditoria y aprendizaje.
Usabilidad en granja: la interfaz debe ser comprensible para perfiles diversos y util en condiciones reales de trabajo.
Transparencia: las recomendaciones predictivas deben mostrar sus limites y evitar presentarse como verdades absolutas.
Impacto esperado
El impacto de la aplicacion se plantea en cuatro dimensiones:

Productiva: mejorar la eficiencia de la explotacion y anticipar desviaciones en produccion o calidad.
Sanitaria: facilitar la deteccion temprana de problemas y el seguimiento de tratamientos.
Operativa: reducir tiempos improductivos, mejorar la coordinacion del equipo y digitalizar rutinas repetitivas.
Sostenible: apoyar un uso mas eficiente de recursos como alimentacion, energia e insumos, contribuyendo a una produccion mas responsable.
Estado del proyecto
Tools4 Milk es un prototipo academico en desarrollo dentro de un Trabajo Final de Master. El alcance funcional y las decisiones tecnicas pueden evolucionar durante las siguientes fases del proyecto.

Por ese motivo, este README se centra en la vision, el proposito y el valor de la aplicacion. La documentacion tecnica se mantiene separada y podra actualizarse conforme avance la implementacion.

Contexto academico
Este proyecto forma parte del Master en Bioinformatica y Bioestadistica de la UOC y la Universidad de Barcelona, dentro del area de desarrollo de programas y aplicaciones.

El trabajo combina revision bibliografica, analisis de requisitos en una explotacion real, diseno de una arquitectura de datos, desarrollo de un prototipo funcional, modelos predictivos y una interfaz DSS orientada a la toma de decisiones en ganaderia lechera.
2.4.	Selección tecnológica y diseño de la arquitectura
La selección del stack tecnológico se fundamentó en criterios de madurez, comunidad, ecosistema de bibliotecas y adecuación a los requisitos del proyecto. Para el backend se eligió Python con el framework FastAPI, por su soporte nativo de programación asíncrona (ASGI), generación automática de documentación OpenAPI/Swagger y validación de datos integrada mediante Pydantic. Para la base de datos se seleccionó PostgreSQL, por su robustez, soporte de tipos JSONB para datos semi-estructurados y amplia comunidad. Para el frontend se eligió Next.js con React, junto con Zustand para la gestión de estado y TanStack Query para la comunicación con la API. El diseño visual se implementó con TailwindCSS.

El sistema adopta una arquitectura monolítica modular desplegada mediante contenedores Docker. A diferencia de aproximaciones basadas en microservicios, se optó por una única aplicación backend que concentra toda la lógica de negocio, simplificando el despliegue y el mantenimiento en el contexto de un MVP. La comunicación entre frontend y backend se realiza exclusivamente a través de una API REST protegida por tokens JWT. La infraestructura de despliegue se orquesta mediante Docker Compose con cuatro servicios containerizados: base de datos, backend, frontend y proxy inverso.



2.5.	Diseño de arquitectura
1.1.12.	Arquitectura implementada
La infraestructura de despliegue se define en un archivo docker-compose.yml que orquesta cuatro servicios:
Servicio	Imagen / Framework	Función
db	postgres:15-alpine	Base de datos relacional PostgreSQL 15
backend	FastAPI 0.115.6 + Uvicorn 0.34.0	API REST monolítica (lógica de negocio)
frontend	Next.js 16.2.6 + React 19.2.6	Interfaz de usuario (TypeScript 6.0)
nginx	nginx:alpine	Proxy inverso y punto de entrada HTTP

El proxy inverso Nginx enruta las peticiones /api/* al backend (puerto 8000), así como las rutas /docs, /redoc, /openapi.json y /health y el resto de rutas al frontend (puerto 3000), proporcionando un punto de entrada unificado en el puerto 80. Los datos persistentes se almacenan en un volumen Docker denominado postgres_data.

[Insertar diagrama de arquitectura del sistema]

El frontend utiliza Zustand 5.0.13 para la gestión de estado global (token JWT, usuario, rol activo, zona seleccionada), TanStack Query 5.100.14 para la comunicación con la API (caché automática, revalidación), TailwindCSS 4.3 para el diseño visual y lucide-react 1.16 para iconografía. Todos los componentes de interfaz se desarrollaron a medida.

1.1.13.	Backend: FastAPI
El backend se implementó como una aplicación monolítica en Python utilizando el framework FastAPI (versión 0.115.6) con el servidor ASGI Uvicorn (versión 0.34.0). La aplicación se estructura en los siguientes módulos principales, cada uno registrado como un router independiente en el punto de entrada (app/main.py):

Router	Prefijo API	Responsabilidad
auth	/api/v1/auth	Autenticación JWT, login y refresco de tokens
frontend_core	/api/v1	CRUD de animales, alertas, tareas, lactaciones, predicciones, calidad, incidencias, empleados, maquinaria y zonas
weather	/api/v1/weather	Consulta y sincronización de datos meteorológicos (AEMET)
audit	/api/v1/audit-log	Registro de auditoría de operaciones (solo administradores)
orders	/api/v1/pedidos	Gestión de pedidos de insumos
shifts	/api/v1/turnos, /api/v1/asignaciones-turno	Planificación de turnos y asignaciones
handovers	/api/v1/resumenes-relevo	Relevos entre turnos con resúmenes estructurados
health	/health, /api/v1/health	Comprobación de estado del servicio
Las dependencias del backend se gestionan mediante un archivo requirements.txt que incluye: SQLAlchemy 2.0.50 como ORM, psycopg 3.x como driver PostgreSQL nativo, Pydantic 2.10+ para validación de esquemas, httpx para peticiones HTTP asíncronas (integración AEMET), bcrypt 4.0.1 y passlib para el hashing de contraseñas, python-jose para la firma y verificación de tokens JWT, y pytest como framework de testing.

Cabe destacar que el proyecto no incluye dependencias de aprendizaje automático (scikit-learn, XGBoost, TensorFlow u otras). Las predicciones se implementan mediante heurísticas aritméticas basadas en datos de lactación y estado sanitario del animal, como se detalla en la sección 4.6.
Insertar diseño de estructura
1.1.14.	Frontend: Next.js + React
La interfaz de usuario se desarrolló con Next.js 16.2.6 y React 19.2.6, utilizando TypeScript 6.0 para el tipado estático. La gestión de estado global se realiza mediante Zustand 5.0.13, que mantiene en un store centralizado el token JWT, los datos del usuario autenticado, el rol activo y la zona seleccionada, con persistencia en localStorage. La comunicación con la API se gestiona mediante TanStack Query 5.100.14, que proporciona caché automática, revalidación en segundo plano y gestión de estados de carga y error.
El diseño visual se basa en TailwindCSS 4.3 como framework de utilidades CSS, complementado con el paquete lucide-react 1.16 para iconografía consistente. No se emplean bibliotecas de componentes prefabricadas (como Material UI o Ant Design); todos los componentes de interfaz se desarrollaron a medida para ajustarse a los requisitos operativos de una explotación ganadera.
Insertar diseño de estructura
1.1.15.	Base de datos: PostgreSQL 15
El sistema de gestión de bases de datos seleccionado es PostgreSQL 15 (imagen Alpine). El esquema relacional se define en el archivo database/init.sql y se complementa con los modelos ORM de SQLAlchemy 2.0 definidos en app/models/tools4milk.py. Las migraciones se aplican mediante un script Python propio (scripts/apply_migrations.py), ejecutado automáticamente en el arranque del contenedor backend.

El esquema comprende más de 25 tablas que cubren los siguientes dominios funcionales:

Dominio	Tablas principales	Descripción
Ganadería	animales, lactaciones, eventos_reproductivos, genomica	Registro individual de animales, ciclos productivos y datos genómicos
Sanidad	eventos_sanitarios, tratamientos_activos, eventos_sanitarios_recria	Historial clínico, tratamientos farmacológicos con checkboxes JSONB y seguimiento clínico de recría
Operativa	tareas_catalogo, tareas_recurrentes, tareas_ejecuciones	Catálogo de tareas, reglas de recurrencia y ejecuciones individuales
Alertas	alertas_umbrales, alertas	Umbrales configurables por métrica y alertas generadas con trazabilidad de resolución
Incidencias	incidencias	Registro de incidencias con severidad, estado, asignación y acciones (JSONB)
Personal	empleados, turnos, asignaciones_turno, resumenes_relevo	Gestión de empleados, planificación de turnos y relevos estructurados
Logística	pedidos	Ciclo de vida de pedidos de insumos (solicitud → aprobación → recepción)
IoT 	lecturas_robot_ordeno, lecturas_carro_mezclador, lecturas_meteorologia	Tablas de series temporales preparadas para la ingesta de datos de sensores y robots
Infraestructura	zonas, maquinaria, boxes_recria	Topología de la explotación y equipamiento
Auditoría	audit_log	Registro inmutable de operaciones con hash SHA-256

Se utiliza el tipo JSONB de PostgreSQL en varios modelos para almacenar estructuras flexibles: checkboxes de seguimiento de tratamientos, acciones registradas en incidencias, detalles de eventos reproductivos y alertas de boxes de recría. Esta decisión permite evolucionar el esquema de datos sin necesidad de migraciones destructivas.

Es relevante señalar que, aunque el archivo init.sql contiene referencias comentadas a la extensión TimescaleDB y a la creación de hypertables, estas funcionalidades no están activas en la versión actual del sistema. Las tablas de series temporales (lecturas_robot_ordeno, lecturas_carro_mezclador, lecturas_meteorologia) operan como tablas PostgreSQL estándar con clave primaria compuesta.

2.6.	Seguridad y control de acceso

Las contraseñas se almacenan hasheadas mediante bcrypt a través de la biblioteca passlib. Los tokens de acceso se generan con python-jose utilizando el algoritmo HS256, incluyendo claims estándar (sub, exp, iat) y un identificador único de token (jti) generado con UUID4. El middleware de autenticación (get_current_user) extrae el token del header Authorization (esquema Bearer), lo verifica contra la clave secreta del servidor y recupera el usuario correspondiente de la base de datos. Los usuarios inactivos son rechazados incluso con un token válido.

El control de acceso basado en roles (RBAC) se implementa en dos capas: en el backend, la función require_roles genera dependencias FastAPI que restringen endpoints a conjuntos de roles permitidos, y el router frontend_core aplica get_current_user a todos sus endpoints. En el frontend, el módulo role-capabilities.ts define 33 capacidades granulares asignadas a cada rol:

Rol	Descripción	Capacidades principales
admin	Administrador del sistema	Acceso completo a todas las funcionalidades (33 capacidades)
veterinario	Personal clínico	Gestión de animales, tratamientos, lactaciones, calidad, alertas, predicciones e incidencias
operario	Personal de campo	Tareas, incidencias, alertas (solo lectura), relevos, maquinaria y vista de animales
alimentacion	Responsable de nutrición	Animales, lactaciones, calidad, tareas, pedidos, incidencias y maquinaria

La pantalla de login incluye cinco usuarios de demostración preconfigurados (admin, roberto.castro, operario.zona, laura.fernandez, dr.mendez) con contraseña compartida, que se siembran automáticamente en el arranque del sistema mediante la función seed_demo_user. Para poder entrar como administrador hay que loggerarse con admin como nombre y testpass123 como contraseña.

2.7.	Integración con datos meteorológicos (AEMET)

El sistema buscar integrar datos meteorológicos reales procedentes de la Agencia Estatal de Meteorología (AEMET) a través de su API REST pública (opendata.aemet.es). El cliente, implementado en la clase AemetClient (app/services/aemet_client.py), realiza las siguientes operaciones:

1.	Solicita la predicción diaria específica para el municipio configurado (Villalba, Lugo, código 27065) enviando la API key como parámetro de autenticación. 

2.	Recibe una URL temporal con los datos en formato JSON, los descarga y parsea. 

3.	Extrae de cada día de predicción: temperatura (media de máxima y mínima), humedad relativa (media de máxima y mínima), probabilidad de precipitación (valor máximo entre los periodos del día) y velocidad del viento. Conviene precisar que el dato relativo a la precipitación corresponde a la probabilidad de precipitación proporcionada por AEMET, y no a una medida de precipitación acumulada en milímetros. 

4.	Realiza un upsert en la tabla lecturas_meteorologia, insertando registros nuevos o actualizando los existentes para evitar duplicados.

La integración requiere una API key válida de AEMET configurada como variable de entorno (AEMET_API_KEY). En ausencia de esta clave, el cliente genera datos meteorológicos sintéticos de respaldo (modo "generated") para que la aplicación pueda funcionar sin la dependencia externa; con una clave válida obtiene la predicción real de AEMET (modo "aemet_real"). Las peticiones HTTP se realizan mediante httpx con un timeout de 20 segundos.





2.8.	Herramientas de desarrollo y testing
El desarrollo se realizó con las siguientes herramientas y prácticas: control de versiones con Git, contenedorización completa con Docker y Docker Compose, linting frontend con ESLint y verificación de tipos con TypeScript (tsc --noEmit). El backend incluye pytest como framework de testing con soporte asíncrono (pytest-asyncio). La validación de configuración en producción se realiza automáticamente al arrancar la aplicación, verificando que la clave secreta tenga una longitud mínima de 32 caracteres y que los orígenes CORS estén explícitamente configurados.
 
3.	Resultados
En esta sección se describe el producto software obtenido como resultado del trabajo de desarrollo. Se presenta cada módulo funcional de la plataforma Tools4Milk tal como se encuentra implementado en el código fuente, incluyendo su interfaz de usuario, su lógica de negocio y sus endpoints API. Todos los elementos descritos son verificables en el repositorio del proyecto.

3.3.	Vista general: Dashboard operativo
El dashboard constituye la pantalla principal del sistema tras el inicio de sesión. Presenta un resumen ejecutivo del estado de la explotación, consumido desde el endpoint GET /api/v1/dashboard/summary. Este endpoint agrega el número de alertas pendientes, el conteo de tareas según su estado (programadas, ejecutadas y vencidas), el número de animales activos y el número de tratamientos activos. El acceso requiere autenticación, ya que el router aplica la dependencia get_current_user a todos sus endpoints. La adaptación de la información al rol del usuario se realiza en el frontend, mediante la visibilidad condicional de secciones según las capacidades del perfil (capacidad view_dashboard), y no mediante un filtrado en el propio endpoint.


































3.4.	Gestión de animales
El módulo de ganadería permite el registro y seguimiento individual de cada animal de la explotación. La interfaz presenta un listado filtrable con búsqueda por crotal oficial, que constituye el identificador único de cada animal. La ficha individual de un animal muestra: datos de identificación (crotal, nombre, raza, sexo, fecha de nacimiento), estado productivo (recría, producción, secado, baja), estado reproductivo, fecha de entrada en la explotación y notas adicionales.

El backend expone endpoints CRUD: listado paginado (GET /api/v1/animals, con parámetros skip/limit y filtro por estado), creación (POST /api/v1/animals), detalle (GET /api/v1/animals/{id}), actualización (PUT /api/v1/animals/{id}) y búsqueda por crotal (GET /api/v1/animals/search/by-crotal/{crotal}). El acceso está controlado por las capacidades view_animals y manage_animals, lo que permite que un operario visualice la ficha de un animal pero no la modifique.

El modelo de datos asocia a cada animal sus lactaciones, tratamientos activos, eventos sanitarios, eventos reproductivos y datos genómicos, proporcionando una visión longitudinal del historial productivo y clínico del animal. La relación madre-hijo se modela mediante una clave foránea autorreferencial en la tabla animales.
































3.5.	Sistema de alertas configurables
El módulo de alertas opera sobre un sistema de umbrales configurables almacenados en la tabla alertas_umbrales. Cada umbral define: un código identificativo, la métrica monitoreada, el operador de comparación, el valor límite, la unidad, el nivel de alerta y los canales de notificación (pantalla TV, tablet y un campo previsto para WhatsApp, actualmente no implementado). Las alertas generadas se almacenan en la tabla alertas con trazabilidad completa: timestamp de generación, animal y zona afectados, estado de resolución y empleado que la resuelve.
La API expone endpoints para listar alertas (con filtro por activas), crear alertas manuales, consultar las alertas de un animal específico, obtener alertas críticas y generar alertas automáticas para un animal concreto mediante el endpoint POST /api/v1/alerts/generate/{animal_id}. La resolución de alertas se realiza mediante PATCH /api/v1/alerts/{alert_id} y se restringe a usuarios con la capacidad resolve_alert (roles admin y veterinario).

La interfaz frontend presenta las alertas en una vista con indicadores visuales de severidad (colores diferenciados para niveles info, aviso, alerta y crítica) y permite la revisión y resolución directa desde la pantalla.

































3.6.	Gestión de tareas operativas y Lean Farming
El sistema implementa un modelo de gestión de tareas inspirado en principios Lean, estructurado en tres niveles: catálogo de tareas (tareas_catalogo), reglas de recurrencia (tareas_recurrentes) y ejecuciones individuales (tareas_ejecuciones). El catálogo define tareas tipo con su código, nombre, descripción, cualificación requerida y duración estimada en minutos. Las reglas de recurrencia asocian una tarea del catálogo a una zona o maquinaria específica con una expresión de frecuencia. Las ejecuciones registran cada instancia concreta con estados (pendiente, en_curso, completada) y marcas temporales de planificación, inicio y fin. Cabe matizar que, aunque el modelo de recurrencia está definido, la generación de ejecuciones no se dispara mediante un planificador automático en la versión actual.

La interfaz de Lean Farming proporciona una vista de tablero de gestión visual de las tareas del día, organizadas por zona y estado. La página de tareas complementa con un listado completo y filtrable de todas las ejecuciones. Ambas vistas están accesibles para operarios (capacidades manage_tasks, create_task, complete_task) y administradores.




















3.7.	Control de calidad de leche
El módulo de calidad de leche presenta un resumen estadístico del estado productivo del rebaño, calculado a partir de los registros de lactaciones activas. El endpoint GET /api/v1/lactations/quality/summary invoca el servicio lactations_service.quality_summary, que agrega métricas de las lactaciones en curso: producción total media, distribución por número de lactación y estadísticas descriptivas del rebaño.

La interfaz frontend presenta estos datos mediante indicadores KPI, tablas resumen y visualizaciones que permiten al responsable de nutrición y al veterinario evaluar rápidamente el rendimiento productivo global. El acceso se controla mediante la capacidad view_quality, disponible para los roles admin, veterinario y alimentacion.

3.8.	Módulo de predicciones
El módulo de predicciones proporciona estimaciones individuales de producción y riesgo sanitario para cada animal. Es importante destacar que, en la versión actual del MVP, estas predicciones se calculan mediante heurísticas aritméticas deterministas, no mediante modelos de aprendizaje automático. El endpoint GET /api/v1/predictions/{animal_id} implementa la siguiente lógica:

Producción base: se calcula como la producción total de la lactación activa dividida entre 305 días (duración estándar de lactación).
Penalización por tratamiento: se aplica un factor de reducción del 8 % si el animal tiene tratamientos activos.
Penalización por alertas: se descuenta un 3 % por cada alerta pendiente, con un tope máximo del 12 %.
Producción esperada: producción_base × (1 − penalización_tratamiento − penalización_alertas).
Rango de predicción: ±7 % sobre el valor esperado.
Serie diaria: 7 valores generados aplicando factores fijos [0.98, 0.99, 1.0, 1.01, 1.0, 1.02, 1.01] sobre la producción esperada.
Nivel de riesgo: alto si hay tratamientos activos, medio si hay alertas pendientes, bajo en caso contrario.

La respuesta incluye también datos de composición de leche (grasa, proteína, lactosa) y riesgos sanitarios específicos (mastitis), si bien estos valores son actualmente fijos (placeholder) y no se calculan a partir de datos reales: la composición se devuelve con valor 0 y la probabilidad de mastitis es una constante. Asimismo, los distintos índices de confianza reportados (entre 0.42 y 0.84 según la dimensión (producción, composición o riesgo) y la disponibilidad de lactación activa) son valores estáticos incorporados en el código.

La interfaz de predicciones permite seleccionar un animal y visualizar sus estimaciones de producción, tendencia, nivel de riesgo y factores de riesgo identificados. Esta vista está restringida a los roles admin y veterinario (capacidad view_predictions).

















3.9.	Gestión de incidencias

El módulo de incidencias permite registrar, clasificar y seguir eventos no planificados que afectan a la operativa de la explotación. Cada incidencia se caracteriza por: tipo y subtipo, severidad (baja, media, alta, crítica), estado (abierta, en_progreso, resuelta, cerrada), título descriptivo, zona y/o maquinaria afectada, animal relacionado (si aplica), empleado que reporta y empleado asignado, timestamps de apertura y cierre, y un campo JSONB de acciones que registra la secuencia de intervenciones realizadas. La interfaz ofrece funcionalidades de creación, filtrado por estado y severidad, detalle y resolución. El acceso se controla mediante las capacidades manage_incidents y create_incident, disponibles para todos los roles del sistema.
























3.10.	Planificación de turnos y relevos
El sistema de turnos permite definir periodos de trabajo (mañana, tarde, noche) con hora de inicio y fin, y asignar empleados a cada turno con zona y rol específicos. La tabla turnos almacena la definición del turno (con restricción de unicidad por fecha y tipo), mientras que asignaciones_turno vincula empleados individuales al turno correspondiente.
El módulo de relevos (handovers) genera resúmenes estructurados de cambio de turno que incluyen: incidencias abiertas, tareas pendientes y alertas pendientes en el momento del relevo, notas del turno saliente, y confirmación del turno entrante con timestamp y empleado que confirma. La interfaz permite la creación y visualización de turnos con sus asignaciones, y existe una vista de relevos optimizada para tablet que simplifica la interacción en dispositivos de campo.



3.11.	Gestión de pedidos de insumos
El módulo de pedidos gestiona el ciclo de vida completo de las solicitudes de insumos: desde la creación de la solicitud hasta la recepción del material. Cada pedido registra el insumo solicitado, cantidad y unidad, estado (solicitado, aprobado, recibido, cancelado), empleado solicitante, proveedor, coste estimado y coste real, y timestamps de cada transición de estado.
La interfaz (página orders, 587 líneas de código) permite crear solicitudes, aprobar pedidos pendientes y registrar la recepción de materiales. El acceso se controla mediante las capacidades manage_orders y create_order, asignadas a los roles admin y alimentacion.


















3.12.	Modo TV para pantallas de zona
El sistema incluye un modo TV diseñado para pantallas de visualización ubicadas en las zonas de trabajo de la explotación. Este modo presenta información operativa relevante (alertas activas, tareas del turno, estado de maquinaria) en formato de solo lectura y con diseño optimizado para pantallas grandes. La configuración de qué zonas disponen de pantalla TV se gestiona mediante el campo tiene_pantalla_tv del modelo Zona.
Existen dos vistas TV implementadas: una vista general (tv) y una vista específica de turnos (tv/shifts). El acceso al modo TV se controla mediante la capacidad view_tv_global, disponible para todos los roles del sistema.















3.13.	Módulos de administración y configuración
El sistema incluye varios módulos administrativos accesibles según el rol del usuario:
Gestión de usuarios y empleados: Administración de empleados (alta, edición, cualificaciones, estado) y, para administradores, gestión de cuentas de usuario. Diferencia entre empleados (personal operativo) y usuarios (cuentas de acceso).
Gestión de zonas: Creación y edición de zonas de la explotación, configurando si disponen de pantalla TV o tablet.
Registro de auditoría: Listado cronológico de todas las operaciones registradas en el audit_log, incluyendo tabla afectada, tipo de operación (INSERT, UPDATE, DELETE), datos anteriores y nuevos (JSONB) y hash SHA-256 para garantizar la integridad del registro.
Integración: Panel de estado de las integraciones externas, incluyendo la conexión con AEMET.
Configuración: Parámetros generales del sistema.
Perfil de usuario: Visualización y edición del perfil del usuario autenticado.
Informe operativo: Generación de informes agregados del estado de la explotación, consolidando datos de producción, alertas, tareas e incidencias.
 
3.14.	Datos meteorológicos en la interfaz
Los datos meteorológicos sincronizados desde AEMET se exponen en la interfaz a través de los endpoints GET /api/v1/weather/current y GET /api/v1/weather/forecast, que consultan las últimas lecturas almacenadas en la tabla lecturas_meteorologia. La información meteorológica se integra como contexto operativo, permitiendo al personal de la explotación correlacionar visualmente condiciones ambientales (temperatura, humedad, probabilidad de precipitación, viento) con eventos productivos o sanitarios.
 
