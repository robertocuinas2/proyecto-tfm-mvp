--
-- PostgreSQL database dump
--

\restrict wUhBdoDLRfdOMMR9pKR4GvZZcoozNJq6lqolT8KCV9bFPmgKT6l426UknihnlTx

-- Dumped from database version 18.4 (Debian 18.4-1.pgdg13+1)
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: estado_animal; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_animal AS ENUM (
    'produccion',
    'seca',
    'recria',
    'gestante',
    'baja'
);


--
-- Name: estado_tarea; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_tarea AS ENUM (
    'pendiente',
    'en_curso',
    'completada',
    'vencida',
    'cancelada'
);


--
-- Name: nivel_alerta; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.nivel_alerta AS ENUM (
    'baja',
    'media',
    'alta'
);


--
-- Name: tipo_turno; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_turno AS ENUM (
    'manana',
    'tarde'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alertas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    umbral_id uuid,
    nivel public.nivel_alerta NOT NULL,
    titulo character varying(200) NOT NULL,
    mensaje text,
    origen_tabla character varying(100),
    origen_id uuid,
    animal_id uuid,
    zona_id uuid,
    push_whatsapp boolean NOT NULL,
    pantalla_tv boolean NOT NULL,
    tablet boolean NOT NULL,
    activa boolean NOT NULL,
    ts_generacion timestamp with time zone NOT NULL,
    ts_resolucion timestamp with time zone,
    resuelta_por uuid
);


--
-- Name: alertas_umbrales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertas_umbrales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    codigo character varying(80) NOT NULL,
    descripcion text NOT NULL,
    metrica character varying(100) NOT NULL,
    operador character varying(10) NOT NULL,
    valor_umbral numeric(12,4) NOT NULL,
    unidad character varying(30),
    nivel_alerta character varying(20) NOT NULL,
    push_whatsapp boolean NOT NULL,
    pantalla_tv boolean NOT NULL,
    tablet boolean NOT NULL,
    activo boolean NOT NULL,
    notas text
);


--
-- Name: animales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    crotal_oficial character varying(20) NOT NULL,
    nombre character varying(80),
    sexo character varying(20) NOT NULL,
    fecha_nacimiento date NOT NULL,
    raza character varying(80),
    estado public.estado_animal NOT NULL,
    estado_reproductivo character varying(40),
    madre_id uuid,
    zona_id uuid,
    fecha_entrada date NOT NULL,
    fecha_baja date,
    motivo_baja character varying(200),
    notas text
);


--
-- Name: asignaciones_turno; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asignaciones_turno (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    turno_id uuid NOT NULL,
    empleado_id uuid NOT NULL,
    zona_id uuid,
    rol character varying(80)
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    ts timestamp with time zone NOT NULL,
    tabla_afectada character varying(100) NOT NULL,
    operacion character varying(6) NOT NULL,
    registro_id uuid NOT NULL,
    datos_anteriores jsonb,
    datos_nuevos jsonb,
    usuario_bd character varying(100) NOT NULL,
    hash_sha256 text NOT NULL
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: boxes_recria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boxes_recria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    box_numero smallint NOT NULL,
    ternero_id uuid,
    fecha_entrada date,
    fecha_salida date,
    activo boolean NOT NULL,
    alertas_box jsonb NOT NULL,
    notas text
);


--
-- Name: core_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_alerts (
    id character varying(80) NOT NULL,
    animal_id character varying(80) NOT NULL,
    tipo_alerta character varying(120) NOT NULL,
    severidad character varying(40) NOT NULL,
    descripcion text NOT NULL,
    recomendacion text,
    estado character varying(40) NOT NULL,
    confianza_prediccion double precision,
    requiere_escalacion boolean NOT NULL,
    fecha_creacion timestamp with time zone NOT NULL,
    fecha_revision timestamp with time zone,
    revisada boolean NOT NULL,
    notas_operario text,
    accion_tomada text,
    veterinario_responsable character varying(120)
);


--
-- Name: core_animals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_animals (
    id character varying(80) NOT NULL,
    crotal_oficial character varying(80) NOT NULL,
    nombre character varying(120),
    sexo character varying(40) NOT NULL,
    fecha_nacimiento character varying(20) NOT NULL,
    raza character varying(80),
    estado character varying(40) NOT NULL,
    estado_reproductivo character varying(80),
    fecha_entrada character varying(20) NOT NULL,
    fecha_baja character varying(20),
    motivo_baja character varying(255),
    notas text
);


--
-- Name: core_employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_employees (
    id character varying(80) NOT NULL,
    nombre character varying(120) NOT NULL,
    apellidos character varying(160),
    role character varying(80),
    zona_principal_id character varying(80),
    activo boolean NOT NULL
);


--
-- Name: core_incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_incidents (
    id character varying(80) NOT NULL,
    tipo character varying(120) NOT NULL,
    zona_id character varying(80),
    animal_id character varying(80),
    descripcion text NOT NULL,
    prioridad character varying(40) NOT NULL,
    estado character varying(40) NOT NULL,
    fecha_creacion timestamp with time zone NOT NULL,
    fecha_resolucion timestamp with time zone,
    resolucion text,
    reportado_por character varying(120)
);


--
-- Name: core_lactations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_lactations (
    id character varying(80) NOT NULL,
    animal_id character varying(80) NOT NULL,
    numero_lactacion integer,
    fecha_inicio character varying(20),
    fecha_fin character varying(20),
    dias_transcurridos integer,
    produccion_promedio double precision,
    produccion_total double precision,
    grasa_promedio double precision,
    proteina_promedio double precision,
    rcs_promedio double precision,
    activa boolean NOT NULL
);


--
-- Name: core_machinery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_machinery (
    id character varying(80) NOT NULL,
    nombre character varying(160) NOT NULL,
    tipo character varying(80) NOT NULL,
    zona_id character varying(80),
    estado character varying(80) NOT NULL,
    proxima_revision character varying(20),
    observaciones text
);


--
-- Name: core_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_tasks (
    id character varying(80) NOT NULL,
    tarea_catalogo_id character varying(80) NOT NULL,
    tarea_catalogo json,
    zona_id character varying(80),
    fecha_programada timestamp with time zone NOT NULL,
    fecha_ejecucion timestamp with time zone,
    estado character varying(40) NOT NULL,
    ejecutado_por character varying(120),
    tiempo_ejecucion_minutos character varying(40),
    resultado character varying(120),
    observaciones text,
    problemas_encontrados text,
    acciones_correctivas text,
    checklist_completado character varying(10) NOT NULL,
    checklist_datos text,
    es_urgente boolean NOT NULL,
    motivo_retraso text,
    requiere_seguimiento boolean NOT NULL,
    fecha_seguimiento timestamp with time zone
);


--
-- Name: core_treatments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_treatments (
    id character varying(80) NOT NULL,
    animal_id character varying(80) NOT NULL,
    medicamento character varying(160),
    dosis character varying(120),
    via_administracion character varying(80),
    fecha_inicio character varying(20) NOT NULL,
    fecha_fin character varying(20),
    periodo_retirada_dias integer,
    fecha_fin_retirada character varying(20),
    activo boolean NOT NULL,
    motivo text,
    veterinario character varying(120),
    observaciones text
);


--
-- Name: core_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_zones (
    id character varying(80) NOT NULL,
    nombre character varying(120) NOT NULL,
    codigo character varying(20) NOT NULL,
    descripcion text,
    tipo character varying(80),
    tiene_pantalla_tv boolean NOT NULL,
    tiene_tablet boolean NOT NULL,
    activa boolean NOT NULL
);


--
-- Name: datos_metereologicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datos_metereologicos (
    id integer NOT NULL,
    fecha_hora timestamp with time zone,
    temperatura_media double precision,
    temperatura_maxima double precision,
    temperatura_minima double precision,
    humedad_relativa double precision,
    precipitacion double precision,
    velocidad_viento double precision,
    presion_atmosferica double precision,
    estado_cielo character varying(120),
    ubicacion character varying(160) NOT NULL,
    latitud double precision,
    longitud double precision,
    fuente character varying(80)
);


--
-- Name: datos_metereologicos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.datos_metereologicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datos_metereologicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.datos_metereologicos_id_seq OWNED BY public.datos_metereologicos.id;


--
-- Name: empleados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empleados (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    apellidos character varying(150) NOT NULL,
    rol character varying(40) NOT NULL,
    zona_principal_id uuid,
    cualificaciones text[],
    telefono character varying(20),
    email character varying(150),
    activo boolean NOT NULL,
    fecha_alta date NOT NULL,
    fecha_baja date
);


--
-- Name: eventos_reproductivos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_reproductivos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    animal_id uuid NOT NULL,
    tipo character varying(50) NOT NULL,
    fecha date NOT NULL,
    hora time without time zone,
    empleado_id uuid,
    detalles jsonb NOT NULL,
    notas text,
    creado_en timestamp with time zone NOT NULL
);


--
-- Name: eventos_sanitarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_sanitarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    animal_id uuid NOT NULL,
    tipo_patologia character varying(50) NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    tratamiento text,
    farmaco character varying(200),
    dosis character varying(100),
    via_administracion character varying(80),
    periodo_retirada_hasta date,
    resuelto boolean NOT NULL,
    coste numeric(8,2),
    veterinario_id uuid,
    notas text
);


--
-- Name: eventos_sanitarios_recria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_sanitarios_recria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    animal_id uuid NOT NULL,
    fecha date NOT NULL,
    edad_dias integer,
    score_neumonia smallint NOT NULL,
    score_diarrea smallint NOT NULL,
    score_ombligo smallint NOT NULL,
    peso_kg numeric(5,1),
    tratamiento text,
    observaciones text,
    empleado_id uuid
);


