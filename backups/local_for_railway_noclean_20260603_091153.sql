--
-- PostgreSQL database dump
--

\restrict COAxfURnEETjXzAAkul4ya9Fk0ZOU3oF7DtjKhQ8C9qS3kkDivH9sql9BNf5vkE

-- Dumped from database version 15.18
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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


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
-- Name: estado_incidencia; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_incidencia AS ENUM (
    'abierta',
    'en_gestion',
    'resuelta',
    'cerrada'
);


--
-- Name: estado_pedido; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_pedido AS ENUM (
    'solicitado',
    'aprobado',
    'en_transito',
    'recibido',
    'cancelado'
);


--
-- Name: estado_reproductivo; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_reproductivo AS ENUM (
    'vacia',
    'en_celo',
    'inseminada',
    'confirmada_gestante',
    'parto_reciente'
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
-- Name: nivel_severidad; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.nivel_severidad AS ENUM (
    'baja',
    'media',
    'alta'
);


--
-- Name: rol_empleado; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rol_empleado AS ENUM (
    'encargado',
    'auxiliar',
    'veterinario',
    'mecanico'
);


--
-- Name: sexo_animal; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sexo_animal AS ENUM (
    'hembra',
    'macho'
);


--
-- Name: tipo_evento_repro; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_evento_repro AS ENUM (
    'celo',
    'inseminacion',
    'diagnostico_gestacion',
    'aborto',
    'parto',
    'secado'
);


--
-- Name: tipo_incidencia; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_incidencia AS ENUM (
    'averia_maquinaria',
    'infraestructura',
    'sanidad_animal',
    'calidad_leche',
    'alimentacion',
    'pedidos'
);


--
-- Name: tipo_maquinaria; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_maquinaria AS ENUM (
    'robot_ordeno',
    'carro_mezclador',
    'amamantadora',
    'bomba',
    'otro'
);


--
-- Name: tipo_patologia; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_patologia AS ENUM (
    'mastitis',
    'cojera',
    'metritis',
    'cetosis',
    'desplazamiento_abomaso',
    'neumonia',
    'diarrea',
    'otra'
);


--
-- Name: tipo_turno; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_turno AS ENUM (
    'manana',
    'tarde'
);


--
-- Name: fn_audit_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_audit_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$ DECLARE v_registro_id UUID; v_datos_ant JSONB; v_datos_new JSONB; v_hash_input TEXT; BEGIN IF TG_OP = 'INSERT' THEN v_registro_id := NEW.id; v_datos_ant := NULL; v_datos_new := to_jsonb(NEW); ELSIF TG_OP = 'UPDATE' THEN v_registro_id := NEW.id; v_datos_ant := to_jsonb(OLD); v_datos_new := to_jsonb(NEW); ELSIF TG_OP = 'DELETE' THEN v_registro_id := OLD.id; v_datos_ant := to_jsonb(OLD); v_datos_new := NULL; END IF; v_hash_input := TG_TABLE_NAME || TG_OP || v_registro_id::TEXT || COALESCE(v_datos_new::TEXT, v_datos_ant::TEXT); INSERT INTO audit_log (tabla_afectada, operacion, registro_id, datos_anteriores, datos_nuevos, hash_sha256) VALUES (TG_TABLE_NAME, TG_OP, v_registro_id, v_datos_ant, v_datos_new, encode(digest(v_hash_input, 'sha256'), 'hex')); RETURN COALESCE(NEW, OLD); END; $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alertas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    umbral_id uuid,
    nivel public.nivel_alerta NOT NULL,
    titulo character varying(200) NOT NULL,
    mensaje text,
    origen_tabla character varying(100),
    origen_id uuid,
    animal_id uuid,
    zona_id uuid,
    push_whatsapp boolean DEFAULT false NOT NULL,
    pantalla_tv boolean DEFAULT true NOT NULL,
    tablet boolean DEFAULT true NOT NULL,
    activa boolean DEFAULT true NOT NULL,
    ts_generacion timestamp with time zone DEFAULT now() NOT NULL,
    ts_resolucion timestamp with time zone,
    resuelta_por uuid
);


--
-- Name: alertas_umbrales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertas_umbrales (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    codigo character varying(80) NOT NULL,
    descripcion text NOT NULL,
    metrica character varying(100) NOT NULL,
    operador character varying(10) NOT NULL,
    valor_umbral numeric(12,4) NOT NULL,
    unidad character varying(30),
    nivel_alerta public.nivel_alerta NOT NULL,
    push_whatsapp boolean DEFAULT false NOT NULL,
    pantalla_tv boolean DEFAULT true NOT NULL,
    tablet boolean NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    notas text,
    CONSTRAINT alertas_umbrales_operador_check CHECK (((operador)::text = ANY ((ARRAY['>'::character varying, '<'::character varying, '>='::character varying, '<='::character varying, '='::character varying])::text[])))
);


--
-- Name: animales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animales (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    crotal_oficial character varying(20) NOT NULL,
    nombre character varying(80),
    sexo public.sexo_animal DEFAULT 'hembra'::public.sexo_animal NOT NULL,
    fecha_nacimiento date NOT NULL,
    raza character varying(80),
    estado public.estado_animal DEFAULT 'recria'::public.estado_animal NOT NULL,
    estado_reproductivo public.estado_reproductivo,
    madre_id uuid,
    fecha_entrada date DEFAULT CURRENT_DATE NOT NULL,
    fecha_baja date,
    motivo_baja character varying(200),
    notas text,
    zona_id uuid,
    CONSTRAINT chk_fechas_animal CHECK (((fecha_baja IS NULL) OR (fecha_baja >= fecha_nacimiento)))
);


--
-- Name: asignaciones_turno; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asignaciones_turno (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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
    ts timestamp with time zone DEFAULT now() NOT NULL,
    tabla_afectada character varying(100) NOT NULL,
    operacion character(6) NOT NULL,
    registro_id uuid NOT NULL,
    datos_anteriores jsonb,
    datos_nuevos jsonb,
    usuario_bd character varying(100) DEFAULT CURRENT_USER NOT NULL,
    hash_sha256 text NOT NULL,
    CONSTRAINT audit_log_operacion_check CHECK ((operacion = ANY (ARRAY['INSERT'::bpchar, 'UPDATE'::bpchar, 'DELETE'::bpchar])))
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
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    box_numero smallint NOT NULL,
    ternero_id uuid,
    fecha_entrada date,
    fecha_salida date,
    activo boolean DEFAULT true NOT NULL,
    alertas_box jsonb DEFAULT '[]'::jsonb NOT NULL,
    notas text,
    CONSTRAINT boxes_recria_box_numero_check CHECK ((box_numero > 0)),
    CONSTRAINT chk_fechas_box CHECK (((fecha_salida IS NULL) OR (fecha_salida >= fecha_entrada)))
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
    estado character varying(40) DEFAULT 'pendiente'::character varying NOT NULL,
    confianza_prediccion real,
    requiere_escalacion boolean DEFAULT false NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL,
    fecha_revision timestamp without time zone,
    revisada boolean DEFAULT false NOT NULL,
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
    activo boolean DEFAULT true NOT NULL
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
    estado character varying(40) DEFAULT 'abierta'::character varying NOT NULL,
    fecha_creacion timestamp without time zone NOT NULL,
    fecha_resolucion timestamp without time zone,
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
    produccion_promedio real,
    produccion_total real,
    grasa_promedio real,
    proteina_promedio real,
    rcs_promedio real,
    activa boolean DEFAULT true NOT NULL
);


--
-- Name: core_machinery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.core_machinery (
    id character varying(80) NOT NULL,
    nombre character varying(160) NOT NULL,
    tipo character varying(80) NOT NULL,
    zona_id character varying(80),
    estado character varying(80) DEFAULT 'operativa'::character varying NOT NULL,
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
    fecha_programada timestamp without time zone NOT NULL,
    fecha_ejecucion timestamp without time zone,
    estado character varying(40) NOT NULL,
    ejecutado_por character varying(120),
    tiempo_ejecucion_minutos character varying(40),
    resultado character varying(120),
    observaciones text,
    problemas_encontrados text,
    acciones_correctivas text,
    checklist_completado character varying(10) DEFAULT 'false'::character varying NOT NULL,
    checklist_datos text,
    es_urgente boolean DEFAULT false NOT NULL,
    motivo_retraso text,
    requiere_seguimiento boolean DEFAULT false NOT NULL,
    fecha_seguimiento timestamp without time zone
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
    activo boolean DEFAULT true NOT NULL,
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
    tiene_pantalla_tv boolean DEFAULT true NOT NULL,
    tiene_tablet boolean DEFAULT true NOT NULL,
    activa boolean DEFAULT true NOT NULL
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
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nombre character varying(100) NOT NULL,
    apellidos character varying(150) NOT NULL,
    rol public.rol_empleado NOT NULL,
    cualificaciones text[] DEFAULT '{}'::text[],
    telefono character varying(20),
    email character varying(150),
    activo boolean DEFAULT true NOT NULL,
    fecha_alta date DEFAULT CURRENT_DATE NOT NULL,
    fecha_baja date,
    zona_principal_id uuid,
    CONSTRAINT chk_fechas_empleado CHECK (((fecha_baja IS NULL) OR (fecha_baja >= fecha_alta)))
);


--
-- Name: TABLE empleados; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.empleados IS 'Registro maestro de trabajadores.';


--
-- Name: COLUMN empleados.cualificaciones; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.empleados.cualificaciones IS 'Array de cualificaciones: VMS, TMR, veterinaria…';


--
-- Name: eventos_reproductivos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_reproductivos (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    animal_id uuid NOT NULL,
    tipo public.tipo_evento_repro NOT NULL,
    fecha date NOT NULL,
    hora time without time zone,
    empleado_id uuid,
    detalles jsonb DEFAULT '{}'::jsonb,
    notas text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: eventos_sanitarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_sanitarios (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    animal_id uuid NOT NULL,
    tipo_patologia public.tipo_patologia NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    tratamiento text,
    farmaco character varying(200),
    dosis character varying(100),
    via_administracion character varying(80),
    periodo_retirada_hasta date,
    resuelto boolean DEFAULT false NOT NULL,
    coste numeric(8,2),
    veterinario_id uuid,
    notas text,
    CONSTRAINT chk_fechas_sanitario CHECK (((fecha_fin IS NULL) OR (fecha_fin >= fecha_inicio)))
);


--
-- Name: eventos_sanitarios_recria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_sanitarios_recria (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    animal_id uuid NOT NULL,
    fecha date NOT NULL,
    edad_dias integer,
    score_neumonia smallint DEFAULT 0 NOT NULL,
    score_diarrea smallint DEFAULT 0 NOT NULL,
    score_ombligo smallint DEFAULT 0 NOT NULL,
    peso_kg numeric(5,1),
    tratamiento text,
    observaciones text,
    empleado_id uuid,
    CONSTRAINT eventos_sanitarios_recria_score_diarrea_check CHECK (((score_diarrea >= 0) AND (score_diarrea <= 3))),
    CONSTRAINT eventos_sanitarios_recria_score_neumonia_check CHECK (((score_neumonia >= 0) AND (score_neumonia <= 3))),
    CONSTRAINT eventos_sanitarios_recria_score_ombligo_check CHECK (((score_ombligo >= 0) AND (score_ombligo <= 3)))
);


--
-- Name: genomica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genomica (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tipo public.tipo_incidencia NOT NULL,
    subtipo character varying(80),
    severidad public.nivel_severidad DEFAULT 'media'::public.nivel_severidad NOT NULL,
    estado public.estado_incidencia DEFAULT 'abierta'::public.estado_incidencia NOT NULL,
    titulo character varying(200) NOT NULL,
    descripcion text,
    zona_id uuid,
    maquinaria_id uuid,
    animal_id uuid,
    reportado_por uuid,
    asignado_a uuid,
    ts_apertura timestamp with time zone DEFAULT now() NOT NULL,
    ts_cierre timestamp with time zone,
    foto_url text,
    acciones jsonb DEFAULT '[]'::jsonb NOT NULL,
    CONSTRAINT chk_cierre_incidencia CHECK (((ts_cierre IS NULL) OR (ts_cierre >= ts_apertura)))
);


--
-- Name: lactaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lactaciones (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    animal_id uuid NOT NULL,
    numero smallint NOT NULL,
    fecha_parto date NOT NULL,
    fecha_secado date,
    produccion_total_kg numeric(8,2),
    notas text,
    grasa_promedio numeric(5,3),
    proteina_promedio numeric(5,3),
    rcs_promedio integer,
    CONSTRAINT chk_fechas_lactacion CHECK (((fecha_secado IS NULL) OR (fecha_secado > fecha_parto))),
    CONSTRAINT lactaciones_numero_check CHECK ((numero >= 1))
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
    desviacion_pct numeric(5,2) GENERATED ALWAYS AS (round((((peso_real - peso_objetivo) / NULLIF(peso_objetivo, (0)::numeric)) * (100)::numeric), 2)) STORED,
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
    radiacion_wm2 numeric(6,1),
    indice_thermo_humedad numeric(5,2) GENERATED ALWAYS AS (round((((0.8 * temperatura_c) + ((humedad_relativa / 100.0) * (temperatura_c - 14.4))) + 46.4), 2)) STORED,
    prob_precipitacion_pct numeric(5,1)
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
    intentos_fallidos smallint DEFAULT 0,
    alerta_robot boolean DEFAULT false
);


--
-- Name: maquinaria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maquinaria (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nombre character varying(100) NOT NULL,
    tipo public.tipo_maquinaria NOT NULL,
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
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    insumo character varying(200) NOT NULL,
    descripcion text,
    cantidad numeric(10,2) NOT NULL,
    unidad character varying(30),
    estado public.estado_pedido DEFAULT 'solicitado'::public.estado_pedido NOT NULL,
    solicitante_id uuid,
    ts_solicitud timestamp with time zone DEFAULT now() NOT NULL,
    ts_aprobacion timestamp with time zone,
    ts_recepcion timestamp with time zone,
    proveedor character varying(150),
    coste_estimado numeric(10,2),
    coste_real numeric(10,2),
    notas text,
    CONSTRAINT pedidos_cantidad_check CHECK ((cantidad > (0)::numeric))
);


--
-- Name: resumenes_relevo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resumenes_relevo (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    turno_saliente_id uuid NOT NULL,
    turno_entrante_id uuid NOT NULL,
    ts_generacion timestamp with time zone DEFAULT now() NOT NULL,
    incidencias_abiertas jsonb DEFAULT '[]'::jsonb NOT NULL,
    tareas_pendientes jsonb DEFAULT '[]'::jsonb NOT NULL,
    alertas_pendientes jsonb DEFAULT '[]'::jsonb NOT NULL,
    notas_saliente text,
    confirmado_por uuid,
    ts_confirmacion timestamp with time zone,
    CONSTRAINT chk_turnos_distintos CHECK ((turno_saliente_id <> turno_entrante_id))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL,
    applied_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tareas_catalogo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tareas_catalogo (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    catalogo_id uuid NOT NULL,
    recurrente_id uuid,
    empleado_id uuid,
    zona_id uuid,
    maquinaria_id uuid,
    estado public.estado_tarea DEFAULT 'pendiente'::public.estado_tarea NOT NULL,
    ts_planificada timestamp with time zone NOT NULL,
    ts_inicio timestamp with time zone,
    ts_fin timestamp with time zone,
    notas text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_ts_ejecucion CHECK (((ts_fin IS NULL) OR (ts_fin >= ts_inicio)))
);


--
-- Name: tareas_recurrentes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tareas_recurrentes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    catalogo_id uuid NOT NULL,
    zona_id uuid,
    maquinaria_id uuid,
    frecuencia_expr character varying(100) NOT NULL,
    descripcion_frecuencia text,
    activa boolean DEFAULT true NOT NULL,
    fecha_inicio date DEFAULT CURRENT_DATE NOT NULL,
    fecha_fin date,
    notas text,
    CONSTRAINT chk_fechas_recurrente CHECK (((fecha_fin IS NULL) OR (fecha_fin >= fecha_inicio)))
);


--
-- Name: COLUMN tareas_recurrentes.frecuencia_expr; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.tareas_recurrentes.frecuencia_expr IS 'Cron estándar (0 22 * * 1,4) o formato propio cada_N_dias:30.';


--
-- Name: tratamientos_activos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tratamientos_activos (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    animal_id uuid NOT NULL,
    evento_sanitario_id uuid,
    farmaco character varying(200) NOT NULL,
    dosis character varying(100),
    via_administracion character varying(80),
    dias_tratamiento smallint NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin_prevista date NOT NULL,
    fecha_fin_real date,
    activo boolean DEFAULT true NOT NULL,
    checkboxes jsonb DEFAULT '[]'::jsonb NOT NULL,
    prescrito_por uuid,
    notas text,
    CONSTRAINT chk_fechas_tratamiento CHECK ((fecha_fin_prevista >= fecha_inicio)),
    CONSTRAINT tratamientos_activos_dias_tratamiento_check CHECK ((dias_tratamiento > 0))
);


--
-- Name: turnos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.turnos (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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
    id uuid NOT NULL,
    username character varying(80) NOT NULL,
    email character varying(255) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    role character varying(40) DEFAULT 'operario'::character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    debe_cambiar_contrasena boolean DEFAULT false NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: v_produccion_diaria; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produccion_diaria AS
 SELECT date_trunc('day'::text, r.ts) AS dia,
    a.crotal_oficial,
    a.id AS animal_id,
    l.numero AS num_lactacion,
    l.fecha_parto,
    (CURRENT_DATE - l.fecha_parto) AS dias_en_leche,
    count(r.ts) AS num_ordenos,
    round(sum(r.produccion_kg), 2) AS produccion_total_kg,
    round(avg(r.conductividad), 2) AS conductividad_media,
    max(r.scc) AS scc_max
   FROM ((public.lecturas_robot_ordeno r
     JOIN public.animales a ON ((r.animal_id = a.id)))
     LEFT JOIN public.lactaciones l ON ((r.lactacion_id = l.id)))
  GROUP BY (date_trunc('day'::text, r.ts)), a.crotal_oficial, a.id, l.numero, l.fecha_parto, (CURRENT_DATE - l.fecha_parto);


--
-- Name: v_tratamientos_pendientes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_tratamientos_pendientes AS
 SELECT a.crotal_oficial,
    a.nombre,
    ta.farmaco,
    ta.fecha_fin_prevista,
    ta.checkboxes,
    ta.id AS tratamiento_id
   FROM (public.tratamientos_activos ta
     JOIN public.animales a ON ((ta.animal_id = a.id)))
  WHERE (ta.activo = true)
  ORDER BY ta.fecha_fin_prevista;


--
-- Name: v_vacas_en_retirada; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_vacas_en_retirada AS
 SELECT a.crotal_oficial,
    a.nombre,
    es.tipo_patologia,
    es.farmaco,
    es.periodo_retirada_hasta,
    (es.periodo_retirada_hasta - CURRENT_DATE) AS dias_restantes
   FROM (public.eventos_sanitarios es
     JOIN public.animales a ON ((es.animal_id = a.id)))
  WHERE (es.periodo_retirada_hasta >= CURRENT_DATE)
  ORDER BY es.periodo_retirada_hasta;


--
-- Name: zonas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zonas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nombre character varying(100) NOT NULL,
    codigo character varying(30) NOT NULL,
    descripcion text,
    tiene_pantalla_tv boolean DEFAULT false NOT NULL,
    tiene_tablet boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE zonas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.zonas IS '5 zonas con pantalla TV informativa y tablet interactiva.';


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
ce2dc9e1-1315-5285-b108-1c09d9ae7263	\N	alta	Robot de ordeno con fallo temporal	El VMS 4 registra dos paradas por error de brazo. Revisar antes del turno de tarde.	incidencias	153da52a-b5d2-53db-8b2c-1292e1e1fd3b	\N	ccca4b6f-9e15-5193-88c8-c44608141146	t	t	t	t	2026-05-30 19:53:17.542964+00	\N	\N
a78b8d0d-b538-5d5e-9e13-d8eb014e50d2	\N	media	Vaca con retraso de ordeno	Animal con mas de 11 horas desde el ultimo paso por robot.	incidencias	c1c5f567-6153-5fb1-ab56-a2c15f9a99c7	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	ccca4b6f-9e15-5193-88c8-c44608141146	f	t	t	t	2026-05-29 19:53:17.542964+00	\N	\N
dcf30175-431e-5f82-a66e-0be1dc3d1c7f	\N	alta	Elevacion de recuento celular	Lectura individual por encima de 350000 cel/ml; tomar muestra de confirmacion.	incidencias	196957e3-30e1-50a9-b8c6-5324e8625627	d172a069-591a-55e4-89fc-32699f1d25c9	df738ef1-6ed8-4172-a99c-f45f7ec5be37	t	t	t	t	2026-05-28 19:53:17.542964+00	\N	\N
9bc20559-69a2-5054-a3ef-a593fd86a374	\N	media	Tratamiento pendiente de confirmar	Falta marcar administracion de segunda dosis en checklist.	incidencias	498fe423-512e-5a1d-93f7-5940ca889eea	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	12928484-dfe8-4637-abb5-954ad7673cc8	f	t	t	t	2026-05-27 19:53:17.542964+00	\N	\N
f794f091-1f82-5f13-8c25-113d281e00f2	\N	media	Bebedero con caudal bajo	Bebedero del lote de produccion con llenado lento.	incidencias	f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30	\N	1819261f-9823-5373-a0dc-533638edb05e	f	t	t	t	2026-05-26 19:53:17.542964+00	\N	\N
d422134c-68ff-5215-a72f-c03ee853aaf7	\N	alta	Stock bajo de detergente alcalino	Quedan dos garrafas, insuficiente para la semana completa.	incidencias	37aa1113-89b0-5f8d-be10-c7fed87f469e	\N	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	t	t	t	t	2026-05-25 19:53:17.542964+00	\N	\N
fa6c02bb-fffd-5bf4-839b-b4c590285bec	\N	media	Desviacion en mezcla unifeed	La paja supero el objetivo en 6%; corregido en segunda carga.	incidencias	bf301360-f84a-5b0e-b62a-23caa034b593	\N	1819261f-9823-5373-a0dc-533638edb05e	f	t	t	f	2026-05-24 19:53:17.542964+00	2026-05-25 19:53:17.542964+00	718c721d-90a7-536a-b47d-bb935fe583f3
985e2266-1b0b-50c9-b03d-b0bcb9c2495e	\N	media	Incidencia en silo de maiz	Lona levantada en lateral norte tras viento nocturno.	incidencias	5bfa710e-ec65-5af2-b146-0fad0d8138bf	\N	46cc7a9d-80c2-5f41-80f8-ab6a8b2644ee	f	t	t	t	2026-05-23 19:53:17.542964+00	\N	\N
1a804df9-d342-5121-848b-96f620d1fc80	\N	alta	Ternero con diarrea neonatal	Box 7 con heces liquidas y ligera deshidratacion.	incidencias	415f1b03-6825-5da0-b3ca-ba52a89cfcf9	874a44ba-01b6-5641-a7a8-14b3adbaa35a	584383a2-21ba-537b-af9b-90d8b722821b	t	t	t	t	2026-05-22 19:53:17.542964+00	\N	\N
a2663df0-08ea-57bb-96aa-36031a067018	\N	media	Vaca con cojera leve	Apoyo irregular en extremidad posterior izquierda.	incidencias	8d02d4b9-2932-5853-b0e4-478817e0c5c0	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	12928484-dfe8-4637-abb5-954ad7673cc8	f	t	t	t	2026-05-21 19:53:17.542964+00	\N	\N
cc1dde7f-3b52-55c7-8271-9d57bbc59020	\N	alta	Caida de vacio en sala	Bomba principal con oscilaciones al arrancar segundo robot.	incidencias	c60e0f88-88f3-5536-83ee-9251b167127f	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	t	t	t	t	2026-05-20 19:53:17.542964+00	\N	\N
f26d0950-ae8d-5c66-9f53-a9c1b5226b9a	\N	media	Sensor sin lectura	Sensor de conductividad del VMS 2 reiniciado y vuelve a emitir.	incidencias	97c3a126-2dc6-5f13-a670-bb0972267513	\N	ccca4b6f-9e15-5193-88c8-c44608141146	f	t	t	f	2026-05-19 19:53:17.542964+00	2026-05-20 19:53:17.542964+00	aed8c2c4-9620-5034-9248-d8564ee7addf
f12e7a2f-620e-5cd7-b679-36fece20e2a1	\N	baja	Tarea de camas no completada	Se reprogramo desinfeccion por entrada de forraje.	incidencias	317dc879-4d94-5ed4-9757-f2c4d8c8e812	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	f	t	t	f	2026-05-18 19:53:17.542964+00	2026-05-19 19:53:17.542964+00	718c721d-90a7-536a-b47d-bb935fe583f3
9bd9bd1b-44c0-5c41-ba8a-0d0229b6e9ea	\N	media	Arrimador sin pasada nocturna	Equipo quedo parado junto a cornadiza; revisar bateria.	incidencias	85bb338b-4e50-5689-b490-915685a2ce07	\N	1819261f-9823-5373-a0dc-533638edb05e	f	t	t	t	2026-05-17 19:53:17.542964+00	\N	\N
5466c5fa-d9e5-5020-986a-e5e43b3d5d6d	\N	media	Temperatura de tanque revisada	Pico de 4.8 C durante lavado; estabilizado tras revision.	incidencias	4bb034da-dc31-505e-a44b-e67c9c21a6db	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	f	t	t	f	2026-05-16 19:53:17.542964+00	2026-05-17 19:53:17.542964+00	aed8c2c4-9620-5034-9248-d8564ee7addf
39d6b5a0-0121-5f48-baae-e1f341a1cb3b	\N	baja	Filtros recibidos incompletos	Proveedor entrego 4 cajas de 6 solicitadas; queda reposicion pendiente.	incidencias	bcb1850d-390e-58c3-b6cf-57fccebffc11	\N	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	f	t	t	f	2026-05-15 19:53:17.542964+00	2026-05-16 19:53:17.542964+00	718c721d-90a7-536a-b47d-bb935fe583f3
c7b71629-2ec4-50b2-99e9-1269dcf66d75	\N	alta	Sospecha de metritis postparto	Animal con descarga anormal y descenso de ingesta.	incidencias	1e8ccb35-7b69-509c-8196-5b1a92beafbe	73956a35-c183-5c88-9b6e-827903fe0241	12928484-dfe8-4637-abb5-954ad7673cc8	t	t	t	t	2026-05-14 19:53:17.542964+00	\N	\N
da9eb70a-c359-5946-b6cc-7ef80c3e7dd2	\N	baja	Tablet de oficina sin carga	Cable sustituido y dispositivo operativo.	incidencias	b0d6febc-76d2-568c-822b-db5cc9ea35f6	\N	041feac1-9de2-4772-af3b-fc7d08acb16f	f	t	t	f	2026-05-13 19:53:17.542964+00	2026-05-14 19:53:17.542964+00	aed8c2c4-9620-5034-9248-d8564ee7addf
56299785-11af-5b2f-9f0d-e0085c361f13	\N	media	Ventilador sector 3 parado	Motor no arranca en modo automatico con THI alto.	incidencias	adbf9a1e-8a9a-56b7-addc-deb367880811	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	f	t	t	t	2026-05-12 19:53:17.542964+00	\N	\N
163849ec-0763-5964-8fbf-57262ab55695	\N	media	Frente de silo irregular	Se recorto frente y se compacto zona abierta.	incidencias	9daf15f0-e0f0-5973-b3e2-174a5a5fe7d9	\N	46cc7a9d-80c2-5f41-80f8-ab6a8b2644ee	f	t	t	f	2026-05-11 19:53:17.542964+00	2026-05-12 19:53:17.542964+00	f2b0bd7e-4171-5347-8179-fe6667ba7985
270406e8-3045-5517-b290-8616c7dba293	\N	media	Novilla con tos persistente	Revisar temperatura y valorar tratamiento respiratorio.	incidencias	f0142fee-b873-5d45-80d9-fbc8f460b796	74107440-00d6-58ee-ae41-82471d6b9aa4	4f5eef67-de33-4897-9669-51ba1a5ef6d6	f	t	t	t	2026-05-10 19:53:17.542964+00	\N	\N
54cb501b-7938-50b7-a0a9-9849e133cd64	\N	baja	Bajada de grasa en lote	Media de grasa baja respecto a semana previa; revisar fibra efectiva.	incidencias	290612c3-2ec1-5f55-b1b0-b49389db3355	\N	1819261f-9823-5373-a0dc-533638edb05e	f	t	t	t	2026-05-09 19:53:17.542964+00	\N	\N
964f31f7-1dcf-59b9-b811-b213eb4b5ee9	\N	media	Revision de tractor completada	Cambio de filtro y engrase realizados.	incidencias	23661db5-4a74-5c10-b3a4-991b4fbb567d	\N	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	f	t	t	f	2026-05-08 19:53:17.542964+00	2026-05-09 19:53:17.542964+00	f2b0bd7e-4171-5347-8179-fe6667ba7985
84ee954a-8b6f-5675-bcb5-098b3eb85c9d	\N	alta	Pedido urgente de antiinflamatorio	Stock minimo alcanzado tras tratamientos de cojeras.	incidencias	b84c837c-8e65-51a7-a0b0-565faa3d59a8	\N	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	t	t	t	t	2026-05-07 19:53:17.542964+00	\N	\N
367a0f13-0c25-5960-b68c-de56cb176e22	\N	media	Cama humeda en boxes de terneros	Cambiar cama de boxes 4 a 8 antes de la tarde.	incidencias	27bc0217-6243-5c80-9f8c-aaef63cb8d91	\N	584383a2-21ba-537b-af9b-90d8b722821b	f	t	t	t	2026-05-06 19:53:17.542964+00	\N	\N
e40c2359-805c-54b0-aeb3-b632f4453a86	\N	alta	Mastitis clinica leve	Cuarteron posterior con grumos en primeros chorros.	incidencias	7e8790a1-a048-50be-87a3-31e395137dd8	2e14a84a-511d-5bcf-867c-216522289b1c	12928484-dfe8-4637-abb5-954ad7673cc8	t	t	t	t	2026-05-05 19:53:17.542964+00	\N	\N
5e5a6389-e0ae-5285-8afb-04be0658f6e4	\N	baja	Bebedero limpiado tras aviso	Retirado resto de forraje de valvula.	incidencias	7e55d431-d27d-59de-b1f3-f8bae2a81d00	\N	1819261f-9823-5373-a0dc-533638edb05e	f	t	t	f	2026-05-04 19:53:17.542964+00	2026-05-05 19:53:17.542964+00	aed8c2c4-9620-5034-9248-d8564ee7addf
35a1fb8f-0bb2-56d4-a16b-2ca7d187f1b4	\N	media	Amamantadora en revision pendiente	Calibracion de polvo de leche fuera de rango.	incidencias	c534fbe9-e9d8-5960-b0a4-befbc200f6aa	\N	584383a2-21ba-537b-af9b-90d8b722821b	f	t	t	t	2026-05-03 19:53:17.542964+00	\N	\N
91450431-ed96-51c3-8d81-53cdb32ae4b9	\N	baja	Muestra de control registrada	Muestra enviada por subida puntual de conductividad.	incidencias	415d9b5b-4fb4-5fdb-8a8d-ea8490a015b0	46e29b13-6344-5b6d-8471-0891456bd85b	df738ef1-6ed8-4172-a99c-f45f7ec5be37	f	t	t	f	2026-05-02 19:53:17.542964+00	2026-05-03 19:53:17.542964+00	f2b0bd7e-4171-5347-8179-fe6667ba7985
c18a3698-00c2-5473-b867-5df448240f6b	\N	media	Limpieza de sala retrasada	Pendiente repaso de zona de espera tras turno de manana.	incidencias	7fdc414c-a010-5da9-8468-48e5ba08e193	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	f	t	t	t	2026-05-01 19:53:17.542964+00	\N	\N
\.


--
-- Data for Name: alertas_umbrales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alertas_umbrales (id, codigo, descripcion, metrica, operador, valor_umbral, unidad, nivel_alerta, push_whatsapp, pantalla_tv, tablet, activo, notas) FROM stdin;
4b7373cf-6ca9-46d4-b2af-961bc9fd9b77	scc_alto	SCC estimado supera umbral de calidad	scc	>	250000.0000	cel/ml	alta	t	t	t	t	\N
32b99201-c645-403a-9992-e11bc8076e2d	tarea_vencida	Tarea no completada transcurridas más de 2 horas de su hora planificada	minutos_retraso_tarea	>	120.0000	min	alta	t	t	t	t	\N
00e80187-c5d5-490a-a4cb-78502b0ef0fb	tratamiento_no_dado	Administración de tratamiento activo no registrada en el día	checkboxes_pendientes	>	0.0000	und	alta	t	t	t	t	\N
8e0d8554-fef9-4eb4-a5dc-ad8c336d6fb9	retraso_ordeno	Retraso en el inicio del ordeño respecto a hora planificada	minutos_retraso_ordeno	>	0.0000	min	media	f	t	t	t	\N
9de3b08f-5fff-440a-8e7b-e5821dccf0bc	desviacion_tmr	Desviación de la ración TMR superior al 5%	desviacion_pct_tmr	>	5.0000	%	media	f	t	t	t	\N
a0a78ba6-b80b-4c21-a27a-ad582b71ca9f	recordatorio_protocolo	Recordatorio de protocolo periódico	protocolo_pendiente	>	0.0000	und	baja	f	t	f	t	\N
b05192af-9c52-4bc9-a395-48c3720164c4	estado_meteo	Información de estado meteorológico para pantalla TV	info_meteo	=	1.0000	\N	baja	f	t	f	t	\N
\.


--
-- Data for Name: animales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.animales (id, crotal_oficial, nombre, sexo, fecha_nacimiento, raza, estado, estado_reproductivo, madre_id, fecha_entrada, fecha_baja, motivo_baja, notas, zona_id) FROM stdin;
5dbdee66-af90-503d-b6c5-b428cebb2b91	ES2706500064	Dalia 64	hembra	2018-03-30	Frisona	seca	confirmada_gestante	\N	2025-03-28	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
5c888535-5880-5f6c-b53c-128c9df5464b	ES2706500065	Vega 65	hembra	2022-03-28	Frisona	seca	confirmada_gestante	\N	2025-03-27	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
963164ac-9734-5fd9-bd3a-fc7dacff84e1	ES2706500066	Senda 66	hembra	2021-03-27	Parda Alpina	seca	confirmada_gestante	\N	2025-03-26	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
ffe82114-3a26-5e7b-8ce6-7a8ef2f12732	ES2706500067	Cora 67	hembra	2020-03-26	Frisona	seca	confirmada_gestante	\N	2025-03-25	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
cf17702f-f18b-553e-9294-67e671e66022	ES2706500010	Xiana 10	hembra	2019-05-23	Frisona	produccion	confirmada_gestante	\N	2025-05-21	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
d172a069-591a-55e4-89fc-32699f1d25c9	ES2706500013	Nube 13	hembra	2022-05-19	Frisona	produccion	inseminada	\N	2025-05-18	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
62d38b4e-74e0-5f20-b66b-64efddec53b7	ES2706500016	Dalia 16	hembra	2019-05-17	Frisona	produccion	vacia	\N	2025-05-15	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
df87133b-ee35-5f6c-982e-0b9e09ad3dea	ES2706500019	Cora 19	hembra	2022-05-13	Frisona	produccion	parto_reciente	\N	2025-05-12	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	ES2706500022	Xiana 22	hembra	2019-05-11	Parda Alpina	produccion	confirmada_gestante	\N	2025-05-09	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
784ed9c6-39d3-5da9-b379-311aca240fdd	ES2706500025	Nube 25	hembra	2022-05-07	Frisona	produccion	inseminada	\N	2025-05-06	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
1c069679-3e6d-5b3e-8842-c27c074da0a0	ES2706500028	Dalia 28	hembra	2019-05-05	Cruce Frisona	produccion	vacia	\N	2025-05-03	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
674f97b3-f5f9-5ead-bf6c-d743870ba36f	ES2706500031	Cora 31	hembra	2022-05-01	Frisona	produccion	parto_reciente	\N	2025-04-30	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
9baa72c1-9b94-594b-8926-8a3c17ee9ac7	ES2706500034	Xiana 34	hembra	2019-04-29	Frisona	produccion	confirmada_gestante	\N	2025-04-27	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
6b224987-9434-5637-a871-9ac01fd4d4c3	ES2706500037	Nube 37	hembra	2022-04-25	Frisona	produccion	inseminada	\N	2025-04-24	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7	ES2706500040	Dalia 40	hembra	2019-04-23	Frisona	produccion	vacia	\N	2025-04-21	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
78f6b86f-6d19-50c5-a003-4cf0c0c02e22	ES2706500043	Cora 43	hembra	2022-04-19	Frisona	produccion	parto_reciente	\N	2025-04-18	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
c9303516-f788-5f46-90dd-bb82d7023d71	ES2706500046	Xiana 46	hembra	2019-04-17	Frisona	produccion	confirmada_gestante	\N	2025-04-15	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
9a533fa2-4f96-500a-af83-80da01f2370d	ES2706500049	Nube 49	hembra	2022-04-13	Cruce Frisona	produccion	inseminada	\N	2025-04-12	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6	ES2706500052	Dalia 52	hembra	2019-04-11	Frisona	produccion	vacia	\N	2025-04-09	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
329e2c29-366f-56b0-b854-ca7cb56bff5f	ES2706500054	Senda 54	hembra	2023-04-08	Frisona	produccion	confirmada_gestante	\N	2025-04-07	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
70a72a01-c51c-5511-b0ee-276eeec0db42	ES2706500084	Luna 84	hembra	2026-02-11	Cruce Frisona	recria	\N	\N	2026-05-07	\N	\N	Ternero/a en recria inicial.	584383a2-21ba-537b-af9b-90d8b722821b
f8f9284b-2242-54c3-9435-e9a2db95edef	ES2706500087	Mora 87	hembra	2026-02-08	Frisona	recria	\N	\N	2026-05-04	\N	\N	Ternero/a en recria inicial.	584383a2-21ba-537b-af9b-90d8b722821b
0faa59c0-c0fc-5b47-803d-44e925588a03	ES2706500090	Senda 90	macho	2026-05-06	Frisona	recria	\N	\N	2026-05-01	\N	\N	Ternero/a en recria inicial.	584383a2-21ba-537b-af9b-90d8b722821b
d58fbf17-442e-5153-8cdf-ce264a40ef4f	ES2706500001	Nube 1	hembra	2022-05-31	Frisona	produccion	inseminada	\N	2025-05-30	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
73956a35-c183-5c88-9b6e-827903fe0241	ES2706500004	Dalia 4	hembra	2019-05-29	Frisona	produccion	vacia	\N	2025-05-27	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	ES2706500007	Cora 7	hembra	2022-05-25	Cruce Frisona	produccion	parto_reciente	\N	2025-05-24	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
0f7ff532-8875-5404-8a53-3c204bdf55e1	ES2706500059	Noa 59	hembra	2018-04-04	Frisona	seca	confirmada_gestante	\N	2025-04-02	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
1f8d73e0-6258-536a-bb01-0fcdd4b96b26	ES2706500060	Luna 60	hembra	2022-04-02	Frisona	seca	confirmada_gestante	\N	2025-04-01	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
5dc5cac3-6bb9-5d56-957b-7677c4bcc56b	ES2706500061	Nube 61	hembra	2021-04-01	Frisona	seca	confirmada_gestante	\N	2025-03-31	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
12ba4d63-24a9-5f3c-9204-99590678f5ed	ES2706500062	Brisa 62	hembra	2020-03-31	Frisona	seca	confirmada_gestante	\N	2025-03-30	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
09065fbe-c2e5-500a-93cc-5f9f55d9f114	ES2706500063	Mora 63	hembra	2019-03-31	Cruce Frisona	seca	confirmada_gestante	\N	2025-03-29	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
0d506129-b7c5-507a-88ca-242344baa5de	ES2706500003	Mora 3	hembra	2020-05-29	Frisona	produccion	parto_reciente	\N	2025-05-28	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
1a6e7a54-8774-52a6-896f-01a35b5cbc2d	ES2706500006	Senda 6	hembra	2023-05-26	Frisona	produccion	confirmada_gestante	\N	2025-05-25	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
936b78c4-7b89-5fcf-97f7-54f007674e36	ES2706500009	Oliva 9	hembra	2020-05-23	Frisona	produccion	inseminada	\N	2025-05-22	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
c7ee8997-4bfb-56ca-9a3f-653af2d06595	ES2706500002	Brisa 2	hembra	2021-05-30	Frisona	produccion	confirmada_gestante	\N	2025-05-29	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
e287b4b8-1876-527c-8b7c-7fdf85c42709	ES2706500005	Vega 5	hembra	2018-05-28	Frisona	produccion	inseminada	\N	2025-05-26	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
3c97c346-b54c-5581-930e-f3264d6773ea	ES2706500008	Nora 8	hembra	2021-05-24	Frisona	produccion	vacia	\N	2025-05-23	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
19eeaa52-2c8b-5e63-ace0-ef1ec00d6da9	ES2706500083	Noa 83	hembra	2026-02-12	Frisona	recria	\N	\N	2026-05-08	\N	\N	Ternero/a en recria inicial.	bc97e385-bbd8-5163-895a-b7156b84e145
a4774bd3-5ee0-54bc-8fb8-cf5df0b3bd89	ES2706500085	Nube 85	hembra	2026-02-10	Frisona	recria	\N	\N	2026-05-06	\N	\N	Ternero/a en recria inicial.	584383a2-21ba-537b-af9b-90d8b722821b
7aaf1f29-d947-5361-9119-50eed5155dcc	ES2706500086	Brisa 86	hembra	2026-02-09	Frisona	recria	\N	\N	2026-05-05	\N	\N	Ternero/a en recria inicial.	bc97e385-bbd8-5163-895a-b7156b84e145
231e6267-606a-5595-92e1-a74dc7a9580e	ES2706500088	Dalia 88	hembra	2026-02-07	Parda Alpina	recria	\N	\N	2026-05-03	\N	\N	Ternero/a en recria inicial.	584383a2-21ba-537b-af9b-90d8b722821b
874a44ba-01b6-5641-a7a8-14b3adbaa35a	ES2706500089	Vega 89	macho	2026-02-06	Frisona	recria	\N	\N	2026-05-02	\N	\N	Ternero/a en recria inicial.	bc97e385-bbd8-5163-895a-b7156b84e145
edf24324-814b-56b2-8b5d-c214ff93fad4	ES2706500091	Cora 91	macho	2026-05-05	Cruce Frisona	recria	\N	\N	2026-04-30	\N	\N	Ternero/a en recria inicial.	584383a2-21ba-537b-af9b-90d8b722821b
9b62d7c9-5d36-53f7-b27d-5699ce5c52e4	ES2706500092	Nora 92	macho	2026-05-04	Frisona	recria	\N	\N	2026-04-29	\N	\N	Ternero/a en recria inicial.	bc97e385-bbd8-5163-895a-b7156b84e145
100ab0c5-a993-504e-90af-c6d7f59f072f	ES2706500071	Noa 71	hembra	2025-01-25	Frisona	gestante	inseminada	\N	2025-03-21	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
ba1837f5-ce8f-55d5-a7c1-f75e574eac0f	ES2706500072	Luna 72	hembra	2025-01-24	Frisona	gestante	inseminada	\N	2025-03-20	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
f4edf01d-3029-53e1-95e5-876c6e613901	ES2706500073	Nube 73	hembra	2025-01-23	Frisona	gestante	inseminada	\N	2025-03-19	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
a0842a46-290f-564e-b305-cadd12a663e4	ES2706500074	Brisa 74	hembra	2025-01-22	Frisona	gestante	inseminada	\N	2025-03-18	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
d310c7c4-c400-5688-b908-536055d69bad	ES2706500075	Mora 75	hembra	2025-01-21	Frisona	gestante	inseminada	\N	2025-03-17	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
c02339ca-c4bc-5afb-b0ab-bb4beb783997	ES2706500076	Dalia 76	hembra	2025-01-20	Frisona	gestante	inseminada	\N	2025-03-16	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
58c0f921-4cc5-5ae0-a3b0-cbcc31f21719	ES2706500077	Vega 77	hembra	2025-01-19	Cruce Frisona	gestante	inseminada	\N	2025-03-15	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
759a20cb-11da-5d54-a6ef-e82e1d84280e	ES2706500078	Senda 78	hembra	2025-01-18	Frisona	gestante	inseminada	\N	2025-03-14	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
3e349a4d-3389-5173-adfb-07c3b16e00c2	ES2706500079	Cora 79	hembra	2025-01-17	Frisona	gestante	inseminada	\N	2025-03-13	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
c4407964-453c-5725-81ed-26abc47257cd	ES2706500080	Nora 80	hembra	2025-01-16	Frisona	gestante	inseminada	\N	2025-05-31	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	ES2706500011	Noa 11	hembra	2018-05-22	Parda Alpina	produccion	parto_reciente	\N	2025-05-20	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
436a7ff2-5df5-51b1-a49f-179831808d47	ES2706500014	Brisa 14	hembra	2021-05-18	Cruce Frisona	produccion	confirmada_gestante	\N	2025-05-17	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
592b42b6-a0bc-52ed-8f7d-44a9ab00b455	ES2706500017	Vega 17	hembra	2018-05-16	Frisona	produccion	inseminada	\N	2025-05-14	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
afe8a03e-b5f2-5013-9b65-26fc935d703f	ES2706500020	Nora 20	hembra	2021-05-12	Frisona	produccion	vacia	\N	2025-05-11	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
1a1a57d7-fc16-5715-8133-35c906e0453a	ES2706500023	Noa 23	hembra	2018-05-10	Frisona	produccion	parto_reciente	\N	2025-05-08	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
46e29b13-6344-5b6d-8471-0891456bd85b	ES2706500026	Brisa 26	hembra	2021-05-06	Frisona	produccion	confirmada_gestante	\N	2025-05-05	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
fae53a98-6313-583b-8c58-8e81fe950f6e	ES2706500029	Vega 29	hembra	2018-05-04	Frisona	produccion	inseminada	\N	2025-05-02	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
0f5350db-fd30-58b4-bf08-ae0b3ca94afd	ES2706500032	Nora 32	hembra	2021-04-30	Frisona	produccion	vacia	\N	2025-04-29	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
ac52e314-03fc-5fc7-95c8-e51551ffca78	ES2706500035	Noa 35	hembra	2018-04-28	Cruce Frisona	produccion	parto_reciente	\N	2025-04-26	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
abe64d55-ec3c-53f6-8051-84c8f56b51d5	ES2706500038	Brisa 38	hembra	2021-04-24	Frisona	produccion	confirmada_gestante	\N	2025-04-23	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
2a91fb61-47ee-5001-a3e6-0e56c0f91308	ES2706500041	Vega 41	hembra	2018-04-22	Frisona	produccion	inseminada	\N	2025-04-20	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
c06ec15f-7d13-5837-b7c2-0b8b8465b3c1	ES2706500044	Nora 44	hembra	2021-04-18	Parda Alpina	produccion	vacia	\N	2025-04-17	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
a306664d-4e62-530d-8fe8-28ebfce56181	ES2706500047	Noa 47	hembra	2018-04-16	Frisona	produccion	parto_reciente	\N	2025-04-14	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
0db75e34-604b-511f-8aea-4156fe8eb5d1	ES2706500050	Brisa 50	hembra	2021-04-12	Frisona	produccion	confirmada_gestante	\N	2025-04-11	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
b7e68ca6-a516-52f8-9a88-8f272749ac23	ES2706500053	Vega 53	hembra	2018-04-10	Frisona	produccion	inseminada	\N	2025-04-08	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	ES2706500012	Luna 12	hembra	2023-05-20	Frisona	produccion	vacia	\N	2025-05-19	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
b5263713-2026-5bad-ae46-296dc48a39d3	ES2706500015	Mora 15	hembra	2020-05-17	Frisona	produccion	parto_reciente	\N	2025-05-16	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	ES2706500018	Senda 18	hembra	2023-05-14	Frisona	produccion	confirmada_gestante	\N	2025-05-13	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	ES2706500021	Oliva 21	hembra	2020-05-11	Cruce Frisona	produccion	inseminada	\N	2025-05-10	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
4c13e989-899c-5d47-8988-380802d72f58	ES2706500024	Luna 24	hembra	2023-05-08	Frisona	produccion	vacia	\N	2025-05-07	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
20cb75da-56ec-50b5-85f8-792b0d74f745	ES2706500027	Mora 27	hembra	2020-05-05	Frisona	produccion	parto_reciente	\N	2025-05-04	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
eeded079-9abf-5844-8559-6eea890a6fe4	ES2706500030	Senda 30	hembra	2023-05-02	Frisona	produccion	confirmada_gestante	\N	2025-05-01	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
3f9aca1c-2859-5e86-909b-fe2777f960ca	ES2706500033	Oliva 33	hembra	2020-04-29	Parda Alpina	produccion	inseminada	\N	2025-04-28	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
bb9fc07f-076f-5182-93d0-8eb2ece1ee89	ES2706500036	Luna 36	hembra	2023-04-26	Frisona	produccion	vacia	\N	2025-04-25	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
2e14a84a-511d-5bcf-867c-216522289b1c	ES2706500039	Mora 39	hembra	2020-04-23	Frisona	produccion	parto_reciente	\N	2025-04-22	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
df02d6c2-f792-565d-ac97-d358d7484092	ES2706500042	Senda 42	hembra	2023-04-20	Cruce Frisona	produccion	confirmada_gestante	\N	2025-04-19	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
0238f86f-4409-54d4-b4eb-0d28d7b4af0c	ES2706500045	Oliva 45	hembra	2020-04-17	Frisona	produccion	inseminada	\N	2025-04-16	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
ab19f1c4-775c-5f7d-8fad-c7b0cea81217	ES2706500048	Luna 48	hembra	2023-04-14	Frisona	produccion	vacia	\N	2025-04-13	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
1cb96771-c7de-53e3-b737-2954be5a71de	ES2706500051	Mora 51	hembra	2020-04-11	Frisona	produccion	parto_reciente	\N	2025-04-10	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
ab624830-c14c-5b1a-afcc-f0b59876050a	ES2706500056	Nora 56	hembra	2021-04-06	Cruce Frisona	produccion	vacia	\N	2025-04-05	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
74107440-00d6-58ee-ae41-82471d6b9aa4	ES2706500081	Oliva 81	hembra	2025-01-15	Frisona	gestante	inseminada	\N	2025-05-30	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
7234f761-7764-5891-8b85-d3e4ca2db7ff	ES2706500082	Xiana 82	hembra	2025-01-14	Frisona	gestante	inseminada	\N	2025-05-29	\N	\N	Novilla gestante en recria avanzada.	12928484-dfe8-4637-abb5-954ad7673cc8
9144858f-31c8-575d-a0ae-366e1d2935fd	ES2706500055	Cora 55	hembra	2022-04-07	Parda Alpina	produccion	parto_reciente	\N	2025-04-06	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
a3c69881-650f-5671-9ae6-8371fb892b89	ES2706500058	Xiana 58	hembra	2019-04-05	Frisona	produccion	confirmada_gestante	\N	2025-04-03	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
efc8bf74-ef7d-5152-a4d4-a077ae7a7d52	ES2706500068	Nora 68	hembra	2019-03-26	Frisona	seca	confirmada_gestante	\N	2025-03-24	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
27ba2d06-b334-5f7c-bd59-ba67cf095d68	ES2706500069	Oliva 69	hembra	2018-03-25	Frisona	seca	confirmada_gestante	\N	2025-03-23	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
389f3969-2148-5055-82d6-166a20ab6a9b	ES2706500070	Xiana 70	hembra	2022-03-23	Cruce Frisona	seca	confirmada_gestante	\N	2025-03-22	\N	\N	Vaca seca en lote preparto o secado.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
798cfeb1-fa83-529d-b119-c7f5cd60f5cd	ES2706500057	Oliva 57	hembra	2020-04-05	Frisona	produccion	inseminada	\N	2025-04-04	\N	\N	Vaca en lactacion con control rutinario de produccion.	df738ef1-6ed8-4172-a99c-f45f7ec5be37
\.


--
-- Data for Name: asignaciones_turno; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.asignaciones_turno (id, turno_id, empleado_id, zona_id, rol) FROM stdin;
0dbfd675-3e3c-50c6-86d2-9d292f8316bf	036532ee-f62c-5adf-ae78-50ff294f0ebf	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
6efd52b4-ab22-5e5a-a47b-af1ba9b89975	477b09af-df38-55f7-898d-347021c79d8e	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
c0e3632e-feac-5f30-90d5-e34799c5de34	dc17241e-e305-5169-87f6-b72de1a7e604	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
a420a50a-566c-58ea-89b3-7a4cd445f2ab	9bf70236-d678-5a3e-ad64-b4fa5b5e3901	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
ec387ed0-1785-5dbe-8dda-7c13267af5cf	637f3b98-4ed6-5d96-ad6f-166b49135040	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
3c72a349-2840-5762-8524-f00ba39fa2ab	c40a8fab-a392-5e5d-9fe6-eb47807c541f	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
f4cf8964-d568-535f-b5a1-0c77515b23c6	806041d7-8f66-5a30-9763-951ec6951183	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
52afaa4b-c628-5ad5-a2ec-0e732cc986bb	7d245751-1ad7-5677-af6d-bfb8c71d1734	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
59517710-a23b-5d47-9873-b0b6f0e52ede	16ab9a4e-295d-5e6e-8bc7-e1d361b1be9f	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
69831e3d-35d9-5782-b5fa-d3d04c103280	6b88b173-cd02-568e-80d9-2a7ed12413ec	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
7672fe2f-c648-5381-9883-b082bc351318	23838145-7ce3-5502-8fdd-0d72fa063c60	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
1f89cab9-dfc8-5b79-9f4b-eef21f7ea9bc	c10998b0-61ca-5c7c-a6ef-07a9b1f3dfba	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
01e2bbdf-7725-58a4-ac49-1eccc2198056	9c721bbb-1e85-5091-8f6e-3d48feeb4597	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
c65833f5-d699-5ad6-8ab7-c8e792275a2b	ca4173b3-5931-5ac8-961d-26c5a7e48959	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	responsable turno
f6f4679c-aeaa-5fbc-9c66-81e7d8cc24aa	036532ee-f62c-5adf-ae78-50ff294f0ebf	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
69b13d33-2b9b-5b50-9aad-75f3e3bdaade	477b09af-df38-55f7-898d-347021c79d8e	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
0590595d-c585-5d5e-bead-63e4e247c06f	dc17241e-e305-5169-87f6-b72de1a7e604	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
159a4eb8-5190-53d9-864f-461b1a526c3d	9bf70236-d678-5a3e-ad64-b4fa5b5e3901	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
59f67810-589c-588a-9974-f225316033aa	637f3b98-4ed6-5d96-ad6f-166b49135040	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
0eab10ab-9ed4-599f-bd11-88b8c7fec318	c40a8fab-a392-5e5d-9fe6-eb47807c541f	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
8a65ead4-629d-562c-9ea4-9585ec0e0c76	806041d7-8f66-5a30-9763-951ec6951183	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
bf7c78ef-f029-5998-a44f-177f68d584e6	7d245751-1ad7-5677-af6d-bfb8c71d1734	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
7cffd169-400b-5cdc-bb1c-407a3ab79b7f	16ab9a4e-295d-5e6e-8bc7-e1d361b1be9f	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
8b15858f-04f0-55d7-9b7e-b51ae7cfd355	6b88b173-cd02-568e-80d9-2a7ed12413ec	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
2364e385-6126-5137-90f8-8cfe7423201f	23838145-7ce3-5502-8fdd-0d72fa063c60	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
3d605d13-8da8-5748-bf63-6a4158c05cbb	c10998b0-61ca-5c7c-a6ef-07a9b1f3dfba	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
9b79ace5-2b5c-5e56-ae81-827f93a0ab57	9c721bbb-1e85-5091-8f6e-3d48feeb4597	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
d0cd5298-e92c-5f7f-acfc-780a99b9de77	ca4173b3-5931-5ac8-961d-26c5a7e48959	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	4f5eef67-de33-4897-9669-51ba1a5ef6d6	operario zona
014be58f-02f5-5f8f-aade-0e98a035644e	036532ee-f62c-5adf-ae78-50ff294f0ebf	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
55b210a0-2edf-52fa-addd-f323537bad19	477b09af-df38-55f7-898d-347021c79d8e	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
d26216ba-046e-5c64-9664-25b2306b7540	dc17241e-e305-5169-87f6-b72de1a7e604	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
12fd9928-8fe9-5170-ab28-a91744416d00	9bf70236-d678-5a3e-ad64-b4fa5b5e3901	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
c6cc45e8-a5f9-5b77-a615-e8471f9f5c37	637f3b98-4ed6-5d96-ad6f-166b49135040	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
cd2ab36f-48b2-5c77-a11b-f84a5c83f7c1	c40a8fab-a392-5e5d-9fe6-eb47807c541f	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
c3a71db0-f59d-5c5b-9318-f37a775a4d7b	806041d7-8f66-5a30-9763-951ec6951183	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
d7292c88-a444-52a3-936b-2b24724489b3	7d245751-1ad7-5677-af6d-bfb8c71d1734	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
636b8bfb-5b28-5e42-a737-c53399e922c9	16ab9a4e-295d-5e6e-8bc7-e1d361b1be9f	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
bfc18706-b9b9-5177-9ca4-b980051c35f2	6b88b173-cd02-568e-80d9-2a7ed12413ec	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
7dfa25b9-c045-5ad2-be5c-ec7356fa281b	23838145-7ce3-5502-8fdd-0d72fa063c60	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
7a4c840d-f6bf-584e-b2be-a7f2c174679f	c10998b0-61ca-5c7c-a6ef-07a9b1f3dfba	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
315cde9a-7e17-5c8a-94bb-dccd126a0ae2	9c721bbb-1e85-5091-8f6e-3d48feeb4597	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
36103c88-5d40-5ac9-b81d-503a40fdf3a0	ca4173b3-5931-5ac8-961d-26c5a7e48959	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	sanidad
d2820273-1f61-52fe-8e45-8507b1a164e2	036532ee-f62c-5adf-ae78-50ff294f0ebf	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
6d5ddcb7-df71-5f8c-aa25-e8186e7c986f	477b09af-df38-55f7-898d-347021c79d8e	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
3420bf28-1d6e-5387-a9bf-24026cc39c09	dc17241e-e305-5169-87f6-b72de1a7e604	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
f17c5ae4-3b91-517d-a94a-1be0df1882ec	9bf70236-d678-5a3e-ad64-b4fa5b5e3901	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
ac088a60-9ed7-5aaa-a60d-5ed663a1fb57	637f3b98-4ed6-5d96-ad6f-166b49135040	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
2ab8cc24-8381-59e1-80a6-a0b4ab410278	c40a8fab-a392-5e5d-9fe6-eb47807c541f	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
695aba7f-434d-5be2-ba20-09e663e2a371	806041d7-8f66-5a30-9763-951ec6951183	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
aad47687-27e5-5ea5-ad1c-c86c7199ef0f	7d245751-1ad7-5677-af6d-bfb8c71d1734	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
4d5f9623-101e-55f5-ab53-70ff155f0642	16ab9a4e-295d-5e6e-8bc7-e1d361b1be9f	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
aac3dedf-1198-54e8-bda1-183091ba81b4	6b88b173-cd02-568e-80d9-2a7ed12413ec	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
489a6c0b-b05d-58b6-8b2d-6615f20ab0a4	23838145-7ce3-5502-8fdd-0d72fa063c60	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
6cd10c4d-58a3-5563-83c8-cb25f1d49052	c10998b0-61ca-5c7c-a6ef-07a9b1f3dfba	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
81aafbf7-3659-5bf3-8e90-e6c115d5113c	9c721bbb-1e85-5091-8f6e-3d48feeb4597	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
80a347fe-c456-5683-89d8-820bd3d1e9bb	ca4173b3-5931-5ac8-961d-26c5a7e48959	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	operario zona
03145b03-8b0d-5a89-a5a4-f4005551edfa	036532ee-f62c-5adf-ae78-50ff294f0ebf	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
ff58d927-a2db-5533-a707-fdbb35a1e698	477b09af-df38-55f7-898d-347021c79d8e	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
aaf00118-fc47-5f24-90e8-3aabaf12d43a	dc17241e-e305-5169-87f6-b72de1a7e604	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
9f2aa4bb-5909-5e6b-a4dd-c841d05827e0	9bf70236-d678-5a3e-ad64-b4fa5b5e3901	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
8414e817-e607-5d90-8124-fea2e4aa05d8	637f3b98-4ed6-5d96-ad6f-166b49135040	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
56df0df9-0003-5adb-99fb-2748c68f12c9	c40a8fab-a392-5e5d-9fe6-eb47807c541f	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
e562d59f-8287-51c9-894c-8a6ce066a231	806041d7-8f66-5a30-9763-951ec6951183	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
052c0587-502f-517c-a576-4a5a485b55d4	7d245751-1ad7-5677-af6d-bfb8c71d1734	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
f7d740ad-b4af-5a76-9e7e-73c5b220ca58	16ab9a4e-295d-5e6e-8bc7-e1d361b1be9f	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
c456efa6-b7c0-58e0-9503-f81101453883	6b88b173-cd02-568e-80d9-2a7ed12413ec	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
e1bfdfd9-a76c-5d85-b918-5c729f818ced	23838145-7ce3-5502-8fdd-0d72fa063c60	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
55083922-eb81-5ef0-b18d-c3eaf828d0e2	c10998b0-61ca-5c7c-a6ef-07a9b1f3dfba	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
8a738483-a01b-5dc3-9e5c-fd54bfd6867b	9c721bbb-1e85-5091-8f6e-3d48feeb4597	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
eeb56308-0d96-52ed-8113-be49eb56dbec	ca4173b3-5931-5ac8-961d-26c5a7e48959	718c721d-90a7-536a-b47d-bb935fe583f3	942963db-2cb5-49b5-9640-c96a138553cc	mantenimiento
eec13042-4672-4096-a23a-4b0094471f19	6716676c-7192-408b-a646-1e806e03d495	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	\N	\N
f5fce046-281e-403a-a396-600b4c6bb033	8c4ccba1-7ed1-4a0e-ad8b-74e7bdc4c792	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	\N	\N
cd9c7b2b-8bbb-45a7-b5b7-3e5dd7ab0d9b	8c4ccba1-7ed1-4a0e-ad8b-74e7bdc4c792	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	\N	\N
93d4d1b7-572c-4df0-b0ca-a2d2b58adb16	8c4ccba1-7ed1-4a0e-ad8b-74e7bdc4c792	aed8c2c4-9620-5034-9248-d8564ee7addf	\N	\N
4ce50d05-88c1-41f8-bb6b-593b0d5983e4	8c4ccba1-7ed1-4a0e-ad8b-74e7bdc4c792	3033a0ee-9ffe-5e7f-a7a2-76f309918749	\N	\N
e9a13fcc-794d-4e92-80ce-a43e9c35d90d	6716676c-7192-408b-a646-1e806e03d495	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	\N	\N
cf925762-7060-469e-8ebd-3a87cc051dfd	6716676c-7192-408b-a646-1e806e03d495	aed8c2c4-9620-5034-9248-d8564ee7addf	\N	\N
08bcf53b-f2f8-4199-b160-6d4eb46bc3ea	6716676c-7192-408b-a646-1e806e03d495	3033a0ee-9ffe-5e7f-a7a2-76f309918749	\N	\N
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, ts, tabla_afectada, operacion, registro_id, datos_anteriores, datos_nuevos, usuario_bd, hash_sha256) FROM stdin;
1	2026-05-31 19:52:02.18229+00	animales	INSERT	d58fbf17-442e-5153-8cdf-ce264a40ef4f	\N	{"id": "d58fbf17-442e-5153-8cdf-ce264a40ef4f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 1", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500001", "fecha_nacimiento": "2022-05-31", "estado_reproductivo": "inseminada"}	postgres	7dbacbf01cb6cabcd648a8d9739362fe265104e08712b7370e1e08b604ad758d
2	2026-05-31 19:52:02.18229+00	animales	INSERT	c7ee8997-4bfb-56ca-9a3f-653af2d06595	\N	{"id": "c7ee8997-4bfb-56ca-9a3f-653af2d06595", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 2", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-29", "crotal_oficial": "ES2706500002", "fecha_nacimiento": "2021-05-30", "estado_reproductivo": "confirmada_gestante"}	postgres	981ed2cffcd1a03110d29f9bfbcb553fe8a8d51ebacb0510818f6ae33beaf957
3	2026-05-31 19:52:02.18229+00	animales	INSERT	0d506129-b7c5-507a-88ca-242344baa5de	\N	{"id": "0d506129-b7c5-507a-88ca-242344baa5de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 3", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-28", "crotal_oficial": "ES2706500003", "fecha_nacimiento": "2020-05-29", "estado_reproductivo": "parto_reciente"}	postgres	a58384bcc1904e1f1bea24542b20058849ec7d157e5831e6de40adcdfc31c944
4	2026-05-31 19:52:02.18229+00	animales	INSERT	73956a35-c183-5c88-9b6e-827903fe0241	\N	{"id": "73956a35-c183-5c88-9b6e-827903fe0241", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 4", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-27", "crotal_oficial": "ES2706500004", "fecha_nacimiento": "2019-05-29", "estado_reproductivo": "vacia"}	postgres	a2d32f2f8bfc8f683f859bd1327d44be538d49e218d0835648a881913de841af
5	2026-05-31 19:52:02.18229+00	animales	INSERT	e287b4b8-1876-527c-8b7c-7fdf85c42709	\N	{"id": "e287b4b8-1876-527c-8b7c-7fdf85c42709", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 5", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-26", "crotal_oficial": "ES2706500005", "fecha_nacimiento": "2018-05-28", "estado_reproductivo": "inseminada"}	postgres	d544aac79d55cad84f6b6faa6e8deb44526a5d485661b764da45d4d0b2cde410
6	2026-05-31 19:52:02.18229+00	animales	INSERT	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	\N	{"id": "1a6e7a54-8774-52a6-896f-01a35b5cbc2d", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 6", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-25", "crotal_oficial": "ES2706500006", "fecha_nacimiento": "2023-05-26", "estado_reproductivo": "confirmada_gestante"}	postgres	f934a062889b2cdd97a082d260b2cfe3d60a6768d845fb3984d1a4a10b5eeaa5
7	2026-05-31 19:52:02.18229+00	animales	INSERT	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	\N	{"id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 7", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-24", "crotal_oficial": "ES2706500007", "fecha_nacimiento": "2022-05-25", "estado_reproductivo": "parto_reciente"}	postgres	ca654ec0bf944c15c511254f1b18367abbf952dad65b11295e9666dfab9e7633
8	2026-05-31 19:52:02.18229+00	animales	INSERT	3c97c346-b54c-5581-930e-f3264d6773ea	\N	{"id": "3c97c346-b54c-5581-930e-f3264d6773ea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-23", "crotal_oficial": "ES2706500008", "fecha_nacimiento": "2021-05-24", "estado_reproductivo": "vacia"}	postgres	ebf78f001c49067936f5479d195af6b6df4fe2275213eebdd088df6fd1fb13e3
9	2026-05-31 19:52:02.18229+00	animales	INSERT	936b78c4-7b89-5fcf-97f7-54f007674e36	\N	{"id": "936b78c4-7b89-5fcf-97f7-54f007674e36", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 9", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-22", "crotal_oficial": "ES2706500009", "fecha_nacimiento": "2020-05-23", "estado_reproductivo": "inseminada"}	postgres	ef9ae9bc33d95a938d16a1a9790dde6927f461754fb60db6498bd15e6ed6c556
10	2026-05-31 19:52:02.18229+00	animales	INSERT	cf17702f-f18b-553e-9294-67e671e66022	\N	{"id": "cf17702f-f18b-553e-9294-67e671e66022", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 10", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-21", "crotal_oficial": "ES2706500010", "fecha_nacimiento": "2019-05-23", "estado_reproductivo": "confirmada_gestante"}	postgres	689e09477da94f8b7e57ee29a196b47f2df7c5495d34e7f8ca8556a399254c4b
11	2026-05-31 19:52:02.18229+00	animales	INSERT	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	\N	{"id": "2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 11", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-20", "crotal_oficial": "ES2706500011", "fecha_nacimiento": "2018-05-22", "estado_reproductivo": "parto_reciente"}	postgres	2613fc58328d186d119959f3dc68dcc4b72e494de8edf2403137854280d9305f
12	2026-05-31 19:52:02.18229+00	animales	INSERT	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	\N	{"id": "e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 12", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-19", "crotal_oficial": "ES2706500012", "fecha_nacimiento": "2023-05-20", "estado_reproductivo": "vacia"}	postgres	332210b48d9bcfd63926fc5daaee6ed275dd156e9723a98b4b3fc15782c2da8e
13	2026-05-31 19:52:02.18229+00	animales	INSERT	d172a069-591a-55e4-89fc-32699f1d25c9	\N	{"id": "d172a069-591a-55e4-89fc-32699f1d25c9", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 13", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-18", "crotal_oficial": "ES2706500013", "fecha_nacimiento": "2022-05-19", "estado_reproductivo": "inseminada"}	postgres	a65422e590744469e16f6f872e23eed146316524999fa4bdd7e1f12335685f10
14	2026-05-31 19:52:02.18229+00	animales	INSERT	436a7ff2-5df5-51b1-a49f-179831808d47	\N	{"id": "436a7ff2-5df5-51b1-a49f-179831808d47", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 14", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-17", "crotal_oficial": "ES2706500014", "fecha_nacimiento": "2021-05-18", "estado_reproductivo": "confirmada_gestante"}	postgres	38f7252609e4b1ad7c4a0da6756aa0a403c9785f500139f4b38fba87088c8236
15	2026-05-31 19:52:02.18229+00	animales	INSERT	b5263713-2026-5bad-ae46-296dc48a39d3	\N	{"id": "b5263713-2026-5bad-ae46-296dc48a39d3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 15", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-16", "crotal_oficial": "ES2706500015", "fecha_nacimiento": "2020-05-17", "estado_reproductivo": "parto_reciente"}	postgres	16935ce10007f660eed0536ad22c340bdf9d6ed35e192093c004ff7d4aab8bce
16	2026-05-31 19:52:02.18229+00	animales	INSERT	62d38b4e-74e0-5f20-b66b-64efddec53b7	\N	{"id": "62d38b4e-74e0-5f20-b66b-64efddec53b7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 16", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-15", "crotal_oficial": "ES2706500016", "fecha_nacimiento": "2019-05-17", "estado_reproductivo": "vacia"}	postgres	909b2f331c60b989b247640c2dfefd4182f3861361ae0baac1be84670431791f
17	2026-05-31 19:52:02.18229+00	animales	INSERT	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	\N	{"id": "592b42b6-a0bc-52ed-8f7d-44a9ab00b455", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 17", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-14", "crotal_oficial": "ES2706500017", "fecha_nacimiento": "2018-05-16", "estado_reproductivo": "inseminada"}	postgres	9048d97de99362e550b4b4ed8916fffcd54fd5de5e2167ce775d56b7defd46c0
18	2026-05-31 19:52:02.18229+00	animales	INSERT	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	\N	{"id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 18", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-13", "crotal_oficial": "ES2706500018", "fecha_nacimiento": "2023-05-14", "estado_reproductivo": "confirmada_gestante"}	postgres	4cd2877e8d49e3b978f7b9eb2941d0b6c76b3e53bb50a8e37211e4defe0cb59c
19	2026-05-31 19:52:02.18229+00	animales	INSERT	df87133b-ee35-5f6c-982e-0b9e09ad3dea	\N	{"id": "df87133b-ee35-5f6c-982e-0b9e09ad3dea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 19", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-12", "crotal_oficial": "ES2706500019", "fecha_nacimiento": "2022-05-13", "estado_reproductivo": "parto_reciente"}	postgres	80f8912c340196e1d541a8266258b6f23f3991d87f80f4de30a326bdaf00e836
20	2026-05-31 19:52:02.18229+00	animales	INSERT	afe8a03e-b5f2-5013-9b65-26fc935d703f	\N	{"id": "afe8a03e-b5f2-5013-9b65-26fc935d703f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 20", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-11", "crotal_oficial": "ES2706500020", "fecha_nacimiento": "2021-05-12", "estado_reproductivo": "vacia"}	postgres	bdeae6ecaf6aa57ea7fc35c5614d4b86943160ba7ada5e8201add7fb02776303
21	2026-05-31 19:52:02.18229+00	animales	INSERT	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	\N	{"id": "e8761f6b-9037-5d8f-bca2-cd8caa3ab0af", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 21", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-10", "crotal_oficial": "ES2706500021", "fecha_nacimiento": "2020-05-11", "estado_reproductivo": "inseminada"}	postgres	7001b4295e4ffc6ff6c458bbe9749851087f88b98bcc16843c18ba058aa13d9a
22	2026-05-31 19:52:02.18229+00	animales	INSERT	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	\N	{"id": "5d712a13-ba73-5fb4-b4f1-1d2b15f2c988", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 22", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-09", "crotal_oficial": "ES2706500022", "fecha_nacimiento": "2019-05-11", "estado_reproductivo": "confirmada_gestante"}	postgres	7c65d90af6daf9bbbfaf23f813378bebdd308c9f466989445893e63e033d2483
23	2026-05-31 19:52:02.18229+00	animales	INSERT	1a1a57d7-fc16-5715-8133-35c906e0453a	\N	{"id": "1a1a57d7-fc16-5715-8133-35c906e0453a", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 23", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-08", "crotal_oficial": "ES2706500023", "fecha_nacimiento": "2018-05-10", "estado_reproductivo": "parto_reciente"}	postgres	6a8d20f9f052b92dbd5c53abe07c266a6a99278e7432e12361c79cca2469a5b5
24	2026-05-31 19:52:02.18229+00	animales	INSERT	4c13e989-899c-5d47-8988-380802d72f58	\N	{"id": "4c13e989-899c-5d47-8988-380802d72f58", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 24", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-07", "crotal_oficial": "ES2706500024", "fecha_nacimiento": "2023-05-08", "estado_reproductivo": "vacia"}	postgres	80e6b61a8c4cc7f91b5d0dd62cca51e1b42e38b76f5646590780c75e6f377d5c
25	2026-05-31 19:52:02.18229+00	animales	INSERT	784ed9c6-39d3-5da9-b379-311aca240fdd	\N	{"id": "784ed9c6-39d3-5da9-b379-311aca240fdd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 25", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-06", "crotal_oficial": "ES2706500025", "fecha_nacimiento": "2022-05-07", "estado_reproductivo": "inseminada"}	postgres	20bdc635795c0e66059e761a4009c27dda613684c67b017e1fb2d6471c99ebb8
26	2026-05-31 19:52:02.18229+00	animales	INSERT	46e29b13-6344-5b6d-8471-0891456bd85b	\N	{"id": "46e29b13-6344-5b6d-8471-0891456bd85b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 26", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-05", "crotal_oficial": "ES2706500026", "fecha_nacimiento": "2021-05-06", "estado_reproductivo": "confirmada_gestante"}	postgres	ed1c0180d79f288e55e4f1454d3c505e6796092ceda7986ee92088e3df5b912b
27	2026-05-31 19:52:02.18229+00	animales	INSERT	20cb75da-56ec-50b5-85f8-792b0d74f745	\N	{"id": "20cb75da-56ec-50b5-85f8-792b0d74f745", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 27", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-04", "crotal_oficial": "ES2706500027", "fecha_nacimiento": "2020-05-05", "estado_reproductivo": "parto_reciente"}	postgres	cbc0c486e11a13f6bd7feb41f52f9727adc24c6c35c31acd70f53e1f51102698
28	2026-05-31 19:52:02.18229+00	animales	INSERT	1c069679-3e6d-5b3e-8842-c27c074da0a0	\N	{"id": "1c069679-3e6d-5b3e-8842-c27c074da0a0", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 28", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-03", "crotal_oficial": "ES2706500028", "fecha_nacimiento": "2019-05-05", "estado_reproductivo": "vacia"}	postgres	d8be50ee97f7b07fcb8ce2fc5526da814781160ba59147ac22264e84634668f0
29	2026-05-31 19:52:02.18229+00	animales	INSERT	fae53a98-6313-583b-8c58-8e81fe950f6e	\N	{"id": "fae53a98-6313-583b-8c58-8e81fe950f6e", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 29", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-02", "crotal_oficial": "ES2706500029", "fecha_nacimiento": "2018-05-04", "estado_reproductivo": "inseminada"}	postgres	4451fdc99f38144e9795458f0a9f199f91e09502b57d6a9bfd22ce9e712fbe16
30	2026-05-31 19:52:02.18229+00	animales	INSERT	eeded079-9abf-5844-8559-6eea890a6fe4	\N	{"id": "eeded079-9abf-5844-8559-6eea890a6fe4", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 30", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-01", "crotal_oficial": "ES2706500030", "fecha_nacimiento": "2023-05-02", "estado_reproductivo": "confirmada_gestante"}	postgres	e372f82f7c101d0c7a40a507122e908de3a44582357d5e0d3837328a8c60e962
31	2026-05-31 19:52:02.18229+00	animales	INSERT	674f97b3-f5f9-5ead-bf6c-d743870ba36f	\N	{"id": "674f97b3-f5f9-5ead-bf6c-d743870ba36f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 31", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-30", "crotal_oficial": "ES2706500031", "fecha_nacimiento": "2022-05-01", "estado_reproductivo": "parto_reciente"}	postgres	c34699e4d94f440641dfcf36ab09330c6de5b0e71e3745e2a222ac5067d2346b
32	2026-05-31 19:52:02.18229+00	animales	INSERT	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	\N	{"id": "0f5350db-fd30-58b4-bf08-ae0b3ca94afd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 32", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-29", "crotal_oficial": "ES2706500032", "fecha_nacimiento": "2021-04-30", "estado_reproductivo": "vacia"}	postgres	e92c18a071e1f8904b523d53218514e08e57e56b3de901243443fcaed6f8fec1
33	2026-05-31 19:52:02.18229+00	animales	INSERT	3f9aca1c-2859-5e86-909b-fe2777f960ca	\N	{"id": "3f9aca1c-2859-5e86-909b-fe2777f960ca", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 33", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-28", "crotal_oficial": "ES2706500033", "fecha_nacimiento": "2020-04-29", "estado_reproductivo": "inseminada"}	postgres	4b7306ce77953d19f3eb9b77ca5329d790d1e4211cbe8cd89891129df3b3ab43
34	2026-05-31 19:52:02.18229+00	animales	INSERT	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	\N	{"id": "9baa72c1-9b94-594b-8926-8a3c17ee9ac7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 34", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-27", "crotal_oficial": "ES2706500034", "fecha_nacimiento": "2019-04-29", "estado_reproductivo": "confirmada_gestante"}	postgres	56c614de082bb83c2bd1f27af2c9e855fce9a2000618f3ea0d9d3905d5e9844b
35	2026-05-31 19:52:02.18229+00	animales	INSERT	ac52e314-03fc-5fc7-95c8-e51551ffca78	\N	{"id": "ac52e314-03fc-5fc7-95c8-e51551ffca78", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 35", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-26", "crotal_oficial": "ES2706500035", "fecha_nacimiento": "2018-04-28", "estado_reproductivo": "parto_reciente"}	postgres	532aa2cc94dce0ae9cc33dabd51e8ef207bcb85174fa80fe86e5d259c7dd1a5a
36	2026-05-31 19:52:02.18229+00	animales	INSERT	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	\N	{"id": "bb9fc07f-076f-5182-93d0-8eb2ece1ee89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 36", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-25", "crotal_oficial": "ES2706500036", "fecha_nacimiento": "2023-04-26", "estado_reproductivo": "vacia"}	postgres	ed45af0dd647060d4cc258288781e45eb38df315e50d8546386be9fc49546330
37	2026-05-31 19:52:02.18229+00	animales	INSERT	6b224987-9434-5637-a871-9ac01fd4d4c3	\N	{"id": "6b224987-9434-5637-a871-9ac01fd4d4c3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-24", "crotal_oficial": "ES2706500037", "fecha_nacimiento": "2022-04-25", "estado_reproductivo": "inseminada"}	postgres	b6f616c1fd21e0eaa5dadd1287eb825a908bba2062a79a530f0de00f573cb228
38	2026-05-31 19:52:02.18229+00	animales	INSERT	abe64d55-ec3c-53f6-8051-84c8f56b51d5	\N	{"id": "abe64d55-ec3c-53f6-8051-84c8f56b51d5", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 38", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-23", "crotal_oficial": "ES2706500038", "fecha_nacimiento": "2021-04-24", "estado_reproductivo": "confirmada_gestante"}	postgres	394d166f0095c25f3e0d6dc043ba114f69c84614db1a2b701fc401d232f30faa
39	2026-05-31 19:52:02.18229+00	animales	INSERT	2e14a84a-511d-5bcf-867c-216522289b1c	\N	{"id": "2e14a84a-511d-5bcf-867c-216522289b1c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 39", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-22", "crotal_oficial": "ES2706500039", "fecha_nacimiento": "2020-04-23", "estado_reproductivo": "parto_reciente"}	postgres	fc12ee585cc1a2dc3e484dd8b45d408154cfc481159e43e01bf20a8d110178ed
40	2026-05-31 19:52:02.18229+00	animales	INSERT	bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7	\N	{"id": "bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 40", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-21", "crotal_oficial": "ES2706500040", "fecha_nacimiento": "2019-04-23", "estado_reproductivo": "vacia"}	postgres	b87068fa92a39f168b4ebaa9574c84d7d9d58c379cd1790d6fb58aa52a603e5e
41	2026-05-31 19:52:02.18229+00	animales	INSERT	2a91fb61-47ee-5001-a3e6-0e56c0f91308	\N	{"id": "2a91fb61-47ee-5001-a3e6-0e56c0f91308", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 41", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-20", "crotal_oficial": "ES2706500041", "fecha_nacimiento": "2018-04-22", "estado_reproductivo": "inseminada"}	postgres	6e651fd2f9876438f8dd32f7c2cb3c8db6e86d3098ecefb61180b98909dd2e8d
42	2026-05-31 19:52:02.18229+00	animales	INSERT	df02d6c2-f792-565d-ac97-d358d7484092	\N	{"id": "df02d6c2-f792-565d-ac97-d358d7484092", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 42", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-19", "crotal_oficial": "ES2706500042", "fecha_nacimiento": "2023-04-20", "estado_reproductivo": "confirmada_gestante"}	postgres	2c650cb7d036f07933fa656895704cf37d5f5d3687fa5c31d2af9342e0927720
43	2026-05-31 19:52:02.18229+00	animales	INSERT	78f6b86f-6d19-50c5-a003-4cf0c0c02e22	\N	{"id": "78f6b86f-6d19-50c5-a003-4cf0c0c02e22", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 43", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-18", "crotal_oficial": "ES2706500043", "fecha_nacimiento": "2022-04-19", "estado_reproductivo": "parto_reciente"}	postgres	ddb0bce09d10992400ad8e65434b470657239eb6e2906cad4f07ca622a78b407
44	2026-05-31 19:52:02.18229+00	animales	INSERT	c06ec15f-7d13-5837-b7c2-0b8b8465b3c1	\N	{"id": "c06ec15f-7d13-5837-b7c2-0b8b8465b3c1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 44", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-17", "crotal_oficial": "ES2706500044", "fecha_nacimiento": "2021-04-18", "estado_reproductivo": "vacia"}	postgres	a71ad7a0098d9f045f7ddcf682d71b7fdc2798a73e2cd3a87d0f220720ada5f9
45	2026-05-31 19:52:02.18229+00	animales	INSERT	0238f86f-4409-54d4-b4eb-0d28d7b4af0c	\N	{"id": "0238f86f-4409-54d4-b4eb-0d28d7b4af0c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 45", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-16", "crotal_oficial": "ES2706500045", "fecha_nacimiento": "2020-04-17", "estado_reproductivo": "inseminada"}	postgres	5809147743d51615d3f6f5b9e44d55d69d10715b43dcb934a3d8576a50726ff4
46	2026-05-31 19:52:02.18229+00	animales	INSERT	c9303516-f788-5f46-90dd-bb82d7023d71	\N	{"id": "c9303516-f788-5f46-90dd-bb82d7023d71", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 46", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-15", "crotal_oficial": "ES2706500046", "fecha_nacimiento": "2019-04-17", "estado_reproductivo": "confirmada_gestante"}	postgres	a2735072dd731688c2cbe4ccc26957be4ea7afc8737f12b9b9710c9064af43ed
47	2026-05-31 19:52:02.18229+00	animales	INSERT	a306664d-4e62-530d-8fe8-28ebfce56181	\N	{"id": "a306664d-4e62-530d-8fe8-28ebfce56181", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 47", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-14", "crotal_oficial": "ES2706500047", "fecha_nacimiento": "2018-04-16", "estado_reproductivo": "parto_reciente"}	postgres	aa70406bc7f8fead3f09d97f43841c54739253b0eafa9f52db303a282b163d40
48	2026-05-31 19:52:02.18229+00	animales	INSERT	ab19f1c4-775c-5f7d-8fad-c7b0cea81217	\N	{"id": "ab19f1c4-775c-5f7d-8fad-c7b0cea81217", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 48", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-13", "crotal_oficial": "ES2706500048", "fecha_nacimiento": "2023-04-14", "estado_reproductivo": "vacia"}	postgres	bd6d9f04afbf8e9cc662ae082c9333a239f7709ec259ec57c9d856748dac8bbc
49	2026-05-31 19:52:02.18229+00	animales	INSERT	9a533fa2-4f96-500a-af83-80da01f2370d	\N	{"id": "9a533fa2-4f96-500a-af83-80da01f2370d", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 49", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-12", "crotal_oficial": "ES2706500049", "fecha_nacimiento": "2022-04-13", "estado_reproductivo": "inseminada"}	postgres	6a4bdade2b773f8c0ff1ed8416820be0c7904e73dc6b9ed491dad13d223e8ef9
50	2026-05-31 19:52:02.18229+00	animales	INSERT	0db75e34-604b-511f-8aea-4156fe8eb5d1	\N	{"id": "0db75e34-604b-511f-8aea-4156fe8eb5d1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 50", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-11", "crotal_oficial": "ES2706500050", "fecha_nacimiento": "2021-04-12", "estado_reproductivo": "confirmada_gestante"}	postgres	ee988a1642b358e514e72f47ed087c2f015ba8076a38bfae098800362d12f474
51	2026-05-31 19:52:02.18229+00	animales	INSERT	1cb96771-c7de-53e3-b737-2954be5a71de	\N	{"id": "1cb96771-c7de-53e3-b737-2954be5a71de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 51", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-10", "crotal_oficial": "ES2706500051", "fecha_nacimiento": "2020-04-11", "estado_reproductivo": "parto_reciente"}	postgres	c1d984849a5134dc7ca5764da60bc0f49730b2200fca1a58004df7b933dbe78b
52	2026-05-31 19:52:02.18229+00	animales	INSERT	7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6	\N	{"id": "7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 52", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-09", "crotal_oficial": "ES2706500052", "fecha_nacimiento": "2019-04-11", "estado_reproductivo": "vacia"}	postgres	043d4b2c786629b2989bb7e86255a9569a4cc00a987e4cec69fa21ddc5dd3525
53	2026-05-31 19:52:02.18229+00	animales	INSERT	b7e68ca6-a516-52f8-9a88-8f272749ac23	\N	{"id": "b7e68ca6-a516-52f8-9a88-8f272749ac23", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 53", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-08", "crotal_oficial": "ES2706500053", "fecha_nacimiento": "2018-04-10", "estado_reproductivo": "inseminada"}	postgres	4dd55fb0be37f15cba23761f39dd0804375ccebee5d30e2e2e38e523539c9482
54	2026-05-31 19:52:02.18229+00	animales	INSERT	329e2c29-366f-56b0-b854-ca7cb56bff5f	\N	{"id": "329e2c29-366f-56b0-b854-ca7cb56bff5f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 54", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-07", "crotal_oficial": "ES2706500054", "fecha_nacimiento": "2023-04-08", "estado_reproductivo": "confirmada_gestante"}	postgres	57dae34af4d68240fc74940886e7cfa4fecba5a18fc10263f216f2c97051dbf0
55	2026-05-31 19:52:02.18229+00	animales	INSERT	9144858f-31c8-575d-a0ae-366e1d2935fd	\N	{"id": "9144858f-31c8-575d-a0ae-366e1d2935fd", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 55", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-06", "crotal_oficial": "ES2706500055", "fecha_nacimiento": "2022-04-07", "estado_reproductivo": "parto_reciente"}	postgres	c29d5e86e721667a929babaffaeab24cb13b1c7c8c6c871ca6244d91b18db999
56	2026-05-31 19:52:02.18229+00	animales	INSERT	ab624830-c14c-5b1a-afcc-f0b59876050a	\N	{"id": "ab624830-c14c-5b1a-afcc-f0b59876050a", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 56", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-05", "crotal_oficial": "ES2706500056", "fecha_nacimiento": "2021-04-06", "estado_reproductivo": "vacia"}	postgres	9e1519353741a27b4e294e0c857d7e2e3781fbf1f1a84b26a61284fa5f97d4a9
57	2026-05-31 19:52:02.18229+00	animales	INSERT	798cfeb1-fa83-529d-b119-c7f5cd60f5cd	\N	{"id": "798cfeb1-fa83-529d-b119-c7f5cd60f5cd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 57", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-04", "crotal_oficial": "ES2706500057", "fecha_nacimiento": "2020-04-05", "estado_reproductivo": "inseminada"}	postgres	a0d7b01dc6a419f5772f8dfdc6ee34622bc5555c9e10901c8f2f223ac552f0b0
58	2026-05-31 19:52:02.18229+00	animales	INSERT	a3c69881-650f-5671-9ae6-8371fb892b89	\N	{"id": "a3c69881-650f-5671-9ae6-8371fb892b89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 58", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-03", "crotal_oficial": "ES2706500058", "fecha_nacimiento": "2019-04-05", "estado_reproductivo": "confirmada_gestante"}	postgres	abcfa05e0222e785f0f4a056819bc75da1e7c643440803a251fd8ed71696cbcb
59	2026-05-31 19:52:02.18229+00	animales	INSERT	0f7ff532-8875-5404-8a53-3c204bdf55e1	\N	{"id": "0f7ff532-8875-5404-8a53-3c204bdf55e1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Noa 59", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-02", "crotal_oficial": "ES2706500059", "fecha_nacimiento": "2018-04-04", "estado_reproductivo": "confirmada_gestante"}	postgres	ff0c76a605830d260f53ce37b62fd1115b50ec77488365462dfb4c6d89af68d3
60	2026-05-31 19:52:02.18229+00	animales	INSERT	1f8d73e0-6258-536a-bb01-0fcdd4b96b26	\N	{"id": "1f8d73e0-6258-536a-bb01-0fcdd4b96b26", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Luna 60", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-01", "crotal_oficial": "ES2706500060", "fecha_nacimiento": "2022-04-02", "estado_reproductivo": "confirmada_gestante"}	postgres	7b60b8420599cb9c0875a99e8c655b969f5bfbdb9db12a68a8d9137fa9e4bf04
61	2026-05-31 19:52:02.18229+00	animales	INSERT	5dc5cac3-6bb9-5d56-957b-7677c4bcc56b	\N	{"id": "5dc5cac3-6bb9-5d56-957b-7677c4bcc56b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nube 61", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-31", "crotal_oficial": "ES2706500061", "fecha_nacimiento": "2021-04-01", "estado_reproductivo": "confirmada_gestante"}	postgres	dbebe959b312e345437e54b979839035e1a2047caa1019465500e8378a328c08
62	2026-05-31 19:52:02.18229+00	animales	INSERT	12ba4d63-24a9-5f3c-9204-99590678f5ed	\N	{"id": "12ba4d63-24a9-5f3c-9204-99590678f5ed", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Brisa 62", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-30", "crotal_oficial": "ES2706500062", "fecha_nacimiento": "2020-03-31", "estado_reproductivo": "confirmada_gestante"}	postgres	002cc76fa3477463b98ef9340577d4f4f6f47dad7a5f535a97dd06d613da7dd4
63	2026-05-31 19:52:02.18229+00	animales	INSERT	09065fbe-c2e5-500a-93cc-5f9f55d9f114	\N	{"id": "09065fbe-c2e5-500a-93cc-5f9f55d9f114", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Mora 63", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-29", "crotal_oficial": "ES2706500063", "fecha_nacimiento": "2019-03-31", "estado_reproductivo": "confirmada_gestante"}	postgres	0128a5e1ea84d60181c39e4e640341ef39914c61ab4cf34d87f08009ac99b5b7
64	2026-05-31 19:52:02.18229+00	animales	INSERT	5dbdee66-af90-503d-b6c5-b428cebb2b91	\N	{"id": "5dbdee66-af90-503d-b6c5-b428cebb2b91", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Dalia 64", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-28", "crotal_oficial": "ES2706500064", "fecha_nacimiento": "2018-03-30", "estado_reproductivo": "confirmada_gestante"}	postgres	d78add383352894027df7a26145969d7a1c1f556d7f22b2da73165cc5eb40097
65	2026-05-31 19:52:02.18229+00	animales	INSERT	5c888535-5880-5f6c-b53c-128c9df5464b	\N	{"id": "5c888535-5880-5f6c-b53c-128c9df5464b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Vega 65", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-27", "crotal_oficial": "ES2706500065", "fecha_nacimiento": "2022-03-28", "estado_reproductivo": "confirmada_gestante"}	postgres	c83e00614950bbdd4ef89a046753f5cba9061afb27e0b8f74ea3f9623aa8a322
66	2026-05-31 19:52:02.18229+00	animales	INSERT	963164ac-9734-5fd9-bd3a-fc7dacff84e1	\N	{"id": "963164ac-9734-5fd9-bd3a-fc7dacff84e1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Senda 66", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-26", "crotal_oficial": "ES2706500066", "fecha_nacimiento": "2021-03-27", "estado_reproductivo": "confirmada_gestante"}	postgres	7b76fb8be2546e5a7749e4a710c3aa688d62fbac41dba639d563cc6047d55a2b
67	2026-05-31 19:52:02.18229+00	animales	INSERT	ffe82114-3a26-5e7b-8ce6-7a8ef2f12732	\N	{"id": "ffe82114-3a26-5e7b-8ce6-7a8ef2f12732", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Cora 67", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-25", "crotal_oficial": "ES2706500067", "fecha_nacimiento": "2020-03-26", "estado_reproductivo": "confirmada_gestante"}	postgres	00acead4d37f81093ce8dc574716d45a65896e56ca163633b648214b5c43ad63
68	2026-05-31 19:52:02.18229+00	animales	INSERT	efc8bf74-ef7d-5152-a4d4-a077ae7a7d52	\N	{"id": "efc8bf74-ef7d-5152-a4d4-a077ae7a7d52", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nora 68", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-24", "crotal_oficial": "ES2706500068", "fecha_nacimiento": "2019-03-26", "estado_reproductivo": "confirmada_gestante"}	postgres	b9dd01cdf911de95f1b3837d7587b110d70cb2cf9cc89171c5a4e5871a3b0b41
69	2026-05-31 19:52:02.18229+00	animales	INSERT	27ba2d06-b334-5f7c-bd59-ba67cf095d68	\N	{"id": "27ba2d06-b334-5f7c-bd59-ba67cf095d68", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Oliva 69", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-23", "crotal_oficial": "ES2706500069", "fecha_nacimiento": "2018-03-25", "estado_reproductivo": "confirmada_gestante"}	postgres	00b237657fb1d15e514160175b15fd50176b527fd0a4255ebbdfa1cadea97271
70	2026-05-31 19:52:02.18229+00	animales	INSERT	389f3969-2148-5055-82d6-166a20ab6a9b	\N	{"id": "389f3969-2148-5055-82d6-166a20ab6a9b", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Xiana 70", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-22", "crotal_oficial": "ES2706500070", "fecha_nacimiento": "2022-03-23", "estado_reproductivo": "confirmada_gestante"}	postgres	69ffc4a04c08e7ee6bc0c1a24a3c4c3f8544c7014bb556c548a00f5b59c2fdee
71	2026-05-31 19:52:02.18229+00	animales	INSERT	100ab0c5-a993-504e-90af-c6d7f59f072f	\N	{"id": "100ab0c5-a993-504e-90af-c6d7f59f072f", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Noa 71", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-21", "crotal_oficial": "ES2706500071", "fecha_nacimiento": "2025-01-25", "estado_reproductivo": "inseminada"}	postgres	224870355eaa701c6e48dfb3b0ec1eaf7bbe3600c08501ddf4debca5c3222d99
72	2026-05-31 19:52:02.18229+00	animales	INSERT	ba1837f5-ce8f-55d5-a7c1-f75e574eac0f	\N	{"id": "ba1837f5-ce8f-55d5-a7c1-f75e574eac0f", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Luna 72", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-20", "crotal_oficial": "ES2706500072", "fecha_nacimiento": "2025-01-24", "estado_reproductivo": "inseminada"}	postgres	d1f74aeb6a2e88c2fb3edd550ac3b250898881eef58df9394ed56263b250feca
73	2026-05-31 19:52:02.18229+00	animales	INSERT	f4edf01d-3029-53e1-95e5-876c6e613901	\N	{"id": "f4edf01d-3029-53e1-95e5-876c6e613901", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Nube 73", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-19", "crotal_oficial": "ES2706500073", "fecha_nacimiento": "2025-01-23", "estado_reproductivo": "inseminada"}	postgres	6c7fc06447963878e55ebc33f5c7dd154dc7cae1d774c8d87d48591edc316f3f
74	2026-05-31 19:52:02.18229+00	animales	INSERT	a0842a46-290f-564e-b305-cadd12a663e4	\N	{"id": "a0842a46-290f-564e-b305-cadd12a663e4", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Brisa 74", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-18", "crotal_oficial": "ES2706500074", "fecha_nacimiento": "2025-01-22", "estado_reproductivo": "inseminada"}	postgres	1721895da13a8e802046ba21947e143301275e36d38e0f540dc1bd8fca466db4
75	2026-05-31 19:52:02.18229+00	animales	INSERT	d310c7c4-c400-5688-b908-536055d69bad	\N	{"id": "d310c7c4-c400-5688-b908-536055d69bad", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Mora 75", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-17", "crotal_oficial": "ES2706500075", "fecha_nacimiento": "2025-01-21", "estado_reproductivo": "inseminada"}	postgres	777c3811a71f4edfbff796183750b66fb2fe4948ec927264b9a454876f7c2539
76	2026-05-31 19:52:02.18229+00	animales	INSERT	c02339ca-c4bc-5afb-b0ab-bb4beb783997	\N	{"id": "c02339ca-c4bc-5afb-b0ab-bb4beb783997", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Dalia 76", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-16", "crotal_oficial": "ES2706500076", "fecha_nacimiento": "2025-01-20", "estado_reproductivo": "inseminada"}	postgres	6de7703969c9b7b2108b9f0d11027308e06b8ee08b4129145f5f4f637b274c09
77	2026-05-31 19:52:02.18229+00	animales	INSERT	58c0f921-4cc5-5ae0-a3b0-cbcc31f21719	\N	{"id": "58c0f921-4cc5-5ae0-a3b0-cbcc31f21719", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Vega 77", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-15", "crotal_oficial": "ES2706500077", "fecha_nacimiento": "2025-01-19", "estado_reproductivo": "inseminada"}	postgres	5e6740523a1fccacdcf84bc81af953e1e0040176542afc156a6c47a4eeefe11f
78	2026-05-31 19:52:02.18229+00	animales	INSERT	759a20cb-11da-5d54-a6ef-e82e1d84280e	\N	{"id": "759a20cb-11da-5d54-a6ef-e82e1d84280e", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Senda 78", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-14", "crotal_oficial": "ES2706500078", "fecha_nacimiento": "2025-01-18", "estado_reproductivo": "inseminada"}	postgres	dbe4d9be06d6fd338525ad1ed46e6553542533224d5f6cf8231aa50832b737a8
79	2026-05-31 19:52:02.18229+00	animales	INSERT	3e349a4d-3389-5173-adfb-07c3b16e00c2	\N	{"id": "3e349a4d-3389-5173-adfb-07c3b16e00c2", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Cora 79", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-13", "crotal_oficial": "ES2706500079", "fecha_nacimiento": "2025-01-17", "estado_reproductivo": "inseminada"}	postgres	85581145ae6e880f5822b0babaa8f23581135a025c593c8b7c3dd3bb8a5acef4
80	2026-05-31 19:52:02.18229+00	animales	INSERT	c4407964-453c-5725-81ed-26abc47257cd	\N	{"id": "c4407964-453c-5725-81ed-26abc47257cd", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Nora 80", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-31", "crotal_oficial": "ES2706500080", "fecha_nacimiento": "2025-01-16", "estado_reproductivo": "inseminada"}	postgres	8ba233f4d865945d019308ee16d3f2005e5fdae6404373af8c0efdd4b39e0cd0
81	2026-05-31 19:52:02.18229+00	animales	INSERT	74107440-00d6-58ee-ae41-82471d6b9aa4	\N	{"id": "74107440-00d6-58ee-ae41-82471d6b9aa4", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Oliva 81", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500081", "fecha_nacimiento": "2025-01-15", "estado_reproductivo": "inseminada"}	postgres	3e9f41e5b813597f727c1203ad31c8e3bff49b05f65d64b1d4c685f758a1971e
82	2026-05-31 19:52:02.18229+00	animales	INSERT	7234f761-7764-5891-8b85-d3e4ca2db7ff	\N	{"id": "7234f761-7764-5891-8b85-d3e4ca2db7ff", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Xiana 82", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-29", "crotal_oficial": "ES2706500082", "fecha_nacimiento": "2025-01-14", "estado_reproductivo": "inseminada"}	postgres	cfee8cc39fe284735214215c502626ea88614e4b188c6d279dd770464db4a104
83	2026-05-31 19:52:02.18229+00	animales	INSERT	19eeaa52-2c8b-5e63-ace0-ef1ec00d6da9	\N	{"id": "19eeaa52-2c8b-5e63-ace0-ef1ec00d6da9", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Noa 83", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-08", "crotal_oficial": "ES2706500083", "fecha_nacimiento": "2026-02-12", "estado_reproductivo": null}	postgres	e5a6b647ae8cce7dbd2b5522cd700e17d4e9ea587758cf2976a636e482130b1b
84	2026-05-31 19:52:02.18229+00	animales	INSERT	70a72a01-c51c-5511-b0ee-276eeec0db42	\N	{"id": "70a72a01-c51c-5511-b0ee-276eeec0db42", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Luna 84", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-07", "crotal_oficial": "ES2706500084", "fecha_nacimiento": "2026-02-11", "estado_reproductivo": null}	postgres	e9443eba40f73d34054130e90ca20d30f132f78e6daf0606f4c28c9a80883bb7
85	2026-05-31 19:52:02.18229+00	animales	INSERT	a4774bd3-5ee0-54bc-8fb8-cf5df0b3bd89	\N	{"id": "a4774bd3-5ee0-54bc-8fb8-cf5df0b3bd89", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Nube 85", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-06", "crotal_oficial": "ES2706500085", "fecha_nacimiento": "2026-02-10", "estado_reproductivo": null}	postgres	b38bdb503cf8cd2b21383746d715b205cd118a21fe352c9ea059e25603106298
86	2026-05-31 19:52:02.18229+00	animales	INSERT	7aaf1f29-d947-5361-9119-50eed5155dcc	\N	{"id": "7aaf1f29-d947-5361-9119-50eed5155dcc", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Brisa 86", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-05", "crotal_oficial": "ES2706500086", "fecha_nacimiento": "2026-02-09", "estado_reproductivo": null}	postgres	f5a7fd996bb32577eb3ad41f034a5abe2cb10eab38e85ec8084f7048a0efc432
87	2026-05-31 19:52:02.18229+00	animales	INSERT	f8f9284b-2242-54c3-9435-e9a2db95edef	\N	{"id": "f8f9284b-2242-54c3-9435-e9a2db95edef", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Mora 87", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-04", "crotal_oficial": "ES2706500087", "fecha_nacimiento": "2026-02-08", "estado_reproductivo": null}	postgres	1c33f7cf7de74ecba7ef9d818780448ea215664e3937c45c47d286ebc9f410c9
88	2026-05-31 19:52:02.18229+00	animales	INSERT	231e6267-606a-5595-92e1-a74dc7a9580e	\N	{"id": "231e6267-606a-5595-92e1-a74dc7a9580e", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Dalia 88", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-03", "crotal_oficial": "ES2706500088", "fecha_nacimiento": "2026-02-07", "estado_reproductivo": null}	postgres	db29ef224cb833cc864cb12d5f616d886ef6378505c7874ebae267e0d51ef54a
89	2026-05-31 19:52:02.18229+00	animales	INSERT	874a44ba-01b6-5641-a7a8-14b3adbaa35a	\N	{"id": "874a44ba-01b6-5641-a7a8-14b3adbaa35a", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Vega 89", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-02", "crotal_oficial": "ES2706500089", "fecha_nacimiento": "2026-02-06", "estado_reproductivo": null}	postgres	c4cf4070e15d46a329e378bf382898b5915cb986edbb48a778d55875d42c4c2d
90	2026-05-31 19:52:02.18229+00	animales	INSERT	0faa59c0-c0fc-5b47-803d-44e925588a03	\N	{"id": "0faa59c0-c0fc-5b47-803d-44e925588a03", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Senda 90", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-01", "crotal_oficial": "ES2706500090", "fecha_nacimiento": "2026-05-06", "estado_reproductivo": null}	postgres	f7bf60f0e117beffa38b1318169be9297a05071494c0f696c66435e5e26c675a
91	2026-05-31 19:52:02.18229+00	animales	INSERT	edf24324-814b-56b2-8b5d-c214ff93fad4	\N	{"id": "edf24324-814b-56b2-8b5d-c214ff93fad4", "raza": "Cruce Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Cora 91", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-30", "crotal_oficial": "ES2706500091", "fecha_nacimiento": "2026-05-05", "estado_reproductivo": null}	postgres	279d39b8d8d8a4eda9d10290d7cea8f88d4fc77cfab37bfd014356eeaf88cac7
92	2026-05-31 19:52:02.18229+00	animales	INSERT	9b62d7c9-5d36-53f7-b27d-5699ce5c52e4	\N	{"id": "9b62d7c9-5d36-53f7-b27d-5699ce5c52e4", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Nora 92", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-29", "crotal_oficial": "ES2706500092", "fecha_nacimiento": "2026-05-04", "estado_reproductivo": null}	postgres	0cd9aa73eab4f88e45652ac90eff2436ee6b517da567cca2038b10ff2c7e2d7c
93	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	97682f5a-49f4-53bf-8a08-4846ba0468ed	\N	{"id": "97682f5a-49f4-53bf-8a08-4846ba0468ed", "coste": 45.00, "dosis": "20 ml/48h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Meloxicam", "resuelto": false, "animal_id": "d58fbf17-442e-5153-8cdf-ce264a40ef4f", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-23", "tipo_patologia": "cojera", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "subcutanea", "periodo_retirada_hasta": null}	postgres	7336d4553488fdd37c65c2b4ce0cac24cdb26d343fe30350a4d33e8c01a6b17f
94	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	ffdb5c2c-362d-59a5-9896-42ccfc261a9b	\N	{"id": "ffdb5c2c-362d-59a5-9896-42ccfc261a9b", "coste": 52.00, "dosis": "1 aplicacion/ordeno", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Penetamato", "resuelto": false, "animal_id": "c7ee8997-4bfb-56ca-9a3f-653af2d06595", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-20", "tipo_patologia": "metritis", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "oral", "periodo_retirada_hasta": null}	postgres	2bb2398eeed142f604e7914af052c93a66c0f3439615085499a5e7c6c4b810c6
95	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	b3a81c79-2168-5203-ba17-489b2d3f3ebf	\N	{"id": "b3a81c79-2168-5203-ba17-489b2d3f3ebf", "coste": 59.00, "dosis": "2 sobres/dia", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Florfenicol", "resuelto": true, "animal_id": "0d506129-b7c5-507a-88ca-242344baa5de", "fecha_fin": "2026-05-28", "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-17", "tipo_patologia": "neumonia", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramamaria", "periodo_retirada_hasta": null}	postgres	acf3abf472069932347b991975b73afc4038e5de86ad80e0eb92640c928ed191
96	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	b899078b-81a1-56c9-939d-7df708e3aa93	\N	{"id": "b899078b-81a1-56c9-939d-7df708e3aa93", "coste": 66.00, "dosis": "10 ml/24h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Electrolitos orales", "resuelto": false, "animal_id": "73956a35-c183-5c88-9b6e-827903fe0241", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-14", "tipo_patologia": "diarrea", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramuscular", "periodo_retirada_hasta": "2026-06-03"}	postgres	5fabe4b6bc659a75b27d7bf1ee0f4325763de0585fd8ffe139a2b511578a7b49
97	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	4eaa9f5b-8295-5d1b-a98e-2c285fdc855e	\N	{"id": "4eaa9f5b-8295-5d1b-a98e-2c285fdc855e", "coste": 73.00, "dosis": "20 ml/48h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Pomada intramamaria", "resuelto": false, "animal_id": "e287b4b8-1876-527c-8b7c-7fdf85c42709", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-11", "tipo_patologia": "otra", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "subcutanea", "periodo_retirada_hasta": null}	postgres	864bec354fbe4d8bdbe2c2a6d82e05f39f863160fa52a694caa8bf0722cd561c
98	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	e3df197e-24f9-5903-bda0-e6cf697f82ad	\N	{"id": "e3df197e-24f9-5903-bda0-e6cf697f82ad", "coste": 80.00, "dosis": "1 aplicacion/ordeno", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Ceftiofur", "resuelto": true, "animal_id": "1a6e7a54-8774-52a6-896f-01a35b5cbc2d", "fecha_fin": "2026-05-25", "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-08", "tipo_patologia": "mastitis", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "oral", "periodo_retirada_hasta": null}	postgres	b4981dfa9682ba6a5a92688de704fdf61b5e07e1e897f1aebb37acfe7bd1129b
99	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	ffb9c824-a985-514a-8076-44cd6d396e71	\N	{"id": "ffb9c824-a985-514a-8076-44cd6d396e71", "coste": 87.00, "dosis": "2 sobres/dia", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Meloxicam", "resuelto": false, "animal_id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-05", "tipo_patologia": "cojera", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramamaria", "periodo_retirada_hasta": null}	postgres	bc0eae945447fdbb6420d179d2e26536e839ce1a63212e03a866b525050c3e02
100	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	abf1ac0a-6bac-5db5-ab56-49868a5d113f	\N	{"id": "abf1ac0a-6bac-5db5-ab56-49868a5d113f", "coste": 94.00, "dosis": "10 ml/24h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Penetamato", "resuelto": false, "animal_id": "3c97c346-b54c-5581-930e-f3264d6773ea", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-05-02", "tipo_patologia": "metritis", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramuscular", "periodo_retirada_hasta": "2026-06-03"}	postgres	640fbd07d3bb9503245de62cabdce1b30dfc41669d76dbda8f84a8123add9212
101	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	99a4215a-c560-51b1-af22-f514c466e839	\N	{"id": "99a4215a-c560-51b1-af22-f514c466e839", "coste": 101.00, "dosis": "20 ml/48h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Florfenicol", "resuelto": true, "animal_id": "936b78c4-7b89-5fcf-97f7-54f007674e36", "fecha_fin": "2026-05-22", "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-29", "tipo_patologia": "neumonia", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "subcutanea", "periodo_retirada_hasta": null}	postgres	b7031a6fad21852758fcfd560fe96c40688480f14ef710023f6a4caf0f315f0b
102	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	58667dde-19dd-5418-9a1a-d6f7d2da1a6c	\N	{"id": "58667dde-19dd-5418-9a1a-d6f7d2da1a6c", "coste": 108.00, "dosis": "1 aplicacion/ordeno", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Electrolitos orales", "resuelto": false, "animal_id": "cf17702f-f18b-553e-9294-67e671e66022", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-26", "tipo_patologia": "diarrea", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "oral", "periodo_retirada_hasta": null}	postgres	43e1eda28a19c68b4d7e986d030eb481a0d58d3c7699f4719b21a2fdc15f3fee
103	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	025ae8e0-6852-5c50-828d-4196e9b8e8b9	\N	{"id": "025ae8e0-6852-5c50-828d-4196e9b8e8b9", "coste": 115.00, "dosis": "2 sobres/dia", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Pomada intramamaria", "resuelto": false, "animal_id": "2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-23", "tipo_patologia": "otra", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramamaria", "periodo_retirada_hasta": null}	postgres	245faaca2ff161f8c5a354cd6c7676eb1fbc494cf90db888f72c1dee211de06b
104	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	9dbc5471-3f77-5012-a9fa-00908a2fc64e	\N	{"id": "9dbc5471-3f77-5012-a9fa-00908a2fc64e", "coste": 122.00, "dosis": "10 ml/24h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Ceftiofur", "resuelto": true, "animal_id": "e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c", "fecha_fin": "2026-05-31", "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-20", "tipo_patologia": "mastitis", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramuscular", "periodo_retirada_hasta": "2026-06-03"}	postgres	71aaed652c8291e721de7532056a49d7f50bcd82b37d838897c256d9bb6700c0
105	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	fbb2ac4e-2d8e-5790-aea9-e7e6bc2b4d3b	\N	{"id": "fbb2ac4e-2d8e-5790-aea9-e7e6bc2b4d3b", "coste": 129.00, "dosis": "20 ml/48h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Meloxicam", "resuelto": false, "animal_id": "d172a069-591a-55e4-89fc-32699f1d25c9", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-17", "tipo_patologia": "cojera", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "subcutanea", "periodo_retirada_hasta": null}	postgres	f03e4312baaae42d3f83a0606feae2f24be810304799c7aed8cfef47bc2ad766
106	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	dd392fa1-af05-5a7c-9488-3aaaf47e736b	\N	{"id": "dd392fa1-af05-5a7c-9488-3aaaf47e736b", "coste": 136.00, "dosis": "1 aplicacion/ordeno", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Penetamato", "resuelto": false, "animal_id": "436a7ff2-5df5-51b1-a49f-179831808d47", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-14", "tipo_patologia": "metritis", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "oral", "periodo_retirada_hasta": null}	postgres	560c1ce0b9b44b4b89c238d3ca173d439fd253a1bfd6aac5a7f00dc3b391cdb4
107	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	bae52c71-c780-5c36-852b-44d7108c6e8d	\N	{"id": "bae52c71-c780-5c36-852b-44d7108c6e8d", "coste": 143.00, "dosis": "2 sobres/dia", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Florfenicol", "resuelto": true, "animal_id": "b5263713-2026-5bad-ae46-296dc48a39d3", "fecha_fin": "2026-05-28", "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-11", "tipo_patologia": "neumonia", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramamaria", "periodo_retirada_hasta": null}	postgres	77b31232583d4da7c6975ee0603456b56b94ebab63d74ee16b47804e6b52ce4f
108	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	1da930ee-2f7a-511c-8f8d-22b62a6e9a10	\N	{"id": "1da930ee-2f7a-511c-8f8d-22b62a6e9a10", "coste": 150.00, "dosis": "10 ml/24h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Electrolitos orales", "resuelto": false, "animal_id": "62d38b4e-74e0-5f20-b66b-64efddec53b7", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-08", "tipo_patologia": "diarrea", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "intramuscular", "periodo_retirada_hasta": "2026-06-03"}	postgres	02ee75ff2da7c0521ffaca8621f059b9743924d69c74fd5b9112fd0cb6620bae
109	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	25469cc9-5627-5fd0-9b8d-d9adca35b5e5	\N	{"id": "25469cc9-5627-5fd0-9b8d-d9adca35b5e5", "coste": 157.00, "dosis": "20 ml/48h", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Pomada intramamaria", "resuelto": false, "animal_id": "592b42b6-a0bc-52ed-8f7d-44a9ab00b455", "fecha_fin": null, "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-05", "tipo_patologia": "otra", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "subcutanea", "periodo_retirada_hasta": null}	postgres	d8d45c90630107afecda849d835dda8a245e84a9565b5929aa4dafdb6aa96626
110	2026-05-31 19:52:32.285005+00	eventos_sanitarios	INSERT	37eaf94b-dcf5-57f2-97a5-7186a9d3052e	\N	{"id": "37eaf94b-dcf5-57f2-97a5-7186a9d3052e", "coste": 164.00, "dosis": "1 aplicacion/ordeno", "notas": "Datos sanitarios realistas para demo funcional.", "farmaco": "Ceftiofur", "resuelto": true, "animal_id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "fecha_fin": "2026-05-25", "tratamiento": "Revision clinica y seguimiento segun protocolo de la explotacion.", "fecha_inicio": "2026-04-02", "tipo_patologia": "mastitis", "veterinario_id": "aed8c2c4-9620-5034-9248-d8564ee7addf", "via_administracion": "oral", "periodo_retirada_hasta": null}	postgres	38ce963d4a70af365ddf1a2ae834136ee8a235c5b6ca5e7931b746df61999b08
111	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	bcfd02e1-00ce-5946-9bf9-41a397f51af1	\N	{"id": "bcfd02e1-00ce-5946-9bf9-41a397f51af1", "dosis": "1 aplicacion/ordeno", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": false, "farmaco": "Ceftiofur", "animal_id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}], "fecha_inicio": "2026-04-02", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": "2026-05-25", "dias_tratamiento": 4, "fecha_fin_prevista": "2026-04-06", "via_administracion": "oral", "evento_sanitario_id": "37eaf94b-dcf5-57f2-97a5-7186a9d3052e"}	postgres	3fba906cafc53ca4840cf22bb9b0ade20e92984cc974a117b9fb01b2672a9220
112	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	b652b220-e16f-55ee-8799-49f39aabd197	\N	{"id": "b652b220-e16f-55ee-8799-49f39aabd197", "dosis": "20 ml/48h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Pomada intramamaria", "animal_id": "592b42b6-a0bc-52ed-8f7d-44a9ab00b455", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-04-05", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 5, "fecha_fin_prevista": "2026-04-10", "via_administracion": "subcutanea", "evento_sanitario_id": "25469cc9-5627-5fd0-9b8d-d9adca35b5e5"}	postgres	273e629c581268e745bfc3288fbe3a7e6a6232923e096fc903d90ca32e66c869
113	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	c1419622-5cfb-5cf3-9785-7ec7ea5c7edb	\N	{"id": "c1419622-5cfb-5cf3-9785-7ec7ea5c7edb", "dosis": "10 ml/24h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Electrolitos orales", "animal_id": "62d38b4e-74e0-5f20-b66b-64efddec53b7", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-04-08", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 6, "fecha_fin_prevista": "2026-04-14", "via_administracion": "intramuscular", "evento_sanitario_id": "1da930ee-2f7a-511c-8f8d-22b62a6e9a10"}	postgres	09be9af603e60a6ee6a444d522a3512cece368e8857a138d80bd5cf0b0fb3a93
114	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	2e0343fd-815b-5f76-adad-30e3cce4121b	\N	{"id": "2e0343fd-815b-5f76-adad-30e3cce4121b", "dosis": "2 sobres/dia", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": false, "farmaco": "Florfenicol", "animal_id": "b5263713-2026-5bad-ae46-296dc48a39d3", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}], "fecha_inicio": "2026-04-11", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": "2026-05-28", "dias_tratamiento": 7, "fecha_fin_prevista": "2026-04-18", "via_administracion": "intramamaria", "evento_sanitario_id": "bae52c71-c780-5c36-852b-44d7108c6e8d"}	postgres	aba200bb5a684ced66d271fcb47f18da1db5a57bda2c2168763d62423f324c90
115	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	f56a4ddc-7cae-55fb-bb6f-b7dba0bcf9e2	\N	{"id": "f56a4ddc-7cae-55fb-bb6f-b7dba0bcf9e2", "dosis": "1 aplicacion/ordeno", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Penetamato", "animal_id": "436a7ff2-5df5-51b1-a49f-179831808d47", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-04-14", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 3, "fecha_fin_prevista": "2026-04-17", "via_administracion": "oral", "evento_sanitario_id": "dd392fa1-af05-5a7c-9488-3aaaf47e736b"}	postgres	4fe0c9108f6aa98af2d22b6a45435261aef68ea8450188a3dd310daba2cfe48a
116	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	9f97f31d-022f-5ce7-890c-336f3613fad9	\N	{"id": "9f97f31d-022f-5ce7-890c-336f3613fad9", "dosis": "20 ml/48h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Meloxicam", "animal_id": "d172a069-591a-55e4-89fc-32699f1d25c9", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-04-17", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 4, "fecha_fin_prevista": "2026-04-21", "via_administracion": "subcutanea", "evento_sanitario_id": "fbb2ac4e-2d8e-5790-aea9-e7e6bc2b4d3b"}	postgres	f08639225ecc2b79934ef140401da066d88ee5998000465d95cdc89785058d93
117	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	3e2971b6-3c94-5f04-af3d-71aef66ba68c	\N	{"id": "3e2971b6-3c94-5f04-af3d-71aef66ba68c", "dosis": "10 ml/24h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": false, "farmaco": "Ceftiofur", "animal_id": "e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}], "fecha_inicio": "2026-04-20", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": "2026-05-31", "dias_tratamiento": 5, "fecha_fin_prevista": "2026-04-25", "via_administracion": "intramuscular", "evento_sanitario_id": "9dbc5471-3f77-5012-a9fa-00908a2fc64e"}	postgres	583d6a743ba83aebc5b36a20fe53b01444aa6a8555197101372ed419dc008cff
118	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	1369afe6-7cdc-531d-972e-29c2d977e4b0	\N	{"id": "1369afe6-7cdc-531d-972e-29c2d977e4b0", "dosis": "2 sobres/dia", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Pomada intramamaria", "animal_id": "2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-04-23", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 6, "fecha_fin_prevista": "2026-04-29", "via_administracion": "intramamaria", "evento_sanitario_id": "025ae8e0-6852-5c50-828d-4196e9b8e8b9"}	postgres	7ffd62a1ee40ae2b5107723fb90f2a5b536fc54d67059d980d29905956d52899
119	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	257cea2c-6850-55f3-b2ef-35408d1d7e99	\N	{"id": "257cea2c-6850-55f3-b2ef-35408d1d7e99", "dosis": "1 aplicacion/ordeno", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Electrolitos orales", "animal_id": "cf17702f-f18b-553e-9294-67e671e66022", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-04-26", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 7, "fecha_fin_prevista": "2026-05-03", "via_administracion": "oral", "evento_sanitario_id": "58667dde-19dd-5418-9a1a-d6f7d2da1a6c"}	postgres	a96cd228dae0b1c1fea4c7d4531b2914fb3a3cb0d378b85a3894761626a7a552
120	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	9a8f8203-f852-5be1-85db-4124ee0bca75	\N	{"id": "9a8f8203-f852-5be1-85db-4124ee0bca75", "dosis": "20 ml/48h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": false, "farmaco": "Florfenicol", "animal_id": "936b78c4-7b89-5fcf-97f7-54f007674e36", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}], "fecha_inicio": "2026-04-29", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": "2026-05-22", "dias_tratamiento": 3, "fecha_fin_prevista": "2026-05-02", "via_administracion": "subcutanea", "evento_sanitario_id": "99a4215a-c560-51b1-af22-f514c466e839"}	postgres	7fea0bb3a6fde99eb8e00ab373c95dd61e7ad3f2428745a265b1af75a11d065a
121	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	ee222de5-d26a-518b-8209-a267aca1e8b8	\N	{"id": "ee222de5-d26a-518b-8209-a267aca1e8b8", "dosis": "10 ml/24h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Penetamato", "animal_id": "3c97c346-b54c-5581-930e-f3264d6773ea", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-05-02", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 4, "fecha_fin_prevista": "2026-05-06", "via_administracion": "intramuscular", "evento_sanitario_id": "abf1ac0a-6bac-5db5-ab56-49868a5d113f"}	postgres	7fe17aa760e49fde391deaf0dfa761a18a086a848c3c5993f703072da640dc44
122	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	6f02881b-17a7-5b3c-9d7d-c76ca57abd11	\N	{"id": "6f02881b-17a7-5b3c-9d7d-c76ca57abd11", "dosis": "2 sobres/dia", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Meloxicam", "animal_id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-05-05", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 5, "fecha_fin_prevista": "2026-05-10", "via_administracion": "intramamaria", "evento_sanitario_id": "ffb9c824-a985-514a-8076-44cd6d396e71"}	postgres	59d52cd00e1a87a8aa3a1e0bea773b6e76daecc33642f8029f5b9415e21efe19
123	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	f81f166d-d2f0-5acb-9077-efeb1ab7ef5b	\N	{"id": "f81f166d-d2f0-5acb-9077-efeb1ab7ef5b", "dosis": "1 aplicacion/ordeno", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": false, "farmaco": "Ceftiofur", "animal_id": "1a6e7a54-8774-52a6-896f-01a35b5cbc2d", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}], "fecha_inicio": "2026-05-08", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": "2026-05-25", "dias_tratamiento": 6, "fecha_fin_prevista": "2026-05-14", "via_administracion": "oral", "evento_sanitario_id": "e3df197e-24f9-5903-bda0-e6cf697f82ad"}	postgres	44f69d61ae28a3c29d6fd01b3b1d372467e996d1a6f26b832465bc88b115a942
124	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	59692272-5b46-5cd9-be95-c50841c3d0f1	\N	{"id": "59692272-5b46-5cd9-be95-c50841c3d0f1", "dosis": "20 ml/48h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Pomada intramamaria", "animal_id": "e287b4b8-1876-527c-8b7c-7fdf85c42709", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-05-11", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 7, "fecha_fin_prevista": "2026-05-18", "via_administracion": "subcutanea", "evento_sanitario_id": "4eaa9f5b-8295-5d1b-a98e-2c285fdc855e"}	postgres	05c1863109c0b0bee366753c0ec1d2fd1cbe246b64a1b1062a427b124f230895
125	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	c6dc6123-355b-5a0d-9984-50ff66028733	\N	{"id": "c6dc6123-355b-5a0d-9984-50ff66028733", "dosis": "10 ml/24h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Electrolitos orales", "animal_id": "73956a35-c183-5c88-9b6e-827903fe0241", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-05-14", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 3, "fecha_fin_prevista": "2026-05-17", "via_administracion": "intramuscular", "evento_sanitario_id": "b899078b-81a1-56c9-939d-7df708e3aa93"}	postgres	54b65393cd44a04a72c2a3475a12aec76905c1f486957ac36d071a62137f6ae2
126	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	bf8c2884-ca99-513a-b595-bdec6886d0bf	\N	{"id": "bf8c2884-ca99-513a-b595-bdec6886d0bf", "dosis": "2 sobres/dia", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": false, "farmaco": "Florfenicol", "animal_id": "0d506129-b7c5-507a-88ca-242344baa5de", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}], "fecha_inicio": "2026-05-17", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": "2026-05-28", "dias_tratamiento": 4, "fecha_fin_prevista": "2026-05-21", "via_administracion": "intramamaria", "evento_sanitario_id": "b3a81c79-2168-5203-ba17-489b2d3f3ebf"}	postgres	3aceae5decfe369c0ca7d71c67666446ec9afaf7ce1535c7c886be2706656667
127	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	d6e69c86-789a-5700-a3ed-92e16ec1ddbd	\N	{"id": "d6e69c86-789a-5700-a3ed-92e16ec1ddbd", "dosis": "1 aplicacion/ordeno", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Penetamato", "animal_id": "c7ee8997-4bfb-56ca-9a3f-653af2d06595", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-05-20", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 5, "fecha_fin_prevista": "2026-05-25", "via_administracion": "oral", "evento_sanitario_id": "ffdb5c2c-362d-59a5-9896-42ccfc261a9b"}	postgres	62dc42f2b985857681c64f2afb0a39b4725f28305f601a9c53ff5607877e11fd
128	2026-05-31 19:52:32.285005+00	tratamientos_activos	INSERT	7b6af28c-abdf-5c69-95c7-91ad13eae6b4	\N	{"id": "7b6af28c-abdf-5c69-95c7-91ad13eae6b4", "dosis": "20 ml/48h", "notas": "Seguimiento de tratamiento con retirada cuando aplica.", "activo": true, "farmaco": "Meloxicam", "animal_id": "d58fbf17-442e-5153-8cdf-ce264a40ef4f", "checkboxes": [{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}], "fecha_inicio": "2026-05-23", "prescrito_por": "aed8c2c4-9620-5034-9248-d8564ee7addf", "fecha_fin_real": null, "dias_tratamiento": 6, "fecha_fin_prevista": "2026-05-29", "via_administracion": "subcutanea", "evento_sanitario_id": "97682f5a-49f4-53bf-8a08-4846ba0468ed"}	postgres	2881b073d71d8bc3914d7e8f55d2dc17ad3eebf3fad30d2c42df9a44da3ce581
129	2026-05-31 19:53:17.542964+00	incidencias	INSERT	153da52a-b5d2-53db-8b2c-1292e1e1fd3b	\N	{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "tipo": "averia_maquinaria", "estado": "abierta", "titulo": "Robot de ordeno con fallo temporal", "subtipo": "robot_ordeno", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "El VMS 4 registra dos paradas por error de brazo. Revisar antes del turno de tarde.", "ts_apertura": "2026-05-30T19:53:17.542964+00:00", "maquinaria_id": "0867ce4d-aeab-5ed8-9cc4-7cf164af60f3", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	612ba81449433f739eefd56710cda73ec72fef46d14fa0d97c7f59c20fb40243
130	2026-05-31 19:53:17.542964+00	incidencias	INSERT	c1c5f567-6153-5fb1-ab56-a2c15f9a99c7	\N	{"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "tipo": "sanidad_animal", "estado": "en_gestion", "titulo": "Vaca con retraso de ordeno", "subtipo": "retraso_ordeno", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "acciones": [], "foto_url": null, "animal_id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Animal con mas de 11 horas desde el ultimo paso por robot.", "ts_apertura": "2026-05-29T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	be730e239e730d06775bb11136be00448c47dbcd616c71560465325aeff65d58
131	2026-05-31 19:53:17.542964+00	incidencias	INSERT	196957e3-30e1-50a9-b8c6-5324e8625627	\N	{"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "tipo": "calidad_leche", "estado": "abierta", "titulo": "Elevacion de recuento celular", "subtipo": "scc", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": "d172a069-591a-55e4-89fc-32699f1d25c9", "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Lectura individual por encima de 350000 cel/ml; tomar muestra de confirmacion.", "ts_apertura": "2026-05-28T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	ba61b744fbffd0c930c31f2f97ceec55e3c0bfa4b506776709d98756d0e705fe
132	2026-05-31 19:53:17.542964+00	incidencias	INSERT	498fe423-512e-5a1d-93f7-5940ca889eea	\N	{"id": "498fe423-512e-5a1d-93f7-5940ca889eea", "tipo": "sanidad_animal", "estado": "en_gestion", "titulo": "Tratamiento pendiente de confirmar", "subtipo": "tratamiento", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "acciones": [], "foto_url": null, "animal_id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "severidad": "media", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Falta marcar administracion de segunda dosis en checklist.", "ts_apertura": "2026-05-27T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	de4192b5494e56fbef63300c65675972f0d1d06140c7c752518c0197052f91fe
133	2026-05-31 19:53:17.542964+00	incidencias	INSERT	f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30	\N	{"id": "f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30", "tipo": "infraestructura", "estado": "abierta", "titulo": "Bebedero con caudal bajo", "subtipo": "bebedero", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Bebedero del lote de produccion con llenado lento.", "ts_apertura": "2026-05-26T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	d1b48b85a5d94d5d8d5eed7247222050b50ffbbf77e7dd470db8c16e4194444a
134	2026-05-31 19:53:17.542964+00	incidencias	INSERT	37aa1113-89b0-5f8d-be10-c7fed87f469e	\N	{"id": "37aa1113-89b0-5f8d-be10-c7fed87f469e", "tipo": "pedidos", "estado": "abierta", "titulo": "Stock bajo de detergente alcalino", "subtipo": "stock", "zona_id": "9dbbf3e4-5070-5c4a-8beb-8b893a3bb081", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Quedan dos garrafas, insuficiente para la semana completa.", "ts_apertura": "2026-05-25T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	72612ee81dd2758ade3d4e212c7a5657c0e9371bf2c080b24b87dca9af600e26
135	2026-05-31 19:53:17.542964+00	incidencias	INSERT	bf301360-f84a-5b0e-b62a-23caa034b593	\N	{"id": "bf301360-f84a-5b0e-b62a-23caa034b593", "tipo": "alimentacion", "estado": "resuelta", "titulo": "Desviacion en mezcla unifeed", "subtipo": "tmr", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [{"ts": "2026-05-25T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-25T19:53:17.542964+00:00", "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "La paja supero el objetivo en 6%; corregido en segunda carga.", "ts_apertura": "2026-05-24T19:53:17.542964+00:00", "maquinaria_id": "1479ad4d-f17a-40bd-8606-590ddb2fa868", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	1e2cb8e9ddd76fa5c6308df592ccec547898c2e71f2b2f5c682a07ba1bc7f9eb
136	2026-05-31 19:53:17.542964+00	incidencias	INSERT	5bfa710e-ec65-5af2-b146-0fad0d8138bf	\N	{"id": "5bfa710e-ec65-5af2-b146-0fad0d8138bf", "tipo": "infraestructura", "estado": "abierta", "titulo": "Incidencia en silo de maiz", "subtipo": "silo", "zona_id": "46cc7a9d-80c2-5f41-80f8-ab6a8b2644ee", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Lona levantada en lateral norte tras viento nocturno.", "ts_apertura": "2026-05-23T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	9daa79912bbdd31b3ad711410c86c6c24c0659e5115ce7739010e2e6423e0f42
137	2026-05-31 19:53:17.542964+00	incidencias	INSERT	415f1b03-6825-5da0-b3ca-ba52a89cfcf9	\N	{"id": "415f1b03-6825-5da0-b3ca-ba52a89cfcf9", "tipo": "sanidad_animal", "estado": "en_gestion", "titulo": "Ternero con diarrea neonatal", "subtipo": "ternero", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "acciones": [], "foto_url": null, "animal_id": "874a44ba-01b6-5641-a7a8-14b3adbaa35a", "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Box 7 con heces liquidas y ligera deshidratacion.", "ts_apertura": "2026-05-22T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	12a85972a3f4423c2b1d61dbce8bc8e133ba97d631423c7e16246ce980cf9a68
138	2026-05-31 19:53:17.542964+00	incidencias	INSERT	8d02d4b9-2932-5853-b0e4-478817e0c5c0	\N	{"id": "8d02d4b9-2932-5853-b0e4-478817e0c5c0", "tipo": "sanidad_animal", "estado": "abierta", "titulo": "Vaca con cojera leve", "subtipo": "cojera", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "acciones": [], "foto_url": null, "animal_id": "e8761f6b-9037-5d8f-bca2-cd8caa3ab0af", "severidad": "media", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Apoyo irregular en extremidad posterior izquierda.", "ts_apertura": "2026-05-21T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	6df59054aa059901828719e2d6982904beaab10a03ae7321dee6f5baaa9c1cd7
139	2026-05-31 19:53:17.542964+00	incidencias	INSERT	c60e0f88-88f3-5536-83ee-9251b167127f	\N	{"id": "c60e0f88-88f3-5536-83ee-9251b167127f", "tipo": "averia_maquinaria", "estado": "abierta", "titulo": "Caida de vacio en sala", "subtipo": "bomba_vacio", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Bomba principal con oscilaciones al arrancar segundo robot.", "ts_apertura": "2026-05-20T19:53:17.542964+00:00", "maquinaria_id": "cca2e231-9ce5-5e6a-a9f2-63c43db556f4", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	a52820313198c49597a9bbddf7ad189a79b3b36289442e2723e8fae836f9d5a7
140	2026-05-31 19:53:17.542964+00	incidencias	INSERT	97c3a126-2dc6-5f13-a670-bb0972267513	\N	{"id": "97c3a126-2dc6-5f13-a670-bb0972267513", "tipo": "averia_maquinaria", "estado": "resuelta", "titulo": "Sensor sin lectura", "subtipo": "sensor", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "acciones": [{"ts": "2026-05-20T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-20T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Sensor de conductividad del VMS 2 reiniciado y vuelve a emitir.", "ts_apertura": "2026-05-19T19:53:17.542964+00:00", "maquinaria_id": "2def9ef9-5ce4-4588-996a-9d149b8888b1", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	13d1aec92c66b8ce1164736a8607fece0e7bb2fb6bfcfc381523edbc0ebebecb
141	2026-05-31 19:53:17.542964+00	incidencias	INSERT	317dc879-4d94-5ed4-9757-f2c4d8c8e812	\N	{"id": "317dc879-4d94-5ed4-9757-f2c4d8c8e812", "tipo": "infraestructura", "estado": "cerrada", "titulo": "Tarea de camas no completada", "subtipo": "tarea", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [{"ts": "2026-05-19T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-19T19:53:17.542964+00:00", "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Se reprogramo desinfeccion por entrada de forraje.", "ts_apertura": "2026-05-18T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	35c082d518e89d6df39d9b98fdda5e55b674ac3b1e57cf81b00599fa750362e9
142	2026-05-31 19:53:17.542964+00	incidencias	INSERT	85bb338b-4e50-5689-b490-915685a2ce07	\N	{"id": "85bb338b-4e50-5689-b490-915685a2ce07", "tipo": "alimentacion", "estado": "abierta", "titulo": "Arrimador sin pasada nocturna", "subtipo": "arrimador", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Equipo quedo parado junto a cornadiza; revisar bateria.", "ts_apertura": "2026-05-17T19:53:17.542964+00:00", "maquinaria_id": "d9c29718-27eb-55a8-99d3-6f55765d7e34", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	b1c7501bf567bb4907df0e35dacad35ad9851b2b7a55ce19b9eb572ca7c98a93
143	2026-05-31 19:53:17.542964+00	incidencias	INSERT	4bb034da-dc31-505e-a44b-e67c9c21a6db	\N	{"id": "4bb034da-dc31-505e-a44b-e67c9c21a6db", "tipo": "calidad_leche", "estado": "cerrada", "titulo": "Temperatura de tanque revisada", "subtipo": "tanque", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [{"ts": "2026-05-17T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-17T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Pico de 4.8 C durante lavado; estabilizado tras revision.", "ts_apertura": "2026-05-16T19:53:17.542964+00:00", "maquinaria_id": "74cf333b-4aba-5db6-bce2-1e13e1439bc2", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	be68e55124fc32d8e803a24e8230f9f12887e06912666dc457d5ce633e5eb0f1
144	2026-05-31 19:53:17.542964+00	incidencias	INSERT	bcb1850d-390e-58c3-b6cf-57fccebffc11	\N	{"id": "bcb1850d-390e-58c3-b6cf-57fccebffc11", "tipo": "pedidos", "estado": "resuelta", "titulo": "Filtros recibidos incompletos", "subtipo": "filtros", "zona_id": "9dbbf3e4-5070-5c4a-8beb-8b893a3bb081", "acciones": [{"ts": "2026-05-16T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-16T19:53:17.542964+00:00", "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Proveedor entrego 4 cajas de 6 solicitadas; queda reposicion pendiente.", "ts_apertura": "2026-05-15T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	21190b8cbc0bc6d229f5d80f9b60126e46e239492b42007d4e0a98c11a09609d
145	2026-05-31 19:53:17.542964+00	incidencias	INSERT	1e8ccb35-7b69-509c-8196-5b1a92beafbe	\N	{"id": "1e8ccb35-7b69-509c-8196-5b1a92beafbe", "tipo": "sanidad_animal", "estado": "abierta", "titulo": "Sospecha de metritis postparto", "subtipo": "metritis", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "acciones": [], "foto_url": null, "animal_id": "73956a35-c183-5c88-9b6e-827903fe0241", "severidad": "alta", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Animal con descarga anormal y descenso de ingesta.", "ts_apertura": "2026-05-14T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	5da15c0b2188b6f598bbe1f65bea71172fda2ea4b7d438517befcef5f8019223
146	2026-05-31 19:53:17.542964+00	incidencias	INSERT	b0d6febc-76d2-568c-822b-db5cc9ea35f6	\N	{"id": "b0d6febc-76d2-568c-822b-db5cc9ea35f6", "tipo": "infraestructura", "estado": "cerrada", "titulo": "Tablet de oficina sin carga", "subtipo": "oficina", "zona_id": "041feac1-9de2-4772-af3b-fc7d08acb16f", "acciones": [{"ts": "2026-05-14T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-14T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Cable sustituido y dispositivo operativo.", "ts_apertura": "2026-05-13T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	9eb808e80647d278336f27e43fd7d8057b258771e66ef2ba233d176342d0ffff
147	2026-05-31 19:53:17.542964+00	incidencias	INSERT	adbf9a1e-8a9a-56b7-addc-deb367880811	\N	{"id": "adbf9a1e-8a9a-56b7-addc-deb367880811", "tipo": "averia_maquinaria", "estado": "en_gestion", "titulo": "Ventilador sector 3 parado", "subtipo": "ventilacion", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Motor no arranca en modo automatico con THI alto.", "ts_apertura": "2026-05-12T19:53:17.542964+00:00", "maquinaria_id": "95ccf014-f4ea-5888-a3d7-cba4804370b8", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	3b24632cc2a9b3f6b4e7a865adb76a60e63946270abd36ec523424d132703e3c
148	2026-05-31 19:53:17.542964+00	incidencias	INSERT	9daf15f0-e0f0-5973-b3e2-174a5a5fe7d9	\N	{"id": "9daf15f0-e0f0-5973-b3e2-174a5a5fe7d9", "tipo": "alimentacion", "estado": "resuelta", "titulo": "Frente de silo irregular", "subtipo": "silos", "zona_id": "46cc7a9d-80c2-5f41-80f8-ab6a8b2644ee", "acciones": [{"ts": "2026-05-12T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-12T19:53:17.542964+00:00", "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Se recorto frente y se compacto zona abierta.", "ts_apertura": "2026-05-11T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	0c3960805c67a18d2cc87051a81246d695b015d73e507d78749b3749360daf99
149	2026-05-31 19:53:17.542964+00	incidencias	INSERT	f0142fee-b873-5d45-80d9-fbc8f460b796	\N	{"id": "f0142fee-b873-5d45-80d9-fbc8f460b796", "tipo": "sanidad_animal", "estado": "abierta", "titulo": "Novilla con tos persistente", "subtipo": "recria", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "acciones": [], "foto_url": null, "animal_id": "74107440-00d6-58ee-ae41-82471d6b9aa4", "severidad": "media", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Revisar temperatura y valorar tratamiento respiratorio.", "ts_apertura": "2026-05-10T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	8136cc8e95755b24946724da294efcd949329694bcf7c93c91ff3b34d89000d5
160	2026-05-31 19:54:56.952826+00	pedidos	INSERT	3f8dfeb0-6221-534c-9b93-49f5f6a433d3	\N	{"id": "3f8dfeb0-6221-534c-9b93-49f5f6a433d3", "notas": "Cambiar primero robots 1 y 2.", "estado": "aprobado", "insumo": "Pezoneras VMS", "unidad": "unidades", "cantidad": 32.00, "proveedor": "DeLaval Servicio", "coste_real": null, "descripcion": "Reposicion por horas de uso.", "ts_recepcion": null, "ts_solicitud": "2026-05-28T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-29T19:54:56.952826+00:00", "coste_estimado": 480.00, "solicitante_id": "f2b0bd7e-4171-5347-8179-fe6667ba7985"}	postgres	7206cebf7948dc06e7daccf1778ada54554f14f3c2ecb578b6089db3fed17a16
150	2026-05-31 19:53:17.542964+00	incidencias	INSERT	290612c3-2ec1-5f55-b1b0-b49389db3355	\N	{"id": "290612c3-2ec1-5f55-b1b0-b49389db3355", "tipo": "calidad_leche", "estado": "abierta", "titulo": "Bajada de grasa en lote", "subtipo": "grasa", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Media de grasa baja respecto a semana previa; revisar fibra efectiva.", "ts_apertura": "2026-05-09T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	23259c464f160f9427557f7ba170078a86903e22bba1848d8dd77d510594d38c
151	2026-05-31 19:53:17.542964+00	incidencias	INSERT	23661db5-4a74-5c10-b3a4-991b4fbb567d	\N	{"id": "23661db5-4a74-5c10-b3a4-991b4fbb567d", "tipo": "averia_maquinaria", "estado": "cerrada", "titulo": "Revision de tractor completada", "subtipo": "tractor", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [{"ts": "2026-05-09T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-09T19:53:17.542964+00:00", "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Cambio de filtro y engrase realizados.", "ts_apertura": "2026-05-08T19:53:17.542964+00:00", "maquinaria_id": "2a645371-8dcf-5741-9cba-4503270ee2ef", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	68ac850440b4b01cbf89e32da213dbeaea83105bd3870a2c6d52102279169c0a
152	2026-05-31 19:53:17.542964+00	incidencias	INSERT	b84c837c-8e65-51a7-a0b0-565faa3d59a8	\N	{"id": "b84c837c-8e65-51a7-a0b0-565faa3d59a8", "tipo": "pedidos", "estado": "abierta", "titulo": "Pedido urgente de antiinflamatorio", "subtipo": "medicamentos", "zona_id": "9dbbf3e4-5070-5c4a-8beb-8b893a3bb081", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Stock minimo alcanzado tras tratamientos de cojeras.", "ts_apertura": "2026-05-07T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	76190da6544a88354015e584721921672a77b17198981d8402d3cb43d63f3f8a
153	2026-05-31 19:53:17.542964+00	incidencias	INSERT	27bc0217-6243-5c80-9f8c-aaef63cb8d91	\N	{"id": "27bc0217-6243-5c80-9f8c-aaef63cb8d91", "tipo": "infraestructura", "estado": "en_gestion", "titulo": "Cama humeda en boxes de terneros", "subtipo": "boxes", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Cambiar cama de boxes 4 a 8 antes de la tarde.", "ts_apertura": "2026-05-06T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	28ac7f5eb40841fc969d4cd1e7b902b0e850b62a7a985a0d9e2408a5107bf5fb
154	2026-05-31 19:53:17.542964+00	incidencias	INSERT	7e8790a1-a048-50be-87a3-31e395137dd8	\N	{"id": "7e8790a1-a048-50be-87a3-31e395137dd8", "tipo": "sanidad_animal", "estado": "abierta", "titulo": "Mastitis clinica leve", "subtipo": "mastitis", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "acciones": [], "foto_url": null, "animal_id": "2e14a84a-511d-5bcf-867c-216522289b1c", "severidad": "alta", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Cuarteron posterior con grumos en primeros chorros.", "ts_apertura": "2026-05-05T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	c0d4c47c0d076355f20f96836f22d06d5a953ce682a7b87c9f43bebebfa2826e
155	2026-05-31 19:53:17.542964+00	incidencias	INSERT	7e55d431-d27d-59de-b1f3-f8bae2a81d00	\N	{"id": "7e55d431-d27d-59de-b1f3-f8bae2a81d00", "tipo": "alimentacion", "estado": "resuelta", "titulo": "Bebedero limpiado tras aviso", "subtipo": "agua", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [{"ts": "2026-05-05T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-05T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Retirado resto de forraje de valvula.", "ts_apertura": "2026-05-04T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	098f1cdeebed1a267f210a1b63e108209ea3405aabc1ed8ce5a4bd04a0d9bb71
156	2026-05-31 19:53:17.542964+00	incidencias	INSERT	c534fbe9-e9d8-5960-b0a4-befbc200f6aa	\N	{"id": "c534fbe9-e9d8-5960-b0a4-befbc200f6aa", "tipo": "averia_maquinaria", "estado": "abierta", "titulo": "Amamantadora en revision pendiente", "subtipo": "amamantadora", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Calibracion de polvo de leche fuera de rango.", "ts_apertura": "2026-05-03T19:53:17.542964+00:00", "maquinaria_id": "1334d1ae-1804-491e-a777-63439f7e9468", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	baa11c123de65147fbf22bc6cb5f1bef2313ca5500657d2574c42e94beefb4be
157	2026-05-31 19:53:17.542964+00	incidencias	INSERT	415d9b5b-4fb4-5fdb-8a8d-ea8490a015b0	\N	{"id": "415d9b5b-4fb4-5fdb-8a8d-ea8490a015b0", "tipo": "calidad_leche", "estado": "cerrada", "titulo": "Muestra de control registrada", "subtipo": "muestra", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [{"ts": "2026-05-03T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": "46e29b13-6344-5b6d-8471-0891456bd85b", "severidad": "baja", "ts_cierre": "2026-05-03T19:53:17.542964+00:00", "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Muestra enviada por subida puntual de conductividad.", "ts_apertura": "2026-05-02T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	35f524737c9ef2f7bb2c3fb68c36598b195cffd730ebe5e758781c2ceea488d1
158	2026-05-31 19:53:17.542964+00	incidencias	INSERT	7fdc414c-a010-5da9-8468-48e5ba08e193	\N	{"id": "7fdc414c-a010-5da9-8468-48e5ba08e193", "tipo": "infraestructura", "estado": "abierta", "titulo": "Limpieza de sala retrasada", "subtipo": "limpieza", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Pendiente repaso de zona de espera tras turno de manana.", "ts_apertura": "2026-05-01T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	7b7732d8eb0d660faa1ccd88da0ff502f7ea402b51da7bdf13c4c2c248eb9c8e
159	2026-05-31 19:54:56.952826+00	pedidos	INSERT	d55d41eb-e505-59ef-8c58-5a53d0d0e26d	\N	{"id": "d55d41eb-e505-59ef-8c58-5a53d0d0e26d", "notas": "Stock por debajo de minimo semanal.", "estado": "solicitado", "insumo": "Detergente alcalino clorado", "unidad": "garrafas", "cantidad": 8.00, "proveedor": "Higiene Ganadera Norte", "coste_real": null, "descripcion": "Limpieza CIP de robots y tanque.", "ts_recepcion": null, "ts_solicitud": "2026-05-30T19:54:56.952826+00:00", "ts_aprobacion": null, "coste_estimado": 312.00, "solicitante_id": "efbe203d-853b-56dc-a3a2-e2839e844083"}	postgres	42121da8e321bd839160cf107e92b2a9c372929a641ccd5c6fd008ad8b5521f9
161	2026-05-31 19:54:56.952826+00	pedidos	INSERT	7bcd772b-76dd-5270-9349-c4e2bc3d3ffd	\N	{"id": "7bcd772b-76dd-5270-9349-c4e2bc3d3ffd", "notas": "Entrega parcial prevista.", "estado": "en_transito", "insumo": "Filtros de leche", "unidad": "cajas", "cantidad": 12.00, "proveedor": "Lactosuministros SL", "coste_real": null, "descripcion": "Filtros compatibles con linea principal.", "ts_recepcion": null, "ts_solicitud": "2026-05-26T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-27T19:54:56.952826+00:00", "coste_estimado": 156.00, "solicitante_id": "3033a0ee-9ffe-5e7f-a7a2-76f309918749"}	postgres	93011d675ad40a86cba01dbbfeebf8a7fd3d5a17fbedbbb7254cd47d80dbc410
162	2026-05-31 19:54:56.952826+00	pedidos	INSERT	b937cd3d-6ade-5ade-9a08-5378a4a608a7	\N	{"id": "b937cd3d-6ade-5ade-9a08-5378a4a608a7", "notas": "Prioridad alta por stock minimo.", "estado": "solicitado", "insumo": "Meloxicam 100 ml", "unidad": "frascos", "cantidad": 6.00, "proveedor": "VetNoroeste", "coste_real": null, "descripcion": "Tratamientos de cojeras y postparto.", "ts_recepcion": null, "ts_solicitud": "2026-05-29T19:54:56.952826+00:00", "ts_aprobacion": null, "coste_estimado": 198.00, "solicitante_id": "aed8c2c4-9620-5034-9248-d8564ee7addf"}	postgres	f494ee2426b37cd7190047f9e46585c1518d94b2ad0905870feb68cafb7d6bb6
163	2026-05-31 19:54:56.952826+00	pedidos	INSERT	8a41525d-02db-55d1-8cbc-c82274294516	\N	{"id": "8a41525d-02db-55d1-8cbc-c82274294516", "notas": "Recibido completo.", "estado": "recibido", "insumo": "Cateteres y material veterinario", "unidad": "kits", "cantidad": 4.00, "proveedor": "VetNoroeste", "coste_real": 89.50, "descripcion": "Material para tratamientos intramamarios.", "ts_recepcion": "2026-05-23T19:54:56.952826+00:00", "ts_solicitud": "2026-05-19T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-20T19:54:56.952826+00:00", "coste_estimado": 92.00, "solicitante_id": "aed8c2c4-9620-5034-9248-d8564ee7addf"}	postgres	65bb73170eda38bfd6057c6460a0e7ee4caae0ca6b3412daac2e68b3163cfe13
164	2026-05-31 19:54:56.952826+00	pedidos	INSERT	45f0c3b2-36e7-501d-a759-72c28ea47ddd	\N	{"id": "45f0c3b2-36e7-501d-a759-72c28ea47ddd", "notas": "Necesario para boxes de terneros.", "estado": "aprobado", "insumo": "Pienso iniciador terneros", "unidad": "sacos", "cantidad": 40.00, "proveedor": "NutriFeed Galicia", "coste_real": null, "descripcion": "Saco 25 kg recria.", "ts_recepcion": null, "ts_solicitud": "2026-05-30T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-31T13:54:56.952826+00:00", "coste_estimado": 740.00, "solicitante_id": "ee779dc8-16c9-597a-b0ed-ff5886d58b9e"}	postgres	97622d89018f3622340cdf259a9317ca4079f4d5a2e997892ef71a2298e698b0
165	2026-05-31 19:54:56.952826+00	pedidos	INSERT	f9d7e405-7731-5b25-95fd-26be04ede639	\N	{"id": "f9d7e405-7731-5b25-95fd-26be04ede639", "notas": "Revisar calibracion al recibir.", "estado": "en_transito", "insumo": "Leche maternizada", "unidad": "sacos", "cantidad": 20.00, "proveedor": "NutriFeed Galicia", "coste_real": null, "descripcion": "Reposicion para amamantadora.", "ts_recepcion": null, "ts_solicitud": "2026-05-27T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-28T19:54:56.952826+00:00", "coste_estimado": 1180.00, "solicitante_id": "ee779dc8-16c9-597a-b0ed-ff5886d58b9e"}	postgres	f687b4980a27cb80ebfd2a26bcbada79c773e60330eae1e0a2fae9f4fa8a2e69
166	2026-05-31 19:54:56.952826+00	pedidos	INSERT	2f43fe4f-9e71-5fc2-b048-d23d48df4408	\N	{"id": "2f43fe4f-9e71-5fc2-b048-d23d48df4408", "notas": "Relacionado con incidencia de vacio.", "estado": "solicitado", "insumo": "Kit juntas bomba de vacio", "unidad": "kit", "cantidad": 1.00, "proveedor": "AgroMantenimiento", "coste_real": null, "descripcion": "Repuesto para mantenimiento correctivo.", "ts_recepcion": null, "ts_solicitud": "2026-05-31T11:54:56.952826+00:00", "ts_aprobacion": null, "coste_estimado": 265.00, "solicitante_id": "718c721d-90a7-536a-b47d-bb935fe583f3"}	postgres	645d1f388c21b480ab90a04453318d8505fda2f0d619496b39c59d2983e6222f
167	2026-05-31 19:54:56.952826+00	pedidos	INSERT	8c5066ac-1c24-598b-a1df-c3815d54991c	\N	{"id": "8c5066ac-1c24-598b-a1df-c3815d54991c", "notas": "Sin incidencias.", "estado": "recibido", "insumo": "Etiquetas y toner oficina", "unidad": "packs", "cantidad": 3.00, "proveedor": "OfiNorte", "coste_real": 71.20, "descripcion": "Material administrativo para registros.", "ts_recepcion": "2026-05-18T19:54:56.952826+00:00", "ts_solicitud": "2026-05-15T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-16T19:54:56.952826+00:00", "coste_estimado": 74.00, "solicitante_id": "efbe203d-853b-56dc-a3a2-e2839e844083"}	postgres	5c75ce74f6d9b194680de0dcb37490b5941cab7c60130b69669c27b0a1c2e83e
168	2026-05-31 19:54:56.952826+00	pedidos	INSERT	37954089-536e-52cd-8476-c27b55c4b40e	\N	{"id": "37954089-536e-52cd-8476-c27b55c4b40e", "notas": "Consumo elevado en tratamientos activos.", "estado": "aprobado", "insumo": "Guantes nitrilo", "unidad": "cajas", "cantidad": 20.00, "proveedor": "Higiene Ganadera Norte", "coste_real": null, "descripcion": "Uso en sala, enfermeria y recria.", "ts_recepcion": null, "ts_solicitud": "2026-05-25T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-26T19:54:56.952826+00:00", "coste_estimado": 210.00, "solicitante_id": "350c2228-7752-5756-bb3e-436f655d703b"}	postgres	9b81618a17184a9ab777107547df94dac8d11b94ef1cda142496deae4a5acfe4
169	2026-05-31 19:54:56.952826+00	pedidos	INSERT	e85735d6-6821-5dd5-a6c8-b058a9766044	\N	{"id": "e85735d6-6821-5dd5-a6c8-b058a9766044", "notas": "Prevision de secados de la semana.", "estado": "solicitado", "insumo": "Sellador pezones secado", "unidad": "cajas", "cantidad": 10.00, "proveedor": "VetNoroeste", "coste_real": null, "descripcion": "Protocolo de vacas secas.", "ts_recepcion": null, "ts_solicitud": "2026-05-31T10:54:56.952826+00:00", "ts_aprobacion": null, "coste_estimado": 340.00, "solicitante_id": "aed8c2c4-9620-5034-9248-d8564ee7addf"}	postgres	e41ed2a49bfdb2f0ef09896019def97091f93f38a5fa4482e0fd517298329e53
170	2026-05-31 19:54:56.952826+00	pedidos	INSERT	722d1923-0a62-555a-bb40-767f9e37db22	\N	{"id": "722d1923-0a62-555a-bb40-767f9e37db22", "notas": "Cancelado por referencia incorrecta.", "estado": "cancelado", "insumo": "Cuchillas carro mezclador", "unidad": "juegos", "cantidad": 2.00, "proveedor": "AgroMantenimiento", "coste_real": null, "descripcion": "Mantenimiento de mezcla TMR.", "ts_recepcion": null, "ts_solicitud": "2026-05-11T19:54:56.952826+00:00", "ts_aprobacion": "2026-05-12T19:54:56.952826+00:00", "coste_estimado": 520.00, "solicitante_id": "718c721d-90a7-536a-b47d-bb935fe583f3"}	postgres	91d99335761a889216d5cef7ddd0688d2e546a3db7929ee49adc353de741b5e8
176	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	c60e0f88-88f3-5536-83ee-9251b167127f	{"id": "c60e0f88-88f3-5536-83ee-9251b167127f", "tipo": "averia_maquinaria", "estado": "abierta", "titulo": "Caida de vacio en sala", "subtipo": "bomba_vacio", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Bomba principal con oscilaciones al arrancar segundo robot.", "ts_apertura": "2026-05-20T19:53:17.542964+00:00", "maquinaria_id": "cca2e231-9ce5-5e6a-a9f2-63c43db556f4", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "c60e0f88-88f3-5536-83ee-9251b167127f", "tipo": "averia_maquinaria", "estado": "abierta", "titulo": "Caida de vacio en sala", "subtipo": "bomba_vacio", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Bomba principal con oscilaciones al arrancar segundo robot.", "ts_apertura": "2026-05-20T19:53:17.542964+00:00", "maquinaria_id": "cca2e231-9ce5-5e6a-a9f2-63c43db556f4", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	5481fc5e0e506061f1b3a8ce4548b9be51266dec0a5f56db54b85422d5fadc64
171	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	153da52a-b5d2-53db-8b2c-1292e1e1fd3b	{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "tipo": "averia_maquinaria", "estado": "abierta", "titulo": "Robot de ordeno con fallo temporal", "subtipo": "robot_ordeno", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "El VMS 4 registra dos paradas por error de brazo. Revisar antes del turno de tarde.", "ts_apertura": "2026-05-30T19:53:17.542964+00:00", "maquinaria_id": "0867ce4d-aeab-5ed8-9cc4-7cf164af60f3", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "tipo": "averia_maquinaria", "estado": "abierta", "titulo": "Robot de ordeno con fallo temporal", "subtipo": "robot_ordeno", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "El VMS 4 registra dos paradas por error de brazo. Revisar antes del turno de tarde.", "ts_apertura": "2026-05-30T19:53:17.542964+00:00", "maquinaria_id": "0867ce4d-aeab-5ed8-9cc4-7cf164af60f3", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	675550fd55413a5fa443734765c4dbc7e2fb055c272468d4c2719ecb0fb089ab
172	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	c1c5f567-6153-5fb1-ab56-a2c15f9a99c7	{"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "tipo": "sanidad_animal", "estado": "en_gestion", "titulo": "Vaca con retraso de ordeno", "subtipo": "retraso_ordeno", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "acciones": [], "foto_url": null, "animal_id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Animal con mas de 11 horas desde el ultimo paso por robot.", "ts_apertura": "2026-05-29T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "tipo": "sanidad_animal", "estado": "en_gestion", "titulo": "Vaca con retraso de ordeno", "subtipo": "retraso_ordeno", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [], "foto_url": null, "animal_id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Animal con mas de 11 horas desde el ultimo paso por robot.", "ts_apertura": "2026-05-29T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	8bf46718647ff1a61cdbf144bbcd54f5aefad7dbc48b6687f2d191b48fccc5a1
173	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	196957e3-30e1-50a9-b8c6-5324e8625627	{"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "tipo": "calidad_leche", "estado": "abierta", "titulo": "Elevacion de recuento celular", "subtipo": "scc", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": "d172a069-591a-55e4-89fc-32699f1d25c9", "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Lectura individual por encima de 350000 cel/ml; tomar muestra de confirmacion.", "ts_apertura": "2026-05-28T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "tipo": "calidad_leche", "estado": "abierta", "titulo": "Elevacion de recuento celular", "subtipo": "scc", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [], "foto_url": null, "animal_id": "d172a069-591a-55e4-89fc-32699f1d25c9", "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Lectura individual por encima de 350000 cel/ml; tomar muestra de confirmacion.", "ts_apertura": "2026-05-28T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	e5543dfca9ed3661339ac28cd8d3ef3f06873df9db4a65accf7861e958243a97
174	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	37aa1113-89b0-5f8d-be10-c7fed87f469e	{"id": "37aa1113-89b0-5f8d-be10-c7fed87f469e", "tipo": "pedidos", "estado": "abierta", "titulo": "Stock bajo de detergente alcalino", "subtipo": "stock", "zona_id": "9dbbf3e4-5070-5c4a-8beb-8b893a3bb081", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Quedan dos garrafas, insuficiente para la semana completa.", "ts_apertura": "2026-05-25T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "37aa1113-89b0-5f8d-be10-c7fed87f469e", "tipo": "pedidos", "estado": "abierta", "titulo": "Stock bajo de detergente alcalino", "subtipo": "stock", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Quedan dos garrafas, insuficiente para la semana completa.", "ts_apertura": "2026-05-25T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	7a9891ace5a8cd3072150321ad9a13d0a9119f4aa854577059220afbb2960e3a
175	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	5bfa710e-ec65-5af2-b146-0fad0d8138bf	{"id": "5bfa710e-ec65-5af2-b146-0fad0d8138bf", "tipo": "infraestructura", "estado": "abierta", "titulo": "Incidencia en silo de maiz", "subtipo": "silo", "zona_id": "46cc7a9d-80c2-5f41-80f8-ab6a8b2644ee", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Lona levantada en lateral norte tras viento nocturno.", "ts_apertura": "2026-05-23T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "5bfa710e-ec65-5af2-b146-0fad0d8138bf", "tipo": "infraestructura", "estado": "abierta", "titulo": "Incidencia en silo de maiz", "subtipo": "silo", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Lona levantada en lateral norte tras viento nocturno.", "ts_apertura": "2026-05-23T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	f3e88c89afb8173ba6a6a7779092ef4adb44c1d32a56d0f681c136bffa527084
187	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	7fdc414c-a010-5da9-8468-48e5ba08e193	{"id": "7fdc414c-a010-5da9-8468-48e5ba08e193", "tipo": "infraestructura", "estado": "abierta", "titulo": "Limpieza de sala retrasada", "subtipo": "limpieza", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Pendiente repaso de zona de espera tras turno de manana.", "ts_apertura": "2026-05-01T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "7fdc414c-a010-5da9-8468-48e5ba08e193", "tipo": "infraestructura", "estado": "abierta", "titulo": "Limpieza de sala retrasada", "subtipo": "limpieza", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Pendiente repaso de zona de espera tras turno de manana.", "ts_apertura": "2026-05-01T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	2ce50ac3af739b0cdebd57bfdb8c89efb9d16cd4ad7d5f13f3836d39a3e33ab2
177	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	97c3a126-2dc6-5f13-a670-bb0972267513	{"id": "97c3a126-2dc6-5f13-a670-bb0972267513", "tipo": "averia_maquinaria", "estado": "resuelta", "titulo": "Sensor sin lectura", "subtipo": "sensor", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "acciones": [{"ts": "2026-05-20T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-20T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Sensor de conductividad del VMS 2 reiniciado y vuelve a emitir.", "ts_apertura": "2026-05-19T19:53:17.542964+00:00", "maquinaria_id": "2def9ef9-5ce4-4588-996a-9d149b8888b1", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "97c3a126-2dc6-5f13-a670-bb0972267513", "tipo": "averia_maquinaria", "estado": "resuelta", "titulo": "Sensor sin lectura", "subtipo": "sensor", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [{"ts": "2026-05-20T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-20T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Sensor de conductividad del VMS 2 reiniciado y vuelve a emitir.", "ts_apertura": "2026-05-19T19:53:17.542964+00:00", "maquinaria_id": "2def9ef9-5ce4-4588-996a-9d149b8888b1", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	35766067abf2c1d06eaa31cb6caaa1c9f8fe0e412a86d513d783c020208b22ee
178	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	317dc879-4d94-5ed4-9757-f2c4d8c8e812	{"id": "317dc879-4d94-5ed4-9757-f2c4d8c8e812", "tipo": "infraestructura", "estado": "cerrada", "titulo": "Tarea de camas no completada", "subtipo": "tarea", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [{"ts": "2026-05-19T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-19T19:53:17.542964+00:00", "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Se reprogramo desinfeccion por entrada de forraje.", "ts_apertura": "2026-05-18T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "317dc879-4d94-5ed4-9757-f2c4d8c8e812", "tipo": "infraestructura", "estado": "cerrada", "titulo": "Tarea de camas no completada", "subtipo": "tarea", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [{"ts": "2026-05-19T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-19T19:53:17.542964+00:00", "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Se reprogramo desinfeccion por entrada de forraje.", "ts_apertura": "2026-05-18T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	87836a1acd8cec50b1a3962a9c098d687b248895acd52002281ed112c455687d
179	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	4bb034da-dc31-505e-a44b-e67c9c21a6db	{"id": "4bb034da-dc31-505e-a44b-e67c9c21a6db", "tipo": "calidad_leche", "estado": "cerrada", "titulo": "Temperatura de tanque revisada", "subtipo": "tanque", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [{"ts": "2026-05-17T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-17T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Pico de 4.8 C durante lavado; estabilizado tras revision.", "ts_apertura": "2026-05-16T19:53:17.542964+00:00", "maquinaria_id": "74cf333b-4aba-5db6-bce2-1e13e1439bc2", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "4bb034da-dc31-505e-a44b-e67c9c21a6db", "tipo": "calidad_leche", "estado": "cerrada", "titulo": "Temperatura de tanque revisada", "subtipo": "tanque", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [{"ts": "2026-05-17T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-17T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Pico de 4.8 C durante lavado; estabilizado tras revision.", "ts_apertura": "2026-05-16T19:53:17.542964+00:00", "maquinaria_id": "74cf333b-4aba-5db6-bce2-1e13e1439bc2", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	af4edc08980ad6ae511d39c3e2a77cb95ae670cfafac591630f76ee0bb14add8
180	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	bcb1850d-390e-58c3-b6cf-57fccebffc11	{"id": "bcb1850d-390e-58c3-b6cf-57fccebffc11", "tipo": "pedidos", "estado": "resuelta", "titulo": "Filtros recibidos incompletos", "subtipo": "filtros", "zona_id": "9dbbf3e4-5070-5c4a-8beb-8b893a3bb081", "acciones": [{"ts": "2026-05-16T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-16T19:53:17.542964+00:00", "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Proveedor entrego 4 cajas de 6 solicitadas; queda reposicion pendiente.", "ts_apertura": "2026-05-15T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "bcb1850d-390e-58c3-b6cf-57fccebffc11", "tipo": "pedidos", "estado": "resuelta", "titulo": "Filtros recibidos incompletos", "subtipo": "filtros", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [{"ts": "2026-05-16T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-16T19:53:17.542964+00:00", "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Proveedor entrego 4 cajas de 6 solicitadas; queda reposicion pendiente.", "ts_apertura": "2026-05-15T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	8e0e57b8b8b5b464278cc7d5f52abe189a19bc04fa97fc00b5d3bd399c005c89
181	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	b0d6febc-76d2-568c-822b-db5cc9ea35f6	{"id": "b0d6febc-76d2-568c-822b-db5cc9ea35f6", "tipo": "infraestructura", "estado": "cerrada", "titulo": "Tablet de oficina sin carga", "subtipo": "oficina", "zona_id": "041feac1-9de2-4772-af3b-fc7d08acb16f", "acciones": [{"ts": "2026-05-14T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-14T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Cable sustituido y dispositivo operativo.", "ts_apertura": "2026-05-13T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "b0d6febc-76d2-568c-822b-db5cc9ea35f6", "tipo": "infraestructura", "estado": "cerrada", "titulo": "Tablet de oficina sin carga", "subtipo": "oficina", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [{"ts": "2026-05-14T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-14T19:53:17.542964+00:00", "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Cable sustituido y dispositivo operativo.", "ts_apertura": "2026-05-13T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	fde64cc8259d3b6aa0f25ccea3c70fa085e9fa2533d142c14048197a96eb2af9
182	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	adbf9a1e-8a9a-56b7-addc-deb367880811	{"id": "adbf9a1e-8a9a-56b7-addc-deb367880811", "tipo": "averia_maquinaria", "estado": "en_gestion", "titulo": "Ventilador sector 3 parado", "subtipo": "ventilacion", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Motor no arranca en modo automatico con THI alto.", "ts_apertura": "2026-05-12T19:53:17.542964+00:00", "maquinaria_id": "95ccf014-f4ea-5888-a3d7-cba4804370b8", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "adbf9a1e-8a9a-56b7-addc-deb367880811", "tipo": "averia_maquinaria", "estado": "en_gestion", "titulo": "Ventilador sector 3 parado", "subtipo": "ventilacion", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": "718c721d-90a7-536a-b47d-bb935fe583f3", "descripcion": "Motor no arranca en modo automatico con THI alto.", "ts_apertura": "2026-05-12T19:53:17.542964+00:00", "maquinaria_id": "95ccf014-f4ea-5888-a3d7-cba4804370b8", "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	c76b69df13269f012ff45ada75856d1943b424b570dbc0cbf88a44fe1a3bcca3
183	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	9daf15f0-e0f0-5973-b3e2-174a5a5fe7d9	{"id": "9daf15f0-e0f0-5973-b3e2-174a5a5fe7d9", "tipo": "alimentacion", "estado": "resuelta", "titulo": "Frente de silo irregular", "subtipo": "silos", "zona_id": "46cc7a9d-80c2-5f41-80f8-ab6a8b2644ee", "acciones": [{"ts": "2026-05-12T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-12T19:53:17.542964+00:00", "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Se recorto frente y se compacto zona abierta.", "ts_apertura": "2026-05-11T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "9daf15f0-e0f0-5973-b3e2-174a5a5fe7d9", "tipo": "alimentacion", "estado": "resuelta", "titulo": "Frente de silo irregular", "subtipo": "silos", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [{"ts": "2026-05-12T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-12T19:53:17.542964+00:00", "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Se recorto frente y se compacto zona abierta.", "ts_apertura": "2026-05-11T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	bbb880e995c558101418ba789b89fa3a0efb471759744ade63bb7c68fc1d2a92
184	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	f0142fee-b873-5d45-80d9-fbc8f460b796	{"id": "f0142fee-b873-5d45-80d9-fbc8f460b796", "tipo": "sanidad_animal", "estado": "abierta", "titulo": "Novilla con tos persistente", "subtipo": "recria", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "acciones": [], "foto_url": null, "animal_id": "74107440-00d6-58ee-ae41-82471d6b9aa4", "severidad": "media", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Revisar temperatura y valorar tratamiento respiratorio.", "ts_apertura": "2026-05-10T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "f0142fee-b873-5d45-80d9-fbc8f460b796", "tipo": "sanidad_animal", "estado": "abierta", "titulo": "Novilla con tos persistente", "subtipo": "recria", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "acciones": [], "foto_url": null, "animal_id": "74107440-00d6-58ee-ae41-82471d6b9aa4", "severidad": "media", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Revisar temperatura y valorar tratamiento respiratorio.", "ts_apertura": "2026-05-10T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	89e5f852a419903962cf00b35d9cb2f4db0c19d50acda720d1c0c1941c6e99b0
185	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	b84c837c-8e65-51a7-a0b0-565faa3d59a8	{"id": "b84c837c-8e65-51a7-a0b0-565faa3d59a8", "tipo": "pedidos", "estado": "abierta", "titulo": "Pedido urgente de antiinflamatorio", "subtipo": "medicamentos", "zona_id": "9dbbf3e4-5070-5c4a-8beb-8b893a3bb081", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Stock minimo alcanzado tras tratamientos de cojeras.", "ts_apertura": "2026-05-07T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "b84c837c-8e65-51a7-a0b0-565faa3d59a8", "tipo": "pedidos", "estado": "abierta", "titulo": "Pedido urgente de antiinflamatorio", "subtipo": "medicamentos", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": "aed8c2c4-9620-5034-9248-d8564ee7addf", "descripcion": "Stock minimo alcanzado tras tratamientos de cojeras.", "ts_apertura": "2026-05-07T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	099a8cd88db68f5155987c89616d04da6582d1476b26de58842385f92bafc431
186	2026-05-31 21:31:57.733599+00	incidencias	UPDATE	415d9b5b-4fb4-5fdb-8a8d-ea8490a015b0	{"id": "415d9b5b-4fb4-5fdb-8a8d-ea8490a015b0", "tipo": "calidad_leche", "estado": "cerrada", "titulo": "Muestra de control registrada", "subtipo": "muestra", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "acciones": [{"ts": "2026-05-03T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": "46e29b13-6344-5b6d-8471-0891456bd85b", "severidad": "baja", "ts_cierre": "2026-05-03T19:53:17.542964+00:00", "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Muestra enviada por subida puntual de conductividad.", "ts_apertura": "2026-05-02T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	{"id": "415d9b5b-4fb4-5fdb-8a8d-ea8490a015b0", "tipo": "calidad_leche", "estado": "cerrada", "titulo": "Muestra de control registrada", "subtipo": "muestra", "zona_id": "0136bdbc-70c7-5c70-8872-c5fcfdf72e40", "acciones": [{"ts": "2026-05-03T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}], "foto_url": null, "animal_id": "46e29b13-6344-5b6d-8471-0891456bd85b", "severidad": "baja", "ts_cierre": "2026-05-03T19:53:17.542964+00:00", "asignado_a": "f2b0bd7e-4171-5347-8179-fe6667ba7985", "descripcion": "Muestra enviada por subida puntual de conductividad.", "ts_apertura": "2026-05-02T19:53:17.542964+00:00", "maquinaria_id": null, "reportado_por": "4830a4e4-9a7f-56dc-9102-12fd9c99e3dc"}	postgres	08564062a087acaacb66f5124fb97469e705b8ca0739d2f304520c63358ac1a4
260	2026-06-01 07:46:04.013977+00	animales	UPDATE	a4774bd3-5ee0-54bc-8fb8-cf5df0b3bd89	{"id": "a4774bd3-5ee0-54bc-8fb8-cf5df0b3bd89", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Nube 85", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-06", "crotal_oficial": "ES2706500085", "fecha_nacimiento": "2026-02-10", "estado_reproductivo": null}	{"id": "a4774bd3-5ee0-54bc-8fb8-cf5df0b3bd89", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Nube 85", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-06", "crotal_oficial": "ES2706500085", "fecha_nacimiento": "2026-02-10", "estado_reproductivo": null}	postgres	c4c94aa664631832c4ff65410ce65a506d2c4950075c783a4c10d5d467878ac6
188	2026-06-01 07:46:03.856208+00	animales	UPDATE	d58fbf17-442e-5153-8cdf-ce264a40ef4f	{"id": "d58fbf17-442e-5153-8cdf-ce264a40ef4f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 1", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500001", "fecha_nacimiento": "2022-05-31", "estado_reproductivo": "inseminada"}	{"id": "d58fbf17-442e-5153-8cdf-ce264a40ef4f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 1", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500001", "fecha_nacimiento": "2022-05-31", "estado_reproductivo": "inseminada"}	postgres	92bd21d68cb98ac3898051b9d91fec7240601fd01178c12afea4fe57c47d804a
189	2026-06-01 07:46:03.856208+00	animales	UPDATE	c7ee8997-4bfb-56ca-9a3f-653af2d06595	{"id": "c7ee8997-4bfb-56ca-9a3f-653af2d06595", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 2", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-29", "crotal_oficial": "ES2706500002", "fecha_nacimiento": "2021-05-30", "estado_reproductivo": "confirmada_gestante"}	{"id": "c7ee8997-4bfb-56ca-9a3f-653af2d06595", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 2", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-29", "crotal_oficial": "ES2706500002", "fecha_nacimiento": "2021-05-30", "estado_reproductivo": "confirmada_gestante"}	postgres	ac9af49396c55321b74b07064306a49afd1a4dea6c833f0234bb92d721decdde
190	2026-06-01 07:46:03.856208+00	animales	UPDATE	0d506129-b7c5-507a-88ca-242344baa5de	{"id": "0d506129-b7c5-507a-88ca-242344baa5de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 3", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-28", "crotal_oficial": "ES2706500003", "fecha_nacimiento": "2020-05-29", "estado_reproductivo": "parto_reciente"}	{"id": "0d506129-b7c5-507a-88ca-242344baa5de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 3", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-28", "crotal_oficial": "ES2706500003", "fecha_nacimiento": "2020-05-29", "estado_reproductivo": "parto_reciente"}	postgres	58c53ed9867963060f680527707b14c72a77f699e274db0e3bf2d6a8e2f8a823
191	2026-06-01 07:46:03.856208+00	animales	UPDATE	73956a35-c183-5c88-9b6e-827903fe0241	{"id": "73956a35-c183-5c88-9b6e-827903fe0241", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 4", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-27", "crotal_oficial": "ES2706500004", "fecha_nacimiento": "2019-05-29", "estado_reproductivo": "vacia"}	{"id": "73956a35-c183-5c88-9b6e-827903fe0241", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 4", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-27", "crotal_oficial": "ES2706500004", "fecha_nacimiento": "2019-05-29", "estado_reproductivo": "vacia"}	postgres	e22331d986d849e35718d332f1cb7a0678b6d02e47ec6de1fc62131a8afe7d54
192	2026-06-01 07:46:03.856208+00	animales	UPDATE	e287b4b8-1876-527c-8b7c-7fdf85c42709	{"id": "e287b4b8-1876-527c-8b7c-7fdf85c42709", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 5", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-26", "crotal_oficial": "ES2706500005", "fecha_nacimiento": "2018-05-28", "estado_reproductivo": "inseminada"}	{"id": "e287b4b8-1876-527c-8b7c-7fdf85c42709", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 5", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-26", "crotal_oficial": "ES2706500005", "fecha_nacimiento": "2018-05-28", "estado_reproductivo": "inseminada"}	postgres	5afa173a07706ff95a4735e6dad281c9ec46649ee31edbd8aca7508bfdf18cb3
193	2026-06-01 07:46:03.856208+00	animales	UPDATE	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	{"id": "1a6e7a54-8774-52a6-896f-01a35b5cbc2d", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 6", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-25", "crotal_oficial": "ES2706500006", "fecha_nacimiento": "2023-05-26", "estado_reproductivo": "confirmada_gestante"}	{"id": "1a6e7a54-8774-52a6-896f-01a35b5cbc2d", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 6", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-25", "crotal_oficial": "ES2706500006", "fecha_nacimiento": "2023-05-26", "estado_reproductivo": "confirmada_gestante"}	postgres	53a13b5c3c4cd0d9094b1283558a8cb0ab4e4f06c370346c53ebdcdac1b74710
194	2026-06-01 07:46:03.856208+00	animales	UPDATE	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	{"id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 7", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-24", "crotal_oficial": "ES2706500007", "fecha_nacimiento": "2022-05-25", "estado_reproductivo": "parto_reciente"}	{"id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 7", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-24", "crotal_oficial": "ES2706500007", "fecha_nacimiento": "2022-05-25", "estado_reproductivo": "parto_reciente"}	postgres	14d75dc214ab57ee485edbb475daf4558a3473313887dc85333e73e3ad44b0b8
195	2026-06-01 07:46:03.856208+00	animales	UPDATE	3c97c346-b54c-5581-930e-f3264d6773ea	{"id": "3c97c346-b54c-5581-930e-f3264d6773ea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 8", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-23", "crotal_oficial": "ES2706500008", "fecha_nacimiento": "2021-05-24", "estado_reproductivo": "vacia"}	{"id": "3c97c346-b54c-5581-930e-f3264d6773ea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 8", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-23", "crotal_oficial": "ES2706500008", "fecha_nacimiento": "2021-05-24", "estado_reproductivo": "vacia"}	postgres	93a4acd9040c5130205aa1fbd3b3ecae91306a2c5e180a120fe891dde486bfae
196	2026-06-01 07:46:03.856208+00	animales	UPDATE	936b78c4-7b89-5fcf-97f7-54f007674e36	{"id": "936b78c4-7b89-5fcf-97f7-54f007674e36", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 9", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-22", "crotal_oficial": "ES2706500009", "fecha_nacimiento": "2020-05-23", "estado_reproductivo": "inseminada"}	{"id": "936b78c4-7b89-5fcf-97f7-54f007674e36", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 9", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-22", "crotal_oficial": "ES2706500009", "fecha_nacimiento": "2020-05-23", "estado_reproductivo": "inseminada"}	postgres	c2ffe34544b6466c40f4c1a5a2a2d8f8483b601ea8601ab63b4f64f3cf9516ea
197	2026-06-01 07:46:03.856208+00	animales	UPDATE	cf17702f-f18b-553e-9294-67e671e66022	{"id": "cf17702f-f18b-553e-9294-67e671e66022", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 10", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-21", "crotal_oficial": "ES2706500010", "fecha_nacimiento": "2019-05-23", "estado_reproductivo": "confirmada_gestante"}	{"id": "cf17702f-f18b-553e-9294-67e671e66022", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 10", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-21", "crotal_oficial": "ES2706500010", "fecha_nacimiento": "2019-05-23", "estado_reproductivo": "confirmada_gestante"}	postgres	045481b322291b20276d78a7e5fbabc8f0fe3bffebbc41339f3fd0aa21dfc4ba
198	2026-06-01 07:46:03.856208+00	animales	UPDATE	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	{"id": "2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 11", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-20", "crotal_oficial": "ES2706500011", "fecha_nacimiento": "2018-05-22", "estado_reproductivo": "parto_reciente"}	{"id": "2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 11", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-20", "crotal_oficial": "ES2706500011", "fecha_nacimiento": "2018-05-22", "estado_reproductivo": "parto_reciente"}	postgres	968c73719a9a58e51f9dd9aeb8864bc9a8fd2b84f8ad230d0ef98f177986eaf9
199	2026-06-01 07:46:03.856208+00	animales	UPDATE	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	{"id": "e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 12", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-19", "crotal_oficial": "ES2706500012", "fecha_nacimiento": "2023-05-20", "estado_reproductivo": "vacia"}	{"id": "e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 12", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-19", "crotal_oficial": "ES2706500012", "fecha_nacimiento": "2023-05-20", "estado_reproductivo": "vacia"}	postgres	c749b55608c0522ece38cf5756843e79adc711c0a40b2b6c1af48e774138e3f4
200	2026-06-01 07:46:03.856208+00	animales	UPDATE	d172a069-591a-55e4-89fc-32699f1d25c9	{"id": "d172a069-591a-55e4-89fc-32699f1d25c9", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 13", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-18", "crotal_oficial": "ES2706500013", "fecha_nacimiento": "2022-05-19", "estado_reproductivo": "inseminada"}	{"id": "d172a069-591a-55e4-89fc-32699f1d25c9", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 13", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-18", "crotal_oficial": "ES2706500013", "fecha_nacimiento": "2022-05-19", "estado_reproductivo": "inseminada"}	postgres	a6ceb29372604d452c759e8d028a1bcecd8a851ee215b85ee1543f6624be3879
201	2026-06-01 07:46:03.856208+00	animales	UPDATE	436a7ff2-5df5-51b1-a49f-179831808d47	{"id": "436a7ff2-5df5-51b1-a49f-179831808d47", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 14", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-17", "crotal_oficial": "ES2706500014", "fecha_nacimiento": "2021-05-18", "estado_reproductivo": "confirmada_gestante"}	{"id": "436a7ff2-5df5-51b1-a49f-179831808d47", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 14", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-17", "crotal_oficial": "ES2706500014", "fecha_nacimiento": "2021-05-18", "estado_reproductivo": "confirmada_gestante"}	postgres	44a26667b146e5195115c364202ea2ae73c2d268fddf36020dbd88282780aeea
202	2026-06-01 07:46:03.856208+00	animales	UPDATE	b5263713-2026-5bad-ae46-296dc48a39d3	{"id": "b5263713-2026-5bad-ae46-296dc48a39d3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 15", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-16", "crotal_oficial": "ES2706500015", "fecha_nacimiento": "2020-05-17", "estado_reproductivo": "parto_reciente"}	{"id": "b5263713-2026-5bad-ae46-296dc48a39d3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 15", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-16", "crotal_oficial": "ES2706500015", "fecha_nacimiento": "2020-05-17", "estado_reproductivo": "parto_reciente"}	postgres	316b2e0c3c00ad95974dcd5f0ad29d71d7c7903a76608af0aa47a513822f497b
203	2026-06-01 07:46:03.856208+00	animales	UPDATE	62d38b4e-74e0-5f20-b66b-64efddec53b7	{"id": "62d38b4e-74e0-5f20-b66b-64efddec53b7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 16", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-15", "crotal_oficial": "ES2706500016", "fecha_nacimiento": "2019-05-17", "estado_reproductivo": "vacia"}	{"id": "62d38b4e-74e0-5f20-b66b-64efddec53b7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 16", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-15", "crotal_oficial": "ES2706500016", "fecha_nacimiento": "2019-05-17", "estado_reproductivo": "vacia"}	postgres	f30bae4d48761408a7bd4337428656e6148d9ae5543f476331ce51944180263a
204	2026-06-01 07:46:03.856208+00	animales	UPDATE	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	{"id": "592b42b6-a0bc-52ed-8f7d-44a9ab00b455", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 17", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-14", "crotal_oficial": "ES2706500017", "fecha_nacimiento": "2018-05-16", "estado_reproductivo": "inseminada"}	{"id": "592b42b6-a0bc-52ed-8f7d-44a9ab00b455", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 17", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-14", "crotal_oficial": "ES2706500017", "fecha_nacimiento": "2018-05-16", "estado_reproductivo": "inseminada"}	postgres	e21a4cada4e3f13d9bf7d261b1c9991a60a74543d89f30cdec54857f5b5a2870
205	2026-06-01 07:46:03.856208+00	animales	UPDATE	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	{"id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 18", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-13", "crotal_oficial": "ES2706500018", "fecha_nacimiento": "2023-05-14", "estado_reproductivo": "confirmada_gestante"}	{"id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 18", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-13", "crotal_oficial": "ES2706500018", "fecha_nacimiento": "2023-05-14", "estado_reproductivo": "confirmada_gestante"}	postgres	4dffca05b185723d76e784493194e52e48784832778600e021d7bc7666459320
206	2026-06-01 07:46:03.856208+00	animales	UPDATE	df87133b-ee35-5f6c-982e-0b9e09ad3dea	{"id": "df87133b-ee35-5f6c-982e-0b9e09ad3dea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 19", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-12", "crotal_oficial": "ES2706500019", "fecha_nacimiento": "2022-05-13", "estado_reproductivo": "parto_reciente"}	{"id": "df87133b-ee35-5f6c-982e-0b9e09ad3dea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 19", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-12", "crotal_oficial": "ES2706500019", "fecha_nacimiento": "2022-05-13", "estado_reproductivo": "parto_reciente"}	postgres	06f258196864c19f453cef53474f0f19b3b0baa2116f3d55f19723733eb4128e
207	2026-06-01 07:46:03.856208+00	animales	UPDATE	afe8a03e-b5f2-5013-9b65-26fc935d703f	{"id": "afe8a03e-b5f2-5013-9b65-26fc935d703f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 20", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-11", "crotal_oficial": "ES2706500020", "fecha_nacimiento": "2021-05-12", "estado_reproductivo": "vacia"}	{"id": "afe8a03e-b5f2-5013-9b65-26fc935d703f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 20", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-11", "crotal_oficial": "ES2706500020", "fecha_nacimiento": "2021-05-12", "estado_reproductivo": "vacia"}	postgres	d6ad0d1e64afe863e0f1a3fc0309d1c8bec524227b3d7a2f15f1085e3fe433d4
208	2026-06-01 07:46:03.856208+00	animales	UPDATE	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	{"id": "e8761f6b-9037-5d8f-bca2-cd8caa3ab0af", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 21", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-10", "crotal_oficial": "ES2706500021", "fecha_nacimiento": "2020-05-11", "estado_reproductivo": "inseminada"}	{"id": "e8761f6b-9037-5d8f-bca2-cd8caa3ab0af", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 21", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-10", "crotal_oficial": "ES2706500021", "fecha_nacimiento": "2020-05-11", "estado_reproductivo": "inseminada"}	postgres	6c8fb8252bfea58aed9cf5a0c5c90f3856841c054a172cb807488ff84e02496d
209	2026-06-01 07:46:03.856208+00	animales	UPDATE	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	{"id": "5d712a13-ba73-5fb4-b4f1-1d2b15f2c988", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 22", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-09", "crotal_oficial": "ES2706500022", "fecha_nacimiento": "2019-05-11", "estado_reproductivo": "confirmada_gestante"}	{"id": "5d712a13-ba73-5fb4-b4f1-1d2b15f2c988", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 22", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-09", "crotal_oficial": "ES2706500022", "fecha_nacimiento": "2019-05-11", "estado_reproductivo": "confirmada_gestante"}	postgres	c686a8de878d6a99df6d1b4efd944a05fa131146ad0deecb1afaf0a2a55ea584
210	2026-06-01 07:46:03.856208+00	animales	UPDATE	1a1a57d7-fc16-5715-8133-35c906e0453a	{"id": "1a1a57d7-fc16-5715-8133-35c906e0453a", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 23", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-08", "crotal_oficial": "ES2706500023", "fecha_nacimiento": "2018-05-10", "estado_reproductivo": "parto_reciente"}	{"id": "1a1a57d7-fc16-5715-8133-35c906e0453a", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 23", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-08", "crotal_oficial": "ES2706500023", "fecha_nacimiento": "2018-05-10", "estado_reproductivo": "parto_reciente"}	postgres	fc810a38237b9a11d37dc552ee2556de88aa6ec6470e564b86f709cd2fb363a8
211	2026-06-01 07:46:03.856208+00	animales	UPDATE	4c13e989-899c-5d47-8988-380802d72f58	{"id": "4c13e989-899c-5d47-8988-380802d72f58", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 24", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-07", "crotal_oficial": "ES2706500024", "fecha_nacimiento": "2023-05-08", "estado_reproductivo": "vacia"}	{"id": "4c13e989-899c-5d47-8988-380802d72f58", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 24", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-07", "crotal_oficial": "ES2706500024", "fecha_nacimiento": "2023-05-08", "estado_reproductivo": "vacia"}	postgres	a52795a7702cdf37c30bc08a43a2f572bb4fef67083f162d7bd73c1c89bc2f0a
212	2026-06-01 07:46:03.856208+00	animales	UPDATE	784ed9c6-39d3-5da9-b379-311aca240fdd	{"id": "784ed9c6-39d3-5da9-b379-311aca240fdd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 25", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-06", "crotal_oficial": "ES2706500025", "fecha_nacimiento": "2022-05-07", "estado_reproductivo": "inseminada"}	{"id": "784ed9c6-39d3-5da9-b379-311aca240fdd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 25", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-06", "crotal_oficial": "ES2706500025", "fecha_nacimiento": "2022-05-07", "estado_reproductivo": "inseminada"}	postgres	cd055ca025bcb218102646265d7f2e1d4cb30715e76351e275ed9feba1f2cffe
213	2026-06-01 07:46:03.856208+00	animales	UPDATE	46e29b13-6344-5b6d-8471-0891456bd85b	{"id": "46e29b13-6344-5b6d-8471-0891456bd85b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 26", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-05", "crotal_oficial": "ES2706500026", "fecha_nacimiento": "2021-05-06", "estado_reproductivo": "confirmada_gestante"}	{"id": "46e29b13-6344-5b6d-8471-0891456bd85b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 26", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-05", "crotal_oficial": "ES2706500026", "fecha_nacimiento": "2021-05-06", "estado_reproductivo": "confirmada_gestante"}	postgres	7e865a249254038457ec110213804f9883d9efe44681bbf72458a42ce6b7cb87
214	2026-06-01 07:46:03.856208+00	animales	UPDATE	20cb75da-56ec-50b5-85f8-792b0d74f745	{"id": "20cb75da-56ec-50b5-85f8-792b0d74f745", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 27", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-04", "crotal_oficial": "ES2706500027", "fecha_nacimiento": "2020-05-05", "estado_reproductivo": "parto_reciente"}	{"id": "20cb75da-56ec-50b5-85f8-792b0d74f745", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 27", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-04", "crotal_oficial": "ES2706500027", "fecha_nacimiento": "2020-05-05", "estado_reproductivo": "parto_reciente"}	postgres	1567d77bf88630306981636f1466925e064971b73c9791153289205a6da24852
215	2026-06-01 07:46:03.856208+00	animales	UPDATE	1c069679-3e6d-5b3e-8842-c27c074da0a0	{"id": "1c069679-3e6d-5b3e-8842-c27c074da0a0", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 28", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-03", "crotal_oficial": "ES2706500028", "fecha_nacimiento": "2019-05-05", "estado_reproductivo": "vacia"}	{"id": "1c069679-3e6d-5b3e-8842-c27c074da0a0", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 28", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-03", "crotal_oficial": "ES2706500028", "fecha_nacimiento": "2019-05-05", "estado_reproductivo": "vacia"}	postgres	cf4bdfc8042e36a3c1d4c65396f703e6831057b2b773ad6c8bd8b13b3b6ef874
216	2026-06-01 07:46:03.856208+00	animales	UPDATE	fae53a98-6313-583b-8c58-8e81fe950f6e	{"id": "fae53a98-6313-583b-8c58-8e81fe950f6e", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 29", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-02", "crotal_oficial": "ES2706500029", "fecha_nacimiento": "2018-05-04", "estado_reproductivo": "inseminada"}	{"id": "fae53a98-6313-583b-8c58-8e81fe950f6e", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 29", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-02", "crotal_oficial": "ES2706500029", "fecha_nacimiento": "2018-05-04", "estado_reproductivo": "inseminada"}	postgres	333dda005053614b01190cd7c89427bc436c25d4b951f3ba92de8eceba38d390
217	2026-06-01 07:46:03.856208+00	animales	UPDATE	eeded079-9abf-5844-8559-6eea890a6fe4	{"id": "eeded079-9abf-5844-8559-6eea890a6fe4", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 30", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-01", "crotal_oficial": "ES2706500030", "fecha_nacimiento": "2023-05-02", "estado_reproductivo": "confirmada_gestante"}	{"id": "eeded079-9abf-5844-8559-6eea890a6fe4", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 30", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-01", "crotal_oficial": "ES2706500030", "fecha_nacimiento": "2023-05-02", "estado_reproductivo": "confirmada_gestante"}	postgres	4d393a89175c3534a1234e9b50801c7d0ff76dc2c6322ced618a3df510ef4dcf
218	2026-06-01 07:46:03.856208+00	animales	UPDATE	674f97b3-f5f9-5ead-bf6c-d743870ba36f	{"id": "674f97b3-f5f9-5ead-bf6c-d743870ba36f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 31", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-30", "crotal_oficial": "ES2706500031", "fecha_nacimiento": "2022-05-01", "estado_reproductivo": "parto_reciente"}	{"id": "674f97b3-f5f9-5ead-bf6c-d743870ba36f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 31", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-30", "crotal_oficial": "ES2706500031", "fecha_nacimiento": "2022-05-01", "estado_reproductivo": "parto_reciente"}	postgres	b64706bc048e3760f8644b8d5ae33045de6b583a4bee1030a35de70244ebfcf1
219	2026-06-01 07:46:03.856208+00	animales	UPDATE	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	{"id": "0f5350db-fd30-58b4-bf08-ae0b3ca94afd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 32", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-29", "crotal_oficial": "ES2706500032", "fecha_nacimiento": "2021-04-30", "estado_reproductivo": "vacia"}	{"id": "0f5350db-fd30-58b4-bf08-ae0b3ca94afd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 32", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-29", "crotal_oficial": "ES2706500032", "fecha_nacimiento": "2021-04-30", "estado_reproductivo": "vacia"}	postgres	160373cd42063facd254c7739c6bbbf81a99979b507f9fc5922e0662701e5cfc
220	2026-06-01 07:46:03.856208+00	animales	UPDATE	3f9aca1c-2859-5e86-909b-fe2777f960ca	{"id": "3f9aca1c-2859-5e86-909b-fe2777f960ca", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 33", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-28", "crotal_oficial": "ES2706500033", "fecha_nacimiento": "2020-04-29", "estado_reproductivo": "inseminada"}	{"id": "3f9aca1c-2859-5e86-909b-fe2777f960ca", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 33", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-28", "crotal_oficial": "ES2706500033", "fecha_nacimiento": "2020-04-29", "estado_reproductivo": "inseminada"}	postgres	db299a386b2b9145ca0029fd10dc0b5a161f1598f96a53da67c4616aa90d6f9d
221	2026-06-01 07:46:03.856208+00	animales	UPDATE	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	{"id": "9baa72c1-9b94-594b-8926-8a3c17ee9ac7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 34", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-27", "crotal_oficial": "ES2706500034", "fecha_nacimiento": "2019-04-29", "estado_reproductivo": "confirmada_gestante"}	{"id": "9baa72c1-9b94-594b-8926-8a3c17ee9ac7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 34", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-27", "crotal_oficial": "ES2706500034", "fecha_nacimiento": "2019-04-29", "estado_reproductivo": "confirmada_gestante"}	postgres	4451821ce1cdd6a638a63bcd002c05e66fc56a74cda38f718b4a8fe7e8cf5d58
222	2026-06-01 07:46:03.856208+00	animales	UPDATE	ac52e314-03fc-5fc7-95c8-e51551ffca78	{"id": "ac52e314-03fc-5fc7-95c8-e51551ffca78", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 35", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-26", "crotal_oficial": "ES2706500035", "fecha_nacimiento": "2018-04-28", "estado_reproductivo": "parto_reciente"}	{"id": "ac52e314-03fc-5fc7-95c8-e51551ffca78", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 35", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-26", "crotal_oficial": "ES2706500035", "fecha_nacimiento": "2018-04-28", "estado_reproductivo": "parto_reciente"}	postgres	1a8589fc70ee4a7528952bc2bcde20b1b59ab5a42077b6bc08aec8612ccf5c0b
223	2026-06-01 07:46:03.856208+00	animales	UPDATE	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	{"id": "bb9fc07f-076f-5182-93d0-8eb2ece1ee89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 36", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-25", "crotal_oficial": "ES2706500036", "fecha_nacimiento": "2023-04-26", "estado_reproductivo": "vacia"}	{"id": "bb9fc07f-076f-5182-93d0-8eb2ece1ee89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 36", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-25", "crotal_oficial": "ES2706500036", "fecha_nacimiento": "2023-04-26", "estado_reproductivo": "vacia"}	postgres	1af64eff5e406a7534d54d52cdbd93b841d3c2a749e86f4eb9288f3275c2b0dc
224	2026-06-01 07:46:03.856208+00	animales	UPDATE	6b224987-9434-5637-a871-9ac01fd4d4c3	{"id": "6b224987-9434-5637-a871-9ac01fd4d4c3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 37", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-24", "crotal_oficial": "ES2706500037", "fecha_nacimiento": "2022-04-25", "estado_reproductivo": "inseminada"}	{"id": "6b224987-9434-5637-a871-9ac01fd4d4c3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 37", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-24", "crotal_oficial": "ES2706500037", "fecha_nacimiento": "2022-04-25", "estado_reproductivo": "inseminada"}	postgres	78f6e986e055e422a8a7c62f9d2fdec995ac87ec9541f5da3fb5527746bab176
225	2026-06-01 07:46:03.856208+00	animales	UPDATE	abe64d55-ec3c-53f6-8051-84c8f56b51d5	{"id": "abe64d55-ec3c-53f6-8051-84c8f56b51d5", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 38", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-23", "crotal_oficial": "ES2706500038", "fecha_nacimiento": "2021-04-24", "estado_reproductivo": "confirmada_gestante"}	{"id": "abe64d55-ec3c-53f6-8051-84c8f56b51d5", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 38", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-23", "crotal_oficial": "ES2706500038", "fecha_nacimiento": "2021-04-24", "estado_reproductivo": "confirmada_gestante"}	postgres	bb82af9f5f3c8a0c1377b8bead10e692f4bb785dbf2be2f4e251c2078ccdaf0c
226	2026-06-01 07:46:03.856208+00	animales	UPDATE	2e14a84a-511d-5bcf-867c-216522289b1c	{"id": "2e14a84a-511d-5bcf-867c-216522289b1c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 39", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-22", "crotal_oficial": "ES2706500039", "fecha_nacimiento": "2020-04-23", "estado_reproductivo": "parto_reciente"}	{"id": "2e14a84a-511d-5bcf-867c-216522289b1c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 39", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-22", "crotal_oficial": "ES2706500039", "fecha_nacimiento": "2020-04-23", "estado_reproductivo": "parto_reciente"}	postgres	f91c7ee9d2032e0c7b0ab3b5b58a42c9cd89f42366ac8175e477fbd9d48043a3
227	2026-06-01 07:46:03.856208+00	animales	UPDATE	bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7	{"id": "bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 40", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-21", "crotal_oficial": "ES2706500040", "fecha_nacimiento": "2019-04-23", "estado_reproductivo": "vacia"}	{"id": "bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 40", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-21", "crotal_oficial": "ES2706500040", "fecha_nacimiento": "2019-04-23", "estado_reproductivo": "vacia"}	postgres	3ebe9afb616a00e7c347da83ee5422d7226c664c38eba5d978dca08ea3ff6c67
228	2026-06-01 07:46:03.856208+00	animales	UPDATE	2a91fb61-47ee-5001-a3e6-0e56c0f91308	{"id": "2a91fb61-47ee-5001-a3e6-0e56c0f91308", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 41", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-20", "crotal_oficial": "ES2706500041", "fecha_nacimiento": "2018-04-22", "estado_reproductivo": "inseminada"}	{"id": "2a91fb61-47ee-5001-a3e6-0e56c0f91308", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 41", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-20", "crotal_oficial": "ES2706500041", "fecha_nacimiento": "2018-04-22", "estado_reproductivo": "inseminada"}	postgres	f3d6005fa12193ce50db13ac2847e6521b0aee8ba98d83a20790dbc648b442a3
229	2026-06-01 07:46:03.856208+00	animales	UPDATE	df02d6c2-f792-565d-ac97-d358d7484092	{"id": "df02d6c2-f792-565d-ac97-d358d7484092", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 42", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-19", "crotal_oficial": "ES2706500042", "fecha_nacimiento": "2023-04-20", "estado_reproductivo": "confirmada_gestante"}	{"id": "df02d6c2-f792-565d-ac97-d358d7484092", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 42", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-19", "crotal_oficial": "ES2706500042", "fecha_nacimiento": "2023-04-20", "estado_reproductivo": "confirmada_gestante"}	postgres	3dd3343ff6b50e2963ce342f396a26871c760519ead51d8311478a0862c823cc
230	2026-06-01 07:46:03.856208+00	animales	UPDATE	78f6b86f-6d19-50c5-a003-4cf0c0c02e22	{"id": "78f6b86f-6d19-50c5-a003-4cf0c0c02e22", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 43", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-18", "crotal_oficial": "ES2706500043", "fecha_nacimiento": "2022-04-19", "estado_reproductivo": "parto_reciente"}	{"id": "78f6b86f-6d19-50c5-a003-4cf0c0c02e22", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 43", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-18", "crotal_oficial": "ES2706500043", "fecha_nacimiento": "2022-04-19", "estado_reproductivo": "parto_reciente"}	postgres	b36ccdacb70766c236e771d0ebdd3938725392547c9287f1548015c519fe9cff
231	2026-06-01 07:46:03.856208+00	animales	UPDATE	c06ec15f-7d13-5837-b7c2-0b8b8465b3c1	{"id": "c06ec15f-7d13-5837-b7c2-0b8b8465b3c1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 44", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-17", "crotal_oficial": "ES2706500044", "fecha_nacimiento": "2021-04-18", "estado_reproductivo": "vacia"}	{"id": "c06ec15f-7d13-5837-b7c2-0b8b8465b3c1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 44", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-17", "crotal_oficial": "ES2706500044", "fecha_nacimiento": "2021-04-18", "estado_reproductivo": "vacia"}	postgres	ce17b83164e122f08e9528827b6bb36a53b2e0a94a61e6738165fed8252bc7dc
232	2026-06-01 07:46:03.856208+00	animales	UPDATE	0238f86f-4409-54d4-b4eb-0d28d7b4af0c	{"id": "0238f86f-4409-54d4-b4eb-0d28d7b4af0c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 45", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-16", "crotal_oficial": "ES2706500045", "fecha_nacimiento": "2020-04-17", "estado_reproductivo": "inseminada"}	{"id": "0238f86f-4409-54d4-b4eb-0d28d7b4af0c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 45", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-16", "crotal_oficial": "ES2706500045", "fecha_nacimiento": "2020-04-17", "estado_reproductivo": "inseminada"}	postgres	087d6e78c38acb7847eba0949f844117d91c364d4ac2a7c9089c3a78b581e1ae
233	2026-06-01 07:46:03.856208+00	animales	UPDATE	c9303516-f788-5f46-90dd-bb82d7023d71	{"id": "c9303516-f788-5f46-90dd-bb82d7023d71", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 46", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-15", "crotal_oficial": "ES2706500046", "fecha_nacimiento": "2019-04-17", "estado_reproductivo": "confirmada_gestante"}	{"id": "c9303516-f788-5f46-90dd-bb82d7023d71", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 46", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-15", "crotal_oficial": "ES2706500046", "fecha_nacimiento": "2019-04-17", "estado_reproductivo": "confirmada_gestante"}	postgres	991bae235b9f3b28b66b798ed0f986a45928688caf7813844cc1030638b213d0
234	2026-06-01 07:46:03.856208+00	animales	UPDATE	a306664d-4e62-530d-8fe8-28ebfce56181	{"id": "a306664d-4e62-530d-8fe8-28ebfce56181", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 47", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-14", "crotal_oficial": "ES2706500047", "fecha_nacimiento": "2018-04-16", "estado_reproductivo": "parto_reciente"}	{"id": "a306664d-4e62-530d-8fe8-28ebfce56181", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Noa 47", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-14", "crotal_oficial": "ES2706500047", "fecha_nacimiento": "2018-04-16", "estado_reproductivo": "parto_reciente"}	postgres	bf7f0ba46c36ab30646607f7c9e9559c914dc91a82e004ff5d3e54e82dbc7802
235	2026-06-01 07:46:03.856208+00	animales	UPDATE	ab19f1c4-775c-5f7d-8fad-c7b0cea81217	{"id": "ab19f1c4-775c-5f7d-8fad-c7b0cea81217", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 48", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-13", "crotal_oficial": "ES2706500048", "fecha_nacimiento": "2023-04-14", "estado_reproductivo": "vacia"}	{"id": "ab19f1c4-775c-5f7d-8fad-c7b0cea81217", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 48", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-13", "crotal_oficial": "ES2706500048", "fecha_nacimiento": "2023-04-14", "estado_reproductivo": "vacia"}	postgres	f1c2da9dcdd6aac0a26236be9f747329f9ff370088aef7abd682dd923621cd09
236	2026-06-01 07:46:03.856208+00	animales	UPDATE	9a533fa2-4f96-500a-af83-80da01f2370d	{"id": "9a533fa2-4f96-500a-af83-80da01f2370d", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 49", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-12", "crotal_oficial": "ES2706500049", "fecha_nacimiento": "2022-04-13", "estado_reproductivo": "inseminada"}	{"id": "9a533fa2-4f96-500a-af83-80da01f2370d", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 49", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-12", "crotal_oficial": "ES2706500049", "fecha_nacimiento": "2022-04-13", "estado_reproductivo": "inseminada"}	postgres	37e6814f990be4656233e16002cdd9fb15936564e8c9a3393021fea80a1738f7
237	2026-06-01 07:46:03.856208+00	animales	UPDATE	0db75e34-604b-511f-8aea-4156fe8eb5d1	{"id": "0db75e34-604b-511f-8aea-4156fe8eb5d1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 50", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-11", "crotal_oficial": "ES2706500050", "fecha_nacimiento": "2021-04-12", "estado_reproductivo": "confirmada_gestante"}	{"id": "0db75e34-604b-511f-8aea-4156fe8eb5d1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Brisa 50", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-11", "crotal_oficial": "ES2706500050", "fecha_nacimiento": "2021-04-12", "estado_reproductivo": "confirmada_gestante"}	postgres	1a2915e8bd98467d9552d53350acb0fa6f9bc276dac8a3f13f93f2ac34cf4f6a
238	2026-06-01 07:46:03.856208+00	animales	UPDATE	1cb96771-c7de-53e3-b737-2954be5a71de	{"id": "1cb96771-c7de-53e3-b737-2954be5a71de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 51", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-10", "crotal_oficial": "ES2706500051", "fecha_nacimiento": "2020-04-11", "estado_reproductivo": "parto_reciente"}	{"id": "1cb96771-c7de-53e3-b737-2954be5a71de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 51", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-10", "crotal_oficial": "ES2706500051", "fecha_nacimiento": "2020-04-11", "estado_reproductivo": "parto_reciente"}	postgres	7ff414747e430bdbb8f2ed5df40619e6da7b50f1fc7d21e01a5034a213c79d23
239	2026-06-01 07:46:03.856208+00	animales	UPDATE	7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6	{"id": "7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 52", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-09", "crotal_oficial": "ES2706500052", "fecha_nacimiento": "2019-04-11", "estado_reproductivo": "vacia"}	{"id": "7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 52", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-09", "crotal_oficial": "ES2706500052", "fecha_nacimiento": "2019-04-11", "estado_reproductivo": "vacia"}	postgres	24fa1b18d9c8eadac458d154de7fa51c2dd72c10ec7ee4208fe1fbd78e27583b
240	2026-06-01 07:46:03.856208+00	animales	UPDATE	b7e68ca6-a516-52f8-9a88-8f272749ac23	{"id": "b7e68ca6-a516-52f8-9a88-8f272749ac23", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 53", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-08", "crotal_oficial": "ES2706500053", "fecha_nacimiento": "2018-04-10", "estado_reproductivo": "inseminada"}	{"id": "b7e68ca6-a516-52f8-9a88-8f272749ac23", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Vega 53", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-08", "crotal_oficial": "ES2706500053", "fecha_nacimiento": "2018-04-10", "estado_reproductivo": "inseminada"}	postgres	b5550619fa9fdebfe738189c8fc739495dd020fd280c656fdc3dd1c4b2c0e33c
241	2026-06-01 07:46:03.856208+00	animales	UPDATE	329e2c29-366f-56b0-b854-ca7cb56bff5f	{"id": "329e2c29-366f-56b0-b854-ca7cb56bff5f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 54", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-07", "crotal_oficial": "ES2706500054", "fecha_nacimiento": "2023-04-08", "estado_reproductivo": "confirmada_gestante"}	{"id": "329e2c29-366f-56b0-b854-ca7cb56bff5f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 54", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-07", "crotal_oficial": "ES2706500054", "fecha_nacimiento": "2023-04-08", "estado_reproductivo": "confirmada_gestante"}	postgres	446e1da9d889ca40f86fe8b9a70f5b4584764524e9656599f307ae2a94b38227
242	2026-06-01 07:46:03.856208+00	animales	UPDATE	9144858f-31c8-575d-a0ae-366e1d2935fd	{"id": "9144858f-31c8-575d-a0ae-366e1d2935fd", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 55", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-06", "crotal_oficial": "ES2706500055", "fecha_nacimiento": "2022-04-07", "estado_reproductivo": "parto_reciente"}	{"id": "9144858f-31c8-575d-a0ae-366e1d2935fd", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 55", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-06", "crotal_oficial": "ES2706500055", "fecha_nacimiento": "2022-04-07", "estado_reproductivo": "parto_reciente"}	postgres	4cd0e968d82f062ba9bc1b440a81b8c9eaf7fd5c1440ff873a33c58c7b8945c6
243	2026-06-01 07:46:03.856208+00	animales	UPDATE	ab624830-c14c-5b1a-afcc-f0b59876050a	{"id": "ab624830-c14c-5b1a-afcc-f0b59876050a", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 56", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-05", "crotal_oficial": "ES2706500056", "fecha_nacimiento": "2021-04-06", "estado_reproductivo": "vacia"}	{"id": "ab624830-c14c-5b1a-afcc-f0b59876050a", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nora 56", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-05", "crotal_oficial": "ES2706500056", "fecha_nacimiento": "2021-04-06", "estado_reproductivo": "vacia"}	postgres	a632160d2a0759dc6070ef3110e109c76b20aead6d7ee1c90a3231ad9ef28d60
244	2026-06-01 07:46:03.856208+00	animales	UPDATE	798cfeb1-fa83-529d-b119-c7f5cd60f5cd	{"id": "798cfeb1-fa83-529d-b119-c7f5cd60f5cd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 57", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-04", "crotal_oficial": "ES2706500057", "fecha_nacimiento": "2020-04-05", "estado_reproductivo": "inseminada"}	{"id": "798cfeb1-fa83-529d-b119-c7f5cd60f5cd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 57", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-04", "crotal_oficial": "ES2706500057", "fecha_nacimiento": "2020-04-05", "estado_reproductivo": "inseminada"}	postgres	5cfd2ff6a750c8d54fdcf226e00125dbc35e2f6184fb06defbb77ee7b091a538
245	2026-06-01 07:46:03.856208+00	animales	UPDATE	a3c69881-650f-5671-9ae6-8371fb892b89	{"id": "a3c69881-650f-5671-9ae6-8371fb892b89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 58", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-03", "crotal_oficial": "ES2706500058", "fecha_nacimiento": "2019-04-05", "estado_reproductivo": "confirmada_gestante"}	{"id": "a3c69881-650f-5671-9ae6-8371fb892b89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 58", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-03", "crotal_oficial": "ES2706500058", "fecha_nacimiento": "2019-04-05", "estado_reproductivo": "confirmada_gestante"}	postgres	9df89d3f0c5aaaba379278826c795f07d9dd61acf231abdbfb56e8236811aed9
246	2026-06-01 07:46:04.003094+00	animales	UPDATE	0f7ff532-8875-5404-8a53-3c204bdf55e1	{"id": "0f7ff532-8875-5404-8a53-3c204bdf55e1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Noa 59", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-02", "crotal_oficial": "ES2706500059", "fecha_nacimiento": "2018-04-04", "estado_reproductivo": "confirmada_gestante"}	{"id": "0f7ff532-8875-5404-8a53-3c204bdf55e1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Noa 59", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-02", "crotal_oficial": "ES2706500059", "fecha_nacimiento": "2018-04-04", "estado_reproductivo": "confirmada_gestante"}	postgres	d4b918ac852d046cba425575e13c74d4bd1cf6f3b76363acd1a4a258495a6ad9
247	2026-06-01 07:46:04.003094+00	animales	UPDATE	1f8d73e0-6258-536a-bb01-0fcdd4b96b26	{"id": "1f8d73e0-6258-536a-bb01-0fcdd4b96b26", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Luna 60", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-01", "crotal_oficial": "ES2706500060", "fecha_nacimiento": "2022-04-02", "estado_reproductivo": "confirmada_gestante"}	{"id": "1f8d73e0-6258-536a-bb01-0fcdd4b96b26", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Luna 60", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-01", "crotal_oficial": "ES2706500060", "fecha_nacimiento": "2022-04-02", "estado_reproductivo": "confirmada_gestante"}	postgres	bac61d00959593ebdf2cebcfc974ff2d221c37041568c0b551927e6aa153e444
248	2026-06-01 07:46:04.003094+00	animales	UPDATE	5dc5cac3-6bb9-5d56-957b-7677c4bcc56b	{"id": "5dc5cac3-6bb9-5d56-957b-7677c4bcc56b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nube 61", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-31", "crotal_oficial": "ES2706500061", "fecha_nacimiento": "2021-04-01", "estado_reproductivo": "confirmada_gestante"}	{"id": "5dc5cac3-6bb9-5d56-957b-7677c4bcc56b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nube 61", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-31", "crotal_oficial": "ES2706500061", "fecha_nacimiento": "2021-04-01", "estado_reproductivo": "confirmada_gestante"}	postgres	1977b78a8b7ebda3bb7b4cc6c94329cf370cba93eb0690f0fb8aca9e7ea82336
249	2026-06-01 07:46:04.003094+00	animales	UPDATE	12ba4d63-24a9-5f3c-9204-99590678f5ed	{"id": "12ba4d63-24a9-5f3c-9204-99590678f5ed", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Brisa 62", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-30", "crotal_oficial": "ES2706500062", "fecha_nacimiento": "2020-03-31", "estado_reproductivo": "confirmada_gestante"}	{"id": "12ba4d63-24a9-5f3c-9204-99590678f5ed", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Brisa 62", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-30", "crotal_oficial": "ES2706500062", "fecha_nacimiento": "2020-03-31", "estado_reproductivo": "confirmada_gestante"}	postgres	9fedd6a38297248d593522a0b24b7604d033d120b7a7e7325610d0fbe41819a1
250	2026-06-01 07:46:04.003094+00	animales	UPDATE	09065fbe-c2e5-500a-93cc-5f9f55d9f114	{"id": "09065fbe-c2e5-500a-93cc-5f9f55d9f114", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Mora 63", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-29", "crotal_oficial": "ES2706500063", "fecha_nacimiento": "2019-03-31", "estado_reproductivo": "confirmada_gestante"}	{"id": "09065fbe-c2e5-500a-93cc-5f9f55d9f114", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Mora 63", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-29", "crotal_oficial": "ES2706500063", "fecha_nacimiento": "2019-03-31", "estado_reproductivo": "confirmada_gestante"}	postgres	4a6e2b62278abedd4771c5e57ec905f35fa03e6b87369715c8e42fa51f835006
251	2026-06-01 07:46:04.003094+00	animales	UPDATE	5dbdee66-af90-503d-b6c5-b428cebb2b91	{"id": "5dbdee66-af90-503d-b6c5-b428cebb2b91", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Dalia 64", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-28", "crotal_oficial": "ES2706500064", "fecha_nacimiento": "2018-03-30", "estado_reproductivo": "confirmada_gestante"}	{"id": "5dbdee66-af90-503d-b6c5-b428cebb2b91", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Dalia 64", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-28", "crotal_oficial": "ES2706500064", "fecha_nacimiento": "2018-03-30", "estado_reproductivo": "confirmada_gestante"}	postgres	8c15fa2927719f34b4b58869d3910b201ca2e3e6937f3dbbd7b33af59019218a
252	2026-06-01 07:46:04.003094+00	animales	UPDATE	5c888535-5880-5f6c-b53c-128c9df5464b	{"id": "5c888535-5880-5f6c-b53c-128c9df5464b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Vega 65", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-27", "crotal_oficial": "ES2706500065", "fecha_nacimiento": "2022-03-28", "estado_reproductivo": "confirmada_gestante"}	{"id": "5c888535-5880-5f6c-b53c-128c9df5464b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Vega 65", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-27", "crotal_oficial": "ES2706500065", "fecha_nacimiento": "2022-03-28", "estado_reproductivo": "confirmada_gestante"}	postgres	eaeb08872edaa352b55aa34a9d085125256ce1283550d7073b1fbdeccc122e40
253	2026-06-01 07:46:04.003094+00	animales	UPDATE	963164ac-9734-5fd9-bd3a-fc7dacff84e1	{"id": "963164ac-9734-5fd9-bd3a-fc7dacff84e1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Senda 66", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-26", "crotal_oficial": "ES2706500066", "fecha_nacimiento": "2021-03-27", "estado_reproductivo": "confirmada_gestante"}	{"id": "963164ac-9734-5fd9-bd3a-fc7dacff84e1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Senda 66", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-26", "crotal_oficial": "ES2706500066", "fecha_nacimiento": "2021-03-27", "estado_reproductivo": "confirmada_gestante"}	postgres	2659e0f8ddfde954efae97798e9f69084e45a4e16f59831b5cf674440b960075
254	2026-06-01 07:46:04.003094+00	animales	UPDATE	ffe82114-3a26-5e7b-8ce6-7a8ef2f12732	{"id": "ffe82114-3a26-5e7b-8ce6-7a8ef2f12732", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Cora 67", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-25", "crotal_oficial": "ES2706500067", "fecha_nacimiento": "2020-03-26", "estado_reproductivo": "confirmada_gestante"}	{"id": "ffe82114-3a26-5e7b-8ce6-7a8ef2f12732", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Cora 67", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-25", "crotal_oficial": "ES2706500067", "fecha_nacimiento": "2020-03-26", "estado_reproductivo": "confirmada_gestante"}	postgres	51746672aec16648a74964816d0c0e67213a9249cef8850aae28b16498031346
255	2026-06-01 07:46:04.003094+00	animales	UPDATE	efc8bf74-ef7d-5152-a4d4-a077ae7a7d52	{"id": "efc8bf74-ef7d-5152-a4d4-a077ae7a7d52", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nora 68", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-24", "crotal_oficial": "ES2706500068", "fecha_nacimiento": "2019-03-26", "estado_reproductivo": "confirmada_gestante"}	{"id": "efc8bf74-ef7d-5152-a4d4-a077ae7a7d52", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nora 68", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-24", "crotal_oficial": "ES2706500068", "fecha_nacimiento": "2019-03-26", "estado_reproductivo": "confirmada_gestante"}	postgres	1c595236883e0bde9f7b957d473707dd3a118a52fcf71e0febc7835d270b6796
256	2026-06-01 07:46:04.003094+00	animales	UPDATE	27ba2d06-b334-5f7c-bd59-ba67cf095d68	{"id": "27ba2d06-b334-5f7c-bd59-ba67cf095d68", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Oliva 69", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-23", "crotal_oficial": "ES2706500069", "fecha_nacimiento": "2018-03-25", "estado_reproductivo": "confirmada_gestante"}	{"id": "27ba2d06-b334-5f7c-bd59-ba67cf095d68", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Oliva 69", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-23", "crotal_oficial": "ES2706500069", "fecha_nacimiento": "2018-03-25", "estado_reproductivo": "confirmada_gestante"}	postgres	f8550386ed965d6f8636329ec2dc66d5e8f6a1bd0d4f49125d2c480b27b2f1c8
257	2026-06-01 07:46:04.003094+00	animales	UPDATE	389f3969-2148-5055-82d6-166a20ab6a9b	{"id": "389f3969-2148-5055-82d6-166a20ab6a9b", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Xiana 70", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-22", "crotal_oficial": "ES2706500070", "fecha_nacimiento": "2022-03-23", "estado_reproductivo": "confirmada_gestante"}	{"id": "389f3969-2148-5055-82d6-166a20ab6a9b", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Xiana 70", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-22", "crotal_oficial": "ES2706500070", "fecha_nacimiento": "2022-03-23", "estado_reproductivo": "confirmada_gestante"}	postgres	5c16173bb594fbac29a7cf9ec48bae25aaf2a170a551e8c76d5c601da4678522
258	2026-06-01 07:46:04.013977+00	animales	UPDATE	19eeaa52-2c8b-5e63-ace0-ef1ec00d6da9	{"id": "19eeaa52-2c8b-5e63-ace0-ef1ec00d6da9", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Noa 83", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-08", "crotal_oficial": "ES2706500083", "fecha_nacimiento": "2026-02-12", "estado_reproductivo": null}	{"id": "19eeaa52-2c8b-5e63-ace0-ef1ec00d6da9", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Noa 83", "zona_id": "bc97e385-bbd8-5163-895a-b7156b84e145", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-08", "crotal_oficial": "ES2706500083", "fecha_nacimiento": "2026-02-12", "estado_reproductivo": null}	postgres	ed99d18e794bad94e6094344d664d14ec4debf62e376ae47ba2a30eb573a2cdc
259	2026-06-01 07:46:04.013977+00	animales	UPDATE	70a72a01-c51c-5511-b0ee-276eeec0db42	{"id": "70a72a01-c51c-5511-b0ee-276eeec0db42", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Luna 84", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-07", "crotal_oficial": "ES2706500084", "fecha_nacimiento": "2026-02-11", "estado_reproductivo": null}	{"id": "70a72a01-c51c-5511-b0ee-276eeec0db42", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Luna 84", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-07", "crotal_oficial": "ES2706500084", "fecha_nacimiento": "2026-02-11", "estado_reproductivo": null}	postgres	d20d189e122b6ad9499521d573d856996f6f366450601e2fe7cab6168d3be9bc
261	2026-06-01 07:46:04.013977+00	animales	UPDATE	7aaf1f29-d947-5361-9119-50eed5155dcc	{"id": "7aaf1f29-d947-5361-9119-50eed5155dcc", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Brisa 86", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-05", "crotal_oficial": "ES2706500086", "fecha_nacimiento": "2026-02-09", "estado_reproductivo": null}	{"id": "7aaf1f29-d947-5361-9119-50eed5155dcc", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Brisa 86", "zona_id": "bc97e385-bbd8-5163-895a-b7156b84e145", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-05", "crotal_oficial": "ES2706500086", "fecha_nacimiento": "2026-02-09", "estado_reproductivo": null}	postgres	a4c70155b41f533737c1187f6327dcb84e203c08568c2450b1a0b24f4c6a9eda
262	2026-06-01 07:46:04.013977+00	animales	UPDATE	f8f9284b-2242-54c3-9435-e9a2db95edef	{"id": "f8f9284b-2242-54c3-9435-e9a2db95edef", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Mora 87", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-04", "crotal_oficial": "ES2706500087", "fecha_nacimiento": "2026-02-08", "estado_reproductivo": null}	{"id": "f8f9284b-2242-54c3-9435-e9a2db95edef", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Mora 87", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-04", "crotal_oficial": "ES2706500087", "fecha_nacimiento": "2026-02-08", "estado_reproductivo": null}	postgres	ddd2ef0bb0670802900ec5e1678e66c105ffd08f7f70fdde3aa04a448de8718d
263	2026-06-01 07:46:04.013977+00	animales	UPDATE	231e6267-606a-5595-92e1-a74dc7a9580e	{"id": "231e6267-606a-5595-92e1-a74dc7a9580e", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Dalia 88", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-03", "crotal_oficial": "ES2706500088", "fecha_nacimiento": "2026-02-07", "estado_reproductivo": null}	{"id": "231e6267-606a-5595-92e1-a74dc7a9580e", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Dalia 88", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-03", "crotal_oficial": "ES2706500088", "fecha_nacimiento": "2026-02-07", "estado_reproductivo": null}	postgres	ccbb75d5e7d28605db464aee07a76e77637edff2d9325a39635b3c7ac1f60d78
264	2026-06-01 07:46:04.013977+00	animales	UPDATE	874a44ba-01b6-5641-a7a8-14b3adbaa35a	{"id": "874a44ba-01b6-5641-a7a8-14b3adbaa35a", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Vega 89", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-02", "crotal_oficial": "ES2706500089", "fecha_nacimiento": "2026-02-06", "estado_reproductivo": null}	{"id": "874a44ba-01b6-5641-a7a8-14b3adbaa35a", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Vega 89", "zona_id": "bc97e385-bbd8-5163-895a-b7156b84e145", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-02", "crotal_oficial": "ES2706500089", "fecha_nacimiento": "2026-02-06", "estado_reproductivo": null}	postgres	1770a95152a47aa46feae7198edb6a7a43257561e0506c7f5bd057b6925b8250
265	2026-06-01 07:46:04.013977+00	animales	UPDATE	0faa59c0-c0fc-5b47-803d-44e925588a03	{"id": "0faa59c0-c0fc-5b47-803d-44e925588a03", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Senda 90", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-01", "crotal_oficial": "ES2706500090", "fecha_nacimiento": "2026-05-06", "estado_reproductivo": null}	{"id": "0faa59c0-c0fc-5b47-803d-44e925588a03", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Senda 90", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-01", "crotal_oficial": "ES2706500090", "fecha_nacimiento": "2026-05-06", "estado_reproductivo": null}	postgres	08fc19be225300dba3ec500ba9858c931994d587dc36cba89d543a615d32f967
266	2026-06-01 07:46:04.013977+00	animales	UPDATE	edf24324-814b-56b2-8b5d-c214ff93fad4	{"id": "edf24324-814b-56b2-8b5d-c214ff93fad4", "raza": "Cruce Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Cora 91", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-30", "crotal_oficial": "ES2706500091", "fecha_nacimiento": "2026-05-05", "estado_reproductivo": null}	{"id": "edf24324-814b-56b2-8b5d-c214ff93fad4", "raza": "Cruce Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Cora 91", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-30", "crotal_oficial": "ES2706500091", "fecha_nacimiento": "2026-05-05", "estado_reproductivo": null}	postgres	47f6e3d8d150db86c11bfa38e47d431b81aa6ab87c23fb019762cef58fa9d251
267	2026-06-01 07:46:04.013977+00	animales	UPDATE	9b62d7c9-5d36-53f7-b27d-5699ce5c52e4	{"id": "9b62d7c9-5d36-53f7-b27d-5699ce5c52e4", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Nora 92", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-29", "crotal_oficial": "ES2706500092", "fecha_nacimiento": "2026-05-04", "estado_reproductivo": null}	{"id": "9b62d7c9-5d36-53f7-b27d-5699ce5c52e4", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Nora 92", "zona_id": "bc97e385-bbd8-5163-895a-b7156b84e145", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-29", "crotal_oficial": "ES2706500092", "fecha_nacimiento": "2026-05-04", "estado_reproductivo": null}	postgres	2d5654686e23dc8fa2a56622543dd6bc30aa82f7c1da6136fdf88de58bdba2dc
268	2026-06-01 07:46:04.025119+00	animales	UPDATE	100ab0c5-a993-504e-90af-c6d7f59f072f	{"id": "100ab0c5-a993-504e-90af-c6d7f59f072f", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Noa 71", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-21", "crotal_oficial": "ES2706500071", "fecha_nacimiento": "2025-01-25", "estado_reproductivo": "inseminada"}	{"id": "100ab0c5-a993-504e-90af-c6d7f59f072f", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Noa 71", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-21", "crotal_oficial": "ES2706500071", "fecha_nacimiento": "2025-01-25", "estado_reproductivo": "inseminada"}	postgres	31772417ec1f3648e3dcbd517a9d630e7184ff46ba541597714c305cb864ba36
269	2026-06-01 07:46:04.025119+00	animales	UPDATE	ba1837f5-ce8f-55d5-a7c1-f75e574eac0f	{"id": "ba1837f5-ce8f-55d5-a7c1-f75e574eac0f", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Luna 72", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-20", "crotal_oficial": "ES2706500072", "fecha_nacimiento": "2025-01-24", "estado_reproductivo": "inseminada"}	{"id": "ba1837f5-ce8f-55d5-a7c1-f75e574eac0f", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Luna 72", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-20", "crotal_oficial": "ES2706500072", "fecha_nacimiento": "2025-01-24", "estado_reproductivo": "inseminada"}	postgres	c58e6c18e24aba60c212e959a05a74790e63eb994c05b3b0607a5cddac21e68a
270	2026-06-01 07:46:04.025119+00	animales	UPDATE	f4edf01d-3029-53e1-95e5-876c6e613901	{"id": "f4edf01d-3029-53e1-95e5-876c6e613901", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Nube 73", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-19", "crotal_oficial": "ES2706500073", "fecha_nacimiento": "2025-01-23", "estado_reproductivo": "inseminada"}	{"id": "f4edf01d-3029-53e1-95e5-876c6e613901", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Nube 73", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-19", "crotal_oficial": "ES2706500073", "fecha_nacimiento": "2025-01-23", "estado_reproductivo": "inseminada"}	postgres	3e90f6dacc98f354f518e5b6cf3e6bf6d416ed7d2dd5e326283b69a4d5109a5e
271	2026-06-01 07:46:04.025119+00	animales	UPDATE	a0842a46-290f-564e-b305-cadd12a663e4	{"id": "a0842a46-290f-564e-b305-cadd12a663e4", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Brisa 74", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-18", "crotal_oficial": "ES2706500074", "fecha_nacimiento": "2025-01-22", "estado_reproductivo": "inseminada"}	{"id": "a0842a46-290f-564e-b305-cadd12a663e4", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Brisa 74", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-18", "crotal_oficial": "ES2706500074", "fecha_nacimiento": "2025-01-22", "estado_reproductivo": "inseminada"}	postgres	fd156a8114dd33e9d6b6bd51c45c1cb9a64f92a49af1ea236a2d845e02dfbd36
272	2026-06-01 07:46:04.025119+00	animales	UPDATE	d310c7c4-c400-5688-b908-536055d69bad	{"id": "d310c7c4-c400-5688-b908-536055d69bad", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Mora 75", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-17", "crotal_oficial": "ES2706500075", "fecha_nacimiento": "2025-01-21", "estado_reproductivo": "inseminada"}	{"id": "d310c7c4-c400-5688-b908-536055d69bad", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Mora 75", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-17", "crotal_oficial": "ES2706500075", "fecha_nacimiento": "2025-01-21", "estado_reproductivo": "inseminada"}	postgres	41b7aee20c266fa1011c8bed70a937400d83cfe1e36fbf66656dc04864e16966
273	2026-06-01 07:46:04.025119+00	animales	UPDATE	c02339ca-c4bc-5afb-b0ab-bb4beb783997	{"id": "c02339ca-c4bc-5afb-b0ab-bb4beb783997", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Dalia 76", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-16", "crotal_oficial": "ES2706500076", "fecha_nacimiento": "2025-01-20", "estado_reproductivo": "inseminada"}	{"id": "c02339ca-c4bc-5afb-b0ab-bb4beb783997", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Dalia 76", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-16", "crotal_oficial": "ES2706500076", "fecha_nacimiento": "2025-01-20", "estado_reproductivo": "inseminada"}	postgres	2dd11646184c768857f41893cc9a98ebe86cdb4794a3a715e48353e71dc61aeb
274	2026-06-01 07:46:04.025119+00	animales	UPDATE	58c0f921-4cc5-5ae0-a3b0-cbcc31f21719	{"id": "58c0f921-4cc5-5ae0-a3b0-cbcc31f21719", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Vega 77", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-15", "crotal_oficial": "ES2706500077", "fecha_nacimiento": "2025-01-19", "estado_reproductivo": "inseminada"}	{"id": "58c0f921-4cc5-5ae0-a3b0-cbcc31f21719", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Vega 77", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-15", "crotal_oficial": "ES2706500077", "fecha_nacimiento": "2025-01-19", "estado_reproductivo": "inseminada"}	postgres	647e537cfd13bad3410bb22b146d650d6b6562bcb18fcacb8bf1de6962020fb7
275	2026-06-01 07:46:04.025119+00	animales	UPDATE	759a20cb-11da-5d54-a6ef-e82e1d84280e	{"id": "759a20cb-11da-5d54-a6ef-e82e1d84280e", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Senda 78", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-14", "crotal_oficial": "ES2706500078", "fecha_nacimiento": "2025-01-18", "estado_reproductivo": "inseminada"}	{"id": "759a20cb-11da-5d54-a6ef-e82e1d84280e", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Senda 78", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-14", "crotal_oficial": "ES2706500078", "fecha_nacimiento": "2025-01-18", "estado_reproductivo": "inseminada"}	postgres	ab984c5d31185ec4ee7dfe9b9b37be99db8f9c1796869785124a9df12b86ee2f
276	2026-06-01 07:46:04.025119+00	animales	UPDATE	3e349a4d-3389-5173-adfb-07c3b16e00c2	{"id": "3e349a4d-3389-5173-adfb-07c3b16e00c2", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Cora 79", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-13", "crotal_oficial": "ES2706500079", "fecha_nacimiento": "2025-01-17", "estado_reproductivo": "inseminada"}	{"id": "3e349a4d-3389-5173-adfb-07c3b16e00c2", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Cora 79", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-13", "crotal_oficial": "ES2706500079", "fecha_nacimiento": "2025-01-17", "estado_reproductivo": "inseminada"}	postgres	0d35e6adedcba6535088447aef39a10cf61790082e3ca441830187d8452c4574
277	2026-06-01 07:46:04.025119+00	animales	UPDATE	c4407964-453c-5725-81ed-26abc47257cd	{"id": "c4407964-453c-5725-81ed-26abc47257cd", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Nora 80", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-31", "crotal_oficial": "ES2706500080", "fecha_nacimiento": "2025-01-16", "estado_reproductivo": "inseminada"}	{"id": "c4407964-453c-5725-81ed-26abc47257cd", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Nora 80", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-31", "crotal_oficial": "ES2706500080", "fecha_nacimiento": "2025-01-16", "estado_reproductivo": "inseminada"}	postgres	771cad5d0a0c2ddb279152d7d6191f96f8c4569cf5a3ec27f6880eff2fac8af2
278	2026-06-01 07:46:04.025119+00	animales	UPDATE	74107440-00d6-58ee-ae41-82471d6b9aa4	{"id": "74107440-00d6-58ee-ae41-82471d6b9aa4", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Oliva 81", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500081", "fecha_nacimiento": "2025-01-15", "estado_reproductivo": "inseminada"}	{"id": "74107440-00d6-58ee-ae41-82471d6b9aa4", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Oliva 81", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500081", "fecha_nacimiento": "2025-01-15", "estado_reproductivo": "inseminada"}	postgres	c2a372cb4f13c862cb209586ac0bce10851ce1f51a71e88dfa67aa39bd57b582
279	2026-06-01 07:46:04.025119+00	animales	UPDATE	7234f761-7764-5891-8b85-d3e4ca2db7ff	{"id": "7234f761-7764-5891-8b85-d3e4ca2db7ff", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Xiana 82", "zona_id": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-29", "crotal_oficial": "ES2706500082", "fecha_nacimiento": "2025-01-14", "estado_reproductivo": "inseminada"}	{"id": "7234f761-7764-5891-8b85-d3e4ca2db7ff", "raza": "Frisona", "sexo": "hembra", "notas": "Novilla gestante en recria avanzada.", "estado": "gestante", "nombre": "Xiana 82", "zona_id": "12928484-dfe8-4637-abb5-954ad7673cc8", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-29", "crotal_oficial": "ES2706500082", "fecha_nacimiento": "2025-01-14", "estado_reproductivo": "inseminada"}	postgres	d762dd86eead1378f681332f8d63cf2ee13669adfc2fbdc2784c5c56b4ca381c
280	2026-06-01 10:09:44.023652+00	animales	UPDATE	70a72a01-c51c-5511-b0ee-276eeec0db42	{"id": "70a72a01-c51c-5511-b0ee-276eeec0db42", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Luna 84", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-07", "crotal_oficial": "ES2706500084", "fecha_nacimiento": "2026-02-11", "estado_reproductivo": null}	{"id": "70a72a01-c51c-5511-b0ee-276eeec0db42", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Luna 84", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-07", "crotal_oficial": "ES2706500084", "fecha_nacimiento": "2026-02-11", "estado_reproductivo": null}	postgres	d68a51adb8fee78d8a197ce722d3caf1a339d9e8eb6feaf9f8da68b6cd561f85
281	2026-06-01 10:09:44.023652+00	animales	UPDATE	f8f9284b-2242-54c3-9435-e9a2db95edef	{"id": "f8f9284b-2242-54c3-9435-e9a2db95edef", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Mora 87", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-04", "crotal_oficial": "ES2706500087", "fecha_nacimiento": "2026-02-08", "estado_reproductivo": null}	{"id": "f8f9284b-2242-54c3-9435-e9a2db95edef", "raza": "Frisona", "sexo": "hembra", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Mora 87", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-04", "crotal_oficial": "ES2706500087", "fecha_nacimiento": "2026-02-08", "estado_reproductivo": null}	postgres	c89b2f7ab377a8a7444a795cc25f9b660978e78c9241fe247959fbdc71bc399f
282	2026-06-01 10:09:44.023652+00	animales	UPDATE	0faa59c0-c0fc-5b47-803d-44e925588a03	{"id": "0faa59c0-c0fc-5b47-803d-44e925588a03", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Senda 90", "zona_id": "4f5eef67-de33-4897-9669-51ba1a5ef6d6", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-01", "crotal_oficial": "ES2706500090", "fecha_nacimiento": "2026-05-06", "estado_reproductivo": null}	{"id": "0faa59c0-c0fc-5b47-803d-44e925588a03", "raza": "Frisona", "sexo": "macho", "notas": "Ternero/a en recria inicial.", "estado": "recria", "nombre": "Senda 90", "zona_id": "584383a2-21ba-537b-af9b-90d8b722821b", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-05-01", "crotal_oficial": "ES2706500090", "fecha_nacimiento": "2026-05-06", "estado_reproductivo": null}	postgres	ea26648f4ae3cf503b812d38df3166984bf8143dbe7ea07ef1080f007ec1760d
283	2026-06-01 10:09:44.084193+00	animales	UPDATE	d58fbf17-442e-5153-8cdf-ce264a40ef4f	{"id": "d58fbf17-442e-5153-8cdf-ce264a40ef4f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 1", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500001", "fecha_nacimiento": "2022-05-31", "estado_reproductivo": "inseminada"}	{"id": "d58fbf17-442e-5153-8cdf-ce264a40ef4f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 1", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-30", "crotal_oficial": "ES2706500001", "fecha_nacimiento": "2022-05-31", "estado_reproductivo": "inseminada"}	postgres	baa3af582f699a5ff3f792b8364c18c5d4f2bdba40c51ec770e323f84cac7ee4
284	2026-06-01 10:09:44.084193+00	animales	UPDATE	73956a35-c183-5c88-9b6e-827903fe0241	{"id": "73956a35-c183-5c88-9b6e-827903fe0241", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 4", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-27", "crotal_oficial": "ES2706500004", "fecha_nacimiento": "2019-05-29", "estado_reproductivo": "vacia"}	{"id": "73956a35-c183-5c88-9b6e-827903fe0241", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 4", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-27", "crotal_oficial": "ES2706500004", "fecha_nacimiento": "2019-05-29", "estado_reproductivo": "vacia"}	postgres	c9f676da0c58cf39407d3de6ed9082da643e6b7139e4ca6a128b91b78cb677e7
285	2026-06-01 10:09:44.084193+00	animales	UPDATE	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	{"id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 7", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-24", "crotal_oficial": "ES2706500007", "fecha_nacimiento": "2022-05-25", "estado_reproductivo": "parto_reciente"}	{"id": "2dd41d6e-e3ad-5870-b8dc-d71361fa1e56", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 7", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-24", "crotal_oficial": "ES2706500007", "fecha_nacimiento": "2022-05-25", "estado_reproductivo": "parto_reciente"}	postgres	b9c8f8697cec48b72e9b27e6e5a8cf88702d3b8180f48fb236f0f27a88880fe9
286	2026-06-01 10:09:44.084193+00	animales	UPDATE	0f7ff532-8875-5404-8a53-3c204bdf55e1	{"id": "0f7ff532-8875-5404-8a53-3c204bdf55e1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Noa 59", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-02", "crotal_oficial": "ES2706500059", "fecha_nacimiento": "2018-04-04", "estado_reproductivo": "confirmada_gestante"}	{"id": "0f7ff532-8875-5404-8a53-3c204bdf55e1", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Noa 59", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-02", "crotal_oficial": "ES2706500059", "fecha_nacimiento": "2018-04-04", "estado_reproductivo": "confirmada_gestante"}	postgres	369bca95d2127c3c0c8a0a2fe8540087d5fe9b89dacc4b17c22576bf438c4669
287	2026-06-01 10:09:44.084193+00	animales	UPDATE	1f8d73e0-6258-536a-bb01-0fcdd4b96b26	{"id": "1f8d73e0-6258-536a-bb01-0fcdd4b96b26", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Luna 60", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-01", "crotal_oficial": "ES2706500060", "fecha_nacimiento": "2022-04-02", "estado_reproductivo": "confirmada_gestante"}	{"id": "1f8d73e0-6258-536a-bb01-0fcdd4b96b26", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Luna 60", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-01", "crotal_oficial": "ES2706500060", "fecha_nacimiento": "2022-04-02", "estado_reproductivo": "confirmada_gestante"}	postgres	a9692e538ffdfc0f09298554111736bc934bb2d0cc5f585b5d5482f88fdce5d6
288	2026-06-01 10:09:44.084193+00	animales	UPDATE	5dc5cac3-6bb9-5d56-957b-7677c4bcc56b	{"id": "5dc5cac3-6bb9-5d56-957b-7677c4bcc56b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nube 61", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-31", "crotal_oficial": "ES2706500061", "fecha_nacimiento": "2021-04-01", "estado_reproductivo": "confirmada_gestante"}	{"id": "5dc5cac3-6bb9-5d56-957b-7677c4bcc56b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nube 61", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-31", "crotal_oficial": "ES2706500061", "fecha_nacimiento": "2021-04-01", "estado_reproductivo": "confirmada_gestante"}	postgres	b13035f5ce561d84371bd0d27fde3b6f0b7ff813ad6a4bd2f1fa2a34b9ed7b5d
289	2026-06-01 10:09:44.084193+00	animales	UPDATE	12ba4d63-24a9-5f3c-9204-99590678f5ed	{"id": "12ba4d63-24a9-5f3c-9204-99590678f5ed", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Brisa 62", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-30", "crotal_oficial": "ES2706500062", "fecha_nacimiento": "2020-03-31", "estado_reproductivo": "confirmada_gestante"}	{"id": "12ba4d63-24a9-5f3c-9204-99590678f5ed", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Brisa 62", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-30", "crotal_oficial": "ES2706500062", "fecha_nacimiento": "2020-03-31", "estado_reproductivo": "confirmada_gestante"}	postgres	e92f83d21bc8a2ca27d412cdc0e563f6b2961ae9d0d416d0db70032bffd52a32
290	2026-06-01 10:09:44.084193+00	animales	UPDATE	09065fbe-c2e5-500a-93cc-5f9f55d9f114	{"id": "09065fbe-c2e5-500a-93cc-5f9f55d9f114", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Mora 63", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-29", "crotal_oficial": "ES2706500063", "fecha_nacimiento": "2019-03-31", "estado_reproductivo": "confirmada_gestante"}	{"id": "09065fbe-c2e5-500a-93cc-5f9f55d9f114", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Mora 63", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-29", "crotal_oficial": "ES2706500063", "fecha_nacimiento": "2019-03-31", "estado_reproductivo": "confirmada_gestante"}	postgres	239c9bc26e0eb59832187e4b99961790193dd212379d24ff32af71ef5c282f19
291	2026-06-01 10:09:44.084193+00	animales	UPDATE	5dbdee66-af90-503d-b6c5-b428cebb2b91	{"id": "5dbdee66-af90-503d-b6c5-b428cebb2b91", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Dalia 64", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-28", "crotal_oficial": "ES2706500064", "fecha_nacimiento": "2018-03-30", "estado_reproductivo": "confirmada_gestante"}	{"id": "5dbdee66-af90-503d-b6c5-b428cebb2b91", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Dalia 64", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-28", "crotal_oficial": "ES2706500064", "fecha_nacimiento": "2018-03-30", "estado_reproductivo": "confirmada_gestante"}	postgres	9eff9cb899465cfa1f71a94e1014422018b47381373e02bbd1d2082cf4f70f02
292	2026-06-01 10:09:44.084193+00	animales	UPDATE	5c888535-5880-5f6c-b53c-128c9df5464b	{"id": "5c888535-5880-5f6c-b53c-128c9df5464b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Vega 65", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-27", "crotal_oficial": "ES2706500065", "fecha_nacimiento": "2022-03-28", "estado_reproductivo": "confirmada_gestante"}	{"id": "5c888535-5880-5f6c-b53c-128c9df5464b", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Vega 65", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-27", "crotal_oficial": "ES2706500065", "fecha_nacimiento": "2022-03-28", "estado_reproductivo": "confirmada_gestante"}	postgres	56a38aeff11b0aa376a5a7c9d6302d8e36fb4336a78d8fb31193b4f73fe81e98
293	2026-06-01 10:09:44.084193+00	animales	UPDATE	963164ac-9734-5fd9-bd3a-fc7dacff84e1	{"id": "963164ac-9734-5fd9-bd3a-fc7dacff84e1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Senda 66", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-26", "crotal_oficial": "ES2706500066", "fecha_nacimiento": "2021-03-27", "estado_reproductivo": "confirmada_gestante"}	{"id": "963164ac-9734-5fd9-bd3a-fc7dacff84e1", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Senda 66", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-26", "crotal_oficial": "ES2706500066", "fecha_nacimiento": "2021-03-27", "estado_reproductivo": "confirmada_gestante"}	postgres	265996f13b73fc48107d0a9f4897016de5954c8692b64e57f6f887edd9193582
294	2026-06-01 10:09:44.084193+00	animales	UPDATE	ffe82114-3a26-5e7b-8ce6-7a8ef2f12732	{"id": "ffe82114-3a26-5e7b-8ce6-7a8ef2f12732", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Cora 67", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-25", "crotal_oficial": "ES2706500067", "fecha_nacimiento": "2020-03-26", "estado_reproductivo": "confirmada_gestante"}	{"id": "ffe82114-3a26-5e7b-8ce6-7a8ef2f12732", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Cora 67", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-25", "crotal_oficial": "ES2706500067", "fecha_nacimiento": "2020-03-26", "estado_reproductivo": "confirmada_gestante"}	postgres	233edeb1ce2ae91acff6e914674a8dbe06c9c64510500aa22d1d0d72d69b563b
295	2026-06-01 10:09:44.084193+00	animales	UPDATE	cf17702f-f18b-553e-9294-67e671e66022	{"id": "cf17702f-f18b-553e-9294-67e671e66022", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 10", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-21", "crotal_oficial": "ES2706500010", "fecha_nacimiento": "2019-05-23", "estado_reproductivo": "confirmada_gestante"}	{"id": "cf17702f-f18b-553e-9294-67e671e66022", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 10", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-21", "crotal_oficial": "ES2706500010", "fecha_nacimiento": "2019-05-23", "estado_reproductivo": "confirmada_gestante"}	postgres	79be17645dcbcf4142552390c702a9c8698aa2d71fa3a30da9f759071327e65d
296	2026-06-01 10:09:44.084193+00	animales	UPDATE	d172a069-591a-55e4-89fc-32699f1d25c9	{"id": "d172a069-591a-55e4-89fc-32699f1d25c9", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 13", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-18", "crotal_oficial": "ES2706500013", "fecha_nacimiento": "2022-05-19", "estado_reproductivo": "inseminada"}	{"id": "d172a069-591a-55e4-89fc-32699f1d25c9", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 13", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-18", "crotal_oficial": "ES2706500013", "fecha_nacimiento": "2022-05-19", "estado_reproductivo": "inseminada"}	postgres	fac7a678798b09da3e4e53a3d4a96d3fa8a747f796523039e2db04f5628d8cef
297	2026-06-01 10:09:44.084193+00	animales	UPDATE	62d38b4e-74e0-5f20-b66b-64efddec53b7	{"id": "62d38b4e-74e0-5f20-b66b-64efddec53b7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 16", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-15", "crotal_oficial": "ES2706500016", "fecha_nacimiento": "2019-05-17", "estado_reproductivo": "vacia"}	{"id": "62d38b4e-74e0-5f20-b66b-64efddec53b7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 16", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-15", "crotal_oficial": "ES2706500016", "fecha_nacimiento": "2019-05-17", "estado_reproductivo": "vacia"}	postgres	a77bfe34a11cdc6575392f2bd15b01f87100ab01a1b64ba2890d7fad421a3733
298	2026-06-01 10:09:44.084193+00	animales	UPDATE	df87133b-ee35-5f6c-982e-0b9e09ad3dea	{"id": "df87133b-ee35-5f6c-982e-0b9e09ad3dea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 19", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-12", "crotal_oficial": "ES2706500019", "fecha_nacimiento": "2022-05-13", "estado_reproductivo": "parto_reciente"}	{"id": "df87133b-ee35-5f6c-982e-0b9e09ad3dea", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 19", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-12", "crotal_oficial": "ES2706500019", "fecha_nacimiento": "2022-05-13", "estado_reproductivo": "parto_reciente"}	postgres	3635cdee98d73090a85d34737e0ca80d82e8c7e7414dcda2ae611b985f4f5b4c
299	2026-06-01 10:09:44.084193+00	animales	UPDATE	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	{"id": "5d712a13-ba73-5fb4-b4f1-1d2b15f2c988", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 22", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-09", "crotal_oficial": "ES2706500022", "fecha_nacimiento": "2019-05-11", "estado_reproductivo": "confirmada_gestante"}	{"id": "5d712a13-ba73-5fb4-b4f1-1d2b15f2c988", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 22", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-09", "crotal_oficial": "ES2706500022", "fecha_nacimiento": "2019-05-11", "estado_reproductivo": "confirmada_gestante"}	postgres	3824096ebd78b2952f057663c0339d47033fa288ef22829e6d80112dc8f1bd95
300	2026-06-01 10:09:44.084193+00	animales	UPDATE	784ed9c6-39d3-5da9-b379-311aca240fdd	{"id": "784ed9c6-39d3-5da9-b379-311aca240fdd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 25", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-06", "crotal_oficial": "ES2706500025", "fecha_nacimiento": "2022-05-07", "estado_reproductivo": "inseminada"}	{"id": "784ed9c6-39d3-5da9-b379-311aca240fdd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 25", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-06", "crotal_oficial": "ES2706500025", "fecha_nacimiento": "2022-05-07", "estado_reproductivo": "inseminada"}	postgres	e6f9f7e23276369548ce5cac7d8a5907d9c1b15935929e67de4418c71dccd60f
301	2026-06-01 10:09:44.084193+00	animales	UPDATE	1c069679-3e6d-5b3e-8842-c27c074da0a0	{"id": "1c069679-3e6d-5b3e-8842-c27c074da0a0", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 28", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-03", "crotal_oficial": "ES2706500028", "fecha_nacimiento": "2019-05-05", "estado_reproductivo": "vacia"}	{"id": "1c069679-3e6d-5b3e-8842-c27c074da0a0", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 28", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-03", "crotal_oficial": "ES2706500028", "fecha_nacimiento": "2019-05-05", "estado_reproductivo": "vacia"}	postgres	c48ebd1795e5fabf75d0d7a4ac0727dd21f9fb1695b0fc28cd4e4b663d8667cd
302	2026-06-01 10:09:44.084193+00	animales	UPDATE	674f97b3-f5f9-5ead-bf6c-d743870ba36f	{"id": "674f97b3-f5f9-5ead-bf6c-d743870ba36f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 31", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-30", "crotal_oficial": "ES2706500031", "fecha_nacimiento": "2022-05-01", "estado_reproductivo": "parto_reciente"}	{"id": "674f97b3-f5f9-5ead-bf6c-d743870ba36f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 31", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-30", "crotal_oficial": "ES2706500031", "fecha_nacimiento": "2022-05-01", "estado_reproductivo": "parto_reciente"}	postgres	51d307b0361018e1d655e156d1f92505cb40cb4205d0404d282c76c92781ca18
303	2026-06-01 10:09:44.084193+00	animales	UPDATE	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	{"id": "9baa72c1-9b94-594b-8926-8a3c17ee9ac7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 34", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-27", "crotal_oficial": "ES2706500034", "fecha_nacimiento": "2019-04-29", "estado_reproductivo": "confirmada_gestante"}	{"id": "9baa72c1-9b94-594b-8926-8a3c17ee9ac7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 34", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-27", "crotal_oficial": "ES2706500034", "fecha_nacimiento": "2019-04-29", "estado_reproductivo": "confirmada_gestante"}	postgres	489ac596e333ccac35ae6f143eb1c93f8d9e20c5fd8f3724eab7fb9e1a17469a
304	2026-06-01 10:09:44.084193+00	animales	UPDATE	6b224987-9434-5637-a871-9ac01fd4d4c3	{"id": "6b224987-9434-5637-a871-9ac01fd4d4c3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 37", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-24", "crotal_oficial": "ES2706500037", "fecha_nacimiento": "2022-04-25", "estado_reproductivo": "inseminada"}	{"id": "6b224987-9434-5637-a871-9ac01fd4d4c3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 37", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-24", "crotal_oficial": "ES2706500037", "fecha_nacimiento": "2022-04-25", "estado_reproductivo": "inseminada"}	postgres	cba9f9b7af839b9130472e281ff9b35bc6149f042d834327597241a5f5a1d490
305	2026-06-01 10:09:44.084193+00	animales	UPDATE	bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7	{"id": "bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 40", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-21", "crotal_oficial": "ES2706500040", "fecha_nacimiento": "2019-04-23", "estado_reproductivo": "vacia"}	{"id": "bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 40", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-21", "crotal_oficial": "ES2706500040", "fecha_nacimiento": "2019-04-23", "estado_reproductivo": "vacia"}	postgres	f5683d4f3c64d0f6bbff2ea4fe9ec869c8b4b2d2cafe66fea8470a0a313fd8d6
306	2026-06-01 10:09:44.084193+00	animales	UPDATE	78f6b86f-6d19-50c5-a003-4cf0c0c02e22	{"id": "78f6b86f-6d19-50c5-a003-4cf0c0c02e22", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 43", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-18", "crotal_oficial": "ES2706500043", "fecha_nacimiento": "2022-04-19", "estado_reproductivo": "parto_reciente"}	{"id": "78f6b86f-6d19-50c5-a003-4cf0c0c02e22", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 43", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-18", "crotal_oficial": "ES2706500043", "fecha_nacimiento": "2022-04-19", "estado_reproductivo": "parto_reciente"}	postgres	bb6aa817c134ac42768d9e1f436595f8076e7f2ed8ffd89cf800a1584771f987
307	2026-06-01 10:09:44.084193+00	animales	UPDATE	c9303516-f788-5f46-90dd-bb82d7023d71	{"id": "c9303516-f788-5f46-90dd-bb82d7023d71", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 46", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-15", "crotal_oficial": "ES2706500046", "fecha_nacimiento": "2019-04-17", "estado_reproductivo": "confirmada_gestante"}	{"id": "c9303516-f788-5f46-90dd-bb82d7023d71", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 46", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-15", "crotal_oficial": "ES2706500046", "fecha_nacimiento": "2019-04-17", "estado_reproductivo": "confirmada_gestante"}	postgres	5751145ed165cc9e7fdeed358614994bbd698831e0c3f40e24abd9a591cf9304
308	2026-06-01 10:09:44.084193+00	animales	UPDATE	9a533fa2-4f96-500a-af83-80da01f2370d	{"id": "9a533fa2-4f96-500a-af83-80da01f2370d", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 49", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-12", "crotal_oficial": "ES2706500049", "fecha_nacimiento": "2022-04-13", "estado_reproductivo": "inseminada"}	{"id": "9a533fa2-4f96-500a-af83-80da01f2370d", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Nube 49", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-12", "crotal_oficial": "ES2706500049", "fecha_nacimiento": "2022-04-13", "estado_reproductivo": "inseminada"}	postgres	2591faed672234e9e21407d6764eb2ad7f0d1c147e2f39369ad68ecc198ada53
309	2026-06-01 10:09:44.084193+00	animales	UPDATE	7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6	{"id": "7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 52", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-09", "crotal_oficial": "ES2706500052", "fecha_nacimiento": "2019-04-11", "estado_reproductivo": "vacia"}	{"id": "7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Dalia 52", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-09", "crotal_oficial": "ES2706500052", "fecha_nacimiento": "2019-04-11", "estado_reproductivo": "vacia"}	postgres	7aa89021f5fef60df700f268708208a746dd22f8ca5a6b93bc642f229532dcfe
310	2026-06-01 10:09:44.084193+00	animales	UPDATE	9144858f-31c8-575d-a0ae-366e1d2935fd	{"id": "9144858f-31c8-575d-a0ae-366e1d2935fd", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 55", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-06", "crotal_oficial": "ES2706500055", "fecha_nacimiento": "2022-04-07", "estado_reproductivo": "parto_reciente"}	{"id": "9144858f-31c8-575d-a0ae-366e1d2935fd", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Cora 55", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-06", "crotal_oficial": "ES2706500055", "fecha_nacimiento": "2022-04-07", "estado_reproductivo": "parto_reciente"}	postgres	8c644870f22c8095fb7650e2711e837a2f946466408490d1e2ae3079b6a9a86c
311	2026-06-01 10:09:44.084193+00	animales	UPDATE	a3c69881-650f-5671-9ae6-8371fb892b89	{"id": "a3c69881-650f-5671-9ae6-8371fb892b89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 58", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-03", "crotal_oficial": "ES2706500058", "fecha_nacimiento": "2019-04-05", "estado_reproductivo": "confirmada_gestante"}	{"id": "a3c69881-650f-5671-9ae6-8371fb892b89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Xiana 58", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-03", "crotal_oficial": "ES2706500058", "fecha_nacimiento": "2019-04-05", "estado_reproductivo": "confirmada_gestante"}	postgres	5ed98128ef7222848a65b90e01ce39416711071a009a3f8643b722b25e18b746
312	2026-06-01 10:09:44.084193+00	animales	UPDATE	efc8bf74-ef7d-5152-a4d4-a077ae7a7d52	{"id": "efc8bf74-ef7d-5152-a4d4-a077ae7a7d52", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nora 68", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-24", "crotal_oficial": "ES2706500068", "fecha_nacimiento": "2019-03-26", "estado_reproductivo": "confirmada_gestante"}	{"id": "efc8bf74-ef7d-5152-a4d4-a077ae7a7d52", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Nora 68", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-24", "crotal_oficial": "ES2706500068", "fecha_nacimiento": "2019-03-26", "estado_reproductivo": "confirmada_gestante"}	postgres	483752e4bc30c56fc4bd20496305563a443d1cf4ff6b2a7cd7b514ed31ce6d69
313	2026-06-01 10:09:44.084193+00	animales	UPDATE	27ba2d06-b334-5f7c-bd59-ba67cf095d68	{"id": "27ba2d06-b334-5f7c-bd59-ba67cf095d68", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Oliva 69", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-23", "crotal_oficial": "ES2706500069", "fecha_nacimiento": "2018-03-25", "estado_reproductivo": "confirmada_gestante"}	{"id": "27ba2d06-b334-5f7c-bd59-ba67cf095d68", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Oliva 69", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-23", "crotal_oficial": "ES2706500069", "fecha_nacimiento": "2018-03-25", "estado_reproductivo": "confirmada_gestante"}	postgres	ef8b89f7d4d274cdf65ac8be218f9f3f629576e3b6166317b14bc7e479bce338
314	2026-06-01 10:09:44.084193+00	animales	UPDATE	389f3969-2148-5055-82d6-166a20ab6a9b	{"id": "389f3969-2148-5055-82d6-166a20ab6a9b", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Xiana 70", "zona_id": "1819261f-9823-5373-a0dc-533638edb05e", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-22", "crotal_oficial": "ES2706500070", "fecha_nacimiento": "2022-03-23", "estado_reproductivo": "confirmada_gestante"}	{"id": "389f3969-2148-5055-82d6-166a20ab6a9b", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca seca en lote preparto o secado.", "estado": "seca", "nombre": "Xiana 70", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-22", "crotal_oficial": "ES2706500070", "fecha_nacimiento": "2022-03-23", "estado_reproductivo": "confirmada_gestante"}	postgres	2f716affc598f488deb0582627375b0f24f8c946111679e009b7d5026e41bf81
315	2026-06-01 10:09:44.097854+00	animales	UPDATE	0d506129-b7c5-507a-88ca-242344baa5de	{"id": "0d506129-b7c5-507a-88ca-242344baa5de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 3", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-28", "crotal_oficial": "ES2706500003", "fecha_nacimiento": "2020-05-29", "estado_reproductivo": "parto_reciente"}	{"id": "0d506129-b7c5-507a-88ca-242344baa5de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 3", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-28", "crotal_oficial": "ES2706500003", "fecha_nacimiento": "2020-05-29", "estado_reproductivo": "parto_reciente"}	postgres	63d435d60f992f371737c38483af8df123cec6db9b4a4799b88930f451a91b82
316	2026-06-01 10:09:44.097854+00	animales	UPDATE	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	{"id": "1a6e7a54-8774-52a6-896f-01a35b5cbc2d", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 6", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-25", "crotal_oficial": "ES2706500006", "fecha_nacimiento": "2023-05-26", "estado_reproductivo": "confirmada_gestante"}	{"id": "1a6e7a54-8774-52a6-896f-01a35b5cbc2d", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 6", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-25", "crotal_oficial": "ES2706500006", "fecha_nacimiento": "2023-05-26", "estado_reproductivo": "confirmada_gestante"}	postgres	ab475be25acd2a4d079e28efd99fe775d7013c388bb40b6d687ef2c58b1cdf83
317	2026-06-01 10:09:44.097854+00	animales	UPDATE	936b78c4-7b89-5fcf-97f7-54f007674e36	{"id": "936b78c4-7b89-5fcf-97f7-54f007674e36", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 9", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-22", "crotal_oficial": "ES2706500009", "fecha_nacimiento": "2020-05-23", "estado_reproductivo": "inseminada"}	{"id": "936b78c4-7b89-5fcf-97f7-54f007674e36", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 9", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-22", "crotal_oficial": "ES2706500009", "fecha_nacimiento": "2020-05-23", "estado_reproductivo": "inseminada"}	postgres	666cd6add01587ccaa01a29d5c3054f3b9fb434aaae7a6cab4e8fb88f06af669
318	2026-06-01 10:09:44.097854+00	animales	UPDATE	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	{"id": "e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 12", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-19", "crotal_oficial": "ES2706500012", "fecha_nacimiento": "2023-05-20", "estado_reproductivo": "vacia"}	{"id": "e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 12", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-19", "crotal_oficial": "ES2706500012", "fecha_nacimiento": "2023-05-20", "estado_reproductivo": "vacia"}	postgres	bbcd9347d9b919facbf37c43437a695c494c948132d14cef232c9d08b8de9758
319	2026-06-01 10:09:44.097854+00	animales	UPDATE	b5263713-2026-5bad-ae46-296dc48a39d3	{"id": "b5263713-2026-5bad-ae46-296dc48a39d3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 15", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-16", "crotal_oficial": "ES2706500015", "fecha_nacimiento": "2020-05-17", "estado_reproductivo": "parto_reciente"}	{"id": "b5263713-2026-5bad-ae46-296dc48a39d3", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 15", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-16", "crotal_oficial": "ES2706500015", "fecha_nacimiento": "2020-05-17", "estado_reproductivo": "parto_reciente"}	postgres	6d71323c5ab30a40476972dd71e354fbd8c70c8dd3bbf5d75ac292aa528f6342
320	2026-06-01 10:09:44.097854+00	animales	UPDATE	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	{"id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 18", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-13", "crotal_oficial": "ES2706500018", "fecha_nacimiento": "2023-05-14", "estado_reproductivo": "confirmada_gestante"}	{"id": "5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 18", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-13", "crotal_oficial": "ES2706500018", "fecha_nacimiento": "2023-05-14", "estado_reproductivo": "confirmada_gestante"}	postgres	13efe97b8f3a796be357cf083e942e024d62961e57f70476b39043779f99e247
321	2026-06-01 10:09:44.097854+00	animales	UPDATE	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	{"id": "e8761f6b-9037-5d8f-bca2-cd8caa3ab0af", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 21", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-10", "crotal_oficial": "ES2706500021", "fecha_nacimiento": "2020-05-11", "estado_reproductivo": "inseminada"}	{"id": "e8761f6b-9037-5d8f-bca2-cd8caa3ab0af", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 21", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-10", "crotal_oficial": "ES2706500021", "fecha_nacimiento": "2020-05-11", "estado_reproductivo": "inseminada"}	postgres	20aa8d6462f442022325f842afd139cef31d3a5c1838fd2317e96b2708a7c697
322	2026-06-01 10:09:44.097854+00	animales	UPDATE	4c13e989-899c-5d47-8988-380802d72f58	{"id": "4c13e989-899c-5d47-8988-380802d72f58", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 24", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-07", "crotal_oficial": "ES2706500024", "fecha_nacimiento": "2023-05-08", "estado_reproductivo": "vacia"}	{"id": "4c13e989-899c-5d47-8988-380802d72f58", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 24", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-07", "crotal_oficial": "ES2706500024", "fecha_nacimiento": "2023-05-08", "estado_reproductivo": "vacia"}	postgres	66cb0917c26bc75ee2afaa657b3e8d2e6e1b635a162f88c781f7545a6fb3ccf3
323	2026-06-01 10:09:44.097854+00	animales	UPDATE	20cb75da-56ec-50b5-85f8-792b0d74f745	{"id": "20cb75da-56ec-50b5-85f8-792b0d74f745", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 27", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-04", "crotal_oficial": "ES2706500027", "fecha_nacimiento": "2020-05-05", "estado_reproductivo": "parto_reciente"}	{"id": "20cb75da-56ec-50b5-85f8-792b0d74f745", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 27", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-04", "crotal_oficial": "ES2706500027", "fecha_nacimiento": "2020-05-05", "estado_reproductivo": "parto_reciente"}	postgres	0292280110c4a0c527d8da1fcb083b15aa26a20793bc196177c08c85c5b02226
324	2026-06-01 10:09:44.097854+00	animales	UPDATE	eeded079-9abf-5844-8559-6eea890a6fe4	{"id": "eeded079-9abf-5844-8559-6eea890a6fe4", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 30", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-01", "crotal_oficial": "ES2706500030", "fecha_nacimiento": "2023-05-02", "estado_reproductivo": "confirmada_gestante"}	{"id": "eeded079-9abf-5844-8559-6eea890a6fe4", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 30", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-01", "crotal_oficial": "ES2706500030", "fecha_nacimiento": "2023-05-02", "estado_reproductivo": "confirmada_gestante"}	postgres	44725aab7dec4931f6cf76747e1ce5e63354fcfcae9232517ce39d0170e80614
325	2026-06-01 10:09:44.097854+00	animales	UPDATE	3f9aca1c-2859-5e86-909b-fe2777f960ca	{"id": "3f9aca1c-2859-5e86-909b-fe2777f960ca", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 33", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-28", "crotal_oficial": "ES2706500033", "fecha_nacimiento": "2020-04-29", "estado_reproductivo": "inseminada"}	{"id": "3f9aca1c-2859-5e86-909b-fe2777f960ca", "raza": "Parda Alpina", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 33", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-28", "crotal_oficial": "ES2706500033", "fecha_nacimiento": "2020-04-29", "estado_reproductivo": "inseminada"}	postgres	d477bd52d3cd64c0490a3f938bc84327ef7e11349b9c285f881db052c30f92d3
326	2026-06-01 10:09:44.097854+00	animales	UPDATE	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	{"id": "bb9fc07f-076f-5182-93d0-8eb2ece1ee89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 36", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-25", "crotal_oficial": "ES2706500036", "fecha_nacimiento": "2023-04-26", "estado_reproductivo": "vacia"}	{"id": "bb9fc07f-076f-5182-93d0-8eb2ece1ee89", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 36", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-25", "crotal_oficial": "ES2706500036", "fecha_nacimiento": "2023-04-26", "estado_reproductivo": "vacia"}	postgres	c981a39ee2d8a73bbd673120639ce358efce98d1420abeec1a2514eb01c023de
327	2026-06-01 10:09:44.097854+00	animales	UPDATE	2e14a84a-511d-5bcf-867c-216522289b1c	{"id": "2e14a84a-511d-5bcf-867c-216522289b1c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 39", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-22", "crotal_oficial": "ES2706500039", "fecha_nacimiento": "2020-04-23", "estado_reproductivo": "parto_reciente"}	{"id": "2e14a84a-511d-5bcf-867c-216522289b1c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 39", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-22", "crotal_oficial": "ES2706500039", "fecha_nacimiento": "2020-04-23", "estado_reproductivo": "parto_reciente"}	postgres	b065fdc5826e7392155bbab62e4ace5c155a3fd7cc9e10087b30b4681b61294f
328	2026-06-01 10:09:44.097854+00	animales	UPDATE	df02d6c2-f792-565d-ac97-d358d7484092	{"id": "df02d6c2-f792-565d-ac97-d358d7484092", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 42", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-19", "crotal_oficial": "ES2706500042", "fecha_nacimiento": "2023-04-20", "estado_reproductivo": "confirmada_gestante"}	{"id": "df02d6c2-f792-565d-ac97-d358d7484092", "raza": "Cruce Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 42", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-19", "crotal_oficial": "ES2706500042", "fecha_nacimiento": "2023-04-20", "estado_reproductivo": "confirmada_gestante"}	postgres	658142bc0a6051817aa7e31cc42ea11ad3f4c6ba4c44e09e30765b2593ffeb3d
329	2026-06-01 10:09:44.097854+00	animales	UPDATE	0238f86f-4409-54d4-b4eb-0d28d7b4af0c	{"id": "0238f86f-4409-54d4-b4eb-0d28d7b4af0c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 45", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-16", "crotal_oficial": "ES2706500045", "fecha_nacimiento": "2020-04-17", "estado_reproductivo": "inseminada"}	{"id": "0238f86f-4409-54d4-b4eb-0d28d7b4af0c", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 45", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-16", "crotal_oficial": "ES2706500045", "fecha_nacimiento": "2020-04-17", "estado_reproductivo": "inseminada"}	postgres	2dc0f60d388b7a437e77082e8dcfc7fef95a1d71d98d133865a3e8fa0be53998
330	2026-06-01 10:09:44.097854+00	animales	UPDATE	ab19f1c4-775c-5f7d-8fad-c7b0cea81217	{"id": "ab19f1c4-775c-5f7d-8fad-c7b0cea81217", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 48", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-13", "crotal_oficial": "ES2706500048", "fecha_nacimiento": "2023-04-14", "estado_reproductivo": "vacia"}	{"id": "ab19f1c4-775c-5f7d-8fad-c7b0cea81217", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Luna 48", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-13", "crotal_oficial": "ES2706500048", "fecha_nacimiento": "2023-04-14", "estado_reproductivo": "vacia"}	postgres	4ba676280cc36ca2766ffadb94bd835ffd0e9d41c852c586292b8b2d8f625086
331	2026-06-01 10:09:44.097854+00	animales	UPDATE	1cb96771-c7de-53e3-b737-2954be5a71de	{"id": "1cb96771-c7de-53e3-b737-2954be5a71de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 51", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-10", "crotal_oficial": "ES2706500051", "fecha_nacimiento": "2020-04-11", "estado_reproductivo": "parto_reciente"}	{"id": "1cb96771-c7de-53e3-b737-2954be5a71de", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Mora 51", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-10", "crotal_oficial": "ES2706500051", "fecha_nacimiento": "2020-04-11", "estado_reproductivo": "parto_reciente"}	postgres	9d89bd09c513be12fc90513b75d672d62ad168a5bd6529583c303e3d711e412f
332	2026-06-01 10:09:44.097854+00	animales	UPDATE	329e2c29-366f-56b0-b854-ca7cb56bff5f	{"id": "329e2c29-366f-56b0-b854-ca7cb56bff5f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 54", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-07", "crotal_oficial": "ES2706500054", "fecha_nacimiento": "2023-04-08", "estado_reproductivo": "confirmada_gestante"}	{"id": "329e2c29-366f-56b0-b854-ca7cb56bff5f", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Senda 54", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-07", "crotal_oficial": "ES2706500054", "fecha_nacimiento": "2023-04-08", "estado_reproductivo": "confirmada_gestante"}	postgres	b72ecc79a227568f952ed05384f80a5341430dfafe40b7f12e6deb87a8a6cb9c
333	2026-06-01 10:09:44.097854+00	animales	UPDATE	798cfeb1-fa83-529d-b119-c7f5cd60f5cd	{"id": "798cfeb1-fa83-529d-b119-c7f5cd60f5cd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 57", "zona_id": "ccca4b6f-9e15-5193-88c8-c44608141146", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-04", "crotal_oficial": "ES2706500057", "fecha_nacimiento": "2020-04-05", "estado_reproductivo": "inseminada"}	{"id": "798cfeb1-fa83-529d-b119-c7f5cd60f5cd", "raza": "Frisona", "sexo": "hembra", "notas": "Vaca en lactacion con control rutinario de produccion.", "estado": "produccion", "nombre": "Oliva 57", "zona_id": "df738ef1-6ed8-4172-a99c-f45f7ec5be37", "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-04", "crotal_oficial": "ES2706500057", "fecha_nacimiento": "2020-04-05", "estado_reproductivo": "inseminada"}	postgres	3c22831bf0f7ea275029e0c047137725f7da3cb53f0343e0bce99a2a13c4a91c
\.


--
-- Data for Name: boxes_recria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.boxes_recria (id, box_numero, ternero_id, fecha_entrada, fecha_salida, activo, alertas_box, notas) FROM stdin;
de8d2e41-e721-530a-87a2-42c80b082de6	1	19eeaa52-2c8b-5e63-ace0-ef1ec00d6da9	2026-05-30	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
0597a3c0-c1fa-5234-b1b3-1eb18ce75c89	2	70a72a01-c51c-5511-b0ee-276eeec0db42	2026-05-29	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
39e1e1a6-3a1a-5207-9abe-63a27dc48c83	3	a4774bd3-5ee0-54bc-8fb8-cf5df0b3bd89	2026-05-28	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
1b7de26a-3a51-5677-b50f-578d4224b0c8	4	7aaf1f29-d947-5361-9119-50eed5155dcc	2026-05-27	\N	t	[{"tipo": "cama_humeda", "nivel": "media"}]	Box operativo con seguimiento diario de encamado y consumo.
ab74853d-4b20-5eea-909f-b72a8aa27ff5	5	f8f9284b-2242-54c3-9435-e9a2db95edef	2026-05-26	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
b7af8fd3-7bdb-5eae-92ea-b232b98611d0	6	231e6267-606a-5595-92e1-a74dc7a9580e	2026-05-25	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
af461da5-6fcb-583a-86e8-a2ddd85024d5	7	874a44ba-01b6-5641-a7a8-14b3adbaa35a	2026-05-24	\N	t	[{"tipo": "cama_humeda", "nivel": "media"}]	Box operativo con seguimiento diario de encamado y consumo.
7c440099-ffd0-5f89-8377-820d31bce09b	8	0faa59c0-c0fc-5b47-803d-44e925588a03	2026-05-23	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
d4245946-2c85-5636-bf22-f7725726b79c	9	edf24324-814b-56b2-8b5d-c214ff93fad4	2026-05-22	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
713a10b5-1ea2-566d-8919-97d6ef0138e2	10	9b62d7c9-5d36-53f7-b27d-5699ce5c52e4	2026-05-21	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
514e40df-ed56-5edd-97c3-889335795ad1	11	\N	2026-05-20	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
bcbd2a68-d4a6-538c-a19c-e10430acfb5e	12	\N	2026-05-19	\N	t	[]	Box operativo con seguimiento diario de encamado y consumo.
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
animal-001	ES001	Luna	hembra	2020-04-12	Frisona	produccion	lactante	2020-04-12	\N	\N	\N
animal-002	ES002	Nube	hembra	2021-09-03	Frisona	produccion	prenada	2021-09-03	\N	\N	\N
animal-003	ES003	Brisa	hembra	2025-01-19	Cruce	recria	\N	2025-01-19	\N	\N	\N
\.


--
-- Data for Name: core_employees; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_employees (id, nombre, apellidos, role, zona_principal_id, activo) FROM stdin;
emp-001	Roberto	Castro	admin	ordeno	t
emp-002	Laura	Fernandez	alimentacion	recria	t
emp-003	Dr.	Mendez	veterinario	paridera	t
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
lac-001	animal-001	3	2025-10-02	\N	236	34.2	8071.2	3.72	3.31	168000	t
lac-002	animal-002	2	2025-11-18	\N	189	30.8	5821.2	3.84	3.39	142000	t
\.


--
-- Data for Name: core_machinery; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_machinery (id, nombre, tipo, zona_id, estado, proxima_revision, observaciones) FROM stdin;
mach-001	Robot de ordeno 1	ordeno	ordeno	operativa	2026-06-10	Lavado automatico correcto.
mach-002	Mezclador unifeed	alimentacion	recria	revision_programada	2026-05-30	Comprobar cuchillas y bascula.
\.


--
-- Data for Name: core_tasks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_tasks (id, tarea_catalogo_id, tarea_catalogo, zona_id, fecha_programada, fecha_ejecucion, estado, ejecutado_por, tiempo_ejecucion_minutos, resultado, observaciones, problemas_encontrados, acciones_correctivas, checklist_completado, checklist_datos, es_urgente, motivo_retraso, requiere_seguimiento, fecha_seguimiento) FROM stdin;
task-001	cat-ord-001	{"id": "cat-ord-001", "nombre": "Revisar tanque", "categoria": "ordeno", "frecuencia": "diaria", "zona_aplicable": "ordeno"}	ordeno	2026-05-31 22:56:54.083822	\N	programada	\N	\N	\N	\N	\N	\N	false	\N	t	\N	f	\N
task-002	cat-par-001	{"id": "cat-par-001", "nombre": "Control encamado", "categoria": "bienestar", "frecuencia": "diaria", "zona_aplicable": "paridera"}	paridera	2026-05-31 17:56:54.083849	\N	retrasada	\N	\N	\N	Pendiente de revision	\N	\N	false	\N	f	\N	t	\N
\.


--
-- Data for Name: core_treatments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_treatments (id, animal_id, medicamento, dosis, via_administracion, fecha_inicio, fecha_fin, periodo_retirada_dias, fecha_fin_retirada, activo, motivo, veterinario, observaciones) FROM stdin;
treat-001	animal-002	Suplemento mineral	120 g/dia	oral	2026-05-20	\N	0	\N	t	Apoyo nutricional en tramo final de gestacion	Dr. Mendez	Revisar condicion corporal semanalmente.
\.


--
-- Data for Name: core_zones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.core_zones (id, nombre, codigo, descripcion, tipo, tiene_pantalla_tv, tiene_tablet, activa) FROM stdin;
ordeno	Sala de ordeno	ORD	Produccion, calidad de leche y tanque.	produccion	t	t	t
paridera	Paridera	PAR	Partos, preparto y atencion neonatal.	cuidados	t	t	t
recria	Recria	REC	Terneras, crecimiento y salud de recria.	crecimiento	t	t	t
\.


--
-- Data for Name: datos_metereologicos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.datos_metereologicos (id, fecha_hora, temperatura_media, temperatura_maxima, temperatura_minima, humedad_relativa, precipitacion, velocidad_viento, presion_atmosferica, estado_cielo, ubicacion, latitud, longitud, fuente) FROM stdin;
\.


--
-- Data for Name: empleados; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.empleados (id, nombre, apellidos, rol, cualificaciones, telefono, email, activo, fecha_alta, fecha_baja, zona_principal_id) FROM stdin;
aed8c2c4-9620-5034-9248-d8564ee7addf	Elena	Mendez Prieto	veterinario	{veterinaria,recria}	600100203	elena.mendez@tools4milk.local	t	2024-06-30	\N	12928484-dfe8-4637-abb5-954ad7673cc8
718c721d-90a7-536a-b47d-bb935fe583f3	Jorge	Mato Iglesias	mecanico	{mantenimiento,robot_ordeno}	600100207	jorge.mato@tools4milk.local	t	2024-12-07	\N	0136bdbc-70c7-5c70-8872-c5fcfdf72e40
4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	Ana	Lopez Valdes	encargado	{gestion,VMS,calidad}	600100201	ana.lopez@tools4milk.local	t	2024-09-18	\N	942963db-2cb5-49b5-9640-c96a138553cc
efbe203d-853b-56dc-a3a2-e2839e844083	Sofia	Barreiro Nunez	encargado	{turnos,pedidos}	600100208	sofia.barreiro@tools4milk.local	t	2025-07-05	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37
ee779dc8-16c9-597a-b0ed-ff5886d58b9e	Diego	Pereira Castro	auxiliar	{recria,terneros}	600100205	diego.pereira@tools4milk.local	t	2025-08-24	\N	bc97e385-bbd8-5163-895a-b7156b84e145
3033a0ee-9ffe-5e7f-a7a2-76f309918749	Irene	Varela Paz	auxiliar	{apoyo,calidad}	600100210	irene.varela@tools4milk.local	t	2026-01-01	\N	bc97e385-bbd8-5163-895a-b7156b84e145
f2b0bd7e-4171-5347-8179-fe6667ba7985	Marcos	Rivas Soto	auxiliar	{sala_ordeno,VMS}	600100202	marcos.rivas@tools4milk.local	t	2025-04-16	\N	4f5eef67-de33-4897-9669-51ba1a5ef6d6
0ecf1a97-9350-535c-9d9a-08f92e2d4b54	Laura	Fernandez Lago	auxiliar	{TMR,alimentacion}	600100204	laura.fernandez@tools4milk.local	t	2025-06-05	\N	4f5eef67-de33-4897-9669-51ba1a5ef6d6
350c2228-7752-5756-bb3e-436f655d703b	Nuria	Santos Vidal	auxiliar	{limpieza,camas}	600100206	nuria.santos@tools4milk.local	t	2025-12-02	\N	1819261f-9823-5373-a0dc-533638edb05e
34b1024d-a884-5dda-b84c-e9460fb19325	Pablo	Costa Rey	auxiliar	{almacen,silos}	600100209	pablo.costa@tools4milk.local	t	2025-09-23	\N	1819261f-9823-5373-a0dc-533638edb05e
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
97682f5a-49f4-53bf-8a08-4846ba0468ed	d58fbf17-442e-5153-8cdf-ce264a40ef4f	cojera	2026-05-23	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Meloxicam	20 ml/48h	subcutanea	\N	f	45.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
ffdb5c2c-362d-59a5-9896-42ccfc261a9b	c7ee8997-4bfb-56ca-9a3f-653af2d06595	metritis	2026-05-20	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Penetamato	1 aplicacion/ordeno	oral	\N	f	52.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
b3a81c79-2168-5203-ba17-489b2d3f3ebf	0d506129-b7c5-507a-88ca-242344baa5de	neumonia	2026-05-17	2026-05-28	Revision clinica y seguimiento segun protocolo de la explotacion.	Florfenicol	2 sobres/dia	intramamaria	\N	t	59.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
b899078b-81a1-56c9-939d-7df708e3aa93	73956a35-c183-5c88-9b6e-827903fe0241	diarrea	2026-05-14	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Electrolitos orales	10 ml/24h	intramuscular	2026-06-03	f	66.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
4eaa9f5b-8295-5d1b-a98e-2c285fdc855e	e287b4b8-1876-527c-8b7c-7fdf85c42709	otra	2026-05-11	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Pomada intramamaria	20 ml/48h	subcutanea	\N	f	73.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
e3df197e-24f9-5903-bda0-e6cf697f82ad	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	mastitis	2026-05-08	2026-05-25	Revision clinica y seguimiento segun protocolo de la explotacion.	Ceftiofur	1 aplicacion/ordeno	oral	\N	t	80.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
ffb9c824-a985-514a-8076-44cd6d396e71	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	cojera	2026-05-05	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Meloxicam	2 sobres/dia	intramamaria	\N	f	87.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
abf1ac0a-6bac-5db5-ab56-49868a5d113f	3c97c346-b54c-5581-930e-f3264d6773ea	metritis	2026-05-02	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Penetamato	10 ml/24h	intramuscular	2026-06-03	f	94.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
99a4215a-c560-51b1-af22-f514c466e839	936b78c4-7b89-5fcf-97f7-54f007674e36	neumonia	2026-04-29	2026-05-22	Revision clinica y seguimiento segun protocolo de la explotacion.	Florfenicol	20 ml/48h	subcutanea	\N	t	101.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
58667dde-19dd-5418-9a1a-d6f7d2da1a6c	cf17702f-f18b-553e-9294-67e671e66022	diarrea	2026-04-26	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Electrolitos orales	1 aplicacion/ordeno	oral	\N	f	108.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
025ae8e0-6852-5c50-828d-4196e9b8e8b9	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	otra	2026-04-23	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Pomada intramamaria	2 sobres/dia	intramamaria	\N	f	115.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
9dbc5471-3f77-5012-a9fa-00908a2fc64e	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	mastitis	2026-04-20	2026-05-31	Revision clinica y seguimiento segun protocolo de la explotacion.	Ceftiofur	10 ml/24h	intramuscular	2026-06-03	t	122.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
fbb2ac4e-2d8e-5790-aea9-e7e6bc2b4d3b	d172a069-591a-55e4-89fc-32699f1d25c9	cojera	2026-04-17	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Meloxicam	20 ml/48h	subcutanea	\N	f	129.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
dd392fa1-af05-5a7c-9488-3aaaf47e736b	436a7ff2-5df5-51b1-a49f-179831808d47	metritis	2026-04-14	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Penetamato	1 aplicacion/ordeno	oral	\N	f	136.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
bae52c71-c780-5c36-852b-44d7108c6e8d	b5263713-2026-5bad-ae46-296dc48a39d3	neumonia	2026-04-11	2026-05-28	Revision clinica y seguimiento segun protocolo de la explotacion.	Florfenicol	2 sobres/dia	intramamaria	\N	t	143.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
1da930ee-2f7a-511c-8f8d-22b62a6e9a10	62d38b4e-74e0-5f20-b66b-64efddec53b7	diarrea	2026-04-08	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Electrolitos orales	10 ml/24h	intramuscular	2026-06-03	f	150.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
25469cc9-5627-5fd0-9b8d-d9adca35b5e5	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	otra	2026-04-05	\N	Revision clinica y seguimiento segun protocolo de la explotacion.	Pomada intramamaria	20 ml/48h	subcutanea	\N	f	157.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
37eaf94b-dcf5-57f2-97a5-7186a9d3052e	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	mastitis	2026-04-02	2026-05-25	Revision clinica y seguimiento segun protocolo de la explotacion.	Ceftiofur	1 aplicacion/ordeno	oral	\N	t	164.00	aed8c2c4-9620-5034-9248-d8564ee7addf	Datos sanitarios realistas para demo funcional.
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
498fe423-512e-5a1d-93f7-5940ca889eea	sanidad_animal	tratamiento	media	en_gestion	Tratamiento pendiente de confirmar	Falta marcar administracion de segunda dosis en checklist.	12928484-dfe8-4637-abb5-954ad7673cc8	\N	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-27 19:53:17.542964+00	\N	\N	[]
f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30	infraestructura	bebedero	media	abierta	Bebedero con caudal bajo	Bebedero del lote de produccion con llenado lento.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-26 19:53:17.542964+00	\N	\N	[]
bf301360-f84a-5b0e-b62a-23caa034b593	alimentacion	tmr	media	resuelta	Desviacion en mezcla unifeed	La paja supero el objetivo en 6%; corregido en segunda carga.	1819261f-9823-5373-a0dc-533638edb05e	1479ad4d-f17a-40bd-8606-590ddb2fa868	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-24 19:53:17.542964+00	2026-05-25 19:53:17.542964+00	\N	[{"ts": "2026-05-25T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
415f1b03-6825-5da0-b3ca-ba52a89cfcf9	sanidad_animal	ternero	alta	en_gestion	Ternero con diarrea neonatal	Box 7 con heces liquidas y ligera deshidratacion.	584383a2-21ba-537b-af9b-90d8b722821b	\N	874a44ba-01b6-5641-a7a8-14b3adbaa35a	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-22 19:53:17.542964+00	\N	\N	[]
8d02d4b9-2932-5853-b0e4-478817e0c5c0	sanidad_animal	cojera	media	abierta	Vaca con cojera leve	Apoyo irregular en extremidad posterior izquierda.	12928484-dfe8-4637-abb5-954ad7673cc8	\N	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-21 19:53:17.542964+00	\N	\N	[]
85bb338b-4e50-5689-b490-915685a2ce07	alimentacion	arrimador	media	abierta	Arrimador sin pasada nocturna	Equipo quedo parado junto a cornadiza; revisar bateria.	1819261f-9823-5373-a0dc-533638edb05e	d9c29718-27eb-55a8-99d3-6f55765d7e34	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-17 19:53:17.542964+00	\N	\N	[]
1e8ccb35-7b69-509c-8196-5b1a92beafbe	sanidad_animal	metritis	alta	abierta	Sospecha de metritis postparto	Animal con descarga anormal y descenso de ingesta.	12928484-dfe8-4637-abb5-954ad7673cc8	\N	73956a35-c183-5c88-9b6e-827903fe0241	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-14 19:53:17.542964+00	\N	\N	[]
290612c3-2ec1-5f55-b1b0-b49389db3355	calidad_leche	grasa	baja	abierta	Bajada de grasa en lote	Media de grasa baja respecto a semana previa; revisar fibra efectiva.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-09 19:53:17.542964+00	\N	\N	[]
23661db5-4a74-5c10-b3a4-991b4fbb567d	averia_maquinaria	tractor	media	cerrada	Revision de tractor completada	Cambio de filtro y engrase realizados.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	2a645371-8dcf-5741-9cba-4503270ee2ef	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-08 19:53:17.542964+00	2026-05-09 19:53:17.542964+00	\N	[{"ts": "2026-05-09T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
27bc0217-6243-5c80-9f8c-aaef63cb8d91	infraestructura	boxes	media	en_gestion	Cama humeda en boxes de terneros	Cambiar cama de boxes 4 a 8 antes de la tarde.	584383a2-21ba-537b-af9b-90d8b722821b	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-06 19:53:17.542964+00	\N	\N	[]
7e8790a1-a048-50be-87a3-31e395137dd8	sanidad_animal	mastitis	alta	abierta	Mastitis clinica leve	Cuarteron posterior con grumos en primeros chorros.	12928484-dfe8-4637-abb5-954ad7673cc8	\N	2e14a84a-511d-5bcf-867c-216522289b1c	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-05 19:53:17.542964+00	\N	\N	[]
7e55d431-d27d-59de-b1f3-f8bae2a81d00	alimentacion	agua	baja	resuelta	Bebedero limpiado tras aviso	Retirado resto de forraje de valvula.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-04 19:53:17.542964+00	2026-05-05 19:53:17.542964+00	\N	[{"ts": "2026-05-05T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
c534fbe9-e9d8-5960-b0a4-befbc200f6aa	averia_maquinaria	amamantadora	media	abierta	Amamantadora en revision pendiente	Calibracion de polvo de leche fuera de rango.	584383a2-21ba-537b-af9b-90d8b722821b	1334d1ae-1804-491e-a777-63439f7e9468	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-03 19:53:17.542964+00	\N	\N	[]
153da52a-b5d2-53db-8b2c-1292e1e1fd3b	averia_maquinaria	robot_ordeno	alta	abierta	Robot de ordeno con fallo temporal	El VMS 4 registra dos paradas por error de brazo. Revisar antes del turno de tarde.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-30 19:53:17.542964+00	\N	\N	[]
c1c5f567-6153-5fb1-ab56-a2c15f9a99c7	sanidad_animal	retraso_ordeno	media	en_gestion	Vaca con retraso de ordeno	Animal con mas de 11 horas desde el ultimo paso por robot.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-29 19:53:17.542964+00	\N	\N	[]
196957e3-30e1-50a9-b8c6-5324e8625627	calidad_leche	scc	alta	abierta	Elevacion de recuento celular	Lectura individual por encima de 350000 cel/ml; tomar muestra de confirmacion.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	d172a069-591a-55e4-89fc-32699f1d25c9	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-28 19:53:17.542964+00	\N	\N	[]
37aa1113-89b0-5f8d-be10-c7fed87f469e	pedidos	stock	alta	abierta	Stock bajo de detergente alcalino	Quedan dos garrafas, insuficiente para la semana completa.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-25 19:53:17.542964+00	\N	\N	[]
5bfa710e-ec65-5af2-b146-0fad0d8138bf	infraestructura	silo	media	abierta	Incidencia en silo de maiz	Lona levantada en lateral norte tras viento nocturno.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-23 19:53:17.542964+00	\N	\N	[]
c60e0f88-88f3-5536-83ee-9251b167127f	averia_maquinaria	bomba_vacio	alta	abierta	Caida de vacio en sala	Bomba principal con oscilaciones al arrancar segundo robot.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	cca2e231-9ce5-5e6a-a9f2-63c43db556f4	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-20 19:53:17.542964+00	\N	\N	[]
97c3a126-2dc6-5f13-a670-bb0972267513	averia_maquinaria	sensor	media	resuelta	Sensor sin lectura	Sensor de conductividad del VMS 2 reiniciado y vuelve a emitir.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	2def9ef9-5ce4-4588-996a-9d149b8888b1	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-19 19:53:17.542964+00	2026-05-20 19:53:17.542964+00	\N	[{"ts": "2026-05-20T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
317dc879-4d94-5ed4-9757-f2c4d8c8e812	infraestructura	tarea	baja	cerrada	Tarea de camas no completada	Se reprogramo desinfeccion por entrada de forraje.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-18 19:53:17.542964+00	2026-05-19 19:53:17.542964+00	\N	[{"ts": "2026-05-19T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
4bb034da-dc31-505e-a44b-e67c9c21a6db	calidad_leche	tanque	media	cerrada	Temperatura de tanque revisada	Pico de 4.8 C durante lavado; estabilizado tras revision.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	74cf333b-4aba-5db6-bce2-1e13e1439bc2	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-16 19:53:17.542964+00	2026-05-17 19:53:17.542964+00	\N	[{"ts": "2026-05-17T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
bcb1850d-390e-58c3-b6cf-57fccebffc11	pedidos	filtros	baja	resuelta	Filtros recibidos incompletos	Proveedor entrego 4 cajas de 6 solicitadas; queda reposicion pendiente.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-15 19:53:17.542964+00	2026-05-16 19:53:17.542964+00	\N	[{"ts": "2026-05-16T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
b0d6febc-76d2-568c-822b-db5cc9ea35f6	infraestructura	oficina	baja	cerrada	Tablet de oficina sin carga	Cable sustituido y dispositivo operativo.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-13 19:53:17.542964+00	2026-05-14 19:53:17.542964+00	\N	[{"ts": "2026-05-14T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
adbf9a1e-8a9a-56b7-addc-deb367880811	averia_maquinaria	ventilacion	media	en_gestion	Ventilador sector 3 parado	Motor no arranca en modo automatico con THI alto.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	95ccf014-f4ea-5888-a3d7-cba4804370b8	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-12 19:53:17.542964+00	\N	\N	[]
9daf15f0-e0f0-5973-b3e2-174a5a5fe7d9	alimentacion	silos	media	resuelta	Frente de silo irregular	Se recorto frente y se compacto zona abierta.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-11 19:53:17.542964+00	2026-05-12 19:53:17.542964+00	\N	[{"ts": "2026-05-12T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
f0142fee-b873-5d45-80d9-fbc8f460b796	sanidad_animal	recria	media	abierta	Novilla con tos persistente	Revisar temperatura y valorar tratamiento respiratorio.	584383a2-21ba-537b-af9b-90d8b722821b	\N	74107440-00d6-58ee-ae41-82471d6b9aa4	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-10 19:53:17.542964+00	\N	\N	[]
b84c837c-8e65-51a7-a0b0-565faa3d59a8	pedidos	medicamentos	alta	abierta	Pedido urgente de antiinflamatorio	Stock minimo alcanzado tras tratamientos de cojeras.	1819261f-9823-5373-a0dc-533638edb05e	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-07 19:53:17.542964+00	\N	\N	[]
415d9b5b-4fb4-5fdb-8a8d-ea8490a015b0	calidad_leche	muestra	baja	cerrada	Muestra de control registrada	Muestra enviada por subida puntual de conductividad.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	46e29b13-6344-5b6d-8471-0891456bd85b	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-02 19:53:17.542964+00	2026-05-03 19:53:17.542964+00	\N	[{"ts": "2026-05-03T19:53:17.542964+00:00", "accion": "Incidencia revisada y cerrada con seguimiento."}]
7fdc414c-a010-5da9-8468-48e5ba08e193	infraestructura	limpieza	media	abierta	Limpieza de sala retrasada	Pendiente repaso de zona de espera tras turno de manana.	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-01 19:53:17.542964+00	\N	\N	[]
\.


--
-- Data for Name: lactaciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lactaciones (id, animal_id, numero, fecha_parto, fecha_secado, produccion_total_kg, notas, grasa_promedio, proteina_promedio, rcs_promedio) FROM stdin;
4b90f632-59f3-5b8f-a197-5ba8f5dad7dc	0f7ff532-8875-5404-8a53-3c204bdf55e1	4	2025-08-05	2026-05-12	7229.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
10e9a124-b2a9-5e18-8381-baf9eacbfb8f	1f8d73e0-6258-536a-bb01-0fcdd4b96b26	5	2025-08-04	2026-05-11	7260.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
22fcd767-6b57-535f-9399-294cd1873d0d	5dc5cac3-6bb9-5d56-957b-7677c4bcc56b	2	2025-08-03	2026-05-10	7291.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
6d66d088-5bc9-5f62-96d3-7781a72ee6af	12ba4d63-24a9-5f3c-9204-99590678f5ed	3	2025-08-02	2026-05-09	7322.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
6de815cc-7206-53f3-8841-766dbc57bc97	09065fbe-c2e5-500a-93cc-5f9f55d9f114	4	2025-08-01	2026-05-08	7353.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
0a6d204e-01b4-5a1e-be12-b5838ba0d5a8	5dbdee66-af90-503d-b6c5-b428cebb2b91	1	2025-07-31	2026-05-07	7384.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
4c6d1e73-f641-5e82-b915-95a0cd2bd068	5c888535-5880-5f6c-b53c-128c9df5464b	5	2025-07-30	2026-05-06	7415.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
af8e1765-6912-50ff-8103-12741d9282cf	963164ac-9734-5fd9-bd3a-fc7dacff84e1	3	2025-07-29	2026-05-05	7446.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
7e0eaf80-bffa-58f4-89fe-b9c12a5deb5a	ffe82114-3a26-5e7b-8ce6-7a8ef2f12732	4	2025-07-28	2026-05-04	7477.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
4da2d95c-5f06-5fa2-9d43-69ef680a0212	efc8bf74-ef7d-5152-a4d4-a077ae7a7d52	1	2025-07-27	2026-05-03	7508.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
167d62d0-29a3-5ce3-acde-14ba62606501	27ba2d06-b334-5f7c-bd59-ba67cf095d68	2	2025-07-26	2026-05-02	7539.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
14a2ff43-f6f4-5fb3-8210-51055ba5f20c	389f3969-2148-5055-82d6-166a20ab6a9b	5	2025-07-25	2026-05-01	7570.00	Registro realista de lactacion para seguimiento de calidad y produccion.	\N	\N	\N
e8407929-25da-5561-a7c3-4541dc93ff50	d58fbf17-442e-5153-8cdf-ce264a40ef4f	2	2026-04-25	\N	6547.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.050	3.448	309149
a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	c7ee8997-4bfb-56ca-9a3f-653af2d06595	3	2026-04-24	\N	6594.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.279	3.368	88490
7621f1a7-be7b-56cd-b317-f0d3671da100	0d506129-b7c5-507a-88ca-242344baa5de	4	2026-04-23	\N	6641.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.914	3.070	72522
064ec719-795a-5ee5-a483-47f76d391cc8	73956a35-c183-5c88-9b6e-827903fe0241	1	2026-04-22	\N	6688.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.678	3.066	148063
7af07ef1-8064-57dd-aa41-6b4c1f917ff1	e287b4b8-1876-527c-8b7c-7fdf85c42709	5	2026-04-21	\N	6735.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.609	3.459	274338
6fd17ce8-0480-58ea-a914-ee3cefea419d	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	3	2026-04-20	\N	6782.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.438	3.479	341969
0a5e4eef-d763-54ac-9552-9e72b62fc99f	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	4	2026-04-19	\N	6829.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.353	3.539	239542
77b47f12-8ea8-50c8-8dd5-bfbda06db861	3c97c346-b54c-5581-930e-f3264d6773ea	1	2026-04-18	\N	6876.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.516	3.152	61256
d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	936b78c4-7b89-5fcf-97f7-54f007674e36	2	2026-04-17	\N	6923.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.363	3.236	123110
b060ba81-8cd5-5ece-bb06-4459d9d6c192	cf17702f-f18b-553e-9294-67e671e66022	5	2026-04-16	\N	6970.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.703	3.558	196233
2ead6940-aa75-5701-a348-929b57d0fc24	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	4	2026-04-15	\N	7017.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.016	3.331	192391
a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	1	2026-04-14	\N	7064.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.619	3.170	282001
36f1d931-0240-57a8-ad21-0eed820caf7d	d172a069-591a-55e4-89fc-32699f1d25c9	2	2026-04-13	\N	7111.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.968	3.065	267735
68a503e7-22a8-5714-bc47-d3dcc87ef423	436a7ff2-5df5-51b1-a49f-179831808d47	3	2026-04-12	\N	7158.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.639	3.603	241926
e37479d9-8791-5f72-983e-f1631d34edf7	b5263713-2026-5bad-ae46-296dc48a39d3	5	2026-04-11	\N	7205.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.560	3.280	331230
973ae836-e018-584f-b590-b84db7a3e86d	62d38b4e-74e0-5f20-b66b-64efddec53b7	1	2026-04-10	\N	7252.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.698	3.075	298272
4957a3f4-17ce-5354-ab80-86d2329fbab1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	2	2026-04-09	\N	7299.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.385	3.664	337852
2cb0627e-c84e-5709-b4f6-339bc1b14911	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	3	2026-04-08	\N	7346.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.662	3.664	75569
6e5b5686-d333-5982-b41f-eee032b8d6a0	df87133b-ee35-5f6c-982e-0b9e09ad3dea	4	2026-04-07	\N	7393.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.684	3.289	340202
e5e51dcf-b0ac-5052-a719-8fa19c11da8a	afe8a03e-b5f2-5013-9b65-26fc935d703f	5	2026-04-06	\N	7440.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.966	3.048	138184
1fc67a37-6696-5dae-aaf9-f610ba5273ae	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	2	2026-04-05	\N	7487.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.620	3.420	163387
d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	3	2026-04-04	\N	7534.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.232	3.074	331772
d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	1a1a57d7-fc16-5715-8133-35c906e0453a	4	2026-04-03	\N	7581.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.506	3.283	371286
52348272-8285-559f-b6f3-914b8c57c752	4c13e989-899c-5d47-8988-380802d72f58	1	2026-04-02	\N	7628.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.529	3.073	376645
1bf518e1-cac0-50e8-bde7-8c23f8bb2592	784ed9c6-39d3-5da9-b379-311aca240fdd	5	2026-04-01	\N	7675.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.120	3.047	63931
53bd7e52-86a1-540a-b190-b1ab73510f55	46e29b13-6344-5b6d-8471-0891456bd85b	3	2026-03-31	\N	7722.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.767	3.798	210010
045d48f7-3f12-5b84-9edb-98b48ee7bb52	20cb75da-56ec-50b5-85f8-792b0d74f745	4	2026-03-30	\N	7769.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.636	3.032	122012
13b587b3-9c90-5f7f-b9e8-14c17384a931	1c069679-3e6d-5b3e-8842-c27c074da0a0	1	2026-03-29	\N	7816.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.947	3.796	188311
b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	fae53a98-6313-583b-8c58-8e81fe950f6e	2	2026-03-28	\N	7863.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.748	3.568	321999
08df51d3-489b-53f0-9c61-446192882a27	eeded079-9abf-5844-8559-6eea890a6fe4	5	2026-03-27	\N	7910.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.160	3.354	160432
fd976089-b688-5bff-af9f-a7dfdea216b1	674f97b3-f5f9-5ead-bf6c-d743870ba36f	4	2026-03-26	\N	7957.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.115	3.354	181322
86401639-58ea-5592-a23e-9c065fc3231f	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	1	2026-03-25	\N	8004.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.454	3.389	372029
bcf02693-ed10-51c4-b023-232f6567db1d	3f9aca1c-2859-5e86-909b-fe2777f960ca	2	2026-03-24	\N	8051.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.189	3.291	195719
f5a39406-3e7d-544f-b975-45d8feebf05f	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	3	2026-03-23	\N	8098.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.807	3.065	296343
23687f00-e66b-5be8-ab3f-1ccd578256b7	ac52e314-03fc-5fc7-95c8-e51551ffca78	5	2026-03-22	\N	8145.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.732	3.033	350589
86e49eb4-d6ad-5da6-bab7-32f91119a92a	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	1	2026-03-21	\N	8192.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.204	3.066	115947
fe1e013e-53e5-5bd9-92b8-443b5cb8e62f	6b224987-9434-5637-a871-9ac01fd4d4c3	2	2026-03-20	\N	8239.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.417	3.244	81535
3c25168d-5e97-508d-8fb3-60974748f73d	abe64d55-ec3c-53f6-8051-84c8f56b51d5	3	2026-03-19	\N	8286.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.860	3.788	299563
ddd72c55-32c7-5391-94d8-8276f7a43c02	2e14a84a-511d-5bcf-867c-216522289b1c	4	2026-03-18	\N	8333.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.033	3.259	250899
320b42f3-973d-56b9-98ea-783f36c3b126	bd424aa8-6ab0-53ae-8e26-0eb2d7f059f7	5	2026-03-17	\N	8380.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.415	3.561	224019
f5f50d8e-3893-59f0-9070-9b6d066bdb3f	2a91fb61-47ee-5001-a3e6-0e56c0f91308	2	2026-03-16	\N	8427.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.975	3.585	135412
615f44ce-f0be-56cb-8c7d-5c7ead5cb1eb	df02d6c2-f792-565d-ac97-d358d7484092	3	2026-03-15	\N	8474.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.652	3.290	103938
f9a6c45d-8668-5d51-81b7-5387e7b8b6de	78f6b86f-6d19-50c5-a003-4cf0c0c02e22	4	2026-03-14	\N	8521.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.458	3.546	143773
e037052a-a00a-55f8-892b-8afe93b10718	c06ec15f-7d13-5837-b7c2-0b8b8465b3c1	1	2026-03-13	\N	8568.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.743	3.298	261999
a65a51e8-138c-520b-a313-ef50dd1f0985	0238f86f-4409-54d4-b4eb-0d28d7b4af0c	5	2026-03-12	\N	8615.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.181	3.585	298331
2ea276d5-c9af-5aa0-9bf5-ee84fca6a2bf	c9303516-f788-5f46-90dd-bb82d7023d71	3	2026-03-11	\N	8662.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.642	3.464	260840
c9a712ea-3b91-5808-85d6-70121114eda3	a306664d-4e62-530d-8fe8-28ebfce56181	4	2026-03-10	\N	8709.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.156	3.317	265884
01e9496c-6dd5-5546-98d6-7e996b700849	ab19f1c4-775c-5f7d-8fad-c7b0cea81217	1	2026-03-09	\N	8756.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.232	3.444	225938
d7149504-2e2a-50bd-893d-70f374e26994	9a533fa2-4f96-500a-af83-80da01f2370d	2	2026-03-08	\N	8803.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.851	3.043	357803
1efb6c30-09e4-54b3-b157-ba96131896a5	0db75e34-604b-511f-8aea-4156fe8eb5d1	5	2026-03-07	\N	8850.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.408	3.604	344393
ef0a6134-4db9-5c68-ab5a-06ad1b6e310e	1cb96771-c7de-53e3-b737-2954be5a71de	4	2026-03-06	\N	8897.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.733	3.792	109437
421088e6-fd48-5417-86f6-d3c3aa5867f0	7849fd17-a936-5c6f-9ffd-a4bd9df6cdf6	1	2026-03-05	\N	8944.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.853	3.786	95903
06553104-6a9a-5ccb-995b-cd3772e1b134	b7e68ca6-a516-52f8-9a88-8f272749ac23	2	2026-03-04	\N	8991.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.640	3.205	76237
7182be4b-9f08-53d8-8be7-e3ca84395e0d	329e2c29-366f-56b0-b854-ca7cb56bff5f	3	2026-03-03	\N	9038.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.059	3.324	232061
ee30ab53-fdaf-5c8b-b233-51ef8a4426da	9144858f-31c8-575d-a0ae-366e1d2935fd	5	2026-03-02	\N	9085.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.215	3.024	53089
9abecae2-30ad-5c55-a5e8-4550191cf7f3	ab624830-c14c-5b1a-afcc-f0b59876050a	1	2026-03-01	\N	9132.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.327	3.459	308031
4a7c4b4f-f461-57a7-b039-d88177d469fe	798cfeb1-fa83-529d-b119-c7f5cd60f5cd	2	2026-02-28	\N	9179.00	Registro realista de lactacion para seguimiento de calidad y produccion.	3.777	3.797	120204
2c23502f-6a36-55a8-bc60-8864a780ceef	a3c69881-650f-5671-9ae6-8371fb892b89	3	2026-02-27	\N	9226.00	Registro realista de lactacion para seguimiento de calidad y produccion.	4.605	3.305	278029
\.


--
-- Data for Name: lecturas_carro_mezclador; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturas_carro_mezclador (ts, mezcla_id, ingrediente, peso_objetivo, peso_real, operario_id) FROM stdin;
\.


--
-- Data for Name: lecturas_meteorologia; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturas_meteorologia (ts, estacion_id, temperatura_c, humedad_relativa, precipitacion_mm, viento_km_h, direccion_viento, radiacion_wm2, prob_precipitacion_pct) FROM stdin;
2026-05-31 19:54:56.952826+00	EST-T4M-01	13.5	62.0	2.4	6.0	180	120.0	\N
2026-05-31 18:54:56.952826+00	EST-T4M-01	14.2	63.0	0.0	7.3	193	185.0	\N
2026-05-31 17:54:56.952826+00	EST-T4M-01	14.9	64.0	0.0	8.6	206	250.0	\N
2026-05-31 16:54:56.952826+00	EST-T4M-01	15.6	65.0	0.0	9.9	219	315.0	\N
2026-05-31 15:54:56.952826+00	EST-T4M-01	16.3	66.0	0.0	11.2	232	380.0	\N
2026-05-31 14:54:56.952826+00	EST-T4M-01	17.0	67.0	0.0	12.5	245	445.0	\N
2026-05-31 13:54:56.952826+00	EST-T4M-01	17.7	68.0	0.0	13.8	258	510.0	\N
2026-05-31 12:54:56.952826+00	EST-T4M-01	18.4	69.0	0.0	15.1	271	575.0	\N
2026-05-31 11:54:56.952826+00	EST-T4M-01	19.1	70.0	0.0	16.4	284	120.0	\N
2026-05-31 10:54:56.952826+00	EST-T4M-01	13.5	71.0	0.0	17.7	297	185.0	\N
2026-05-31 09:54:56.952826+00	EST-T4M-01	14.2	72.0	0.0	19.0	190	250.0	\N
2026-05-31 08:54:56.952826+00	EST-T4M-01	14.9	73.0	2.4	20.3	203	315.0	\N
2026-05-31 07:54:56.952826+00	EST-T4M-01	15.6	74.0	0.0	6.0	216	380.0	\N
2026-05-31 06:54:56.952826+00	EST-T4M-01	16.3	75.0	0.0	7.3	229	445.0	\N
2026-05-31 05:54:56.952826+00	EST-T4M-01	17.0	76.0	0.0	8.6	242	510.0	\N
2026-05-31 04:54:56.952826+00	EST-T4M-01	17.7	77.0	0.0	9.9	255	575.0	\N
2026-05-31 03:54:56.952826+00	EST-T4M-01	18.4	78.0	0.0	11.2	268	120.0	\N
2026-05-31 02:54:56.952826+00	EST-T4M-01	19.1	79.0	0.0	12.5	281	185.0	\N
2026-05-31 01:54:56.952826+00	EST-T4M-01	13.5	62.0	0.0	13.8	294	250.0	\N
2026-05-31 00:54:56.952826+00	EST-T4M-01	14.2	63.0	0.0	15.1	187	315.0	\N
2026-05-30 23:54:56.952826+00	EST-T4M-01	14.9	64.0	0.0	16.4	200	380.0	\N
2026-05-30 22:54:56.952826+00	EST-T4M-01	15.6	65.0	0.0	17.7	213	445.0	\N
2026-05-30 21:54:56.952826+00	EST-T4M-01	16.3	66.0	2.4	19.0	226	510.0	\N
2026-05-30 20:54:56.952826+00	EST-T4M-01	17.0	67.0	0.0	20.3	239	575.0	\N
2026-05-30 19:54:56.952826+00	EST-T4M-01	17.7	68.0	0.0	6.0	252	120.0	\N
2026-05-30 18:54:56.952826+00	EST-T4M-01	18.4	69.0	0.0	7.3	265	185.0	\N
2026-05-30 17:54:56.952826+00	EST-T4M-01	19.1	70.0	0.0	8.6	278	250.0	\N
2026-05-30 16:54:56.952826+00	EST-T4M-01	13.5	71.0	0.0	9.9	291	315.0	\N
2026-05-30 15:54:56.952826+00	EST-T4M-01	14.2	72.0	0.0	11.2	184	380.0	\N
2026-05-30 14:54:56.952826+00	EST-T4M-01	14.9	73.0	0.0	12.5	197	445.0	\N
2026-05-30 13:54:56.952826+00	EST-T4M-01	15.6	74.0	0.0	13.8	210	510.0	\N
2026-05-30 12:54:56.952826+00	EST-T4M-01	16.3	75.0	0.0	15.1	223	575.0	\N
2026-05-30 11:54:56.952826+00	EST-T4M-01	17.0	76.0	0.0	16.4	236	120.0	\N
2026-05-30 10:54:56.952826+00	EST-T4M-01	17.7	77.0	2.4	17.7	249	185.0	\N
2026-05-30 09:54:56.952826+00	EST-T4M-01	18.4	78.0	0.0	19.0	262	250.0	\N
2026-05-30 08:54:56.952826+00	EST-T4M-01	19.1	79.0	0.0	20.3	275	315.0	\N
2026-05-30 07:54:56.952826+00	EST-T4M-01	13.5	62.0	0.0	6.0	288	380.0	\N
2026-05-30 06:54:56.952826+00	EST-T4M-01	14.2	63.0	0.0	7.3	181	445.0	\N
2026-05-30 05:54:56.952826+00	EST-T4M-01	14.9	64.0	0.0	8.6	194	510.0	\N
2026-05-30 04:54:56.952826+00	EST-T4M-01	15.6	65.0	0.0	9.9	207	575.0	\N
2026-05-30 03:54:56.952826+00	EST-T4M-01	16.3	66.0	0.0	11.2	220	120.0	\N
2026-05-30 02:54:56.952826+00	EST-T4M-01	17.0	67.0	0.0	12.5	233	185.0	\N
2026-05-30 01:54:56.952826+00	EST-T4M-01	17.7	68.0	0.0	13.8	246	250.0	\N
2026-05-30 00:54:56.952826+00	EST-T4M-01	18.4	69.0	0.0	15.1	259	315.0	\N
2026-05-29 23:54:56.952826+00	EST-T4M-01	19.1	70.0	2.4	16.4	272	380.0	\N
2026-05-29 22:54:56.952826+00	EST-T4M-01	13.5	71.0	0.0	17.7	285	445.0	\N
2026-05-29 21:54:56.952826+00	EST-T4M-01	14.2	72.0	0.0	19.0	298	510.0	\N
2026-05-29 20:54:56.952826+00	EST-T4M-01	14.9	73.0	0.0	20.3	191	575.0	\N
2026-05-29 19:54:56.952826+00	EST-T4M-01	15.6	74.0	0.0	6.0	204	120.0	\N
2026-05-29 18:54:56.952826+00	EST-T4M-01	16.3	75.0	0.0	7.3	217	185.0	\N
2026-05-29 17:54:56.952826+00	EST-T4M-01	17.0	76.0	0.0	8.6	230	250.0	\N
2026-05-29 16:54:56.952826+00	EST-T4M-01	17.7	77.0	0.0	9.9	243	315.0	\N
2026-05-29 15:54:56.952826+00	EST-T4M-01	18.4	78.0	0.0	11.2	256	380.0	\N
2026-05-29 14:54:56.952826+00	EST-T4M-01	19.1	79.0	0.0	12.5	269	445.0	\N
2026-05-29 13:54:56.952826+00	EST-T4M-01	13.5	62.0	0.0	13.8	282	510.0	\N
2026-05-29 12:54:56.952826+00	EST-T4M-01	14.2	63.0	2.4	15.1	295	575.0	\N
2026-05-29 11:54:56.952826+00	EST-T4M-01	14.9	64.0	0.0	16.4	188	120.0	\N
2026-05-29 10:54:56.952826+00	EST-T4M-01	15.6	65.0	0.0	17.7	201	185.0	\N
2026-05-29 09:54:56.952826+00	EST-T4M-01	16.3	66.0	0.0	19.0	214	250.0	\N
2026-05-29 08:54:56.952826+00	EST-T4M-01	17.0	67.0	0.0	20.3	227	315.0	\N
2026-05-29 07:54:56.952826+00	EST-T4M-01	17.7	68.0	0.0	6.0	240	380.0	\N
2026-05-29 06:54:56.952826+00	EST-T4M-01	18.4	69.0	0.0	7.3	253	445.0	\N
2026-05-29 05:54:56.952826+00	EST-T4M-01	19.1	70.0	0.0	8.6	266	510.0	\N
2026-05-29 04:54:56.952826+00	EST-T4M-01	13.5	71.0	0.0	9.9	279	575.0	\N
2026-05-29 03:54:56.952826+00	EST-T4M-01	14.2	72.0	0.0	11.2	292	120.0	\N
2026-05-29 02:54:56.952826+00	EST-T4M-01	14.9	73.0	0.0	12.5	185	185.0	\N
2026-05-29 01:54:56.952826+00	EST-T4M-01	15.6	74.0	2.4	13.8	198	250.0	\N
2026-05-29 00:54:56.952826+00	EST-T4M-01	16.3	75.0	0.0	15.1	211	315.0	\N
2026-05-28 23:54:56.952826+00	EST-T4M-01	17.0	76.0	0.0	16.4	224	380.0	\N
2026-05-28 22:54:56.952826+00	EST-T4M-01	17.7	77.0	0.0	17.7	237	445.0	\N
2026-05-28 21:54:56.952826+00	EST-T4M-01	18.4	78.0	0.0	19.0	250	510.0	\N
2026-05-28 20:54:56.952826+00	EST-T4M-01	19.1	79.0	0.0	20.3	263	575.0	\N
\.


--
-- Data for Name: lecturas_robot_ordeno; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturas_robot_ordeno (ts, robot_id, animal_id, lactacion_id, produccion_kg, conductividad, flujo_max, scc, duracion_min, intentos_fallidos, alerta_robot) FROM stdin;
2026-05-31 05:31:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d58fbf17-442e-5153-8cdf-ce264a40ef4f	e8407929-25da-5561-a7c3-4541dc93ff50	9.23	4.58	2.35	97300	6.8	0	f
2026-05-31 05:32:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	c7ee8997-4bfb-56ca-9a3f-653af2d06595	a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	9.96	4.76	2.60	104600	7.6	0	f
2026-05-31 05:33:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	0d506129-b7c5-507a-88ca-242344baa5de	7621f1a7-be7b-56cd-b317-f0d3671da100	10.69	4.94	2.85	111900	8.4	0	f
2026-05-31 05:34:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	73956a35-c183-5c88-9b6e-827903fe0241	064ec719-795a-5ee5-a483-47f76d391cc8	11.42	5.12	3.10	119200	9.2	0	f
2026-05-31 05:35:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e287b4b8-1876-527c-8b7c-7fdf85c42709	7af07ef1-8064-57dd-aa41-6b4c1f917ff1	12.15	5.30	2.10	126500	6.0	0	f
2026-05-31 05:36:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	6fd17ce8-0480-58ea-a914-ee3cefea419d	12.88	4.40	2.35	133800	6.8	0	f
2026-05-31 05:37:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	0a5e4eef-d763-54ac-9552-9e72b62fc99f	13.61	4.58	2.60	141100	7.6	0	f
2026-05-31 05:38:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	3c97c346-b54c-5581-930e-f3264d6773ea	77b47f12-8ea8-50c8-8dd5-bfbda06db861	14.34	4.76	2.85	148400	8.4	0	f
2026-05-31 05:39:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	936b78c4-7b89-5fcf-97f7-54f007674e36	d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	15.07	4.94	3.10	155700	9.2	0	f
2026-05-31 05:40:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	cf17702f-f18b-553e-9294-67e671e66022	b060ba81-8cd5-5ece-bb06-4459d9d6c192	8.50	5.12	2.10	163000	6.0	0	f
2026-05-31 05:41:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	2ead6940-aa75-5701-a348-929b57d0fc24	9.23	5.30	2.35	170300	6.8	0	f
2026-05-31 05:42:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	9.96	4.40	2.60	177600	7.6	0	f
2026-05-31 05:43:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d172a069-591a-55e4-89fc-32699f1d25c9	36f1d931-0240-57a8-ad21-0eed820caf7d	10.69	4.58	2.85	380000	8.4	0	t
2026-05-31 05:44:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	436a7ff2-5df5-51b1-a49f-179831808d47	68a503e7-22a8-5714-bc47-d3dcc87ef423	11.42	4.76	3.10	192200	9.2	0	f
2026-05-31 05:45:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	b5263713-2026-5bad-ae46-296dc48a39d3	e37479d9-8791-5f72-983e-f1631d34edf7	12.15	4.94	2.10	199500	6.0	0	f
2026-05-31 05:46:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	62d38b4e-74e0-5f20-b66b-64efddec53b7	973ae836-e018-584f-b590-b84db7a3e86d	12.88	5.12	2.35	206800	6.8	0	f
2026-05-31 05:47:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	4957a3f4-17ce-5354-ab80-86d2329fbab1	13.61	5.30	2.60	214100	7.6	1	f
2026-05-31 05:48:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	2cb0627e-c84e-5709-b4f6-339bc1b14911	14.34	4.40	2.85	221400	8.4	0	f
2026-05-31 05:49:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	df87133b-ee35-5f6c-982e-0b9e09ad3dea	6e5b5686-d333-5982-b41f-eee032b8d6a0	15.07	4.58	3.10	228700	9.2	0	f
2026-05-31 05:50:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	afe8a03e-b5f2-5013-9b65-26fc935d703f	e5e51dcf-b0ac-5052-a719-8fa19c11da8a	8.50	4.76	2.10	236000	6.0	0	f
2026-05-31 05:51:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	1fc67a37-6696-5dae-aaf9-f610ba5273ae	9.23	4.94	2.35	243300	6.8	0	f
2026-05-31 05:52:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	9.96	5.12	2.60	95600	7.6	0	f
2026-05-31 05:53:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	1a1a57d7-fc16-5715-8133-35c906e0453a	d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	10.69	5.30	2.85	102900	8.4	0	f
2026-05-31 05:54:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	4c13e989-899c-5d47-8988-380802d72f58	52348272-8285-559f-b6f3-914b8c57c752	11.42	4.40	3.10	110200	9.2	0	f
2026-05-31 05:55:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	784ed9c6-39d3-5da9-b379-311aca240fdd	1bf518e1-cac0-50e8-bde7-8c23f8bb2592	12.15	4.58	2.10	117500	6.0	0	f
2026-05-31 05:56:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	46e29b13-6344-5b6d-8471-0891456bd85b	53bd7e52-86a1-540a-b190-b1ab73510f55	12.88	4.76	2.35	380000	6.8	0	t
2026-05-31 05:57:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	20cb75da-56ec-50b5-85f8-792b0d74f745	045d48f7-3f12-5b84-9edb-98b48ee7bb52	13.61	4.94	2.60	132100	7.6	0	f
2026-05-31 05:58:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	1c069679-3e6d-5b3e-8842-c27c074da0a0	13b587b3-9c90-5f7f-b9e8-14c17384a931	14.34	5.12	2.85	139400	8.4	0	f
2026-05-31 05:59:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	fae53a98-6313-583b-8c58-8e81fe950f6e	b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	15.07	5.30	3.10	146700	9.2	0	f
2026-05-31 06:00:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	eeded079-9abf-5844-8559-6eea890a6fe4	08df51d3-489b-53f0-9c61-446192882a27	8.50	4.40	2.10	154000	6.0	0	f
2026-05-31 06:01:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	674f97b3-f5f9-5ead-bf6c-d743870ba36f	fd976089-b688-5bff-af9f-a7dfdea216b1	9.23	4.58	2.35	161300	6.8	0	f
2026-05-31 06:02:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	86401639-58ea-5592-a23e-9c065fc3231f	9.96	4.76	2.60	168600	7.6	0	f
2026-05-31 06:03:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	3f9aca1c-2859-5e86-909b-fe2777f960ca	bcf02693-ed10-51c4-b023-232f6567db1d	10.69	4.94	2.85	175900	8.4	0	f
2026-05-31 06:04:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	f5a39406-3e7d-544f-b975-45d8feebf05f	11.42	5.12	3.10	183200	9.2	1	f
2026-05-31 06:05:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	ac52e314-03fc-5fc7-95c8-e51551ffca78	23687f00-e66b-5be8-ab3f-1ccd578256b7	12.15	5.30	2.10	190500	6.0	0	f
2026-05-31 06:06:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	86e49eb4-d6ad-5da6-bab7-32f91119a92a	12.88	4.40	2.35	197800	6.8	0	f
2026-05-30 05:31:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d58fbf17-442e-5153-8cdf-ce264a40ef4f	e8407929-25da-5561-a7c3-4541dc93ff50	9.96	4.76	2.60	98400	7.6	0	f
2026-05-30 05:32:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	c7ee8997-4bfb-56ca-9a3f-653af2d06595	a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	10.69	4.94	2.85	105700	8.4	0	f
2026-05-30 05:33:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	0d506129-b7c5-507a-88ca-242344baa5de	7621f1a7-be7b-56cd-b317-f0d3671da100	11.42	5.12	3.10	113000	9.2	0	f
2026-05-30 05:34:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	73956a35-c183-5c88-9b6e-827903fe0241	064ec719-795a-5ee5-a483-47f76d391cc8	12.15	5.30	2.10	120300	6.0	0	f
2026-05-30 05:35:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e287b4b8-1876-527c-8b7c-7fdf85c42709	7af07ef1-8064-57dd-aa41-6b4c1f917ff1	12.88	4.40	2.35	127600	6.8	0	f
2026-05-30 05:36:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	6fd17ce8-0480-58ea-a914-ee3cefea419d	13.61	4.58	2.60	134900	7.6	0	f
2026-05-30 05:37:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	0a5e4eef-d763-54ac-9552-9e72b62fc99f	14.34	4.76	2.85	142200	8.4	0	f
2026-05-30 05:38:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	3c97c346-b54c-5581-930e-f3264d6773ea	77b47f12-8ea8-50c8-8dd5-bfbda06db861	15.07	4.94	3.10	149500	9.2	0	f
2026-05-30 05:39:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	936b78c4-7b89-5fcf-97f7-54f007674e36	d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	8.50	5.12	2.10	156800	6.0	0	f
2026-05-30 05:40:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	cf17702f-f18b-553e-9294-67e671e66022	b060ba81-8cd5-5ece-bb06-4459d9d6c192	9.23	5.30	2.35	164100	6.8	0	f
2026-05-30 05:41:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	2ead6940-aa75-5701-a348-929b57d0fc24	9.96	4.40	2.60	171400	7.6	0	f
2026-05-30 05:42:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	10.69	4.58	2.85	178700	8.4	0	f
2026-05-30 05:43:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d172a069-591a-55e4-89fc-32699f1d25c9	36f1d931-0240-57a8-ad21-0eed820caf7d	11.42	4.76	3.10	380000	9.2	0	t
2026-05-30 05:44:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	436a7ff2-5df5-51b1-a49f-179831808d47	68a503e7-22a8-5714-bc47-d3dcc87ef423	12.15	4.94	2.10	193300	6.0	0	f
2026-05-30 05:45:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	b5263713-2026-5bad-ae46-296dc48a39d3	e37479d9-8791-5f72-983e-f1631d34edf7	12.88	5.12	2.35	200600	6.8	0	f
2026-05-30 05:46:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	62d38b4e-74e0-5f20-b66b-64efddec53b7	973ae836-e018-584f-b590-b84db7a3e86d	13.61	5.30	2.60	207900	7.6	0	f
2026-05-30 05:47:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	4957a3f4-17ce-5354-ab80-86d2329fbab1	14.34	4.40	2.85	215200	8.4	1	f
2026-05-30 05:48:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	2cb0627e-c84e-5709-b4f6-339bc1b14911	15.07	4.58	3.10	222500	9.2	0	f
2026-05-30 05:49:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	df87133b-ee35-5f6c-982e-0b9e09ad3dea	6e5b5686-d333-5982-b41f-eee032b8d6a0	8.50	4.76	2.10	229800	6.0	0	f
2026-05-30 05:50:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	afe8a03e-b5f2-5013-9b65-26fc935d703f	e5e51dcf-b0ac-5052-a719-8fa19c11da8a	9.23	4.94	2.35	237100	6.8	0	f
2026-05-30 05:51:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	1fc67a37-6696-5dae-aaf9-f610ba5273ae	9.96	5.12	2.60	244400	7.6	0	f
2026-05-30 05:52:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	10.69	5.30	2.85	96700	8.4	0	f
2026-05-30 05:53:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	1a1a57d7-fc16-5715-8133-35c906e0453a	d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	11.42	4.40	3.10	104000	9.2	0	f
2026-05-30 05:54:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	4c13e989-899c-5d47-8988-380802d72f58	52348272-8285-559f-b6f3-914b8c57c752	12.15	4.58	2.10	111300	6.0	0	f
2026-05-30 05:55:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	784ed9c6-39d3-5da9-b379-311aca240fdd	1bf518e1-cac0-50e8-bde7-8c23f8bb2592	12.88	4.76	2.35	118600	6.8	0	f
2026-05-30 05:56:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	46e29b13-6344-5b6d-8471-0891456bd85b	53bd7e52-86a1-540a-b190-b1ab73510f55	13.61	4.94	2.60	380000	7.6	0	t
2026-05-30 05:57:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	20cb75da-56ec-50b5-85f8-792b0d74f745	045d48f7-3f12-5b84-9edb-98b48ee7bb52	14.34	5.12	2.85	133200	8.4	0	f
2026-05-30 05:58:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	1c069679-3e6d-5b3e-8842-c27c074da0a0	13b587b3-9c90-5f7f-b9e8-14c17384a931	15.07	5.30	3.10	140500	9.2	0	f
2026-05-30 05:59:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	fae53a98-6313-583b-8c58-8e81fe950f6e	b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	8.50	4.40	2.10	147800	6.0	0	f
2026-05-30 06:00:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	eeded079-9abf-5844-8559-6eea890a6fe4	08df51d3-489b-53f0-9c61-446192882a27	9.23	4.58	2.35	155100	6.8	0	f
2026-05-30 06:01:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	674f97b3-f5f9-5ead-bf6c-d743870ba36f	fd976089-b688-5bff-af9f-a7dfdea216b1	9.96	4.76	2.60	162400	7.6	0	f
2026-05-30 06:02:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	86401639-58ea-5592-a23e-9c065fc3231f	10.69	4.94	2.85	169700	8.4	0	f
2026-05-30 06:03:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	3f9aca1c-2859-5e86-909b-fe2777f960ca	bcf02693-ed10-51c4-b023-232f6567db1d	11.42	5.12	3.10	177000	9.2	0	f
2026-05-30 06:04:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	f5a39406-3e7d-544f-b975-45d8feebf05f	12.15	5.30	2.10	184300	6.0	1	f
2026-05-30 06:05:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	ac52e314-03fc-5fc7-95c8-e51551ffca78	23687f00-e66b-5be8-ab3f-1ccd578256b7	12.88	4.40	2.35	191600	6.8	0	f
2026-05-30 06:06:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	86e49eb4-d6ad-5da6-bab7-32f91119a92a	13.61	4.58	2.60	198900	7.6	0	f
2026-05-29 05:31:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d58fbf17-442e-5153-8cdf-ce264a40ef4f	e8407929-25da-5561-a7c3-4541dc93ff50	10.69	4.94	2.85	99500	8.4	0	f
2026-05-29 05:32:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	c7ee8997-4bfb-56ca-9a3f-653af2d06595	a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	11.42	5.12	3.10	106800	9.2	0	f
2026-05-29 05:33:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	0d506129-b7c5-507a-88ca-242344baa5de	7621f1a7-be7b-56cd-b317-f0d3671da100	12.15	5.30	2.10	114100	6.0	0	f
2026-05-29 05:34:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	73956a35-c183-5c88-9b6e-827903fe0241	064ec719-795a-5ee5-a483-47f76d391cc8	12.88	4.40	2.35	121400	6.8	0	f
2026-05-29 05:35:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e287b4b8-1876-527c-8b7c-7fdf85c42709	7af07ef1-8064-57dd-aa41-6b4c1f917ff1	13.61	4.58	2.60	128700	7.6	0	f
2026-05-29 05:36:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	6fd17ce8-0480-58ea-a914-ee3cefea419d	14.34	4.76	2.85	136000	8.4	0	f
2026-05-29 05:37:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	0a5e4eef-d763-54ac-9552-9e72b62fc99f	15.07	4.94	3.10	143300	9.2	0	f
2026-05-29 05:38:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	3c97c346-b54c-5581-930e-f3264d6773ea	77b47f12-8ea8-50c8-8dd5-bfbda06db861	8.50	5.12	2.10	150600	6.0	0	f
2026-05-29 05:39:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	936b78c4-7b89-5fcf-97f7-54f007674e36	d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	9.23	5.30	2.35	157900	6.8	0	f
2026-05-29 05:40:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	cf17702f-f18b-553e-9294-67e671e66022	b060ba81-8cd5-5ece-bb06-4459d9d6c192	9.96	4.40	2.60	165200	7.6	0	f
2026-05-29 05:41:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	2ead6940-aa75-5701-a348-929b57d0fc24	10.69	4.58	2.85	172500	8.4	0	f
2026-05-29 05:42:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	11.42	4.76	3.10	179800	9.2	0	f
2026-05-29 05:43:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d172a069-591a-55e4-89fc-32699f1d25c9	36f1d931-0240-57a8-ad21-0eed820caf7d	12.15	4.94	2.10	380000	6.0	0	t
2026-05-29 05:44:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	436a7ff2-5df5-51b1-a49f-179831808d47	68a503e7-22a8-5714-bc47-d3dcc87ef423	12.88	5.12	2.35	194400	6.8	0	f
2026-05-29 05:45:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	b5263713-2026-5bad-ae46-296dc48a39d3	e37479d9-8791-5f72-983e-f1631d34edf7	13.61	5.30	2.60	201700	7.6	0	f
2026-05-29 05:46:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	62d38b4e-74e0-5f20-b66b-64efddec53b7	973ae836-e018-584f-b590-b84db7a3e86d	14.34	4.40	2.85	209000	8.4	0	f
2026-05-29 05:47:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	4957a3f4-17ce-5354-ab80-86d2329fbab1	15.07	4.58	3.10	216300	9.2	1	f
2026-05-29 05:48:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	2cb0627e-c84e-5709-b4f6-339bc1b14911	8.50	4.76	2.10	223600	6.0	0	f
2026-05-29 05:49:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	df87133b-ee35-5f6c-982e-0b9e09ad3dea	6e5b5686-d333-5982-b41f-eee032b8d6a0	9.23	4.94	2.35	230900	6.8	0	f
2026-05-29 05:50:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	afe8a03e-b5f2-5013-9b65-26fc935d703f	e5e51dcf-b0ac-5052-a719-8fa19c11da8a	9.96	5.12	2.60	238200	7.6	0	f
2026-05-29 05:51:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	1fc67a37-6696-5dae-aaf9-f610ba5273ae	10.69	5.30	2.85	90500	8.4	0	f
2026-05-29 05:52:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	11.42	4.40	3.10	97800	9.2	0	f
2026-05-29 05:53:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	1a1a57d7-fc16-5715-8133-35c906e0453a	d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	12.15	4.58	2.10	105100	6.0	0	f
2026-05-29 05:54:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	4c13e989-899c-5d47-8988-380802d72f58	52348272-8285-559f-b6f3-914b8c57c752	12.88	4.76	2.35	112400	6.8	0	f
2026-05-29 05:55:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	784ed9c6-39d3-5da9-b379-311aca240fdd	1bf518e1-cac0-50e8-bde7-8c23f8bb2592	13.61	4.94	2.60	119700	7.6	0	f
2026-05-29 05:56:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	46e29b13-6344-5b6d-8471-0891456bd85b	53bd7e52-86a1-540a-b190-b1ab73510f55	14.34	5.12	2.85	380000	8.4	0	t
2026-05-29 05:57:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	20cb75da-56ec-50b5-85f8-792b0d74f745	045d48f7-3f12-5b84-9edb-98b48ee7bb52	15.07	5.30	3.10	134300	9.2	0	f
2026-05-29 05:58:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	1c069679-3e6d-5b3e-8842-c27c074da0a0	13b587b3-9c90-5f7f-b9e8-14c17384a931	8.50	4.40	2.10	141600	6.0	0	f
2026-05-29 05:59:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	fae53a98-6313-583b-8c58-8e81fe950f6e	b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	9.23	4.58	2.35	148900	6.8	0	f
2026-05-29 06:00:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	eeded079-9abf-5844-8559-6eea890a6fe4	08df51d3-489b-53f0-9c61-446192882a27	9.96	4.76	2.60	156200	7.6	0	f
2026-05-29 06:01:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	674f97b3-f5f9-5ead-bf6c-d743870ba36f	fd976089-b688-5bff-af9f-a7dfdea216b1	10.69	4.94	2.85	163500	8.4	0	f
2026-05-29 06:02:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	86401639-58ea-5592-a23e-9c065fc3231f	11.42	5.12	3.10	170800	9.2	0	f
2026-05-29 06:03:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	3f9aca1c-2859-5e86-909b-fe2777f960ca	bcf02693-ed10-51c4-b023-232f6567db1d	12.15	5.30	2.10	178100	6.0	0	f
2026-05-29 06:04:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	f5a39406-3e7d-544f-b975-45d8feebf05f	12.88	4.40	2.35	185400	6.8	1	f
2026-05-29 06:05:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	ac52e314-03fc-5fc7-95c8-e51551ffca78	23687f00-e66b-5be8-ab3f-1ccd578256b7	13.61	4.58	2.60	192700	7.6	0	f
2026-05-29 06:06:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	86e49eb4-d6ad-5da6-bab7-32f91119a92a	14.34	4.76	2.85	200000	8.4	0	f
2026-05-28 05:31:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d58fbf17-442e-5153-8cdf-ce264a40ef4f	e8407929-25da-5561-a7c3-4541dc93ff50	11.42	5.12	3.10	100600	9.2	0	f
2026-05-28 05:32:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	c7ee8997-4bfb-56ca-9a3f-653af2d06595	a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	12.15	5.30	2.10	107900	6.0	0	f
2026-05-28 05:33:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	0d506129-b7c5-507a-88ca-242344baa5de	7621f1a7-be7b-56cd-b317-f0d3671da100	12.88	4.40	2.35	115200	6.8	0	f
2026-05-28 05:34:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	73956a35-c183-5c88-9b6e-827903fe0241	064ec719-795a-5ee5-a483-47f76d391cc8	13.61	4.58	2.60	122500	7.6	0	f
2026-05-28 05:35:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e287b4b8-1876-527c-8b7c-7fdf85c42709	7af07ef1-8064-57dd-aa41-6b4c1f917ff1	14.34	4.76	2.85	129800	8.4	0	f
2026-05-28 05:36:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	6fd17ce8-0480-58ea-a914-ee3cefea419d	15.07	4.94	3.10	137100	9.2	0	f
2026-05-28 05:37:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	0a5e4eef-d763-54ac-9552-9e72b62fc99f	8.50	5.12	2.10	144400	6.0	0	f
2026-05-28 05:38:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	3c97c346-b54c-5581-930e-f3264d6773ea	77b47f12-8ea8-50c8-8dd5-bfbda06db861	9.23	5.30	2.35	151700	6.8	0	f
2026-05-28 05:39:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	936b78c4-7b89-5fcf-97f7-54f007674e36	d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	9.96	4.40	2.60	159000	7.6	0	f
2026-05-28 05:40:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	cf17702f-f18b-553e-9294-67e671e66022	b060ba81-8cd5-5ece-bb06-4459d9d6c192	10.69	4.58	2.85	166300	8.4	0	f
2026-05-28 05:41:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	2ead6940-aa75-5701-a348-929b57d0fc24	11.42	4.76	3.10	173600	9.2	0	f
2026-05-28 05:42:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	12.15	4.94	2.10	180900	6.0	0	f
2026-05-28 05:43:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d172a069-591a-55e4-89fc-32699f1d25c9	36f1d931-0240-57a8-ad21-0eed820caf7d	12.88	5.12	2.35	380000	6.8	0	t
2026-05-28 05:44:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	436a7ff2-5df5-51b1-a49f-179831808d47	68a503e7-22a8-5714-bc47-d3dcc87ef423	13.61	5.30	2.60	195500	7.6	0	f
2026-05-28 05:45:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	b5263713-2026-5bad-ae46-296dc48a39d3	e37479d9-8791-5f72-983e-f1631d34edf7	14.34	4.40	2.85	202800	8.4	0	f
2026-05-28 05:46:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	62d38b4e-74e0-5f20-b66b-64efddec53b7	973ae836-e018-584f-b590-b84db7a3e86d	15.07	4.58	3.10	210100	9.2	0	f
2026-05-28 05:47:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	4957a3f4-17ce-5354-ab80-86d2329fbab1	8.50	4.76	2.10	217400	6.0	1	f
2026-05-28 05:48:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	2cb0627e-c84e-5709-b4f6-339bc1b14911	9.23	4.94	2.35	224700	6.8	0	f
2026-05-28 05:49:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	df87133b-ee35-5f6c-982e-0b9e09ad3dea	6e5b5686-d333-5982-b41f-eee032b8d6a0	9.96	5.12	2.60	232000	7.6	0	f
2026-05-28 05:50:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	afe8a03e-b5f2-5013-9b65-26fc935d703f	e5e51dcf-b0ac-5052-a719-8fa19c11da8a	10.69	5.30	2.85	239300	8.4	0	f
2026-05-28 05:51:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	1fc67a37-6696-5dae-aaf9-f610ba5273ae	11.42	4.40	3.10	91600	9.2	0	f
2026-05-28 05:52:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	12.15	4.58	2.10	98900	6.0	0	f
2026-05-28 05:53:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	1a1a57d7-fc16-5715-8133-35c906e0453a	d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	12.88	4.76	2.35	106200	6.8	0	f
2026-05-28 05:54:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	4c13e989-899c-5d47-8988-380802d72f58	52348272-8285-559f-b6f3-914b8c57c752	13.61	4.94	2.60	113500	7.6	0	f
2026-05-28 05:55:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	784ed9c6-39d3-5da9-b379-311aca240fdd	1bf518e1-cac0-50e8-bde7-8c23f8bb2592	14.34	5.12	2.85	120800	8.4	0	f
2026-05-28 05:56:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	46e29b13-6344-5b6d-8471-0891456bd85b	53bd7e52-86a1-540a-b190-b1ab73510f55	15.07	5.30	3.10	380000	9.2	0	t
2026-05-28 05:57:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	20cb75da-56ec-50b5-85f8-792b0d74f745	045d48f7-3f12-5b84-9edb-98b48ee7bb52	8.50	4.40	2.10	135400	6.0	0	f
2026-05-28 05:58:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	1c069679-3e6d-5b3e-8842-c27c074da0a0	13b587b3-9c90-5f7f-b9e8-14c17384a931	9.23	4.58	2.35	142700	6.8	0	f
2026-05-28 05:59:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	fae53a98-6313-583b-8c58-8e81fe950f6e	b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	9.96	4.76	2.60	150000	7.6	0	f
2026-05-28 06:00:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	eeded079-9abf-5844-8559-6eea890a6fe4	08df51d3-489b-53f0-9c61-446192882a27	10.69	4.94	2.85	157300	8.4	0	f
2026-05-28 06:01:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	674f97b3-f5f9-5ead-bf6c-d743870ba36f	fd976089-b688-5bff-af9f-a7dfdea216b1	11.42	5.12	3.10	164600	9.2	0	f
2026-05-28 06:02:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	86401639-58ea-5592-a23e-9c065fc3231f	12.15	5.30	2.10	171900	6.0	0	f
2026-05-28 06:03:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	3f9aca1c-2859-5e86-909b-fe2777f960ca	bcf02693-ed10-51c4-b023-232f6567db1d	12.88	4.40	2.35	179200	6.8	0	f
2026-05-28 06:04:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	f5a39406-3e7d-544f-b975-45d8feebf05f	13.61	4.58	2.60	186500	7.6	1	f
2026-05-28 06:05:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	ac52e314-03fc-5fc7-95c8-e51551ffca78	23687f00-e66b-5be8-ab3f-1ccd578256b7	14.34	4.76	2.85	193800	8.4	0	f
2026-05-28 06:06:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	86e49eb4-d6ad-5da6-bab7-32f91119a92a	15.07	4.94	3.10	201100	9.2	0	f
2026-05-27 05:31:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d58fbf17-442e-5153-8cdf-ce264a40ef4f	e8407929-25da-5561-a7c3-4541dc93ff50	12.15	5.30	2.10	101700	6.0	0	f
2026-05-27 05:32:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	c7ee8997-4bfb-56ca-9a3f-653af2d06595	a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	12.88	4.40	2.35	109000	6.8	0	f
2026-05-27 05:33:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	0d506129-b7c5-507a-88ca-242344baa5de	7621f1a7-be7b-56cd-b317-f0d3671da100	13.61	4.58	2.60	116300	7.6	0	f
2026-05-27 05:34:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	73956a35-c183-5c88-9b6e-827903fe0241	064ec719-795a-5ee5-a483-47f76d391cc8	14.34	4.76	2.85	123600	8.4	0	f
2026-05-27 05:35:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e287b4b8-1876-527c-8b7c-7fdf85c42709	7af07ef1-8064-57dd-aa41-6b4c1f917ff1	15.07	4.94	3.10	130900	9.2	0	f
2026-05-27 05:36:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	6fd17ce8-0480-58ea-a914-ee3cefea419d	8.50	5.12	2.10	138200	6.0	0	f
2026-05-27 05:37:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	0a5e4eef-d763-54ac-9552-9e72b62fc99f	9.23	5.30	2.35	145500	6.8	0	f
2026-05-27 05:38:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	3c97c346-b54c-5581-930e-f3264d6773ea	77b47f12-8ea8-50c8-8dd5-bfbda06db861	9.96	4.40	2.60	152800	7.6	0	f
2026-05-27 05:39:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	936b78c4-7b89-5fcf-97f7-54f007674e36	d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	10.69	4.58	2.85	160100	8.4	0	f
2026-05-27 05:40:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	cf17702f-f18b-553e-9294-67e671e66022	b060ba81-8cd5-5ece-bb06-4459d9d6c192	11.42	4.76	3.10	167400	9.2	0	f
2026-05-27 05:41:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	2ead6940-aa75-5701-a348-929b57d0fc24	12.15	4.94	2.10	174700	6.0	0	f
2026-05-27 05:42:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	12.88	5.12	2.35	182000	6.8	0	f
2026-05-27 05:43:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d172a069-591a-55e4-89fc-32699f1d25c9	36f1d931-0240-57a8-ad21-0eed820caf7d	13.61	5.30	2.60	380000	7.6	0	t
2026-05-27 05:44:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	436a7ff2-5df5-51b1-a49f-179831808d47	68a503e7-22a8-5714-bc47-d3dcc87ef423	14.34	4.40	2.85	196600	8.4	0	f
2026-05-27 05:45:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	b5263713-2026-5bad-ae46-296dc48a39d3	e37479d9-8791-5f72-983e-f1631d34edf7	15.07	4.58	3.10	203900	9.2	0	f
2026-05-27 05:46:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	62d38b4e-74e0-5f20-b66b-64efddec53b7	973ae836-e018-584f-b590-b84db7a3e86d	8.50	4.76	2.10	211200	6.0	0	f
2026-05-27 05:47:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	4957a3f4-17ce-5354-ab80-86d2329fbab1	9.23	4.94	2.35	218500	6.8	1	f
2026-05-27 05:48:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	2cb0627e-c84e-5709-b4f6-339bc1b14911	9.96	5.12	2.60	225800	7.6	0	f
2026-05-27 05:49:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	df87133b-ee35-5f6c-982e-0b9e09ad3dea	6e5b5686-d333-5982-b41f-eee032b8d6a0	10.69	5.30	2.85	233100	8.4	0	f
2026-05-27 05:50:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	afe8a03e-b5f2-5013-9b65-26fc935d703f	e5e51dcf-b0ac-5052-a719-8fa19c11da8a	11.42	4.40	3.10	240400	9.2	0	f
2026-05-27 05:51:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	1fc67a37-6696-5dae-aaf9-f610ba5273ae	12.15	4.58	2.10	92700	6.0	0	f
2026-05-27 05:52:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	12.88	4.76	2.35	100000	6.8	0	f
2026-05-27 05:53:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	1a1a57d7-fc16-5715-8133-35c906e0453a	d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	13.61	4.94	2.60	107300	7.6	0	f
2026-05-27 05:54:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	4c13e989-899c-5d47-8988-380802d72f58	52348272-8285-559f-b6f3-914b8c57c752	14.34	5.12	2.85	114600	8.4	0	f
2026-05-27 05:55:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	784ed9c6-39d3-5da9-b379-311aca240fdd	1bf518e1-cac0-50e8-bde7-8c23f8bb2592	15.07	5.30	3.10	121900	9.2	0	f
2026-05-27 05:56:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	46e29b13-6344-5b6d-8471-0891456bd85b	53bd7e52-86a1-540a-b190-b1ab73510f55	8.50	4.40	2.10	380000	6.0	0	t
2026-05-27 05:57:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	20cb75da-56ec-50b5-85f8-792b0d74f745	045d48f7-3f12-5b84-9edb-98b48ee7bb52	9.23	4.58	2.35	136500	6.8	0	f
2026-05-27 05:58:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	1c069679-3e6d-5b3e-8842-c27c074da0a0	13b587b3-9c90-5f7f-b9e8-14c17384a931	9.96	4.76	2.60	143800	7.6	0	f
2026-05-27 05:59:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	fae53a98-6313-583b-8c58-8e81fe950f6e	b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	10.69	4.94	2.85	151100	8.4	0	f
2026-05-27 06:00:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	eeded079-9abf-5844-8559-6eea890a6fe4	08df51d3-489b-53f0-9c61-446192882a27	11.42	5.12	3.10	158400	9.2	0	f
2026-05-27 06:01:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	674f97b3-f5f9-5ead-bf6c-d743870ba36f	fd976089-b688-5bff-af9f-a7dfdea216b1	12.15	5.30	2.10	165700	6.0	0	f
2026-05-27 06:02:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	86401639-58ea-5592-a23e-9c065fc3231f	12.88	4.40	2.35	173000	6.8	0	f
2026-05-27 06:03:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	3f9aca1c-2859-5e86-909b-fe2777f960ca	bcf02693-ed10-51c4-b023-232f6567db1d	13.61	4.58	2.60	180300	7.6	0	f
2026-05-27 06:04:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	f5a39406-3e7d-544f-b975-45d8feebf05f	14.34	4.76	2.85	187600	8.4	1	f
2026-05-27 06:05:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	ac52e314-03fc-5fc7-95c8-e51551ffca78	23687f00-e66b-5be8-ab3f-1ccd578256b7	15.07	4.94	3.10	194900	9.2	0	f
2026-05-27 06:06:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	86e49eb4-d6ad-5da6-bab7-32f91119a92a	8.50	5.12	2.10	202200	6.0	0	f
2026-05-26 05:31:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d58fbf17-442e-5153-8cdf-ce264a40ef4f	e8407929-25da-5561-a7c3-4541dc93ff50	12.88	4.40	2.35	102800	6.8	0	f
2026-05-26 05:32:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	c7ee8997-4bfb-56ca-9a3f-653af2d06595	a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	13.61	4.58	2.60	110100	7.6	0	f
2026-05-26 05:33:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	0d506129-b7c5-507a-88ca-242344baa5de	7621f1a7-be7b-56cd-b317-f0d3671da100	14.34	4.76	2.85	117400	8.4	0	f
2026-05-26 05:34:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	73956a35-c183-5c88-9b6e-827903fe0241	064ec719-795a-5ee5-a483-47f76d391cc8	15.07	4.94	3.10	124700	9.2	0	f
2026-05-26 05:35:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e287b4b8-1876-527c-8b7c-7fdf85c42709	7af07ef1-8064-57dd-aa41-6b4c1f917ff1	8.50	5.12	2.10	132000	6.0	0	f
2026-05-26 05:36:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	6fd17ce8-0480-58ea-a914-ee3cefea419d	9.23	5.30	2.35	139300	6.8	0	f
2026-05-26 05:37:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	0a5e4eef-d763-54ac-9552-9e72b62fc99f	9.96	4.40	2.60	146600	7.6	0	f
2026-05-26 05:38:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	3c97c346-b54c-5581-930e-f3264d6773ea	77b47f12-8ea8-50c8-8dd5-bfbda06db861	10.69	4.58	2.85	153900	8.4	0	f
2026-05-26 05:39:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	936b78c4-7b89-5fcf-97f7-54f007674e36	d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	11.42	4.76	3.10	161200	9.2	0	f
2026-05-26 05:40:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	cf17702f-f18b-553e-9294-67e671e66022	b060ba81-8cd5-5ece-bb06-4459d9d6c192	12.15	4.94	2.10	168500	6.0	0	f
2026-05-26 05:41:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	2ead6940-aa75-5701-a348-929b57d0fc24	12.88	5.12	2.35	175800	6.8	0	f
2026-05-26 05:42:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	13.61	5.30	2.60	183100	7.6	0	f
2026-05-26 05:43:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d172a069-591a-55e4-89fc-32699f1d25c9	36f1d931-0240-57a8-ad21-0eed820caf7d	14.34	4.40	2.85	380000	8.4	0	t
2026-05-26 05:44:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	436a7ff2-5df5-51b1-a49f-179831808d47	68a503e7-22a8-5714-bc47-d3dcc87ef423	15.07	4.58	3.10	197700	9.2	0	f
2026-05-26 05:45:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	b5263713-2026-5bad-ae46-296dc48a39d3	e37479d9-8791-5f72-983e-f1631d34edf7	8.50	4.76	2.10	205000	6.0	0	f
2026-05-26 05:46:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	62d38b4e-74e0-5f20-b66b-64efddec53b7	973ae836-e018-584f-b590-b84db7a3e86d	9.23	4.94	2.35	212300	6.8	0	f
2026-05-26 05:47:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	4957a3f4-17ce-5354-ab80-86d2329fbab1	9.96	5.12	2.60	219600	7.6	1	f
2026-05-26 05:48:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	2cb0627e-c84e-5709-b4f6-339bc1b14911	10.69	5.30	2.85	226900	8.4	0	f
2026-05-26 05:49:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	df87133b-ee35-5f6c-982e-0b9e09ad3dea	6e5b5686-d333-5982-b41f-eee032b8d6a0	11.42	4.40	3.10	234200	9.2	0	f
2026-05-26 05:50:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	afe8a03e-b5f2-5013-9b65-26fc935d703f	e5e51dcf-b0ac-5052-a719-8fa19c11da8a	12.15	4.58	2.10	241500	6.0	0	f
2026-05-26 05:51:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	1fc67a37-6696-5dae-aaf9-f610ba5273ae	12.88	4.76	2.35	93800	6.8	0	f
2026-05-26 05:52:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	13.61	4.94	2.60	101100	7.6	0	f
2026-05-26 05:53:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	1a1a57d7-fc16-5715-8133-35c906e0453a	d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	14.34	5.12	2.85	108400	8.4	0	f
2026-05-26 05:54:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	4c13e989-899c-5d47-8988-380802d72f58	52348272-8285-559f-b6f3-914b8c57c752	15.07	5.30	3.10	115700	9.2	0	f
2026-05-26 05:55:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	784ed9c6-39d3-5da9-b379-311aca240fdd	1bf518e1-cac0-50e8-bde7-8c23f8bb2592	8.50	4.40	2.10	123000	6.0	0	f
2026-05-26 05:56:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	46e29b13-6344-5b6d-8471-0891456bd85b	53bd7e52-86a1-540a-b190-b1ab73510f55	9.23	4.58	2.35	380000	6.8	0	t
2026-05-26 05:57:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	20cb75da-56ec-50b5-85f8-792b0d74f745	045d48f7-3f12-5b84-9edb-98b48ee7bb52	9.96	4.76	2.60	137600	7.6	0	f
2026-05-26 05:58:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	1c069679-3e6d-5b3e-8842-c27c074da0a0	13b587b3-9c90-5f7f-b9e8-14c17384a931	10.69	4.94	2.85	144900	8.4	0	f
2026-05-26 05:59:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	fae53a98-6313-583b-8c58-8e81fe950f6e	b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	11.42	5.12	3.10	152200	9.2	0	f
2026-05-26 06:00:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	eeded079-9abf-5844-8559-6eea890a6fe4	08df51d3-489b-53f0-9c61-446192882a27	12.15	5.30	2.10	159500	6.0	0	f
2026-05-26 06:01:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	674f97b3-f5f9-5ead-bf6c-d743870ba36f	fd976089-b688-5bff-af9f-a7dfdea216b1	12.88	4.40	2.35	166800	6.8	0	f
2026-05-26 06:02:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	86401639-58ea-5592-a23e-9c065fc3231f	13.61	4.58	2.60	174100	7.6	0	f
2026-05-26 06:03:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	3f9aca1c-2859-5e86-909b-fe2777f960ca	bcf02693-ed10-51c4-b023-232f6567db1d	14.34	4.76	2.85	181400	8.4	0	f
2026-05-26 06:04:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	f5a39406-3e7d-544f-b975-45d8feebf05f	15.07	4.94	3.10	188700	9.2	1	f
2026-05-26 06:05:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	ac52e314-03fc-5fc7-95c8-e51551ffca78	23687f00-e66b-5be8-ab3f-1ccd578256b7	8.50	5.12	2.10	196000	6.0	0	f
2026-05-26 06:06:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	86e49eb4-d6ad-5da6-bab7-32f91119a92a	9.23	5.30	2.35	203300	6.8	0	f
2026-05-25 05:31:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d58fbf17-442e-5153-8cdf-ce264a40ef4f	e8407929-25da-5561-a7c3-4541dc93ff50	13.61	4.58	2.60	103900	7.6	0	f
2026-05-25 05:32:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	c7ee8997-4bfb-56ca-9a3f-653af2d06595	a56e01e0-50bc-5dc3-aa1d-e09c0f21a9d6	14.34	4.76	2.85	111200	8.4	0	f
2026-05-25 05:33:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	0d506129-b7c5-507a-88ca-242344baa5de	7621f1a7-be7b-56cd-b317-f0d3671da100	15.07	4.94	3.10	118500	9.2	0	f
2026-05-25 05:34:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	73956a35-c183-5c88-9b6e-827903fe0241	064ec719-795a-5ee5-a483-47f76d391cc8	8.50	5.12	2.10	125800	6.0	0	f
2026-05-25 05:35:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e287b4b8-1876-527c-8b7c-7fdf85c42709	7af07ef1-8064-57dd-aa41-6b4c1f917ff1	9.23	5.30	2.35	133100	6.8	0	f
2026-05-25 05:36:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	6fd17ce8-0480-58ea-a914-ee3cefea419d	9.96	4.40	2.60	140400	7.6	0	f
2026-05-25 05:37:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	0a5e4eef-d763-54ac-9552-9e72b62fc99f	10.69	4.58	2.85	147700	8.4	0	f
2026-05-25 05:38:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	3c97c346-b54c-5581-930e-f3264d6773ea	77b47f12-8ea8-50c8-8dd5-bfbda06db861	11.42	4.76	3.10	155000	9.2	0	f
2026-05-25 05:39:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	936b78c4-7b89-5fcf-97f7-54f007674e36	d6fc7697-1ba3-5d64-9ce2-7424b4bbb666	12.15	4.94	2.10	162300	6.0	0	f
2026-05-25 05:40:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	cf17702f-f18b-553e-9294-67e671e66022	b060ba81-8cd5-5ece-bb06-4459d9d6c192	12.88	5.12	2.35	169600	6.8	0	f
2026-05-25 05:41:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	2ead6940-aa75-5701-a348-929b57d0fc24	13.61	5.30	2.60	176900	7.6	0	f
2026-05-25 05:42:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	a63c9331-12b0-54d7-ab6f-8d8ce6fb9bf8	14.34	4.40	2.85	184200	8.4	0	f
2026-05-25 05:43:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	d172a069-591a-55e4-89fc-32699f1d25c9	36f1d931-0240-57a8-ad21-0eed820caf7d	15.07	4.58	3.10	380000	9.2	0	t
2026-05-25 05:44:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	436a7ff2-5df5-51b1-a49f-179831808d47	68a503e7-22a8-5714-bc47-d3dcc87ef423	8.50	4.76	2.10	198800	6.0	0	f
2026-05-25 05:45:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	b5263713-2026-5bad-ae46-296dc48a39d3	e37479d9-8791-5f72-983e-f1631d34edf7	9.23	4.94	2.35	206100	6.8	0	f
2026-05-25 05:46:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	62d38b4e-74e0-5f20-b66b-64efddec53b7	973ae836-e018-584f-b590-b84db7a3e86d	9.96	5.12	2.60	213400	7.6	0	f
2026-05-25 05:47:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	4957a3f4-17ce-5354-ab80-86d2329fbab1	10.69	5.30	2.85	220700	8.4	1	f
2026-05-25 05:48:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	2cb0627e-c84e-5709-b4f6-339bc1b14911	11.42	4.40	3.10	228000	9.2	0	f
2026-05-25 05:49:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	df87133b-ee35-5f6c-982e-0b9e09ad3dea	6e5b5686-d333-5982-b41f-eee032b8d6a0	12.15	4.58	2.10	235300	6.0	0	f
2026-05-25 05:50:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	afe8a03e-b5f2-5013-9b65-26fc935d703f	e5e51dcf-b0ac-5052-a719-8fa19c11da8a	12.88	4.76	2.35	242600	6.8	0	f
2026-05-25 05:51:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	e8761f6b-9037-5d8f-bca2-cd8caa3ab0af	1fc67a37-6696-5dae-aaf9-f610ba5273ae	13.61	4.94	2.60	94900	7.6	0	f
2026-05-25 05:52:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	5d712a13-ba73-5fb4-b4f1-1d2b15f2c988	d9109af4-5d3a-522c-a56e-7d7fc4d81bc0	14.34	5.12	2.85	102200	8.4	0	f
2026-05-25 05:53:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	1a1a57d7-fc16-5715-8133-35c906e0453a	d1a8d138-1fbf-5957-9b46-0c4f5a0934e2	15.07	5.30	3.10	109500	9.2	0	f
2026-05-25 05:54:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	4c13e989-899c-5d47-8988-380802d72f58	52348272-8285-559f-b6f3-914b8c57c752	8.50	4.40	2.10	116800	6.0	0	f
2026-05-25 05:55:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	784ed9c6-39d3-5da9-b379-311aca240fdd	1bf518e1-cac0-50e8-bde7-8c23f8bb2592	9.23	4.58	2.35	124100	6.8	0	f
2026-05-25 05:56:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	46e29b13-6344-5b6d-8471-0891456bd85b	53bd7e52-86a1-540a-b190-b1ab73510f55	9.96	4.76	2.60	380000	7.6	0	t
2026-05-25 05:57:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	20cb75da-56ec-50b5-85f8-792b0d74f745	045d48f7-3f12-5b84-9edb-98b48ee7bb52	10.69	4.94	2.85	138700	8.4	0	f
2026-05-25 05:58:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	1c069679-3e6d-5b3e-8842-c27c074da0a0	13b587b3-9c90-5f7f-b9e8-14c17384a931	11.42	5.12	3.10	146000	9.2	0	f
2026-05-25 05:59:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	fae53a98-6313-583b-8c58-8e81fe950f6e	b0ddf0c1-df89-5ba6-ab3a-0903554f5a09	12.15	5.30	2.10	153300	6.0	0	f
2026-05-25 06:00:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	eeded079-9abf-5844-8559-6eea890a6fe4	08df51d3-489b-53f0-9c61-446192882a27	12.88	4.40	2.35	160600	6.8	0	f
2026-05-25 06:01:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	674f97b3-f5f9-5ead-bf6c-d743870ba36f	fd976089-b688-5bff-af9f-a7dfdea216b1	13.61	4.58	2.60	167900	7.6	0	f
2026-05-25 06:02:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	0f5350db-fd30-58b4-bf08-ae0b3ca94afd	86401639-58ea-5592-a23e-9c065fc3231f	14.34	4.76	2.85	175200	8.4	0	f
2026-05-25 06:03:00+00	2def9ef9-5ce4-4588-996a-9d149b8888b1	3f9aca1c-2859-5e86-909b-fe2777f960ca	bcf02693-ed10-51c4-b023-232f6567db1d	15.07	4.94	3.10	182500	9.2	0	f
2026-05-25 06:04:00+00	ecd8c871-5c03-4f1b-8797-e60499747b96	9baa72c1-9b94-594b-8926-8a3c17ee9ac7	f5a39406-3e7d-544f-b975-45d8feebf05f	8.50	5.12	2.10	189800	6.0	1	f
2026-05-25 06:05:00+00	0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	ac52e314-03fc-5fc7-95c8-e51551ffca78	23687f00-e66b-5be8-ab3f-1ccd578256b7	9.23	5.30	2.35	197100	6.8	0	f
2026-05-25 06:06:00+00	50bfdd77-8aa3-446d-a0f4-05f3453f8536	bb9fc07f-076f-5182-93d0-8eb2ece1ee89	86e49eb4-d6ad-5da6-bab7-32f91119a92a	9.96	4.40	2.60	204400	7.6	0	f
\.


--
-- Data for Name: maquinaria; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maquinaria (id, nombre, tipo, zona_id, marca, modelo, numero_serie, fecha_instalacion, activa, estado, notas) FROM stdin;
1479ad4d-f17a-40bd-8606-590ddb2fa868	Carro TMR	carro_mezclador	1819261f-9823-5373-a0dc-533638edb05e	Trioliet	Solomix 2	TMR-01	\N	t	operativa	\N
1334d1ae-1804-491e-a777-63439f7e9468	Amamantadora	amamantadora	584383a2-21ba-537b-af9b-90d8b722821b	Förster	HL 102	AMA-01	\N	t	revision_pendiente	\N
d9c29718-27eb-55a8-99d3-6f55765d7e34	Arrimador automatico	otro	1819261f-9823-5373-a0dc-533638edb05e	Lely	Juno	ARR-JUNO-01	2024-06-30	t	revision_pendiente	Revisar bateria y ruta nocturna.
2a645371-8dcf-5741-9cba-4503270ee2ef	Tractor alimentacion	otro	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	John Deere	6120M	TR-6120M-01	2020-05-22	t	operativa	Uso principal para forraje y cama.
50bfdd77-8aa3-446d-a0f4-05f3453f8536	VMS 1	robot_ordeno	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	DeLaval	VMS V300	VMS-VMS-1	\N	t	operativa	\N
2def9ef9-5ce4-4588-996a-9d149b8888b1	VMS 2	robot_ordeno	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	DeLaval	VMS V300	VMS-VMS-2	\N	t	operativa	\N
ecd8c871-5c03-4f1b-8797-e60499747b96	VMS 3	robot_ordeno	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	DeLaval	VMS V300	VMS-VMS-3	\N	t	operativa	\N
0867ce4d-aeab-5ed8-9cc4-7cf164af60f3	VMS 4	robot_ordeno	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	DeLaval	VMS V300	VMS-4	2023-12-13	t	mantenimiento	Revision de brazo programada y calibracion pendiente.
cca2e231-9ce5-5e6a-a9f2-63c43db556f4	Bomba de vacio principal	bomba	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	DeLaval	DVP 2600	BVP-2600-01	2021-06-26	t	averia	Perdida intermitente de vacio en picos de demanda.
74cf333b-4aba-5db6-bce2-1e13e1439bc2	Tanque de leche 18000 L	otro	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	GEA	CoolPro 18000	TNK-18K-01	2022-04-22	t	operativa	Temperatura estable en ultimas lecturas.
95ccf014-f4ea-5888-a3d7-cba4804370b8	Sistema de ventilacion nave	otro	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	Fancom	Dairy Air	VENT-01	2023-09-24	t	operativa	Modo automatico por temperatura y humedad.
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pedidos (id, insumo, descripcion, cantidad, unidad, estado, solicitante_id, ts_solicitud, ts_aprobacion, ts_recepcion, proveedor, coste_estimado, coste_real, notas) FROM stdin;
d55d41eb-e505-59ef-8c58-5a53d0d0e26d	Detergente alcalino clorado	Limpieza CIP de robots y tanque.	8.00	garrafas	solicitado	efbe203d-853b-56dc-a3a2-e2839e844083	2026-05-30 19:54:56.952826+00	\N	\N	Higiene Ganadera Norte	312.00	\N	Stock por debajo de minimo semanal.
3f8dfeb0-6221-534c-9b93-49f5f6a433d3	Pezoneras VMS	Reposicion por horas de uso.	32.00	unidades	aprobado	f2b0bd7e-4171-5347-8179-fe6667ba7985	2026-05-28 19:54:56.952826+00	2026-05-29 19:54:56.952826+00	\N	DeLaval Servicio	480.00	\N	Cambiar primero robots 1 y 2.
7bcd772b-76dd-5270-9349-c4e2bc3d3ffd	Filtros de leche	Filtros compatibles con linea principal.	12.00	cajas	en_transito	3033a0ee-9ffe-5e7f-a7a2-76f309918749	2026-05-26 19:54:56.952826+00	2026-05-27 19:54:56.952826+00	\N	Lactosuministros SL	156.00	\N	Entrega parcial prevista.
b937cd3d-6ade-5ade-9a08-5378a4a608a7	Meloxicam 100 ml	Tratamientos de cojeras y postparto.	6.00	frascos	solicitado	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-29 19:54:56.952826+00	\N	\N	VetNoroeste	198.00	\N	Prioridad alta por stock minimo.
8a41525d-02db-55d1-8cbc-c82274294516	Cateteres y material veterinario	Material para tratamientos intramamarios.	4.00	kits	recibido	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-19 19:54:56.952826+00	2026-05-20 19:54:56.952826+00	2026-05-23 19:54:56.952826+00	VetNoroeste	92.00	89.50	Recibido completo.
45f0c3b2-36e7-501d-a759-72c28ea47ddd	Pienso iniciador terneros	Saco 25 kg recria.	40.00	sacos	aprobado	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	2026-05-30 19:54:56.952826+00	2026-05-31 13:54:56.952826+00	\N	NutriFeed Galicia	740.00	\N	Necesario para boxes de terneros.
f9d7e405-7731-5b25-95fd-26be04ede639	Leche maternizada	Reposicion para amamantadora.	20.00	sacos	en_transito	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	2026-05-27 19:54:56.952826+00	2026-05-28 19:54:56.952826+00	\N	NutriFeed Galicia	1180.00	\N	Revisar calibracion al recibir.
2f43fe4f-9e71-5fc2-b048-d23d48df4408	Kit juntas bomba de vacio	Repuesto para mantenimiento correctivo.	1.00	kit	solicitado	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-31 11:54:56.952826+00	\N	\N	AgroMantenimiento	265.00	\N	Relacionado con incidencia de vacio.
8c5066ac-1c24-598b-a1df-c3815d54991c	Etiquetas y toner oficina	Material administrativo para registros.	3.00	packs	recibido	efbe203d-853b-56dc-a3a2-e2839e844083	2026-05-15 19:54:56.952826+00	2026-05-16 19:54:56.952826+00	2026-05-18 19:54:56.952826+00	OfiNorte	74.00	71.20	Sin incidencias.
37954089-536e-52cd-8476-c27b55c4b40e	Guantes nitrilo	Uso en sala, enfermeria y recria.	20.00	cajas	aprobado	350c2228-7752-5756-bb3e-436f655d703b	2026-05-25 19:54:56.952826+00	2026-05-26 19:54:56.952826+00	\N	Higiene Ganadera Norte	210.00	\N	Consumo elevado en tratamientos activos.
e85735d6-6821-5dd5-a6c8-b058a9766044	Sellador pezones secado	Protocolo de vacas secas.	10.00	cajas	solicitado	aed8c2c4-9620-5034-9248-d8564ee7addf	2026-05-31 10:54:56.952826+00	\N	\N	VetNoroeste	340.00	\N	Prevision de secados de la semana.
722d1923-0a62-555a-bb40-767f9e37db22	Cuchillas carro mezclador	Mantenimiento de mezcla TMR.	2.00	juegos	cancelado	718c721d-90a7-536a-b47d-bb935fe583f3	2026-05-11 19:54:56.952826+00	2026-05-12 19:54:56.952826+00	\N	AgroMantenimiento	520.00	\N	Cancelado por referencia incorrecta.
\.


--
-- Data for Name: resumenes_relevo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.resumenes_relevo (id, turno_saliente_id, turno_entrante_id, ts_generacion, incidencias_abiertas, tareas_pendientes, alertas_pendientes, notas_saliente, confirmado_por, ts_confirmacion) FROM stdin;
3acf4b78-b827-5269-a549-f2c8a879b631	9bf70236-d678-5a3e-ad64-b4fa5b5e3901	dc17241e-e305-5169-87f6-b72de1a7e604	2026-05-31 17:54:18.555534+00	[{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "titulo": "Robot de ordeno con fallo temporal", "severidad": "alta"}, {"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "titulo": "Vaca con retraso de ordeno", "severidad": "media"}, {"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "titulo": "Elevacion de recuento celular", "severidad": "alta"}, {"id": "498fe423-512e-5a1d-93f7-5940ca889eea", "titulo": "Tratamiento pendiente de confirmar", "severidad": "media"}, {"id": "f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30", "titulo": "Bebedero con caudal bajo", "severidad": "media"}]	[{"id": "e20f3bea-6346-57dc-9e09-2b339adeda61", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}, {"id": "9d42ba3f-9254-58bd-be77-b0747638a0d0", "notas": "Revision de silos y cierre de lona.", "estado": "pendiente"}, {"id": "d6d422c1-4235-54e3-bbbc-c31e28734985", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "35221d42-c625-58f1-a043-4e75b5fec446", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "2bdf3026-ac39-5773-b525-ce66c894bab8", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}]	[{"id": "ce2dc9e1-1315-5285-b108-1c09d9ae7263", "nivel": "alta", "titulo": "Robot de ordeno con fallo temporal"}, {"id": "a78b8d0d-b538-5d5e-9e13-d8eb014e50d2", "nivel": "media", "titulo": "Vaca con retraso de ordeno"}, {"id": "dcf30175-431e-5f82-a66e-0be1dc3d1c7f", "nivel": "alta", "titulo": "Elevacion de recuento celular"}, {"id": "9bc20559-69a2-5054-a3ef-a593fd86a374", "nivel": "media", "titulo": "Tratamiento pendiente de confirmar"}, {"id": "f794f091-1f82-5f13-8c25-113d281e00f2", "nivel": "media", "titulo": "Bebedero con caudal bajo"}]	Pendiente vigilar incidencias de robots, tratamientos activos y tareas vencidas antes del cierre de jornada.	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	2026-05-31 18:54:18.555534+00
d73ce57f-b8ba-5eed-a0ae-178d6e4a0d1c	dc17241e-e305-5169-87f6-b72de1a7e604	9bf70236-d678-5a3e-ad64-b4fa5b5e3901	2026-05-31 17:54:18.555534+00	[{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "titulo": "Robot de ordeno con fallo temporal", "severidad": "alta"}, {"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "titulo": "Vaca con retraso de ordeno", "severidad": "media"}, {"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "titulo": "Elevacion de recuento celular", "severidad": "alta"}, {"id": "498fe423-512e-5a1d-93f7-5940ca889eea", "titulo": "Tratamiento pendiente de confirmar", "severidad": "media"}, {"id": "f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30", "titulo": "Bebedero con caudal bajo", "severidad": "media"}]	[{"id": "e20f3bea-6346-57dc-9e09-2b339adeda61", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}, {"id": "9d42ba3f-9254-58bd-be77-b0747638a0d0", "notas": "Revision de silos y cierre de lona.", "estado": "pendiente"}, {"id": "d6d422c1-4235-54e3-bbbc-c31e28734985", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "35221d42-c625-58f1-a043-4e75b5fec446", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "2bdf3026-ac39-5773-b525-ce66c894bab8", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}]	[{"id": "ce2dc9e1-1315-5285-b108-1c09d9ae7263", "nivel": "alta", "titulo": "Robot de ordeno con fallo temporal"}, {"id": "a78b8d0d-b538-5d5e-9e13-d8eb014e50d2", "nivel": "media", "titulo": "Vaca con retraso de ordeno"}, {"id": "dcf30175-431e-5f82-a66e-0be1dc3d1c7f", "nivel": "alta", "titulo": "Elevacion de recuento celular"}, {"id": "9bc20559-69a2-5054-a3ef-a593fd86a374", "nivel": "media", "titulo": "Tratamiento pendiente de confirmar"}, {"id": "f794f091-1f82-5f13-8c25-113d281e00f2", "nivel": "media", "titulo": "Bebedero con caudal bajo"}]	Pendiente vigilar incidencias de robots, tratamientos activos y tareas vencidas antes del cierre de jornada.	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	2026-05-31 18:54:18.555534+00
7111d2fc-d987-5664-bb51-ad84496b0aa5	c40a8fab-a392-5e5d-9fe6-eb47807c541f	637f3b98-4ed6-5d96-ad6f-166b49135040	2026-05-31 17:54:18.555534+00	[{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "titulo": "Robot de ordeno con fallo temporal", "severidad": "alta"}, {"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "titulo": "Vaca con retraso de ordeno", "severidad": "media"}, {"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "titulo": "Elevacion de recuento celular", "severidad": "alta"}, {"id": "498fe423-512e-5a1d-93f7-5940ca889eea", "titulo": "Tratamiento pendiente de confirmar", "severidad": "media"}, {"id": "f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30", "titulo": "Bebedero con caudal bajo", "severidad": "media"}]	[{"id": "e20f3bea-6346-57dc-9e09-2b339adeda61", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}, {"id": "9d42ba3f-9254-58bd-be77-b0747638a0d0", "notas": "Revision de silos y cierre de lona.", "estado": "pendiente"}, {"id": "d6d422c1-4235-54e3-bbbc-c31e28734985", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "35221d42-c625-58f1-a043-4e75b5fec446", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "2bdf3026-ac39-5773-b525-ce66c894bab8", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}]	[{"id": "ce2dc9e1-1315-5285-b108-1c09d9ae7263", "nivel": "alta", "titulo": "Robot de ordeno con fallo temporal"}, {"id": "a78b8d0d-b538-5d5e-9e13-d8eb014e50d2", "nivel": "media", "titulo": "Vaca con retraso de ordeno"}, {"id": "dcf30175-431e-5f82-a66e-0be1dc3d1c7f", "nivel": "alta", "titulo": "Elevacion de recuento celular"}, {"id": "9bc20559-69a2-5054-a3ef-a593fd86a374", "nivel": "media", "titulo": "Tratamiento pendiente de confirmar"}, {"id": "f794f091-1f82-5f13-8c25-113d281e00f2", "nivel": "media", "titulo": "Bebedero con caudal bajo"}]	Pendiente vigilar incidencias de robots, tratamientos activos y tareas vencidas antes del cierre de jornada.	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	\N
defc08c1-0c5e-5ffc-b6ef-39bac7fdc79f	637f3b98-4ed6-5d96-ad6f-166b49135040	c40a8fab-a392-5e5d-9fe6-eb47807c541f	2026-05-31 17:54:18.555534+00	[{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "titulo": "Robot de ordeno con fallo temporal", "severidad": "alta"}, {"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "titulo": "Vaca con retraso de ordeno", "severidad": "media"}, {"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "titulo": "Elevacion de recuento celular", "severidad": "alta"}, {"id": "498fe423-512e-5a1d-93f7-5940ca889eea", "titulo": "Tratamiento pendiente de confirmar", "severidad": "media"}, {"id": "f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30", "titulo": "Bebedero con caudal bajo", "severidad": "media"}]	[{"id": "e20f3bea-6346-57dc-9e09-2b339adeda61", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}, {"id": "9d42ba3f-9254-58bd-be77-b0747638a0d0", "notas": "Revision de silos y cierre de lona.", "estado": "pendiente"}, {"id": "d6d422c1-4235-54e3-bbbc-c31e28734985", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "35221d42-c625-58f1-a043-4e75b5fec446", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "2bdf3026-ac39-5773-b525-ce66c894bab8", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}]	[{"id": "ce2dc9e1-1315-5285-b108-1c09d9ae7263", "nivel": "alta", "titulo": "Robot de ordeno con fallo temporal"}, {"id": "a78b8d0d-b538-5d5e-9e13-d8eb014e50d2", "nivel": "media", "titulo": "Vaca con retraso de ordeno"}, {"id": "dcf30175-431e-5f82-a66e-0be1dc3d1c7f", "nivel": "alta", "titulo": "Elevacion de recuento celular"}, {"id": "9bc20559-69a2-5054-a3ef-a593fd86a374", "nivel": "media", "titulo": "Tratamiento pendiente de confirmar"}, {"id": "f794f091-1f82-5f13-8c25-113d281e00f2", "nivel": "media", "titulo": "Bebedero con caudal bajo"}]	Pendiente vigilar incidencias de robots, tratamientos activos y tareas vencidas antes del cierre de jornada.	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	\N
fafb137f-b295-58b5-8a0b-894205ee39f8	7d245751-1ad7-5677-af6d-bfb8c71d1734	806041d7-8f66-5a30-9763-951ec6951183	2026-05-31 17:54:18.555534+00	[{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "titulo": "Robot de ordeno con fallo temporal", "severidad": "alta"}, {"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "titulo": "Vaca con retraso de ordeno", "severidad": "media"}, {"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "titulo": "Elevacion de recuento celular", "severidad": "alta"}, {"id": "498fe423-512e-5a1d-93f7-5940ca889eea", "titulo": "Tratamiento pendiente de confirmar", "severidad": "media"}, {"id": "f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30", "titulo": "Bebedero con caudal bajo", "severidad": "media"}]	[{"id": "e20f3bea-6346-57dc-9e09-2b339adeda61", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}, {"id": "9d42ba3f-9254-58bd-be77-b0747638a0d0", "notas": "Revision de silos y cierre de lona.", "estado": "pendiente"}, {"id": "d6d422c1-4235-54e3-bbbc-c31e28734985", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "35221d42-c625-58f1-a043-4e75b5fec446", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "2bdf3026-ac39-5773-b525-ce66c894bab8", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}]	[{"id": "ce2dc9e1-1315-5285-b108-1c09d9ae7263", "nivel": "alta", "titulo": "Robot de ordeno con fallo temporal"}, {"id": "a78b8d0d-b538-5d5e-9e13-d8eb014e50d2", "nivel": "media", "titulo": "Vaca con retraso de ordeno"}, {"id": "dcf30175-431e-5f82-a66e-0be1dc3d1c7f", "nivel": "alta", "titulo": "Elevacion de recuento celular"}, {"id": "9bc20559-69a2-5054-a3ef-a593fd86a374", "nivel": "media", "titulo": "Tratamiento pendiente de confirmar"}, {"id": "f794f091-1f82-5f13-8c25-113d281e00f2", "nivel": "media", "titulo": "Bebedero con caudal bajo"}]	Pendiente vigilar incidencias de robots, tratamientos activos y tareas vencidas antes del cierre de jornada.	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	\N
e15845c8-33e6-570c-a3e8-da47ea2939d6	806041d7-8f66-5a30-9763-951ec6951183	7d245751-1ad7-5677-af6d-bfb8c71d1734	2026-05-31 17:54:18.555534+00	[{"id": "153da52a-b5d2-53db-8b2c-1292e1e1fd3b", "titulo": "Robot de ordeno con fallo temporal", "severidad": "alta"}, {"id": "c1c5f567-6153-5fb1-ab56-a2c15f9a99c7", "titulo": "Vaca con retraso de ordeno", "severidad": "media"}, {"id": "196957e3-30e1-50a9-b8c6-5324e8625627", "titulo": "Elevacion de recuento celular", "severidad": "alta"}, {"id": "498fe423-512e-5a1d-93f7-5940ca889eea", "titulo": "Tratamiento pendiente de confirmar", "severidad": "media"}, {"id": "f5ded69d-a8cc-5117-bcaf-1cf1cc6f8c30", "titulo": "Bebedero con caudal bajo", "severidad": "media"}]	[{"id": "e20f3bea-6346-57dc-9e09-2b339adeda61", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}, {"id": "9d42ba3f-9254-58bd-be77-b0747638a0d0", "notas": "Revision de silos y cierre de lona.", "estado": "pendiente"}, {"id": "d6d422c1-4235-54e3-bbbc-c31e28734985", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "35221d42-c625-58f1-a043-4e75b5fec446", "notas": "Limpieza de robots completada sin alarmas.", "estado": "pendiente"}, {"id": "2bdf3026-ac39-5773-b525-ce66c894bab8", "notas": "Preparar racion de tarde con control de desviacion.", "estado": "vencida"}]	[{"id": "ce2dc9e1-1315-5285-b108-1c09d9ae7263", "nivel": "alta", "titulo": "Robot de ordeno con fallo temporal"}, {"id": "a78b8d0d-b538-5d5e-9e13-d8eb014e50d2", "nivel": "media", "titulo": "Vaca con retraso de ordeno"}, {"id": "dcf30175-431e-5f82-a66e-0be1dc3d1c7f", "nivel": "alta", "titulo": "Elevacion de recuento celular"}, {"id": "9bc20559-69a2-5054-a3ef-a593fd86a374", "nivel": "media", "titulo": "Tratamiento pendiente de confirmar"}, {"id": "f794f091-1f82-5f13-8c25-113d281e00f2", "nivel": "media", "titulo": "Bebedero con caudal bajo"}]	Pendiente vigilar incidencias de robots, tratamientos activos y tareas vencidas antes del cierre de jornada.	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	\N
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schema_migrations (version, applied_at) FROM stdin;
0000_users.sql	2026-05-31 19:22:33.738185
0001_core_frontend.sql	2026-05-31 19:22:33.738185
0002_user_roles.sql	2026-05-31 19:22:33.738185
0003_machinery_estado.sql	2026-05-31 19:22:33.738185
0004_tareas_empleado_id.sql	2026-06-01 05:48:48.607432
0005_empleados_zona_principal.sql	2026-06-01 05:48:48.607432
0006_animals_quality_fields.sql	2026-06-01 07:45:41.968341
0002b_baseline_tools4milk.sql	2026-06-02 22:06:55.785074
0007_meteo_prob_precipitacion.sql	2026-06-02 22:06:55.785074
\.


--
-- Data for Name: tareas_catalogo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tareas_catalogo (id, codigo, nombre, descripcion, cualificacion_requerida, duracion_estimada_min, activa) FROM stdin;
b41521f2-44cd-44bc-b7f7-e0e419547009	lavado_robot	Lavado de robot de ordeño	\N	VMS	45	t
08e3b526-81b3-4f00-a4d6-a10dc3789ea0	desinfeccion_camas	Desinfección de camas	\N	\N	60	t
ffd7fe81-7a8c-4379-b351-755e7d09474e	limpieza_bebederos	Limpieza de bebederos	\N	\N	30	t
124d471a-18f5-42f2-9abd-2c00be35398a	preparacion_racion	Preparación ración unifeed (TMR)	\N	TMR	40	t
f1f54927-7db0-4b7d-b849-bbf4028dee33	revision_terneros	Revisión diaria terneros	\N	\N	30	t
749c3577-3ec2-4829-9112-1e11300fdcb4	control_tratamientos	Control y administración tratamientos	\N	veterinaria	20	t
ce0af70a-5965-487f-9644-3682a4650712	recogida_muestras	Recogida muestras de leche	\N	\N	15	t
33d0a035-e85f-5da6-8926-ec18f6c2cbb9	revision_silos	Revision de silos y frente de forraje	Comprobar frente, lona y posibles entradas de agua.	TMR	25	t
755b7735-e9dc-5a61-b10a-289f4c2bdcc8	revision_pezoneras	Revision de pezoneras y colectores	Comprobar desgaste, vacio y limpieza visual.	VMS	35	t
305a27d5-7f53-572d-a92c-b84e72cc3a8b	revision_maquinaria	Revision diaria de maquinaria critica	Comprobar alarmas, engrase y estado general.	mantenimiento	45	t
faa9ed87-a868-586a-a9ae-4cd973b4cfa0	control_stock	Control de stock de almacen	Revisar detergentes, filtros, medicamentos y repuestos.	\N	30	t
75ff20dd-caf5-4af5-a599-65efd704a986	TASK-E8797BC2	Validacion LeanFarming	Descripcion actualizada	\N	60	f
\.


--
-- Data for Name: tareas_ejecuciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tareas_ejecuciones (id, catalogo_id, recurrente_id, empleado_id, zona_id, maquinaria_id, estado, ts_planificada, ts_inicio, ts_fin, notas, creado_en) FROM stdin;
346325a0-54a4-5245-8f60-345e8e9f843b	124d471a-18f5-42f2-9abd-2c00be35398a	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	pendiente	2026-05-30 21:54:18.555534+00	\N	\N	Limpieza de robots completada sin alarmas.	2026-05-25 19:54:18.555534+00
40506064-f18e-4bdb-a2f3-9f3ce5da48eb	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-01 07:00:00+00	\N	\N	\N	2026-06-01 10:15:58.486101+00
6c51884d-e939-4cb3-bfd2-463b39a55e13	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-01 09:00:00+00	\N	\N	\N	2026-06-01 10:15:58.586296+00
adb4fd88-fc0c-45de-a524-1dce3e4eb1d1	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-01 17:00:00+00	\N	\N	\N	2026-06-01 10:15:58.656613+00
5702a582-3e56-4f62-a5b7-0af7dcd01994	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-01 08:00:00+00	\N	\N	\N	2026-06-01 10:15:58.740979+00
93fd21d7-84cf-459f-9808-81b6940b6131	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-01 18:00:00+00	\N	\N	\N	2026-06-01 10:15:58.820634+00
672f140e-28f3-495a-8674-9baf962dd4eb	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-02 07:00:00+00	\N	\N	\N	2026-06-01 10:15:59.00489+00
478057a6-a502-4932-ab1e-bf96902edd19	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-02 09:00:00+00	\N	\N	\N	2026-06-01 10:15:59.084089+00
c6dbec99-b303-4ca9-9322-0a78145831af	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-02 17:00:00+00	\N	\N	\N	2026-06-01 10:15:59.161611+00
228642a9-7ddb-4ed7-a24c-47d9393bf9d8	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-02 08:00:00+00	\N	\N	\N	2026-06-01 10:15:59.239723+00
f81c7736-9b35-4988-82d8-49ef29515e3f	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-02 18:00:00+00	\N	\N	\N	2026-06-01 10:15:59.316507+00
62c4f1d3-0abf-4ec0-a48e-adbcb38025f1	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-03 07:00:00+00	\N	\N	\N	2026-06-01 10:15:59.515397+00
62e8a3b3-40d4-456b-80f6-e75c5655ca55	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-03 09:00:00+00	\N	\N	\N	2026-06-01 10:15:59.639262+00
bd5383fd-d8ff-4538-b801-7701d795fa50	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-03 17:00:00+00	\N	\N	\N	2026-06-01 10:15:59.721585+00
5d5d8a25-f725-4dfa-93cd-11e6afd89fc2	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-03 08:00:00+00	\N	\N	\N	2026-06-01 10:15:59.805287+00
81eaa5e7-829c-433b-99e6-0630579e039a	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-03 18:00:00+00	\N	\N	\N	2026-06-01 10:15:59.869189+00
5fc80c58-a239-47e7-a62f-b42fede6b5da	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-04 07:00:00+00	\N	\N	\N	2026-06-01 10:16:00.04864+00
f39a740f-8de2-40ea-abd1-35dce4723e4f	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-04 09:00:00+00	\N	\N	\N	2026-06-01 10:16:00.116755+00
9a3199b7-3ff4-4846-ae6a-d26ae8dda69e	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-04 17:00:00+00	\N	\N	\N	2026-06-01 10:16:00.181768+00
28234648-0774-442a-98c0-23178963a7f0	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-04 08:00:00+00	\N	\N	\N	2026-06-01 10:16:00.295088+00
94d07554-6c3a-42ab-9617-6fd2670bd3d2	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-04 18:00:00+00	\N	\N	\N	2026-06-01 10:16:00.367649+00
931f5782-a5c9-42d5-907e-3f18e6454197	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-05 07:00:00+00	\N	\N	\N	2026-06-01 10:16:00.543721+00
b41fbb25-2b2f-4d03-9144-d1c20a25cc67	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-05 09:00:00+00	\N	\N	\N	2026-06-01 10:16:00.612241+00
6ab051c5-4468-499c-8d3a-293827c5f48d	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-05 17:00:00+00	\N	\N	\N	2026-06-01 10:16:00.681827+00
100451cd-2f7b-4091-afc5-a9cb8379ad3a	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-05 08:00:00+00	\N	\N	\N	2026-06-01 10:16:00.749217+00
4e03bcd8-275e-47c3-ae85-4d85227e14c3	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-05 18:00:00+00	\N	\N	\N	2026-06-01 10:16:00.822402+00
5b2636dc-4f27-49a3-83dc-52f2ebd9d07a	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-06 07:00:00+00	\N	\N	\N	2026-06-01 10:16:01.053529+00
fe9ff100-8f18-41c0-8d45-a50ff0daf25a	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-06 09:00:00+00	\N	\N	\N	2026-06-01 10:16:01.160835+00
5749a4e5-6ef4-48e5-bdd4-d56a4ce5154f	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-06 17:00:00+00	\N	\N	\N	2026-06-01 10:16:01.277936+00
920577e6-a402-4ead-8ba5-1197b6654e18	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-06 08:00:00+00	\N	\N	\N	2026-06-01 10:16:01.397266+00
70e2d78f-362b-4523-9074-c31ec57151a2	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-06 18:00:00+00	\N	\N	\N	2026-06-01 10:16:01.484386+00
7dda7221-2799-40df-ae1c-9939ccd010df	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-07 07:00:00+00	\N	\N	\N	2026-06-01 10:16:01.66607+00
a43f812c-e0b2-4375-9bfd-fd70b53074c4	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-07 09:00:00+00	\N	\N	\N	2026-06-01 10:16:01.746605+00
dfd1c65e-d83a-4fd9-8803-c94f2f7ac4ed	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	df738ef1-6ed8-4172-a99c-f45f7ec5be37	\N	pendiente	2026-06-07 17:00:00+00	\N	\N	\N	2026-06-01 10:16:01.819649+00
c3fab286-aed2-4201-a01f-a6987c3dfb0c	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-07 08:00:00+00	\N	\N	\N	2026-06-01 10:16:01.900435+00
f98ae490-1de5-454d-903a-87c7b2b55dd0	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-07 18:00:00+00	\N	\N	\N	2026-06-01 10:16:02.010245+00
2bdf3026-ac39-5773-b525-ce66c894bab8	08e3b526-81b3-4f00-a4d6-a10dc3789ea0	\N	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	\N	pendiente	2026-05-28 18:54:18.555534+00	\N	\N	Preparar racion de tarde con control de desviacion.	2026-05-28 19:54:18.555534+00
e531c7cc-14dc-5564-bde7-cda15c02a8de	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	3033a0ee-9ffe-5e7f-a7a2-76f309918749	12928484-dfe8-4637-abb5-954ad7673cc8	1479ad4d-f17a-40bd-8606-590ddb2fa868	completada	2026-05-27 19:54:18.555534+00	2026-05-31 15:54:18.555534+00	2026-05-31 18:54:18.555534+00	Control de tratamientos y retirada de leche.	2026-05-27 19:54:18.555534+00
1f594e89-86f1-59bb-8135-377d72f21ea9	305a27d5-7f53-572d-a92c-b84e72cc3a8b	\N	350c2228-7752-5756-bb3e-436f655d703b	1819261f-9823-5373-a0dc-533638edb05e	50bfdd77-8aa3-446d-a0f4-05f3453f8536	completada	2026-05-28 23:54:18.555534+00	2026-05-31 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	Comprobar bebederos del lote principal.	2026-05-23 19:54:18.555534+00
e20f3bea-6346-57dc-9e09-2b339adeda61	755b7735-e9dc-5a61-b10a-289f4c2bdcc8	\N	aed8c2c4-9620-5034-9248-d8564ee7addf	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	cancelada	2026-05-27 15:54:18.555534+00	\N	\N	Preparar racion de tarde con control de desviacion.	2026-05-22 19:54:18.555534+00
40b6b72c-9d2e-5d0b-be2b-4bc07f285c05	08e3b526-81b3-4f00-a4d6-a10dc3789ea0	\N	3033a0ee-9ffe-5e7f-a7a2-76f309918749	584383a2-21ba-537b-af9b-90d8b722821b	\N	completada	2026-05-27 20:54:18.555534+00	2026-05-31 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	Comprobar bebederos del lote principal.	2026-05-27 19:54:18.555534+00
52ef2b04-8975-5f3d-8d2a-6e006d0ffade	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	718c721d-90a7-536a-b47d-bb935fe583f3	12928484-dfe8-4637-abb5-954ad7673cc8	\N	vencida	2026-05-31 21:54:18.555534+00	\N	\N	Preparar racion de tarde con control de desviacion.	2026-05-26 19:54:18.555534+00
bc321b28-3cbb-5fc5-8ebc-decd5651ec1a	124d471a-18f5-42f2-9abd-2c00be35398a	\N	f2b0bd7e-4171-5347-8179-fe6667ba7985	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	pendiente	2026-05-29 23:54:18.555534+00	\N	\N	Revision de silos y cierre de lona.	2026-05-24 19:54:18.555534+00
8b0bd0ec-cc9a-576b-acc7-2061e45df05d	305a27d5-7f53-572d-a92c-b84e72cc3a8b	\N	34b1024d-a884-5dda-b84c-e9460fb19325	1819261f-9823-5373-a0dc-533638edb05e	\N	en_curso	2026-05-27 16:54:18.555534+00	2026-05-31 18:54:18.555534+00	\N	Revision de camas con reposicion parcial.	2026-05-22 19:54:18.555534+00
6ba2ede0-8212-5c0f-a650-d0e44eb4ec77	08e3b526-81b3-4f00-a4d6-a10dc3789ea0	\N	718c721d-90a7-536a-b47d-bb935fe583f3	584383a2-21ba-537b-af9b-90d8b722821b	\N	en_curso	2026-05-31 22:54:18.555534+00	2026-05-31 18:54:18.555534+00	\N	Revision de camas con reposicion parcial.	2026-05-26 19:54:18.555534+00
2777d550-b9ca-53c8-ba66-3010517c9317	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	0ecf1a97-9350-535c-9d9a-08f92e2d4b54	12928484-dfe8-4637-abb5-954ad7673cc8	\N	completada	2026-05-30 23:54:18.555534+00	2026-05-31 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	Comprobar bebederos del lote principal.	2026-05-25 19:54:18.555534+00
fa09d8bd-d9da-5cb0-bd31-a033fc32dba9	124d471a-18f5-42f2-9abd-2c00be35398a	\N	350c2228-7752-5756-bb3e-436f655d703b	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	74cf333b-4aba-5db6-bce2-1e13e1439bc2	completada	2026-05-28 16:54:18.555534+00	2026-05-31 15:54:18.555534+00	2026-05-31 18:54:18.555534+00	Control de tratamientos y retirada de leche.	2026-05-23 19:54:18.555534+00
ad7f9f66-726d-5c48-b395-3980c95b6a41	305a27d5-7f53-572d-a92c-b84e72cc3a8b	\N	efbe203d-853b-56dc-a3a2-e2839e844083	1819261f-9823-5373-a0dc-533638edb05e	\N	pendiente	2026-05-31 18:54:18.555534+00	\N	\N	Limpieza de robots completada sin alarmas.	2026-05-31 19:54:18.555534+00
14200d92-0551-53b1-824b-c5e83636ee63	08e3b526-81b3-4f00-a4d6-a10dc3789ea0	\N	0ecf1a97-9350-535c-9d9a-08f92e2d4b54	584383a2-21ba-537b-af9b-90d8b722821b	cca2e231-9ce5-5e6a-a9f2-63c43db556f4	pendiente	2026-05-30 15:54:18.555534+00	\N	\N	Limpieza de robots completada sin alarmas.	2026-05-25 19:54:18.555534+00
63539e2d-3f28-58b8-ab43-d8fef305a843	faa9ed87-a868-586a-a9ae-4cd973b4cfa0	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	1819261f-9823-5373-a0dc-533638edb05e	\N	en_curso	2026-05-30 16:54:18.555534+00	2026-05-31 18:54:18.555534+00	\N	Revision de camas con reposicion parcial.	2026-05-30 19:54:18.555534+00
fa2f43b9-12af-5972-b1e0-06cf9967765e	749c3577-3ec2-4829-9112-1e11300fdcb4	\N	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	584383a2-21ba-537b-af9b-90d8b722821b	\N	completada	2026-05-29 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	Comprobar bebederos del lote principal.	2026-05-29 19:54:18.555534+00
e7e11510-bce2-58a5-a702-ea1bbb8d5203	ffd7fe81-7a8c-4379-b351-755e7d09474e	\N	718c721d-90a7-536a-b47d-bb935fe583f3	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	pendiente	2026-05-31 20:54:18.555534+00	\N	\N	Revision de silos y cierre de lona.	2026-05-26 19:54:18.555534+00
59da5173-bd40-5587-943c-2c4110f5a9f7	ce0af70a-5965-487f-9644-3682a4650712	\N	f2b0bd7e-4171-5347-8179-fe6667ba7985	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	en_curso	2026-05-29 22:54:18.555534+00	2026-05-31 18:54:18.555534+00	\N	Revision de camas con reposicion parcial.	2026-05-24 19:54:18.555534+00
fb7c92b3-8869-57de-a0ba-72e4134d89dc	33d0a035-e85f-5da6-8926-ec18f6c2cbb9	\N	efbe203d-853b-56dc-a3a2-e2839e844083	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	completada	2026-05-31 16:54:18.555534+00	2026-05-31 15:54:18.555534+00	2026-05-31 18:54:18.555534+00	Control de tratamientos y retirada de leche.	2026-05-31 19:54:18.555534+00
b14c9ca0-bf0d-5240-a908-6edce3bfa028	f1f54927-7db0-4b7d-b849-bbf4028dee33	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	1819261f-9823-5373-a0dc-533638edb05e	\N	pendiente	2026-05-30 17:54:18.555534+00	\N	\N	Revision de silos y cierre de lona.	2026-05-30 19:54:18.555534+00
cf425745-60cc-50b8-9a82-63bd181876b4	faa9ed87-a868-586a-a9ae-4cd973b4cfa0	\N	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	1819261f-9823-5373-a0dc-533638edb05e	1334d1ae-1804-491e-a777-63439f7e9468	pendiente	2026-05-29 18:54:18.555534+00	\N	\N	Limpieza de robots completada sin alarmas.	2026-05-29 19:54:18.555534+00
b07997c3-829c-5561-a883-40e7b52ff09e	749c3577-3ec2-4829-9112-1e11300fdcb4	\N	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	\N	en_curso	2026-05-28 19:54:18.555534+00	2026-05-31 18:54:18.555534+00	\N	Revision de camas con reposicion parcial.	2026-05-28 19:54:18.555534+00
16f1362c-d273-5bc1-b31b-f394dc178be3	ffd7fe81-7a8c-4379-b351-755e7d09474e	\N	0ecf1a97-9350-535c-9d9a-08f92e2d4b54	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	95ccf014-f4ea-5888-a3d7-cba4804370b8	completada	2026-05-30 22:54:18.555534+00	2026-05-31 15:54:18.555534+00	2026-05-31 18:54:18.555534+00	Control de tratamientos y retirada de leche.	2026-05-25 19:54:18.555534+00
35221d42-c625-58f1-a043-4e75b5fec446	ce0af70a-5965-487f-9644-3682a4650712	\N	350c2228-7752-5756-bb3e-436f655d703b	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	pendiente	2026-05-28 15:54:18.555534+00	\N	\N	Limpieza de robots completada sin alarmas.	2026-05-23 19:54:18.555534+00
c4396814-7a99-5de3-afad-87b0203689d8	755b7735-e9dc-5a61-b10a-289f4c2bdcc8	\N	efbe203d-853b-56dc-a3a2-e2839e844083	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	2def9ef9-5ce4-4588-996a-9d149b8888b1	completada	2026-05-31 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	Comprobar bebederos del lote principal.	2026-05-31 19:54:18.555534+00
84d3c80a-b49f-5146-a605-ddaf4d11bdc6	33d0a035-e85f-5da6-8926-ec18f6c2cbb9	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	vencida	2026-05-30 18:54:18.555534+00	\N	\N	Preparar racion de tarde con control de desviacion.	2026-05-30 19:54:18.555534+00
d8fbfdf4-7f79-53a4-926b-4228288cabee	f1f54927-7db0-4b7d-b849-bbf4028dee33	\N	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	1819261f-9823-5373-a0dc-533638edb05e	\N	completada	2026-05-29 19:54:18.555534+00	2026-05-31 15:54:18.555534+00	2026-05-31 18:54:18.555534+00	Control de tratamientos y retirada de leche.	2026-05-29 19:54:18.555534+00
179220af-a3c1-54aa-850b-a741d65ac6da	faa9ed87-a868-586a-a9ae-4cd973b4cfa0	\N	aed8c2c4-9620-5034-9248-d8564ee7addf	1819261f-9823-5373-a0dc-533638edb05e	\N	pendiente	2026-05-28 20:54:18.555534+00	\N	\N	Revision de silos y cierre de lona.	2026-05-28 19:54:18.555534+00
d6d422c1-4235-54e3-bbbc-c31e28734985	749c3577-3ec2-4829-9112-1e11300fdcb4	\N	3033a0ee-9ffe-5e7f-a7a2-76f309918749	584383a2-21ba-537b-af9b-90d8b722821b	d9c29718-27eb-55a8-99d3-6f55765d7e34	pendiente	2026-05-27 21:54:18.555534+00	\N	\N	Limpieza de robots completada sin alarmas.	2026-05-27 19:54:18.555534+00
2e5375c1-61d3-5382-828b-2b72937d26bd	ffd7fe81-7a8c-4379-b351-755e7d09474e	\N	f2b0bd7e-4171-5347-8179-fe6667ba7985	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	vencida	2026-05-29 15:54:18.555534+00	\N	\N	Preparar racion de tarde con control de desviacion.	2026-05-24 19:54:18.555534+00
58f6eb65-8937-57a0-8fa4-754937578d24	755b7735-e9dc-5a61-b10a-289f4c2bdcc8	\N	4830a4e4-9a7f-56dc-9102-12fd9c99e3dc	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	en_curso	2026-05-30 19:54:18.555534+00	2026-05-31 18:54:18.555534+00	\N	Revision de camas con reposicion parcial.	2026-05-30 19:54:18.555534+00
5ce712e6-fa7c-5a97-bb1e-e703299f4006	33d0a035-e85f-5da6-8926-ec18f6c2cbb9	\N	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	ecd8c871-5c03-4f1b-8797-e60499747b96	completada	2026-05-29 20:54:18.555534+00	2026-05-31 17:54:18.555534+00	2026-05-31 17:54:18.555534+00	Comprobar bebederos del lote principal.	2026-05-29 19:54:18.555534+00
7f034368-959f-50d4-8417-b4a2ffe520d8	f1f54927-7db0-4b7d-b849-bbf4028dee33	\N	aed8c2c4-9620-5034-9248-d8564ee7addf	1819261f-9823-5373-a0dc-533638edb05e	\N	vencida	2026-05-28 21:54:18.555534+00	\N	\N	Preparar racion de tarde con control de desviacion.	2026-05-28 19:54:18.555534+00
feae938e-a1e0-558d-8492-9b6bb9fc6e24	faa9ed87-a868-586a-a9ae-4cd973b4cfa0	\N	3033a0ee-9ffe-5e7f-a7a2-76f309918749	1819261f-9823-5373-a0dc-533638edb05e	\N	completada	2026-05-27 22:54:18.555534+00	2026-05-31 15:54:18.555534+00	2026-05-31 18:54:18.555534+00	Control de tratamientos y retirada de leche.	2026-05-27 19:54:18.555534+00
b3d2a278-40c3-5318-834b-08dbf27e80bb	749c3577-3ec2-4829-9112-1e11300fdcb4	\N	718c721d-90a7-536a-b47d-bb935fe583f3	584383a2-21ba-537b-af9b-90d8b722821b	\N	pendiente	2026-05-31 23:54:18.555534+00	\N	\N	Revision de silos y cierre de lona.	2026-05-26 19:54:18.555534+00
9d42ba3f-9254-58bd-be77-b0747638a0d0	ce0af70a-5965-487f-9644-3682a4650712	\N	34b1024d-a884-5dda-b84c-e9460fb19325	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	completada	2026-05-27 17:54:18.555534+00	2026-05-31 19:55:34.794+00	\N	Revision de silos y cierre de lona.	2026-05-22 19:54:18.555534+00
84696b80-a270-5c29-a6e2-5306302696a1	f1f54927-7db0-4b7d-b849-bbf4028dee33	\N	ee779dc8-16c9-597a-b0ed-ff5886d58b9e	584383a2-21ba-537b-af9b-90d8b722821b	\N	pendiente	2026-05-31 22:31:57.733599+00	\N	\N	Revisar boxes, cama y consumo de leche.	2026-05-31 21:31:57.733599+00
16d05462-3564-5a0b-a580-7b3d43b47803	749c3577-3ec2-4829-9112-1e11300fdcb4	\N	aed8c2c4-9620-5034-9248-d8564ee7addf	584383a2-21ba-537b-af9b-90d8b722821b	\N	pendiente	2026-05-31 23:31:57.733599+00	\N	\N	Control de diarreas y tratamientos en boxes.	2026-05-31 21:31:57.733599+00
00b52acc-8aa4-5b46-91b5-cba3cd5eff6e	749c3577-3ec2-4829-9112-1e11300fdcb4	\N	aed8c2c4-9620-5034-9248-d8564ee7addf	12928484-dfe8-4637-abb5-954ad7673cc8	\N	pendiente	2026-05-31 22:16:57.733599+00	\N	\N	Revisar tratamientos activos y retiradas.	2026-05-31 21:31:57.733599+00
d45c87c0-e7cf-53b0-a234-012ed5af2cda	305a27d5-7f53-572d-a92c-b84e72cc3a8b	\N	718c721d-90a7-536a-b47d-bb935fe583f3	0136bdbc-70c7-5c70-8872-c5fcfdf72e40	\N	pendiente	2026-06-01 01:31:57.733599+00	\N	\N	Revision de averias y mantenimiento pendiente.	2026-05-31 21:31:57.733599+00
79a77795-3b8e-5bf0-a0eb-3cce55d500ab	ffd7fe81-7a8c-4379-b351-755e7d09474e	\N	3033a0ee-9ffe-5e7f-a7a2-76f309918749	bc97e385-bbd8-5163-895a-b7156b84e145	\N	pendiente	2026-06-01 00:31:57.733599+00	\N	\N	Revisar agua y bebederos de novillas.	2026-05-31 21:31:57.733599+00
170b7e04-5d57-5c03-bab7-dfc548db1b03	124d471a-18f5-42f2-9abd-2c00be35398a	\N	350c2228-7752-5756-bb3e-436f655d703b	1819261f-9823-5373-a0dc-533638edb05e	\N	pendiente	2026-05-31 23:01:57.733599+00	\N	\N	Preparar racion y revisar desviaciones TMR.	2026-05-31 21:31:57.733599+00
\.


--
-- Data for Name: tareas_recurrentes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tareas_recurrentes (id, catalogo_id, zona_id, maquinaria_id, frecuencia_expr, descripcion_frecuencia, activa, fecha_inicio, fecha_fin, notas) FROM stdin;
e8b43672-2f50-4e39-9226-5912b4abbe30	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	0 22 * * 1,4	Lunes y jueves a las 22:00	t	2026-05-31	\N	Lavado robots 1-2 (lun/jue)
1a77ccfa-84e5-4f8f-b9c2-d68f4aee2c6e	b41521f2-44cd-44bc-b7f7-e0e419547009	\N	\N	0 22 * * 2,5	Martes y viernes a las 22:00	t	2026-05-31	\N	Lavado robots 3 (mar/vie)
90dce67b-5709-4c6b-ac49-6f6c2c91ee4f	08e3b526-81b3-4f00-a4d6-a10dc3789ea0	\N	\N	cada_N_dias:30	Cada 30 días	t	2026-05-31	\N	Desinfectante camas patio lactación
39ef88e7-73e4-4785-ada6-9deefc3060f0	ffd7fe81-7a8c-4379-b351-755e7d09474e	\N	\N	0 10 * * 1,3,5	Lunes, miércoles y viernes a las 10:00	t	2026-05-31	\N	Bebederos L/X/V
\.


--
-- Data for Name: tratamientos_activos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tratamientos_activos (id, animal_id, evento_sanitario_id, farmaco, dosis, via_administracion, dias_tratamiento, fecha_inicio, fecha_fin_prevista, fecha_fin_real, activo, checkboxes, prescrito_por, notas) FROM stdin;
bcfd02e1-00ce-5946-9bf9-41a397f51af1	5c67547b-6b24-50ca-b4fc-3ec8cd1c6c3f	37eaf94b-dcf5-57f2-97a5-7186a9d3052e	Ceftiofur	1 aplicacion/ordeno	oral	4	2026-04-02	2026-04-06	2026-05-25	f	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
b652b220-e16f-55ee-8799-49f39aabd197	592b42b6-a0bc-52ed-8f7d-44a9ab00b455	25469cc9-5627-5fd0-9b8d-d9adca35b5e5	Pomada intramamaria	20 ml/48h	subcutanea	5	2026-04-05	2026-04-10	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
c1419622-5cfb-5cf3-9785-7ec7ea5c7edb	62d38b4e-74e0-5f20-b66b-64efddec53b7	1da930ee-2f7a-511c-8f8d-22b62a6e9a10	Electrolitos orales	10 ml/24h	intramuscular	6	2026-04-08	2026-04-14	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
2e0343fd-815b-5f76-adad-30e3cce4121b	b5263713-2026-5bad-ae46-296dc48a39d3	bae52c71-c780-5c36-852b-44d7108c6e8d	Florfenicol	2 sobres/dia	intramamaria	7	2026-04-11	2026-04-18	2026-05-28	f	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
f56a4ddc-7cae-55fb-bb6f-b7dba0bcf9e2	436a7ff2-5df5-51b1-a49f-179831808d47	dd392fa1-af05-5a7c-9488-3aaaf47e736b	Penetamato	1 aplicacion/ordeno	oral	3	2026-04-14	2026-04-17	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
9f97f31d-022f-5ce7-890c-336f3613fad9	d172a069-591a-55e4-89fc-32699f1d25c9	fbb2ac4e-2d8e-5790-aea9-e7e6bc2b4d3b	Meloxicam	20 ml/48h	subcutanea	4	2026-04-17	2026-04-21	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
3e2971b6-3c94-5f04-af3d-71aef66ba68c	e8ce7a5c-39f9-5960-aa80-9ea67c14ca5c	9dbc5471-3f77-5012-a9fa-00908a2fc64e	Ceftiofur	10 ml/24h	intramuscular	5	2026-04-20	2026-04-25	2026-05-31	f	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
1369afe6-7cdc-531d-972e-29c2d977e4b0	2a773b34-d3f5-5a8e-9651-e2ee4e58a9b4	025ae8e0-6852-5c50-828d-4196e9b8e8b9	Pomada intramamaria	2 sobres/dia	intramamaria	6	2026-04-23	2026-04-29	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
257cea2c-6850-55f3-b2ef-35408d1d7e99	cf17702f-f18b-553e-9294-67e671e66022	58667dde-19dd-5418-9a1a-d6f7d2da1a6c	Electrolitos orales	1 aplicacion/ordeno	oral	7	2026-04-26	2026-05-03	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
9a8f8203-f852-5be1-85db-4124ee0bca75	936b78c4-7b89-5fcf-97f7-54f007674e36	99a4215a-c560-51b1-af22-f514c466e839	Florfenicol	20 ml/48h	subcutanea	3	2026-04-29	2026-05-02	2026-05-22	f	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
ee222de5-d26a-518b-8209-a267aca1e8b8	3c97c346-b54c-5581-930e-f3264d6773ea	abf1ac0a-6bac-5db5-ab56-49868a5d113f	Penetamato	10 ml/24h	intramuscular	4	2026-05-02	2026-05-06	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
6f02881b-17a7-5b3c-9d7d-c76ca57abd11	2dd41d6e-e3ad-5870-b8dc-d71361fa1e56	ffb9c824-a985-514a-8076-44cd6d396e71	Meloxicam	2 sobres/dia	intramamaria	5	2026-05-05	2026-05-10	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
f81f166d-d2f0-5acb-9077-efeb1ab7ef5b	1a6e7a54-8774-52a6-896f-01a35b5cbc2d	e3df197e-24f9-5903-bda0-e6cf697f82ad	Ceftiofur	1 aplicacion/ordeno	oral	6	2026-05-08	2026-05-14	2026-05-25	f	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
59692272-5b46-5cd9-be95-c50841c3d0f1	e287b4b8-1876-527c-8b7c-7fdf85c42709	4eaa9f5b-8295-5d1b-a98e-2c285fdc855e	Pomada intramamaria	20 ml/48h	subcutanea	7	2026-05-11	2026-05-18	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
c6dc6123-355b-5a0d-9984-50ff66028733	73956a35-c183-5c88-9b6e-827903fe0241	b899078b-81a1-56c9-939d-7df708e3aa93	Electrolitos orales	10 ml/24h	intramuscular	3	2026-05-14	2026-05-17	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
bf8c2884-ca99-513a-b595-bdec6886d0bf	0d506129-b7c5-507a-88ca-242344baa5de	b3a81c79-2168-5203-ba17-489b2d3f3ebf	Florfenicol	2 sobres/dia	intramamaria	4	2026-05-17	2026-05-21	2026-05-28	f	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": true}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
d6e69c86-789a-5700-a3ed-92e16ec1ddbd	c7ee8997-4bfb-56ca-9a3f-653af2d06595	ffdb5c2c-362d-59a5-9896-42ccfc261a9b	Penetamato	1 aplicacion/ordeno	oral	5	2026-05-20	2026-05-25	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
7b6af28c-abdf-5c69-95c7-91ad13eae6b4	d58fbf17-442e-5153-8cdf-ce264a40ef4f	97682f5a-49f4-53bf-8a08-4846ba0468ed	Meloxicam	20 ml/48h	subcutanea	6	2026-05-23	2026-05-29	\N	t	[{"dia": 1, "administrado": true}, {"dia": 2, "administrado": false}]	aed8c2c4-9620-5034-9248-d8564ee7addf	Seguimiento de tratamiento con retirada cuando aplica.
\.


--
-- Data for Name: turnos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.turnos (id, fecha, tipo_turno, hora_inicio, hora_fin, notas) FROM stdin;
036532ee-f62c-5adf-ae78-50ff294f0ebf	2026-05-29	manana	06:00:00	14:00:00	Turno planificado para cobertura de rutina.
dc17241e-e305-5169-87f6-b72de1a7e604	2026-05-30	manana	06:00:00	14:00:00	Turno planificado para cobertura de rutina.
637f3b98-4ed6-5d96-ad6f-166b49135040	2026-05-31	manana	06:00:00	14:00:00	Turno operativo de hoy con seguimiento de incidencias abiertas.
806041d7-8f66-5a30-9763-951ec6951183	2026-06-01	manana	06:00:00	14:00:00	Turno planificado para cobertura de rutina.
16ab9a4e-295d-5e6e-8bc7-e1d361b1be9f	2026-06-02	manana	06:00:00	14:00:00	Turno planificado para cobertura de rutina.
23838145-7ce3-5502-8fdd-0d72fa063c60	2026-06-03	manana	06:00:00	14:00:00	Turno planificado para cobertura de rutina.
9c721bbb-1e85-5091-8f6e-3d48feeb4597	2026-06-04	manana	06:00:00	14:00:00	Turno planificado para cobertura de rutina.
477b09af-df38-55f7-898d-347021c79d8e	2026-05-29	tarde	16:00:00	00:00:00	Turno planificado para cobertura de rutina.
9bf70236-d678-5a3e-ad64-b4fa5b5e3901	2026-05-30	tarde	16:00:00	00:00:00	Turno planificado para cobertura de rutina.
c40a8fab-a392-5e5d-9fe6-eb47807c541f	2026-05-31	tarde	16:00:00	00:00:00	Turno operativo de hoy con seguimiento de incidencias abiertas.
7d245751-1ad7-5677-af6d-bfb8c71d1734	2026-06-01	tarde	16:00:00	00:00:00	Turno planificado para cobertura de rutina.
6b88b173-cd02-568e-80d9-2a7ed12413ec	2026-06-02	tarde	16:00:00	00:00:00	Turno planificado para cobertura de rutina.
c10998b0-61ca-5c7c-a6ef-07a9b1f3dfba	2026-06-03	tarde	16:00:00	00:00:00	Turno planificado para cobertura de rutina.
ca4173b3-5931-5ac8-961d-26c5a7e48959	2026-06-04	tarde	16:00:00	00:00:00	Turno planificado para cobertura de rutina.
6716676c-7192-408b-a646-1e806e03d495	2026-06-05	manana	06:00:00	14:00:00	Turno automático
8c4ccba1-7ed1-4a0e-ad8b-74e7bdc4c792	2026-06-05	tarde	06:00:00	14:00:00	\N
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuarios (id, username, email, hashed_password, role, activo, debe_cambiar_contrasena, fecha_creacion) FROM stdin;
a3816fd8-a008-4008-b1fb-6a2746b6c71f	admin	admin@tools4milk.local	$2b$12$RBoVVvT8MBmodgOOFaldC.8cU7vm6g78v0gj64aRe3A6oA5T1VtyG	admin	t	f	2026-05-31 19:22:35.832502
9f8b2df9-5cae-4340-84c7-368b278fc345	roberto.castro	roberto.castro@tools4milk.local	$2b$12$OzZKqJiuVbRcNpW2s8VJCehg/4wYWYcwONZEQEJ0RAjphAzJj5vT6	admin	t	f	2026-05-31 19:22:36.103988
fe874b51-24d6-48b9-a606-f97f77ceebd3	operario.zona	operario.zona@tools4milk.local	$2b$12$61lHaN2fElz9KLyV6bwRdOkVdF/M83NlBmW4kXGALWQ1GkOGJkJk.	operario	t	f	2026-05-31 19:22:36.344042
39f4122a-a170-4e14-a71a-784c9cb36496	laura.fernandez	laura.fernandez@tools4milk.local	$2b$12$ilcMPH7bhzkL9UaIsb/YeOIx1/0cbZ9YrdMUQQBSSMKG2ZR7z1KNS	alimentacion	t	f	2026-05-31 19:22:36.577802
49b05742-a2fd-4af7-8c26-a19534c7b371	dr.mendez	dr.mendez@tools4milk.local	$2b$12$JM7EcZ6SsEUOqFXvVQ14We4pD4T6aVistD9EX.9EQdWvxQ99aoVyW	veterinario	t	f	2026-05-31 19:22:36.84707
\.


--
-- Data for Name: zonas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zonas (id, nombre, codigo, descripcion, tiene_pantalla_tv, tiene_tablet) FROM stdin;
df738ef1-6ed8-4172-a99c-f45f7ec5be37	Nave	sala_ordeno	Sala de ordeño robótico VMS	t	t
12928484-dfe8-4637-abb5-954ad7673cc8	Enfermería	enfermeria	Animales enfermos y en tratamiento	t	t
041feac1-9de2-4772-af3b-fc7d08acb16f	Oficina	oficina	Gestión administrativa y técnica	t	t
942963db-2cb5-49b5-9640-c96a138553cc	General	general	Área general sin pantalla asignada	f	f
ccca4b6f-9e15-5193-88c8-c44608141146	Zona de robots	robots	Area de robots de ordeno y espera monitorizada.	t	t
1819261f-9823-5373-a0dc-533638edb05e	Patio de alimentacion	patio_alimentacion	Comederos, arrimador y control de racion.	t	t
46cc7a9d-80c2-5f41-80f8-ab6a8b2644ee	Silos	silos	Silos de forraje, concentrado y correctores.	f	t
9dbbf3e4-5070-5c4a-8beb-8b893a3bb081	Almacen	almacen	Material de limpieza, repuestos y productos veterinarios.	f	t
584383a2-21ba-537b-af9b-90d8b722821b	Boxes de terneros	boxes_terneros	Boxes individuales y zona de lactancia artificial.	t	t
0136bdbc-70c7-5c70-8872-c5fcfdf72e40	Zona de maquinaria	maquinaria	Aparcamiento, taller y mantenimiento preventivo.	f	t
bc97e385-bbd8-5163-895a-b7156b84e145	Zona de recria	zona_recria	Terneras y novillas con ficha completa tras la salida de boxes.	t	t
4f5eef67-de33-4897-9669-51ba1a5ef6d6	Histórico Boxes	becerrero	Cría de terneros y becerros	t	t
\.


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 333, true);


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
-- Name: animales animales_crotal_oficial_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animales
    ADD CONSTRAINT animales_crotal_oficial_key UNIQUE (crotal_oficial);


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
-- Name: core_animals core_animals_crotal_oficial_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.core_animals
    ADD CONSTRAINT core_animals_crotal_oficial_key UNIQUE (crotal_oficial);


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
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


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
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_username_key UNIQUE (username);


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
-- Name: idx_alertas_activas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alertas_activas ON public.alertas USING btree (activa, ts_generacion DESC) WHERE (activa = true);


--
-- Name: idx_alertas_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alertas_animal ON public.alertas USING btree (animal_id) WHERE (animal_id IS NOT NULL);


--
-- Name: idx_alertas_nivel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alertas_nivel ON public.alertas USING btree (nivel);


--
-- Name: idx_animales_crotal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_animales_crotal ON public.animales USING btree (crotal_oficial);


--
-- Name: idx_animales_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_animales_estado ON public.animales USING btree (estado);


--
-- Name: idx_animales_estado_repro; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_animales_estado_repro ON public.animales USING btree (estado_reproductivo);


--
-- Name: idx_animales_madre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_animales_madre ON public.animales USING btree (madre_id);


--
-- Name: idx_audit_registro; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_registro ON public.audit_log USING btree (registro_id);


--
-- Name: idx_audit_tabla; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_tabla ON public.audit_log USING btree (tabla_afectada, ts DESC);


--
-- Name: idx_audit_ts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_ts ON public.audit_log USING btree (ts DESC);


--
-- Name: idx_boxes_alertas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_boxes_alertas ON public.boxes_recria USING gin (alertas_box);


--
-- Name: idx_boxes_ternero; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_boxes_ternero ON public.boxes_recria USING btree (ternero_id) WHERE (ternero_id IS NOT NULL);


--
-- Name: idx_carro_mezcla; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carro_mezcla ON public.lecturas_carro_mezclador USING btree (mezcla_id, ts DESC);


--
-- Name: idx_ejecuciones_empleado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ejecuciones_empleado ON public.tareas_ejecuciones USING btree (empleado_id);


--
-- Name: idx_ejecuciones_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ejecuciones_estado ON public.tareas_ejecuciones USING btree (estado);


--
-- Name: idx_ejecuciones_planificada; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ejecuciones_planificada ON public.tareas_ejecuciones USING btree (ts_planificada);


--
-- Name: idx_ejecuciones_zona; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ejecuciones_zona ON public.tareas_ejecuciones USING btree (zona_id);


--
-- Name: idx_ev_recria_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_recria_animal ON public.eventos_sanitarios_recria USING btree (animal_id);


--
-- Name: idx_ev_recria_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_recria_fecha ON public.eventos_sanitarios_recria USING btree (fecha DESC);


--
-- Name: idx_ev_repro_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_repro_animal ON public.eventos_reproductivos USING btree (animal_id);


--
-- Name: idx_ev_repro_det; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_repro_det ON public.eventos_reproductivos USING gin (detalles);


--
-- Name: idx_ev_repro_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_repro_fecha ON public.eventos_reproductivos USING btree (fecha DESC);


--
-- Name: idx_ev_repro_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_repro_tipo ON public.eventos_reproductivos USING btree (tipo);


--
-- Name: idx_ev_sanitarios_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_sanitarios_animal ON public.eventos_sanitarios USING btree (animal_id);


--
-- Name: idx_ev_sanitarios_retirada; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_sanitarios_retirada ON public.eventos_sanitarios USING btree (periodo_retirada_hasta) WHERE (periodo_retirada_hasta IS NOT NULL);


--
-- Name: idx_ev_sanitarios_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ev_sanitarios_tipo ON public.eventos_sanitarios USING btree (tipo_patologia);


--
-- Name: idx_genomica_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_genomica_animal ON public.genomica USING btree (animal_id);


--
-- Name: idx_incidencias_acciones; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidencias_acciones ON public.incidencias USING gin (acciones);


--
-- Name: idx_incidencias_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidencias_animal ON public.incidencias USING btree (animal_id);


--
-- Name: idx_incidencias_apertura; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidencias_apertura ON public.incidencias USING btree (ts_apertura DESC);


--
-- Name: idx_incidencias_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidencias_estado ON public.incidencias USING btree (estado);


--
-- Name: idx_incidencias_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidencias_tipo ON public.incidencias USING btree (tipo);


--
-- Name: idx_incidencias_zona; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidencias_zona ON public.incidencias USING btree (zona_id);


--
-- Name: idx_lactaciones_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lactaciones_animal ON public.lactaciones USING btree (animal_id);


--
-- Name: idx_lactaciones_parto; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lactaciones_parto ON public.lactaciones USING btree (fecha_parto DESC);


--
-- Name: idx_pedidos_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_estado ON public.pedidos USING btree (estado);


--
-- Name: idx_pedidos_ts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_ts ON public.pedidos USING btree (ts_solicitud DESC);


--
-- Name: idx_robot_ordeno_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_robot_ordeno_animal ON public.lecturas_robot_ordeno USING btree (animal_id, ts DESC);


--
-- Name: idx_robot_ordeno_robot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_robot_ordeno_robot ON public.lecturas_robot_ordeno USING btree (robot_id, ts DESC);


--
-- Name: idx_tratamientos_activos; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tratamientos_activos ON public.tratamientos_activos USING btree (activo) WHERE (activo = true);


--
-- Name: idx_tratamientos_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tratamientos_animal ON public.tratamientos_activos USING btree (animal_id);


--
-- Name: ix_animales_zona_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animales_zona_id ON public.animales USING btree (zona_id);


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

CREATE INDEX ix_core_animals_crotal_oficial ON public.core_animals USING btree (crotal_oficial);


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
-- Name: ix_empleados_zona_principal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_empleados_zona_principal_id ON public.empleados USING btree (zona_principal_id);


--
-- Name: ix_tareas_ejecuciones_empleado_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tareas_ejecuciones_empleado_id ON public.tareas_ejecuciones USING btree (empleado_id);


--
-- Name: ix_usuarios_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usuarios_email ON public.usuarios USING btree (email);


--
-- Name: ix_usuarios_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usuarios_role ON public.usuarios USING btree (role);


--
-- Name: ix_usuarios_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_usuarios_username ON public.usuarios USING btree (username);


--
-- Name: animales trg_audit_animales; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_animales AFTER INSERT OR DELETE OR UPDATE ON public.animales FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: eventos_sanitarios trg_audit_eventos_sanitarios; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_eventos_sanitarios AFTER INSERT OR DELETE OR UPDATE ON public.eventos_sanitarios FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: incidencias trg_audit_incidencias; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_incidencias AFTER INSERT OR DELETE OR UPDATE ON public.incidencias FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: pedidos trg_audit_pedidos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_pedidos AFTER INSERT OR DELETE OR UPDATE ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: tratamientos_activos trg_audit_tratamientos_activos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_tratamientos_activos AFTER INSERT OR DELETE OR UPDATE ON public.tratamientos_activos FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


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
-- Name: empleados fk_empleados_zona_principal; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT fk_empleados_zona_principal FOREIGN KEY (zona_principal_id) REFERENCES public.zonas(id) ON DELETE SET NULL;


--
-- Name: incidencias fk_incidencias_animal; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT fk_incidencias_animal FOREIGN KEY (animal_id) REFERENCES public.animales(id) ON DELETE SET NULL;


--
-- Name: genomica genomica_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genomica
    ADD CONSTRAINT genomica_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


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

\unrestrict COAxfURnEETjXzAAkul4ya9Fk0ZOU3oF7DtjKhQ8C9qS3kkDivH9sql9BNf5vkE