--
-- Name: genomica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genomica (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    animal_id uuid NOT NULL,
    fecha_extraccion date NOT NULL,
    tipo_muestra character varying(60),
    laboratorio character varying(150),
    referencia_lab character varying(100),
    fecha_resultado date,
    resultados_ref text,
    notas text
);


--
-- Name: incidencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incidencias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tipo character varying(50) NOT NULL,
    subtipo character varying(80),
    severidad character varying(20) NOT NULL,
    estado character varying(20) NOT NULL,
    titulo character varying(200) NOT NULL,
    descripcion text,
    zona_id uuid,
    maquinaria_id uuid,
    animal_id uuid,
    reportado_por uuid,
    asignado_a uuid,
    ts_apertura timestamp with time zone NOT NULL,
    ts_cierre timestamp with time zone,
    foto_url text,
    acciones jsonb NOT NULL
);


--
-- Name: lactaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lactaciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    animal_id uuid NOT NULL,
    numero smallint NOT NULL,
    fecha_parto date NOT NULL,
    fecha_secado date,
    produccion_total_kg numeric(8,2),
    grasa_promedio numeric(5,3),
    proteina_promedio numeric(5,3),
    rcs_promedio integer,
    notas text
);


--
-- Name: lecturas_carro_mezclador; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lecturas_carro_mezclador (
    ts timestamp with time zone NOT NULL,
    mezcla_id uuid NOT NULL,
    ingrediente character varying(100) NOT NULL,
    peso_objetivo numeric(7,2) NOT NULL,
    peso_real numeric(7,2),
    operario_id uuid
);


--
-- Name: lecturas_meteorologia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lecturas_meteorologia (
    ts timestamp with time zone NOT NULL,
    estacion_id character varying(20) NOT NULL,
    temperatura_c numeric(4,1),
    humedad_relativa numeric(4,1),
    precipitacion_mm numeric(5,1),
    viento_km_h numeric(5,1),
    direccion_viento smallint,
    radiacion_wm2 numeric(6,1)
);


--
-- Name: lecturas_robot_ordeno; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lecturas_robot_ordeno (
    ts timestamp with time zone NOT NULL,
    robot_id uuid NOT NULL,
    animal_id uuid NOT NULL,
    lactacion_id uuid,
    produccion_kg numeric(5,2),
    conductividad numeric(5,2),
    flujo_max numeric(4,2),
    scc integer,
    duracion_min numeric(5,1),
    intentos_fallidos smallint NOT NULL,
    alerta_robot boolean NOT NULL
);


--
-- Name: maquinaria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maquinaria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    tipo character varying(40) NOT NULL,
    zona_id uuid,
    marca character varying(100),
    modelo character varying(100),
    numero_serie character varying(100),
    fecha_instalacion date,
    activa boolean DEFAULT true NOT NULL,
    estado character varying(40) DEFAULT 'operativa'::character varying NOT NULL,
    notas text
);


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    insumo character varying(200) NOT NULL,
    descripcion text,
    cantidad numeric(10,2) NOT NULL,
    unidad character varying(30),
    estado character varying(20) NOT NULL,
    solicitante_id uuid,
    ts_solicitud timestamp with time zone NOT NULL,
    ts_aprobacion timestamp with time zone,
    ts_recepcion timestamp with time zone,
    proveedor character varying(150),
    coste_estimado numeric(10,2),
    coste_real numeric(10,2),
    notas text
);


--
-- Name: resumenes_relevo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resumenes_relevo (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    turno_saliente_id uuid NOT NULL,
    turno_entrante_id uuid NOT NULL,
    ts_generacion timestamp with time zone NOT NULL,
    incidencias_abiertas jsonb NOT NULL,
    tareas_pendientes jsonb NOT NULL,
    alertas_pendientes jsonb NOT NULL,
    notas_saliente text,
    confirmado_por uuid,
    ts_confirmacion timestamp with time zone
);


--
-- Name: tareas_catalogo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tareas_catalogo (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    codigo character varying(60) NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    cualificacion_requerida text,
    duracion_estimada_min integer,
    activa boolean DEFAULT true NOT NULL
);


--
-- Name: tareas_ejecuciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tareas_ejecuciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    catalogo_id uuid NOT NULL,
    recurrente_id uuid,
    empleado_id uuid,
    zona_id uuid,
    maquinaria_id uuid,
    estado public.estado_tarea NOT NULL,
    ts_planificada timestamp with time zone NOT NULL,
    ts_inicio timestamp with time zone,
    ts_fin timestamp with time zone,
    notas text,
    creado_en timestamp with time zone NOT NULL
);


--
-- Name: tareas_recurrentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tareas_recurrentes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    catalogo_id uuid NOT NULL,
    zona_id uuid,
    maquinaria_id uuid,
    frecuencia_expr character varying(100) NOT NULL,
    descripcion_frecuencia text,
    activa boolean NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    notas text
);


--
-- Name: tratamientos_activos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tratamientos_activos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    animal_id uuid NOT NULL,
    evento_sanitario_id uuid,
    farmaco character varying(200) NOT NULL,
    dosis character varying(100),
    via_administracion character varying(80),
    dias_tratamiento smallint NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin_prevista date NOT NULL,
    fecha_fin_real date,
    activo boolean NOT NULL,
    checkboxes jsonb NOT NULL,
    prescrito_por uuid,
    notas text
);


--
-- Name: turnos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.turnos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fecha date NOT NULL,
    tipo_turno public.tipo_turno NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    notas text
);


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(80) NOT NULL,
    email character varying(255) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    role character varying(40) NOT NULL,
    activo boolean NOT NULL,
    debe_cambiar_contrasena boolean NOT NULL,
    fecha_creacion timestamp with time zone NOT NULL
);


--
-- Name: zonas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zonas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    codigo character varying(30) NOT NULL,
    descripcion text,
    tiene_pantalla_tv boolean NOT NULL,
    tiene_tablet boolean NOT NULL
);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: datos_metereologicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_metereologicos ALTER COLUMN id SET DEFAULT nextval('public.datos_metereologicos_id_seq'::regclass);


--
-- Data for Name: alertas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alertas (id, umbral_id, nivel, titulo, mensaje, origen_tabla, origen_id, animal_id, zona_id, push_whatsapp, pantalla_tv, tablet, activa, ts_generacion, ts_resolucion, resuelta_por) FROM stdin;
bfff44da-ce8c-4e33-aea3-3fc44553bf13	\N	alta	RCS individual fuera de rango	RCS individual fuera de rango.	\N	\N	ccc31b03-59ce-4c4b-aba9-0c81614e5088	\N	f	t	t	t	2026-06-02 01:08:41.299942+00	\N	\N
784d0623-0bee-47a4-8c68-c0248ebb4e54	\N	media	Tarea de lavado de robot pendiente	Tarea de lavado de robot pendiente.	\N	\N	6531f064-936a-48e6-ad33-e4207476ddfc	\N	f	t	t	t	2026-06-01 18:08:41.300172+00	\N	\N
57720dad-67d7-4d0d-a2c0-d9c109da1517	\N	alta	Tratamiento activo sin registrar	Tratamiento activo sin registrar.	\N	\N	6585a2a9-6e35-4958-a40e-653ababa5d65	\N	f	t	t	t	2026-06-01 19:08:41.300251+00	\N	\N
68074092-0c3e-4c36-917f-00e7d6a0581f	\N	baja	Recordatorio de protocolo de vacunación	Recordatorio de protocolo de vacunación.	\N	\N	8299c2db-ca85-4049-9e73-68b62e770b5e	\N	f	t	t	t	2026-06-02 19:08:41.300309+00	\N	\N
e9446dee-1fe8-415e-b732-aaf573b94d01	\N	media	Desviación de ración TMR > 5%	Desviación de ración TMR > 5%.	\N	\N	9a3e4fb5-7c02-4f83-8f6e-d432d3093862	\N	f	t	t	t	2026-06-02 10:08:41.300362+00	\N	\N
\.


--
-- Data for Name: alertas_umbrales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alertas_umbrales (id, codigo, descripcion, metrica, operador, valor_umbral, unidad, nivel_alerta, push_whatsapp, pantalla_tv, tablet, activo, notas) FROM stdin;
\.


--
-- Data for Name: animales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.animales (id, crotal_oficial, nombre, sexo, fecha_nacimiento, raza, estado, estado_reproductivo, madre_id, zona_id, fecha_entrada, fecha_baja, motivo_baja, notas) FROM stdin;
ccc31b03-59ce-4c4b-aba9-0c81614e5088	ES1500000001	Lúa	hembra	2021-02-18	Pardo Alpina	produccion	vacia	\N	\N	2021-06-03	\N	\N	\N
6531f064-936a-48e6-ad33-e4207476ddfc	ES1500000002	Estrela	hembra	2018-12-14	Cruce	produccion	parto_reciente	\N	\N	2019-06-04	\N	\N	\N
6585a2a9-6e35-4958-a40e-653ababa5d65	ES1500000003	Marela	hembra	2023-01-15	Cruce	produccion	confirmada_gestante	\N	\N	2023-06-03	\N	\N	\N
8299c2db-ca85-4049-9e73-68b62e770b5e	ES1500000004	Pinta	hembra	2019-02-24	Frisona	produccion	vacia	\N	\N	2019-06-04	\N	\N	\N
9a3e4fb5-7c02-4f83-8f6e-d432d3093862	ES1500000005	Galana	hembra	2023-02-12	Pardo Alpina	produccion	confirmada_gestante	\N	\N	2023-06-03	\N	\N	\N
3197b691-8153-4c3b-b59e-2bc44b2ef8f3	ES1500000006	Loira	hembra	2023-04-23	Pardo Alpina	produccion	parto_reciente	\N	\N	2023-06-03	\N	\N	\N
6ba424e3-ab02-4186-8e44-203f04a3732d	ES1500000007	Cabana	hembra	2021-04-21	Frisona	produccion	vacia	\N	\N	2021-06-03	\N	\N	\N
2bc3ec73-e0a8-442f-a62e-c8dfefb0f3a3	ES1500000008	Rosa	hembra	2019-11-25	Frisona	produccion	confirmada_gestante	\N	\N	2020-06-03	\N	\N	\N
7510d06f-9604-4cfd-b92f-bb322435d97f	ES1500000009	Vaqueira	hembra	2020-05-22	Frisona	produccion	parto_reciente	\N	\N	2020-06-03	\N	\N	\N
506e8f7c-aeaa-4d53-b862-e3a1d449756c	ES1500000010	Moura	hembra	2021-02-28	Frisona	produccion	inseminada	\N	\N	2021-06-03	\N	\N	\N
8bd66d2e-2108-494a-a71d-32da9ad999a1	ES1500000011	Xoana	hembra	2019-02-25	Frisona	produccion	parto_reciente	\N	\N	2019-06-04	\N	\N	\N
cbb5b74b-04aa-4a29-b76f-1d204f07e7e8	ES1500000012	Brava	hembra	2020-01-07	Pardo Alpina	produccion	confirmada_gestante	\N	\N	2020-06-03	\N	\N	\N
eac5e48d-852b-488d-978d-d7cd273fa68a	ES1500000013	Donosa	hembra	2019-04-28	Frisona	produccion	inseminada	\N	\N	2019-06-04	\N	\N	\N
92213cac-37ee-494a-a71d-7f70570e12d6	ES1500000014	Faísca	hembra	2021-04-06	Frisona	produccion	parto_reciente	\N	\N	2021-06-03	\N	\N	\N
eb5247b6-6796-4c63-ba5b-b656a79e8e5d	ES1500000015	Lousa	hembra	2019-05-05	Frisona	produccion	confirmada_gestante	\N	\N	2019-06-04	\N	\N	\N
5485f060-45cd-4b94-a9d4-e73f51f03abc	ES1500000016	Meiga	hembra	2021-02-18	Cruce	produccion	inseminada	\N	\N	2021-06-03	\N	\N	\N
5a8f5a05-bcbe-4cb0-a1ec-7dd07a5f1c2a	ES1500000017	Nai	hembra	2018-11-24	Frisona	produccion	vacia	\N	\N	2019-06-04	\N	\N	\N
09022a53-d44a-4727-a0e6-50d6516a3931	ES1500000018	Perla	hembra	2020-11-24	Frisona	produccion	parto_reciente	\N	\N	2021-06-03	\N	\N	\N
ce063c55-dc12-465b-b8d4-d9d9f1597feb	ES1500000019	Quenlla	hembra	2021-03-11	Frisona	produccion	confirmada_gestante	\N	\N	2021-06-03	\N	\N	\N
9741bd61-4f0a-476a-9d02-4058c5ffb3cd	ES1500000020	Ruda	hembra	2020-12-15	Frisona	produccion	confirmada_gestante	\N	\N	2021-06-03	\N	\N	\N
156682e8-c418-4dbe-ab7c-cae4a647ab74	ES1500000021	Sela	hembra	2020-05-19	Pardo Alpina	produccion	vacia	\N	\N	2020-06-03	\N	\N	\N
9c831d18-7636-4ba8-93f1-a83ac83b6974	ES1500000022	Tella	hembra	2021-12-08	Cruce	produccion	confirmada_gestante	\N	\N	2022-06-03	\N	\N	\N
f579430d-07da-401c-a6f4-77147e25706e	ES1500000023	Uxía	hembra	2021-05-15	Frisona	produccion	inseminada	\N	\N	2021-06-03	\N	\N	\N
b3a5730a-9db7-4d8b-8566-00f6754d4aa2	ES1500000024	Veiga	hembra	2019-12-09	Frisona	produccion	confirmada_gestante	\N	\N	2020-06-03	\N	\N	\N
39a211d9-b089-40f9-8117-709e15e96105	ES1500000025	Airexa	hembra	2020-05-08	Cruce	produccion	vacia	\N	\N	2020-06-03	\N	\N	\N
a360ded8-0ae1-41d4-b3f6-20cf7afda3d4	ES1500000026	Bican	hembra	2020-04-28	Frisona	produccion	parto_reciente	\N	\N	2020-06-03	\N	\N	\N
3ed470f7-737e-4949-922b-3418fa9a45bd	ES1500000027	Centola	hembra	2019-03-28	Cruce	produccion	inseminada	\N	\N	2019-06-04	\N	\N	\N
c64d0fc4-0c5e-4605-a2d7-8eba4d29b047	ES1500000028	Dorna	hembra	2021-12-27	Frisona	produccion	vacia	\N	\N	2022-06-03	\N	\N	\N
4f2aaf22-fe56-40cb-aad8-aaa6d7e60044	ES1500000029	Eira	hembra	2022-04-15	Frisona	produccion	inseminada	\N	\N	2022-06-03	\N	\N	\N
9d2d6988-a97f-449c-95c4-67cf0dbe0d7c	ES1500000030	Fonte	hembra	2020-02-13	Frisona	produccion	confirmada_gestante	\N	\N	2020-06-03	\N	\N	\N
1f93c113-f4cc-462b-8a99-8b70a5fc654e	ES1500000031	Lúa	hembra	2019-06-04	Pardo Alpina	gestante	confirmada_gestante	\N	\N	2023-12-15	\N	\N	\N
5677d8ef-46e9-46e1-a28f-887dc830ad1e	ES1500000032	Estrela	hembra	2018-06-04	Cruce	seca	confirmada_gestante	\N	\N	2023-12-15	\N	\N	\N
e06f5c59-a96f-4ecd-bf8e-82d0be353989	ES1500000033	Marela	hembra	2018-06-04	Frisona	gestante	confirmada_gestante	\N	\N	2023-12-15	\N	\N	\N
2b914db8-e190-45bd-82f7-217202733482	ES1500000034	Pinta	hembra	2021-06-03	Frisona	seca	confirmada_gestante	\N	\N	2023-12-15	\N	\N	\N
836495b5-111e-4a1d-b27c-3bfb896ba378	ES1500000035	Galana	hembra	2021-06-03	Pardo Alpina	produccion	vacia	\N	\N	2024-07-02	\N	\N	\N
695c4157-8cfa-4464-8240-f0c0465c74af	ES1500000036	Loira	hembra	2021-06-03	Frisona	produccion	vacia	\N	\N	2024-07-02	\N	\N	\N
f95dd3cd-b5c0-40b6-8288-a77bf3e8030a	ES1500000037	Cabana	hembra	2023-06-03	Frisona	produccion	vacia	\N	\N	2024-07-02	\N	\N	\N
5d5eb290-dea4-40b8-a664-231bad30660b	ES1500000038	Rosa	hembra	2025-05-08	Frisona	recria	\N	\N	\N	2025-05-08	\N	\N	\N
9bc2a239-9362-440c-b758-490d29bd179e	ES1500000039	Vaqueira	hembra	2025-05-08	Frisona	recria	\N	\N	\N	2025-05-08	\N	\N	\N
51a8e0b6-f4cb-4e6d-9447-185eab1a2787	ES1500000040	Moura	hembra	2025-02-07	Pardo Alpina	recria	\N	\N	\N	2025-02-07	\N	\N	\N
62b58c14-d29c-4510-9d40-6555a215788b	ES1500000041	Xoana	hembra	2025-04-08	Frisona	recria	\N	\N	\N	2025-04-08	\N	\N	\N
066d5f29-44fa-4e7f-bb11-6ec9217c582b	ES1500000042	Brava	hembra	2025-02-07	Frisona	recria	\N	\N	\N	2025-02-07	\N	\N	\N
1f8f2f8b-9f42-49d7-a195-4727121e47d3	ES1500000043	Donosa	hembra	2024-11-09	Frisona	recria	\N	\N	\N	2024-11-09	\N	\N	\N
1ddc88e7-f5a8-4f96-b3d5-89e3bc7ab619	ES1500000044	Faísca	hembra	2025-09-05	Frisona	recria	\N	\N	\N	2025-09-05	\N	\N	\N
944b8dc6-0e9c-4148-80be-692b88bf94d7	ES1500000045	Lousa	hembra	2024-12-09	Frisona	recria	\N	\N	\N	2024-12-09	\N	\N	\N
98a22029-1634-4f4c-99e4-ee9f140b3d21	ES1500000046	Meiga	hembra	2025-09-05	Cruce	recria	\N	\N	\N	2025-09-05	\N	\N	\N
182c8460-161f-4501-b7f4-deb36056f381	ES1500000047	Nai	hembra	2024-11-09	Frisona	recria	\N	\N	\N	2024-11-09	\N	\N	\N
7385630a-1c05-4c98-82a4-256a4455faaa	ES1500000048	\N	macho	2026-04-24	Frisona	recria	\N	\N	\N	2026-04-24	\N	\N	\N
84fe1ec8-1456-4a8b-b88f-4e86a52f92f3	ES1500000049	\N	macho	2026-05-16	Frisona	recria	\N	\N	\N	2026-05-16	\N	\N	\N
9bab4b03-2dae-4f9e-85d3-3dbed91c7bf1	ES1500000050	\N	hembra	2026-04-28	Frisona	recria	\N	\N	\N	2026-04-28	\N	\N	\N
5265a5e3-829b-40a3-8fa7-abc71fc93062	ES1500000051	\N	macho	2026-04-30	Cruce	recria	\N	\N	\N	2026-04-30	\N	\N	\N
0af62238-54d7-47e1-9f18-90c556566fec	ES1500000052	\N	macho	2026-04-28	Pardo Alpina	recria	\N	\N	\N	2026-04-28	\N	\N	\N
9a43fbd3-40c9-4baf-8b09-98423ff23b89	ES1500000053	\N	macho	2026-04-04	Frisona	recria	\N	\N	\N	2026-04-04	\N	\N	\N
\.


--
-- Data for Name: asignaciones_turno; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.asignaciones_turno (id, turno_id, empleado_id, zona_id, rol) FROM stdin;
701c68a8-5332-4074-b629-65425e4e9e4b	a22ebeca-a56f-41fe-bd1c-59dfa58c84ed	0525a759-071e-456f-b665-d7cdbf945fd9	\N	auxiliar
0c50e1c7-ade4-44b3-bf49-01a3d1da59e6	a22ebeca-a56f-41fe-bd1c-59dfa58c84ed	d2478d12-e98d-407b-95f0-84a12e7b3a28	\N	auxiliar
b32d9eda-f60c-4229-8e64-46cbdc4bb389	8daf2fde-c21f-45c7-9c1a-9404ee253fe2	7def8ca6-c357-497c-b3bd-729866e76435	\N	veterinario
6593bbcd-4c5c-47d7-adbd-a4f5d45213c5	8daf2fde-c21f-45c7-9c1a-9404ee253fe2	d3c0f3b4-0c93-4ff1-83d5-30ae502b0c9e	\N	mecanico
bccf1f7f-25ef-4ea5-b705-47ea6d6241d9	6ba00d74-01c1-4ebb-a04d-26e1445df35b	0525a759-071e-456f-b665-d7cdbf945fd9	\N	auxiliar
4539e182-ddfb-48fa-8071-a21ddb41874d	6ba00d74-01c1-4ebb-a04d-26e1445df35b	a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	\N	auxiliar
ff796266-d754-4985-87bc-89b3622e22f9	ab7683f2-ad68-47d2-a104-fb769efe5328	098dda7f-1765-4280-9eb6-b9299a3d4688	\N	encargado
dab7bdd9-af81-4379-938f-6f03c9d37f34	ab7683f2-ad68-47d2-a104-fb769efe5328	d2478d12-e98d-407b-95f0-84a12e7b3a28	\N	auxiliar
b84fa6e2-7c28-4cb7-b34a-87b9962f8643	c6c9e0ee-bc95-4808-8142-83f878897ca7	d3c0f3b4-0c93-4ff1-83d5-30ae502b0c9e	\N	mecanico
39177753-0fad-4b85-8089-a8ff428d3911	c6c9e0ee-bc95-4808-8142-83f878897ca7	a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	\N	auxiliar
1fbb31a8-16d1-4dbc-96bd-312c7cc60231	ce83d9a6-90b0-4c2d-9dfd-6b890eb82443	d3c0f3b4-0c93-4ff1-83d5-30ae502b0c9e	\N	mecanico
a44ebbe7-3d0c-4cdb-ad0c-6e8f06c96ac8	ce83d9a6-90b0-4c2d-9dfd-6b890eb82443	0525a759-071e-456f-b665-d7cdbf945fd9	\N	auxiliar
165fd64d-5f1a-4c3d-ac49-f92930dde48d	eac87073-c293-4b6f-b8f3-8fc809d6768c	7def8ca6-c357-497c-b3bd-729866e76435	\N	veterinario
b6b7b970-d116-4798-8d95-6c333f12ef74	eac87073-c293-4b6f-b8f3-8fc809d6768c	a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	\N	auxiliar
07d33fde-7131-4eab-8f98-1bc473cf4684	58d475b3-5b87-42c2-9c16-ed00ac3f2e50	d3c0f3b4-0c93-4ff1-83d5-30ae502b0c9e	\N	mecanico
7c2e5ad9-a44a-46fe-bed4-6eb20a3b4fd9	58d475b3-5b87-42c2-9c16-ed00ac3f2e50	0525a759-071e-456f-b665-d7cdbf945fd9	\N	auxiliar
eff59ea3-8e51-415e-9e6c-b5b4d343bdd0	48823616-3534-43a6-abdc-e87c67ff1c48	a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	\N	auxiliar
9e3f30f9-3a3a-48bd-80f3-c5afb8f53b3b	48823616-3534-43a6-abdc-e87c67ff1c48	d3c0f3b4-0c93-4ff1-83d5-30ae502b0c9e	\N	mecanico
474474dc-b47d-4384-b7b4-05f97df8001a	bc11a5ea-e86e-4170-86ac-b5451347e923	a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	\N	auxiliar
faec11d6-2035-4073-a776-7342e6f974cf	bc11a5ea-e86e-4170-86ac-b5451347e923	7def8ca6-c357-497c-b3bd-729866e76435	\N	veterinario
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, ts, tabla_afectada, operacion, registro_id, datos_anteriores, datos_nuevos, usuario_bd, hash_sha256) FROM stdin;
\.


--
-- Data for Name: boxes_recria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.boxes_recria (id, box_numero, ternero_id, fecha_entrada, fecha_salida, activo, alertas_box, notas) FROM stdin;
4e9767a3-7a06-4466-a9d2-8bd85b901514	1	84fe1ec8-1456-4a8b-b88f-4e86a52f92f3	2026-05-07	\N	t	[]	\N
17684488-51ef-40cd-abca-3933901ececc	2	5265a5e3-829b-40a3-8fa7-abc71fc93062	2026-05-21	\N	t	[]	\N
4cfc863f-0f6c-4bfa-9304-5b73aad792a3	3	0af62238-54d7-47e1-9f18-90c556566fec	2026-05-04	\N	t	[]	\N
421e53bc-f59e-4f13-9ee8-85020d0ef303	4	9bab4b03-2dae-4f9e-85d3-3dbed91c7bf1	2026-05-23	\N	t	[]	\N
4127e180-9b40-44d5-b767-1879abdbdb69	5	7385630a-1c05-4c98-82a4-256a4455faaa	2026-05-31	\N	t	[]	\N
28020539-9c81-43e1-b8bb-8ef1bb0b8ae4	6	9a43fbd3-40c9-4baf-8b09-98423ff23b89	2026-05-23	\N	t	[]	\N
beff653e-f390-4afa-97e2-61ea0ffb3aff	7	\N	\N	\N	t	[]	\N
700281f1-59fc-4f05-93a0-b23473d2edd6	8	\N	\N	\N	t	[]	\N
\.


--
-- Data for Name: core_alerts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_alerts (id, animal_id, tipo_alerta, severidad, descripcion, recomendacion, estado, confianza_prediccion, requiere_escalacion, fecha_creacion, fecha_revision, revisada, notas_operario, accion_tomada, veterinario_responsable) FROM stdin;
\.


--
-- Data for Name: core_animals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_animals (id, crotal_oficial, nombre, sexo, fecha_nacimiento, raza, estado, estado_reproductivo, fecha_entrada, fecha_baja, motivo_baja, notas) FROM stdin;
\.


--
-- Data for Name: core_employees; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_employees (id, nombre, apellidos, role, zona_principal_id, activo) FROM stdin;
\.


--
-- Data for Name: core_incidents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_incidents (id, tipo, zona_id, animal_id, descripcion, prioridad, estado, fecha_creacion, fecha_resolucion, resolucion, reportado_por) FROM stdin;
\.


--
-- Data for Name: core_lactations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_lactations (id, animal_id, numero_lactacion, fecha_inicio, fecha_fin, dias_transcurridos, produccion_promedio, produccion_total, grasa_promedio, proteina_promedio, rcs_promedio, activa) FROM stdin;
\.


--
-- Data for Name: core_machinery; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_machinery (id, nombre, tipo, zona_id, estado, proxima_revision, observaciones) FROM stdin;
\.


--
-- Data for Name: core_tasks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_tasks (id, tarea_catalogo_id, tarea_catalogo, zona_id, fecha_programada, fecha_ejecucion, estado, ejecutado_por, tiempo_ejecucion_minutos, resultado, observaciones, problemas_encontrados, acciones_correctivas, checklist_completado, checklist_datos, es_urgente, motivo_retraso, requiere_seguimiento, fecha_seguimiento) FROM stdin;
\.


--
-- Data for Name: core_treatments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_treatments (id, animal_id, medicamento, dosis, via_administracion, fecha_inicio, fecha_fin, periodo_retirada_dias, fecha_fin_retirada, activo, motivo, veterinario, observaciones) FROM stdin;
\.


--
-- Data for Name: core_zones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_zones (id, nombre, codigo, descripcion, tipo, tiene_pantalla_tv, tiene_tablet, activa) FROM stdin;
\.


--
-- Data for Name: datos_metereologicos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.datos_metereologicos (id, fecha_hora, temperatura_media, temperatura_maxima, temperatura_minima, humedad_relativa, precipitacion, velocidad_viento, presion_atmosferica, estado_cielo, ubicacion, latitud, longitud, fuente) FROM stdin;
\.


--
-- Data for Name: empleados; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.empleados (id, nombre, apellidos, rol, zona_principal_id, cualificaciones, telefono, email, activo, fecha_alta, fecha_baja) FROM stdin;
098dda7f-1765-4280-9eb6-b9299a3d4688	Roberto	Castro	encargado	\N	{VMS,TMR}	\N	\N	t	2021-01-15	\N
0525a759-071e-456f-b665-d7cdbf945fd9	Laura	Fernández	auxiliar	\N	{TMR}	\N	\N	t	2021-01-15	\N
d2478d12-e98d-407b-95f0-84a12e7b3a28	Marcos	Vázquez	auxiliar	\N	{}	\N	\N	t	2021-01-15	\N
7def8ca6-c357-497c-b3bd-729866e76435	Elena	Méndez	veterinario	\N	{veterinaria}	\N	\N	t	2021-01-15	\N
a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	Sofía	Rodríguez	auxiliar	\N	{}	\N	\N	t	2021-01-15	\N
d3c0f3b4-0c93-4ff1-83d5-30ae502b0c9e	Diego	López	mecanico	\N	{mecanica}	\N	\N	t	2021-01-15	\N
\.


--
-- Data for Name: eventos_reproductivos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.eventos_reproductivos (id, animal_id, tipo, fecha, hora, empleado_id, detalles, notas, creado_en) FROM stdin;
\.


--
-- Data for Name: eventos_sanitarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.eventos_sanitarios (id, animal_id, tipo_patologia, fecha_inicio, fecha_fin, tratamiento, farmaco, dosis, via_administracion, periodo_retirada_hasta, resuelto, coste, veterinario_id, notas) FROM stdin;
6f455fd9-5ffc-47f1-a5b0-3295ffb3329c	ccc31b03-59ce-4c4b-aba9-0c81614e5088	mastitis	2026-05-22	2026-05-26	Protocolo estándar	\N	\N	\N	\N	t	\N	7def8ca6-c357-497c-b3bd-729866e76435	\N
d586a39a-801b-4146-afa5-862b310d15b1	6531f064-936a-48e6-ad33-e4207476ddfc	cojera	2026-04-23	2026-05-03	Protocolo estándar	\N	\N	\N	\N	t	\N	7def8ca6-c357-497c-b3bd-729866e76435	\N
30c38bef-90ed-42a7-962d-a918a44db52a	6585a2a9-6e35-4958-a40e-653ababa5d65	metritis	2026-05-26	2026-05-31	Protocolo estándar	\N	\N	\N	\N	t	\N	7def8ca6-c357-497c-b3bd-729866e76435	\N
08dc7f39-e2b8-48b1-a62a-bba950561294	8299c2db-ca85-4049-9e73-68b62e770b5e	cetosis	2026-04-28	2026-05-03	Protocolo estándar	\N	\N	\N	\N	t	\N	7def8ca6-c357-497c-b3bd-729866e76435	\N
38d225dd-81d2-4e22-b4a7-8adf19dfd68c	9a3e4fb5-7c02-4f83-8f6e-d432d3093862	otra	2026-05-22	2026-05-25	Protocolo estándar	\N	\N	\N	\N	t	\N	7def8ca6-c357-497c-b3bd-729866e76435	\N
\.


--
-- Data for Name: eventos_sanitarios_recria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.eventos_sanitarios_recria (id, animal_id, fecha, edad_dias, score_neumonia, score_diarrea, score_ombligo, peso_kg, tratamiento, observaciones, empleado_id) FROM stdin;
\.


--
-- Data for Name: genomica; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.genomica (id, animal_id, fecha_extraccion, tipo_muestra, laboratorio, referencia_lab, fecha_resultado, resultados_ref, notas) FROM stdin;
\.


--
-- Data for Name: incidencias; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.incidencias (id, tipo, subtipo, severidad, estado, titulo, descripcion, zona_id, maquinaria_id, animal_id, reportado_por, asignado_a, ts_apertura, ts_cierre, foto_url, acciones) FROM stdin;
44cc9d63-9514-4db2-b9f2-e05ec25cd46a	averia_maquinaria	\N	alta	abierta	Robot VMS 2 con error de vacío	Robot VMS 2 con error de vacío.	\N	\N	\N	a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	\N	2026-05-29 18:08:39.930765+00	\N	\N	[]
86a4d15b-557f-476c-a71c-1aa0956afc38	calidad_leche	\N	media	en_gestion	RCS elevado en tanque	RCS elevado en tanque.	\N	\N	\N	d2478d12-e98d-407b-95f0-84a12e7b3a28	\N	2026-05-27 21:08:39.932339+00	\N	\N	[]
437c100a-fb88-4b1f-9296-b11c3180f245	sanidad_animal	\N	alta	abierta	Cojera en revisión	Cojera en revisión.	\N	\N	\N	d2478d12-e98d-407b-95f0-84a12e7b3a28	\N	2026-05-28 18:08:39.93268+00	\N	\N	[]
34ae5888-e697-4876-b9e3-c368b7b8283b	infraestructura	\N	baja	resuelta	Bebedero atascado	Bebedero atascado.	\N	\N	\N	0525a759-071e-456f-b665-d7cdbf945fd9	\N	2026-06-01 23:08:39.932888+00	2026-06-02 05:08:39.932888+00	\N	[]
fe489ca2-c191-4d41-af0b-d0a4e97efa38	alimentacion	\N	media	abierta	Desviación en ración TMR	Desviación en ración TMR.	\N	\N	\N	a470c830-bad5-43c5-ae68-e0b8cd0f8dfa	\N	2026-05-27 20:08:39.933272+00	\N	\N	[]
ff49a0d0-8088-48d9-82d8-73659f4fb967	pedidos	\N	baja	cerrada	Retraso en entrega de pienso	Retraso en entrega de pienso.	\N	\N	\N	7def8ca6-c357-497c-b3bd-729866e76435	\N	2026-05-28 18:08:39.93345+00	2026-05-29 00:08:39.93345+00	\N	[]
\.


--
-- Data for Name: lactaciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lactaciones (id, animal_id, numero, fecha_parto, fecha_secado, produccion_total_kg, grasa_promedio, proteina_promedio, rcs_promedio, notas) FROM stdin;
32917532-7976-43a0-b734-5204939a2a7f	ccc31b03-59ce-4c4b-aba9-0c81614e5088	3	2026-01-01	\N	5390.60	3.978	3.520	216000	\N
1d352973-9c9e-4d1a-b55a-e75e43794fc2	6531f064-936a-48e6-ad33-e4207476ddfc	4	2025-09-22	\N	6757.30	3.984	3.515	296000	\N
63dc0bdf-07aa-4af6-9229-aa8e45956a0d	6585a2a9-6e35-4958-a40e-653ababa5d65	3	2026-03-13	\N	2910.60	3.700	3.336	214000	\N
86c110e3-f335-4ed8-9ae8-4e4e4f087e4e	8299c2db-ca85-4049-9e73-68b62e770b5e	3	2026-03-25	\N	2365.70	3.886	3.469	254000	\N
225aafe6-9ef4-4f2d-8284-023f98d4f0db	9a3e4fb5-7c02-4f83-8f6e-d432d3093862	3	2026-01-12	\N	5394.90	4.120	3.392	265000	\N
b9c5bb4d-6b8a-4973-8e7f-9c859b07afd2	3197b691-8153-4c3b-b59e-2bc44b2ef8f3	4	2026-04-15	\N	1912.00	3.892	3.519	257000	\N
8f6527e2-13e6-4486-9c88-e0ce7f4bafee	6ba424e3-ab02-4186-8e44-203f04a3732d	1	2025-12-23	\N	6405.10	3.658	3.423	125000	\N
f17a18d2-598f-4f79-b03f-30350b66e920	2bc3ec73-e0a8-442f-a62e-c8dfefb0f3a3	5	2025-08-17	\N	8924.50	4.137	3.263	147000	\N
33c97831-49cb-42e4-952e-9a930cf8fd8e	7510d06f-9604-4cfd-b92f-bb322435d97f	3	2025-12-07	\N	4804.00	4.010	3.568	247000	\N
c87b5f19-e70a-418f-bf81-6b49e77b0506	506e8f7c-aeaa-4d53-b862-e3a1d449756c	3	2026-02-24	\N	3509.70	3.609	3.414	180000	\N
f9219ba6-eaf0-4db3-bbf1-3b69daa0d837	8bd66d2e-2108-494a-a71d-32da9ad999a1	3	2026-01-08	\N	5099.60	3.683	3.486	246000	\N
eb4ca1cd-10fc-4b23-bfbd-ec48118db952	cbb5b74b-04aa-4a29-b76f-1d204f07e7e8	4	2026-03-12	\N	3052.50	4.150	3.528	216000	\N
df487ba2-ce04-41ce-9d59-60697236e1b1	eac5e48d-852b-488d-978d-d7cd273fa68a	5	2025-11-25	\N	7451.10	3.870	3.572	211000	\N
46e8d4a1-a5fc-4fbe-a3d2-10d5576b7b80	92213cac-37ee-494a-a71d-7f70570e12d6	1	2025-12-21	\N	4515.80	3.870	3.278	278000	\N
5008b93e-f75d-43c5-bf8d-58bcf52b8f51	eb5247b6-6796-4c63-ba5b-b656a79e8e5d	3	2025-09-12	\N	8090.30	3.746	3.247	240000	\N
9cb0e786-71f1-4df3-8ade-c444b17794cb	5485f060-45cd-4b94-a9d4-e73f51f03abc	4	2025-12-27	\N	5539.20	4.170	3.393	98000	\N
99f97420-055e-4fd3-b126-b52b0281568e	5a8f5a05-bcbe-4cb0-a1ec-7dd07a5f1c2a	1	2025-12-05	\N	5102.30	3.639	3.234	120000	\N
9ad0b9de-2a80-4391-b249-b3c1bbdbca5f	09022a53-d44a-4727-a0e6-50d6516a3931	5	2025-08-04	\N	11992.40	3.721	3.591	239000	\N
138b1dd0-4c0a-4355-9353-3d967778825d	ce063c55-dc12-465b-b8d4-d9d9f1597feb	5	2025-09-22	\N	6977.80	3.721	3.273	311000	\N
4c8bea50-8f7c-4dd8-b870-ad4a77dbb81e	9741bd61-4f0a-476a-9d02-4058c5ffb3cd	4	2026-01-02	\N	5004.30	3.988	3.206	243000	\N
f935b52a-d3e0-475b-b8a3-429918c24ce8	156682e8-c418-4dbe-ab7c-cae4a647ab74	5	2026-03-09	\N	3162.70	3.995	3.211	226000	\N
0020f27c-b9c4-4357-b34d-9ce9b188f9db	9c831d18-7636-4ba8-93f1-a83ac83b6974	3	2026-04-14	\N	1551.70	3.609	3.541	194000	\N
caa5f8ed-4a9e-4aba-a8b3-4775dfa7d685	f579430d-07da-401c-a6f4-77147e25706e	5	2026-01-16	\N	5222.60	3.812	3.462	291000	\N
21ff2a47-5638-4254-851d-737371fac2b5	b3a5730a-9db7-4d8b-8566-00f6754d4aa2	2	2025-12-16	\N	6521.90	4.108	3.559	227000	\N
fb411801-a1e6-48e7-9fbf-de3794e428a0	39a211d9-b089-40f9-8117-709e15e96105	3	2025-09-09	\N	8561.60	3.857	3.214	275000	\N
8ad1d377-7256-4801-9862-7ed4c79cd146	a360ded8-0ae1-41d4-b3f6-20cf7afda3d4	3	2025-09-03	\N	9687.60	4.035	3.556	229000	\N
ec382f24-af1b-4966-bae0-bb79cf8eccd7	3ed470f7-737e-4949-922b-3418fa9a45bd	4	2026-04-11	\N	1658.00	3.758	3.257	219000	\N
52e45995-77d3-4a37-b326-78e93d1540dc	c64d0fc4-0c5e-4605-a2d7-8eba4d29b047	2	2025-08-01	\N	8181.40	3.824	3.552	163000	\N
ac4fe526-d383-4269-826c-26e05e8de67d	4f2aaf22-fe56-40cb-aad8-aaa6d7e60044	4	2025-10-25	\N	6784.60	3.711	3.309	268000	\N
dcf5fb53-3bef-4c8b-9a61-02ad8904933c	9d2d6988-a97f-449c-95c4-67cf0dbe0d7c	2	2025-10-06	\N	6881.70	3.656	3.277	110000	\N
ccea2857-829c-4e10-80da-3c934dbb1b9c	836495b5-111e-4a1d-b27c-3bfb896ba378	1	2025-12-20	\N	5279.90	3.777	3.408	297000	\N
781d7846-272e-4903-978d-5f9175f5cde9	695c4157-8cfa-4464-8240-f0c0465c74af	1	2026-03-01	\N	2881.50	4.038	3.510	112000	\N
6e14c9e2-1eac-433e-b51e-3a7f8cee125f	f95dd3cd-b5c0-40b6-8288-a77bf3e8030a	3	2025-08-01	\N	10170.80	4.137	3.565	305000	\N
\.


--
-- Data for Name: lecturas_carro_mezclador; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturas_carro_mezclador (ts, mezcla_id, ingrediente, peso_objetivo, peso_real, operario_id) FROM stdin;
\.


--
-- Data for Name: lecturas_meteorologia; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturas_meteorologia (ts, estacion_id, temperatura_c, humedad_relativa, precipitacion_mm, viento_km_h, direccion_viento, radiacion_wm2) FROM stdin;
\.


--
-- Data for Name: lecturas_robot_ordeno; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturas_robot_ordeno (ts, robot_id, animal_id, lactacion_id, produccion_kg, conductividad, flujo_max, scc, duracion_min, intentos_fallidos, alerta_robot) FROM stdin;
\.


--
-- Data for Name: maquinaria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maquinaria (id, nombre, tipo, zona_id, marca, modelo, numero_serie, fecha_instalacion, activa, estado, notas) FROM stdin;
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pedidos (id, insumo, descripcion, cantidad, unidad, estado, solicitante_id, ts_solicitud, ts_aprobacion, ts_recepcion, proveedor, coste_estimado, coste_real, notas) FROM stdin;
3d1f7310-4668-4434-afa6-7be8e6bcb8d3	Pienso de arranque terneros	\N	500.00	kg	solicitado	098dda7f-1765-4280-9eb6-b9299a3d4688	2026-05-23 23:08:45.540649+00	\N	\N	Nutrega	\N	\N	\N
59982622-b443-4d3f-ad42-c794ec6c1b4a	Pajuelas de semen Frisona	\N	20.00	ud	aprobado	098dda7f-1765-4280-9eb6-b9299a3d4688	2026-05-26 23:08:45.541035+00	\N	\N	Xenética	\N	\N	\N
243e605b-873a-4590-9282-a5f15869de02	Selladores de pezones	\N	4.00	garrafa	en_transito	098dda7f-1765-4280-9eb6-b9299a3d4688	2026-05-28 23:08:45.541181+00	\N	\N	DeLaval	\N	\N	\N
7f9cba32-70fb-4683-83a8-6e9653b34ea6	Concentrado producción	\N	1000.00	kg	recibido	098dda7f-1765-4280-9eb6-b9299a3d4688	2026-05-25 23:08:45.541293+00	\N	\N	Nutrega	\N	\N	\N
4a56165e-4c98-4441-9f43-cd3f51345a2d	Guantes de palpación	\N	2.00	caja	solicitado	098dda7f-1765-4280-9eb6-b9299a3d4688	2026-05-30 23:08:45.54139+00	\N	\N	Agrocenter	\N	\N	\N
\.


--
-- Data for Name: resumenes_relevo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.resumenes_relevo (id, turno_saliente_id, turno_entrante_id, ts_generacion, incidencias_abiertas, tareas_pendientes, alertas_pendientes, notas_saliente, confirmado_por, ts_confirmacion) FROM stdin;
ecfb0bf1-02f2-4d75-8896-67769f70ea05	a22ebeca-a56f-41fe-bd1c-59dfa58c84ed	8daf2fde-c21f-45c7-9c1a-9404ee253fe2	2026-06-02 23:08:44.433969+00	[]	[]	[]	Robot VMS 2 en revisión. Vigilar RCS del tanque.	\N	\N
\.


--
-- Data for Name: tareas_catalogo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tareas_catalogo (id, codigo, nombre, descripcion, cualificacion_requerida, duracion_estimada_min, activa) FROM stdin;
\.


--
-- Data for Name: tareas_ejecuciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tareas_ejecuciones (id, catalogo_id, recurrente_id, empleado_id, zona_id, maquinaria_id, estado, ts_planificada, ts_inicio, ts_fin, notas, creado_en) FROM stdin;
\.


--
-- Data for Name: tareas_recurrentes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tareas_recurrentes (id, catalogo_id, zona_id, maquinaria_id, frecuencia_expr, descripcion_frecuencia, activa, fecha_inicio, fecha_fin, notas) FROM stdin;
\.


--
-- Data for Name: tratamientos_activos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tratamientos_activos (id, animal_id, evento_sanitario_id, farmaco, dosis, via_administracion, dias_tratamiento, fecha_inicio, fecha_fin_prevista, fecha_fin_real, activo, checkboxes, prescrito_por, notas) FROM stdin;
4704abc9-ed58-4180-9350-786f05319a36	ccc31b03-59ce-4c4b-aba9-0c81614e5088	\N	Mastijet	1 cánula/12h	intramamaria	4	2026-06-01	2026-06-05	\N	t	[]	7def8ca6-c357-497c-b3bd-729866e76435	\N
8a6d78e3-ff89-45dc-983d-7e2c6d2e48e2	6531f064-936a-48e6-ad33-e4207476ddfc	\N	Penethaject	20 ml/día	intramuscular	3	2026-06-02	2026-06-05	\N	t	[]	7def8ca6-c357-497c-b3bd-729866e76435	\N
b65da245-2296-4e22-9bd7-b8a7d6241ff9	6585a2a9-6e35-4958-a40e-653ababa5d65	\N	Metacam	15 ml/día	subcutánea	2	2026-06-02	2026-06-04	\N	t	[]	7def8ca6-c357-497c-b3bd-729866e76435	\N
\.


--
-- Data for Name: turnos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.turnos (id, fecha, tipo_turno, hora_inicio, hora_fin, notas) FROM stdin;
a22ebeca-a56f-41fe-bd1c-59dfa58c84ed	2026-06-02	manana	06:00:00	14:00:00	\N
8daf2fde-c21f-45c7-9c1a-9404ee253fe2	2026-06-02	tarde	14:00:00	22:00:00	\N
6ba00d74-01c1-4ebb-a04d-26e1445df35b	2026-06-03	manana	06:00:00	14:00:00	\N
ab7683f2-ad68-47d2-a104-fb769efe5328	2026-06-03	tarde	14:00:00	22:00:00	\N
c6c9e0ee-bc95-4808-8142-83f878897ca7	2026-06-04	manana	06:00:00	14:00:00	\N
ce83d9a6-90b0-4c2d-9dfd-6b890eb82443	2026-06-04	tarde	14:00:00	22:00:00	\N
eac87073-c293-4b6f-b8f3-8fc809d6768c	2026-06-05	manana	06:00:00	14:00:00	\N
58d475b3-5b87-42c2-9c16-ed00ac3f2e50	2026-06-05	tarde	14:00:00	22:00:00	\N
48823616-3534-43a6-abdc-e87c67ff1c48	2026-06-06	manana	06:00:00	14:00:00	\N
bc11a5ea-e86e-4170-86ac-b5451347e923	2026-06-06	tarde	14:00:00	22:00:00	\N
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuarios (id, username, email, hashed_password, role, activo, debe_cambiar_contrasena, fecha_creacion) FROM stdin;
90efd8fb-337c-41b4-b4fd-3c94512a17db	dr.mendez	dr.mendez@tools4milk.local	$2b$12$g5SXP6PnL2CBlbLtX.uM2eOxg2gmlTwNdVDB3GTvb1OGQIDrRVCHu	veterinario	t	f	2026-06-02 19:26:19.766713+00
0ae364f7-5663-4db8-98eb-cb12799c86e2	admin	admin@tools4milk.local	$2b$12$6xrF4o6mBz08Zq3fML4OH.CnsRtSngq1YIi9x.F9e4LuIWf1sw1h6	admin	t	f	2026-06-02 19:26:18.858418+00
53017704-20a8-4709-85f0-e37c03fe8abb	roberto.castro	roberto.castro@tools4milk.local	$2b$12$iwa1d2BxQdyAqcN6BzCBV.5S/AaU2xeA839DvAmf1L3FWKUN4Ymxi	admin	t	f	2026-06-02 19:26:19.085552+00
6d6fa008-d2e8-4915-b8b1-9da5cc34809c	operario.zona	operario.zona@tools4milk.local	$2b$12$Kp9S0yaA/YCG9EgdfBQg3.qpRO./KoVmjs9V.n3EtIdnMnXwk.d2C	operario	t	f	2026-06-02 19:26:19.312266+00
7a1ab8ff-55bf-4c54-a8fa-172863b509ad	laura.fernandez	laura.fernandez@tools4milk.local	$2b$12$fKR82id/KIdSYoZJSSisGu6h9o7oNEt5ElPGzCWd2E02lADKezAe2	alimentacion	t	f	2026-06-02 19:26:19.537803+00
\.


--
-- Data for Name: zonas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zonas (id, nombre, codigo, descripcion, tiene_pantalla_tv, tiene_tablet) FROM stdin;
\.


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 1, false);


--
-- Name: datos_metereologicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datos_metereologicos_id_seq', 1, false);


--
-- Name: alertas alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (id);


--
-- Name: alertas_umbrales alertas_umbrales_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas_umbrales
    ADD CONSTRAINT alertas_umbrales_codigo_key UNIQUE (codigo);


--
-- Name: alertas_umbrales alertas_umbrales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas_umbrales
    ADD CONSTRAINT alertas_umbrales_pkey PRIMARY KEY (id);


--
-- Name: animales animales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animales
    ADD CONSTRAINT animales_pkey PRIMARY KEY (id);


--
-- Name: asignaciones_turno asignaciones_turno_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_pkey PRIMARY KEY (id);


--
-- Name: asignaciones_turno asignaciones_turno_turno_id_empleado_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_turno_id_empleado_id_key UNIQUE (turno_id, empleado_id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: boxes_recria boxes_recria_box_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes_recria
    ADD CONSTRAINT boxes_recria_box_numero_key UNIQUE (box_numero);


--
-- Name: boxes_recria boxes_recria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes_recria
    ADD CONSTRAINT boxes_recria_pkey PRIMARY KEY (id);


--
-- Name: core_alerts core_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_alerts
    ADD CONSTRAINT core_alerts_pkey PRIMARY KEY (id);


--
-- Name: core_animals core_animals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_animals
    ADD CONSTRAINT core_animals_pkey PRIMARY KEY (id);


--
-- Name: core_employees core_employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_employees
    ADD CONSTRAINT core_employees_pkey PRIMARY KEY (id);


--
-- Name: core_incidents core_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_incidents
    ADD CONSTRAINT core_incidents_pkey PRIMARY KEY (id);


--
-- Name: core_lactations core_lactations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_lactations
    ADD CONSTRAINT core_lactations_pkey PRIMARY KEY (id);


--
-- Name: core_machinery core_machinery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_machinery
    ADD CONSTRAINT core_machinery_pkey PRIMARY KEY (id);


--
-- Name: core_tasks core_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_tasks
    ADD CONSTRAINT core_tasks_pkey PRIMARY KEY (id);


--
-- Name: core_treatments core_treatments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_treatments
    ADD CONSTRAINT core_treatments_pkey PRIMARY KEY (id);


--
-- Name: core_zones core_zones_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_zones
    ADD CONSTRAINT core_zones_codigo_key UNIQUE (codigo);


--
-- Name: core_zones core_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_zones
    ADD CONSTRAINT core_zones_pkey PRIMARY KEY (id);


--
-- Name: datos_metereologicos datos_metereologicos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_metereologicos
    ADD CONSTRAINT datos_metereologicos_pkey PRIMARY KEY (id);


--
-- Name: empleados empleados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_pkey PRIMARY KEY (id);


--
-- Name: eventos_reproductivos eventos_reproductivos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_reproductivos
    ADD CONSTRAINT eventos_reproductivos_pkey PRIMARY KEY (id);


--
-- Name: eventos_sanitarios eventos_sanitarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_sanitarios
    ADD CONSTRAINT eventos_sanitarios_pkey PRIMARY KEY (id);


--
-- Name: eventos_sanitarios_recria eventos_sanitarios_recria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_sanitarios_recria
    ADD CONSTRAINT eventos_sanitarios_recria_pkey PRIMARY KEY (id);


--
-- Name: genomica genomica_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genomica
    ADD CONSTRAINT genomica_pkey PRIMARY KEY (id);


--
-- Name: incidencias incidencias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_pkey PRIMARY KEY (id);


--
-- Name: lactaciones lactaciones_animal_id_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lactaciones
    ADD CONSTRAINT lactaciones_animal_id_numero_key UNIQUE (animal_id, numero);


--
-- Name: lactaciones lactaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lactaciones
    ADD CONSTRAINT lactaciones_pkey PRIMARY KEY (id);


--
-- Name: lecturas_carro_mezclador lecturas_carro_mezclador_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturas_carro_mezclador
    ADD CONSTRAINT lecturas_carro_mezclador_pkey PRIMARY KEY (ts, mezcla_id, ingrediente);


--
-- Name: lecturas_meteorologia lecturas_meteorologia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturas_meteorologia
    ADD CONSTRAINT lecturas_meteorologia_pkey PRIMARY KEY (ts, estacion_id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_pkey PRIMARY KEY (ts, robot_id);


--
-- Name: maquinaria maquinaria_numero_serie_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maquinaria
    ADD CONSTRAINT maquinaria_numero_serie_key UNIQUE (numero_serie);


--
-- Name: maquinaria maquinaria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maquinaria
    ADD CONSTRAINT maquinaria_pkey PRIMARY KEY (id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- Name: resumenes_relevo resumenes_relevo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_pkey PRIMARY KEY (id);


--
-- Name: tareas_catalogo tareas_catalogo_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_catalogo
    ADD CONSTRAINT tareas_catalogo_codigo_key UNIQUE (codigo);


--
-- Name: tareas_catalogo tareas_catalogo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_catalogo
    ADD CONSTRAINT tareas_catalogo_pkey PRIMARY KEY (id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_pkey PRIMARY KEY (id);


--
-- Name: tareas_recurrentes tareas_recurrentes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_pkey PRIMARY KEY (id);


--
-- Name: tratamientos_activos tratamientos_activos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_pkey PRIMARY KEY (id);


--
-- Name: turnos turnos_fecha_tipo_turno_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_fecha_tipo_turno_key UNIQUE (fecha, tipo_turno);


--
-- Name: turnos turnos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: zonas zonas_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_codigo_key UNIQUE (codigo);


--
-- Name: zonas zonas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_nombre_key UNIQUE (nombre);


--
-- Name: zonas zonas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_pkey PRIMARY KEY (id);


--
-- Name: ix_alertas_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_alertas_animal_id ON public.alertas USING btree (animal_id);


--
-- Name: ix_animales_crotal_oficial; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_animales_crotal_oficial ON public.animales USING btree (crotal_oficial);


--
-- Name: ix_animales_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animales_estado ON public.animales USING btree (estado);


--
-- Name: ix_animales_estado_reproductivo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animales_estado_reproductivo ON public.animales USING btree (estado_reproductivo);


--
-- Name: ix_animales_zona_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animales_zona_id ON public.animales USING btree (zona_id);


--
-- Name: ix_audit_log_registro_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_log_registro_id ON public.audit_log USING btree (registro_id);


--
-- Name: ix_boxes_recria_ternero_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_boxes_recria_ternero_id ON public.boxes_recria USING btree (ternero_id);


--
-- Name: ix_core_alerts_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_alerts_animal_id ON public.core_alerts USING btree (animal_id);


--
-- Name: ix_core_alerts_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_alerts_estado ON public.core_alerts USING btree (estado);


--
-- Name: ix_core_alerts_severidad; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_alerts_severidad ON public.core_alerts USING btree (severidad);


--
-- Name: ix_core_animals_crotal_oficial; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_core_animals_crotal_oficial ON public.core_animals USING btree (crotal_oficial);


--
-- Name: ix_core_animals_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_animals_estado ON public.core_animals USING btree (estado);


--
-- Name: ix_core_employees_activo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_employees_activo ON public.core_employees USING btree (activo);


--
-- Name: ix_core_incidents_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_incidents_animal_id ON public.core_incidents USING btree (animal_id);


--
-- Name: ix_core_incidents_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_incidents_estado ON public.core_incidents USING btree (estado);


--
-- Name: ix_core_incidents_prioridad; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_incidents_prioridad ON public.core_incidents USING btree (prioridad);


--
-- Name: ix_core_incidents_zona_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_incidents_zona_id ON public.core_incidents USING btree (zona_id);


--
-- Name: ix_core_lactations_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_lactations_animal_id ON public.core_lactations USING btree (animal_id);


--
-- Name: ix_core_machinery_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_machinery_estado ON public.core_machinery USING btree (estado);


--
-- Name: ix_core_tasks_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_tasks_estado ON public.core_tasks USING btree (estado);


--
-- Name: ix_core_tasks_zona_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_tasks_zona_id ON public.core_tasks USING btree (zona_id);


--
-- Name: ix_core_treatments_activo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_treatments_activo ON public.core_treatments USING btree (activo);


--
-- Name: ix_core_treatments_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_core_treatments_animal_id ON public.core_treatments USING btree (animal_id);


--
-- Name: ix_eventos_reproductivos_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_eventos_reproductivos_animal_id ON public.eventos_reproductivos USING btree (animal_id);


--
-- Name: ix_eventos_sanitarios_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_eventos_sanitarios_animal_id ON public.eventos_sanitarios USING btree (animal_id);


--
-- Name: ix_eventos_sanitarios_recria_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_eventos_sanitarios_recria_animal_id ON public.eventos_sanitarios_recria USING btree (animal_id);


--
-- Name: ix_genomica_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_genomica_animal_id ON public.genomica USING btree (animal_id);


--
-- Name: ix_incidencias_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incidencias_animal_id ON public.incidencias USING btree (animal_id);


--
-- Name: ix_incidencias_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incidencias_estado ON public.incidencias USING btree (estado);


--
-- Name: ix_incidencias_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incidencias_tipo ON public.incidencias USING btree (tipo);


--
-- Name: ix_incidencias_zona_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incidencias_zona_id ON public.incidencias USING btree (zona_id);


--
-- Name: ix_lactaciones_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_lactaciones_animal_id ON public.lactaciones USING btree (animal_id);


--
-- Name: ix_lactaciones_fecha_parto; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_lactaciones_fecha_parto ON public.lactaciones USING btree (fecha_parto);


--
-- Name: ix_pedidos_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pedidos_estado ON public.pedidos USING btree (estado);


--
-- Name: ix_tareas_ejecuciones_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tareas_ejecuciones_estado ON public.tareas_ejecuciones USING btree (estado);


--
-- Name: ix_tareas_ejecuciones_ts_planificada; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tareas_ejecuciones_ts_planificada ON public.tareas_ejecuciones USING btree (ts_planificada);


--
-- Name: ix_tareas_ejecuciones_zona_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tareas_ejecuciones_zona_id ON public.tareas_ejecuciones USING btree (zona_id);


--
-- Name: ix_tratamientos_activos_activo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tratamientos_activos_activo ON public.tratamientos_activos USING btree (activo);


--
-- Name: ix_tratamientos_activos_animal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tratamientos_activos_animal_id ON public.tratamientos_activos USING btree (animal_id);


--
-- Name: ix_usuarios_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_usuarios_email ON public.usuarios USING btree (email);


--
-- Name: ix_usuarios_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usuarios_role ON public.usuarios USING btree (role);


--
-- Name: ix_usuarios_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_usuarios_username ON public.usuarios USING btree (username);


--
-- Name: alertas alertas_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: alertas alertas_resuelta_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_resuelta_por_fkey FOREIGN KEY (resuelta_por) REFERENCES public.empleados(id);


--
-- Name: alertas alertas_umbral_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_umbral_id_fkey FOREIGN KEY (umbral_id) REFERENCES public.alertas_umbrales(id);


--
-- Name: alertas alertas_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: animales animales_madre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animales
    ADD CONSTRAINT animales_madre_id_fkey FOREIGN KEY (madre_id) REFERENCES public.animales(id);


--
-- Name: animales animales_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animales
    ADD CONSTRAINT animales_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id) ON DELETE SET NULL;


--
-- Name: asignaciones_turno asignaciones_turno_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: asignaciones_turno asignaciones_turno_turno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_turno_id_fkey FOREIGN KEY (turno_id) REFERENCES public.turnos(id) ON DELETE CASCADE;


--
-- Name: asignaciones_turno asignaciones_turno_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: boxes_recria boxes_recria_ternero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes_recria
    ADD CONSTRAINT boxes_recria_ternero_id_fkey FOREIGN KEY (ternero_id) REFERENCES public.animales(id);


--
-- Name: empleados empleados_zona_principal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_zona_principal_id_fkey FOREIGN KEY (zona_principal_id) REFERENCES public.zonas(id) ON DELETE SET NULL;


--
-- Name: eventos_reproductivos eventos_reproductivos_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_reproductivos
    ADD CONSTRAINT eventos_reproductivos_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: eventos_reproductivos eventos_reproductivos_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_reproductivos
    ADD CONSTRAINT eventos_reproductivos_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: eventos_sanitarios eventos_sanitarios_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_sanitarios
    ADD CONSTRAINT eventos_sanitarios_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: eventos_sanitarios_recria eventos_sanitarios_recria_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_sanitarios_recria
    ADD CONSTRAINT eventos_sanitarios_recria_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: eventos_sanitarios_recria eventos_sanitarios_recria_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_sanitarios_recria
    ADD CONSTRAINT eventos_sanitarios_recria_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: eventos_sanitarios eventos_sanitarios_veterinario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_sanitarios
    ADD CONSTRAINT eventos_sanitarios_veterinario_id_fkey FOREIGN KEY (veterinario_id) REFERENCES public.empleados(id);


--
-- Name: genomica genomica_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genomica
    ADD CONSTRAINT genomica_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: incidencias incidencias_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: incidencias incidencias_asignado_a_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_asignado_a_fkey FOREIGN KEY (asignado_a) REFERENCES public.empleados(id);


--
-- Name: incidencias incidencias_maquinaria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_maquinaria_id_fkey FOREIGN KEY (maquinaria_id) REFERENCES public.maquinaria(id);


--
-- Name: incidencias incidencias_reportado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_reportado_por_fkey FOREIGN KEY (reportado_por) REFERENCES public.empleados(id);


--
-- Name: incidencias incidencias_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: lactaciones lactaciones_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lactaciones
    ADD CONSTRAINT lactaciones_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: lecturas_carro_mezclador lecturas_carro_mezclador_operario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturas_carro_mezclador
    ADD CONSTRAINT lecturas_carro_mezclador_operario_id_fkey FOREIGN KEY (operario_id) REFERENCES public.empleados(id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_lactacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_lactacion_id_fkey FOREIGN KEY (lactacion_id) REFERENCES public.lactaciones(id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_robot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_robot_id_fkey FOREIGN KEY (robot_id) REFERENCES public.maquinaria(id);


--
-- Name: maquinaria maquinaria_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maquinaria
    ADD CONSTRAINT maquinaria_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id) ON DELETE SET NULL;


--
-- Name: pedidos pedidos_solicitante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_solicitante_id_fkey FOREIGN KEY (solicitante_id) REFERENCES public.empleados(id);


--
-- Name: resumenes_relevo resumenes_relevo_confirmado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_confirmado_por_fkey FOREIGN KEY (confirmado_por) REFERENCES public.empleados(id);


--
-- Name: resumenes_relevo resumenes_relevo_turno_entrante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_turno_entrante_id_fkey FOREIGN KEY (turno_entrante_id) REFERENCES public.turnos(id);


--
-- Name: resumenes_relevo resumenes_relevo_turno_saliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_turno_saliente_id_fkey FOREIGN KEY (turno_saliente_id) REFERENCES public.turnos(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_catalogo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_catalogo_id_fkey FOREIGN KEY (catalogo_id) REFERENCES public.tareas_catalogo(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_maquinaria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_maquinaria_id_fkey FOREIGN KEY (maquinaria_id) REFERENCES public.maquinaria(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_recurrente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_recurrente_id_fkey FOREIGN KEY (recurrente_id) REFERENCES public.tareas_recurrentes(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: tareas_recurrentes tareas_recurrentes_catalogo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_catalogo_id_fkey FOREIGN KEY (catalogo_id) REFERENCES public.tareas_catalogo(id);


--
-- Name: tareas_recurrentes tareas_recurrentes_maquinaria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_maquinaria_id_fkey FOREIGN KEY (maquinaria_id) REFERENCES public.maquinaria(id);


--
-- Name: tareas_recurrentes tareas_recurrentes_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: tratamientos_activos tratamientos_activos_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: tratamientos_activos tratamientos_activos_evento_sanitario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_evento_sanitario_id_fkey FOREIGN KEY (evento_sanitario_id) REFERENCES public.eventos_sanitarios(id);


--
-- Name: tratamientos_activos tratamientos_activos_prescrito_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_prescrito_por_fkey FOREIGN KEY (prescrito_por) REFERENCES public.empleados(id);


--
-- PostgreSQL database dump complete
--

\unrestrict wUhBdoDLRfdOMMR9pKR4GvZZcoozNJq6lqolT8KCV9bFPmgKT6l426UknihnlTx

