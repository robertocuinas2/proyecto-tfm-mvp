--
-- PostgreSQL database dump
--

\restrict WybNZwSmdesk8SzSweOHIBmipVqaodA7G36cEKykoGwDpw1X2UyVXhYI1lQvog7

-- Dumped from database version 15.18
-- Dumped by pg_dump version 15.18

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: estado_animal; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_animal AS ENUM (
    'produccion',
    'seca',
    'recria',
    'gestante',
    'baja'
);


ALTER TYPE public.estado_animal OWNER TO postgres;

--
-- Name: estado_incidencia; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_incidencia AS ENUM (
    'abierta',
    'en_gestion',
    'resuelta',
    'cerrada'
);


ALTER TYPE public.estado_incidencia OWNER TO postgres;

--
-- Name: estado_pedido; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_pedido AS ENUM (
    'solicitado',
    'aprobado',
    'en_transito',
    'recibido',
    'cancelado'
);


ALTER TYPE public.estado_pedido OWNER TO postgres;

--
-- Name: estado_reproductivo; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_reproductivo AS ENUM (
    'vacia',
    'en_celo',
    'inseminada',
    'confirmada_gestante',
    'parto_reciente'
);


ALTER TYPE public.estado_reproductivo OWNER TO postgres;

--
-- Name: estado_tarea; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_tarea AS ENUM (
    'pendiente',
    'en_curso',
    'completada',
    'vencida',
    'cancelada'
);


ALTER TYPE public.estado_tarea OWNER TO postgres;

--
-- Name: nivel_alerta; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.nivel_alerta AS ENUM (
    'baja',
    'media',
    'alta'
);


ALTER TYPE public.nivel_alerta OWNER TO postgres;

--
-- Name: nivel_severidad; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.nivel_severidad AS ENUM (
    'baja',
    'media',
    'alta'
);


ALTER TYPE public.nivel_severidad OWNER TO postgres;

--
-- Name: rol_empleado; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.rol_empleado AS ENUM (
    'encargado',
    'auxiliar',
    'veterinario',
    'mecanico'
);


ALTER TYPE public.rol_empleado OWNER TO postgres;

--
-- Name: sexo_animal; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.sexo_animal AS ENUM (
    'hembra',
    'macho'
);


ALTER TYPE public.sexo_animal OWNER TO postgres;

--
-- Name: tipo_evento_repro; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_evento_repro AS ENUM (
    'celo',
    'inseminacion',
    'diagnostico_gestacion',
    'aborto',
    'parto',
    'secado'
);


ALTER TYPE public.tipo_evento_repro OWNER TO postgres;

--
-- Name: tipo_incidencia; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_incidencia AS ENUM (
    'averia_maquinaria',
    'infraestructura',
    'sanidad_animal',
    'calidad_leche',
    'alimentacion',
    'pedidos'
);


ALTER TYPE public.tipo_incidencia OWNER TO postgres;

--
-- Name: tipo_maquinaria; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_maquinaria AS ENUM (
    'robot_ordeno',
    'carro_mezclador',
    'amamantadora',
    'bomba',
    'otro'
);


ALTER TYPE public.tipo_maquinaria OWNER TO postgres;

--
-- Name: tipo_patologia; Type: TYPE; Schema: public; Owner: postgres
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


ALTER TYPE public.tipo_patologia OWNER TO postgres;

--
-- Name: tipo_turno; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_turno AS ENUM (
    'manana',
    'tarde'
);


ALTER TYPE public.tipo_turno OWNER TO postgres;

--
-- Name: fn_audit_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_audit_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_registro_id UUID;
    v_datos_ant   JSONB;
    v_datos_new   JSONB;
    v_hash_input  TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_registro_id := NEW.id;
        v_datos_ant   := NULL;
        v_datos_new   := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        v_registro_id := NEW.id;
        v_datos_ant   := to_jsonb(OLD);
        v_datos_new   := to_jsonb(NEW);
    ELSIF TG_OP = 'DELETE' THEN
        v_registro_id := OLD.id;
        v_datos_ant   := to_jsonb(OLD);
        v_datos_new   := NULL;
    END IF;

    v_hash_input := TG_TABLE_NAME || TG_OP || v_registro_id::TEXT
                    || COALESCE(v_datos_new::TEXT, v_datos_ant::TEXT);

    INSERT INTO audit_log (
        tabla_afectada, operacion, registro_id,
        datos_anteriores, datos_nuevos, hash_sha256
    ) VALUES (
        TG_TABLE_NAME, TG_OP, v_registro_id,
        v_datos_ant, v_datos_new,
        encode(digest(v_hash_input, 'sha256'), 'hex')
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.fn_audit_trigger() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alertas; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.alertas OWNER TO postgres;

--
-- Name: alertas_umbrales; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.alertas_umbrales OWNER TO postgres;

--
-- Name: animales; Type: TABLE; Schema: public; Owner: postgres
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
    CONSTRAINT chk_fechas_animal CHECK (((fecha_baja IS NULL) OR (fecha_baja >= fecha_nacimiento)))
);


ALTER TABLE public.animales OWNER TO postgres;

--
-- Name: asignaciones_turno; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.asignaciones_turno (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    turno_id uuid NOT NULL,
    empleado_id uuid NOT NULL,
    zona_id uuid,
    rol character varying(80)
);


ALTER TABLE public.asignaciones_turno OWNER TO postgres;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_log_id_seq OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: boxes_recria; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.boxes_recria OWNER TO postgres;

--
-- Name: core_alerts; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_alerts OWNER TO postgres;

--
-- Name: core_animals; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_animals OWNER TO postgres;

--
-- Name: core_employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.core_employees (
    id character varying(80) NOT NULL,
    nombre character varying(120) NOT NULL,
    apellidos character varying(160),
    role character varying(80),
    zona_principal_id character varying(80),
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.core_employees OWNER TO postgres;

--
-- Name: core_incidents; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_incidents OWNER TO postgres;

--
-- Name: core_lactations; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_lactations OWNER TO postgres;

--
-- Name: core_machinery; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_machinery OWNER TO postgres;

--
-- Name: core_tasks; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_tasks OWNER TO postgres;

--
-- Name: core_treatments; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_treatments OWNER TO postgres;

--
-- Name: core_zones; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.core_zones OWNER TO postgres;

--
-- Name: datos_metereologicos; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.datos_metereologicos OWNER TO postgres;

--
-- Name: datos_metereologicos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.datos_metereologicos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.datos_metereologicos_id_seq OWNER TO postgres;

--
-- Name: datos_metereologicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.datos_metereologicos_id_seq OWNED BY public.datos_metereologicos.id;


--
-- Name: empleados; Type: TABLE; Schema: public; Owner: postgres
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
    CONSTRAINT chk_fechas_empleado CHECK (((fecha_baja IS NULL) OR (fecha_baja >= fecha_alta)))
);


ALTER TABLE public.empleados OWNER TO postgres;

--
-- Name: TABLE empleados; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.empleados IS 'Registro maestro de trabajadores.';


--
-- Name: COLUMN empleados.cualificaciones; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleados.cualificaciones IS 'Array de cualificaciones: VMS, TMR, veterinaria…';


--
-- Name: eventos_reproductivos; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.eventos_reproductivos OWNER TO postgres;

--
-- Name: eventos_sanitarios; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.eventos_sanitarios OWNER TO postgres;

--
-- Name: eventos_sanitarios_recria; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.eventos_sanitarios_recria OWNER TO postgres;

--
-- Name: genomica; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.genomica OWNER TO postgres;

--
-- Name: incidencias; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.incidencias OWNER TO postgres;

--
-- Name: lactaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lactaciones (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    animal_id uuid NOT NULL,
    numero smallint NOT NULL,
    fecha_parto date NOT NULL,
    fecha_secado date,
    produccion_total_kg numeric(8,2),
    notas text,
    CONSTRAINT chk_fechas_lactacion CHECK (((fecha_secado IS NULL) OR (fecha_secado > fecha_parto))),
    CONSTRAINT lactaciones_numero_check CHECK ((numero >= 1))
);


ALTER TABLE public.lactaciones OWNER TO postgres;

--
-- Name: lecturas_carro_mezclador; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.lecturas_carro_mezclador OWNER TO postgres;

--
-- Name: lecturas_meteorologia; Type: TABLE; Schema: public; Owner: postgres
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
    indice_thermo_humedad numeric(5,2) GENERATED ALWAYS AS (round((((0.8 * temperatura_c) + ((humedad_relativa / 100.0) * (temperatura_c - 14.4))) + 46.4), 2)) STORED
);


ALTER TABLE public.lecturas_meteorologia OWNER TO postgres;

--
-- Name: lecturas_robot_ordeno; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.lecturas_robot_ordeno OWNER TO postgres;

--
-- Name: maquinaria; Type: TABLE; Schema: public; Owner: postgres
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
    notas text
);


ALTER TABLE public.maquinaria OWNER TO postgres;

--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- Name: resumenes_relevo; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.resumenes_relevo OWNER TO postgres;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL,
    applied_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: tareas_catalogo; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.tareas_catalogo OWNER TO postgres;

--
-- Name: tareas_ejecuciones; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.tareas_ejecuciones OWNER TO postgres;

--
-- Name: tareas_recurrentes; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.tareas_recurrentes OWNER TO postgres;

--
-- Name: COLUMN tareas_recurrentes.frecuencia_expr; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.tareas_recurrentes.frecuencia_expr IS 'Cron estándar (0 22 * * 1,4) o formato propio cada_N_dias:30.';


--
-- Name: tratamientos_activos; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.tratamientos_activos OWNER TO postgres;

--
-- Name: turnos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.turnos (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    fecha date NOT NULL,
    tipo_turno public.tipo_turno NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone NOT NULL,
    notas text
);


ALTER TABLE public.turnos OWNER TO postgres;

--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: v_produccion_diaria; Type: VIEW; Schema: public; Owner: postgres
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


ALTER TABLE public.v_produccion_diaria OWNER TO postgres;

--
-- Name: v_tratamientos_pendientes; Type: VIEW; Schema: public; Owner: postgres
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


ALTER TABLE public.v_tratamientos_pendientes OWNER TO postgres;

--
-- Name: v_vacas_en_retirada; Type: VIEW; Schema: public; Owner: postgres
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


ALTER TABLE public.v_vacas_en_retirada OWNER TO postgres;

--
-- Name: zonas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zonas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nombre character varying(100) NOT NULL,
    codigo character varying(30) NOT NULL,
    descripcion text,
    tiene_pantalla_tv boolean DEFAULT false NOT NULL,
    tiene_tablet boolean DEFAULT false NOT NULL
);


ALTER TABLE public.zonas OWNER TO postgres;

--
-- Name: TABLE zonas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.zonas IS '5 zonas con pantalla TV informativa y tablet interactiva.';


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: datos_metereologicos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datos_metereologicos ALTER COLUMN id SET DEFAULT nextval('public.datos_metereologicos_id_seq'::regclass);


--
-- Data for Name: alertas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alertas (id, umbral_id, nivel, titulo, mensaje, origen_tabla, origen_id, animal_id, zona_id, push_whatsapp, pantalla_tv, tablet, activa, ts_generacion, ts_resolucion, resuelta_por) FROM stdin;
ee3122d5-e023-448d-8fd7-b6e670a26c0e	3f706da8-7370-463a-82e5-7a01f86be77f	alta	[DEMO] Animal sin ordeñar en última sesión	Alerta generada por simulador demo. Nivel: alta.	\N	\N	b5297515-9959-455e-86e4-30052372eddd	\N	f	t	t	t	2026-05-18 16:16:23.794412+00	\N	\N
095f0504-585f-488b-b164-e24e98e86286	2372fdbc-a691-4872-a7d1-ddee17ac163d	alta	[DEMO] Tarea de ordeño retrasada más de 2h	Alerta generada por simulador demo. Nivel: alta.	\N	\N	\N	df0512cb-3963-4225-97dd-242b835a8118	f	t	t	t	2026-05-22 20:16:23.795131+00	\N	\N
254e5b71-ffb3-4ad0-94ed-0c96066aae12	3f706da8-7370-463a-82e5-7a01f86be77f	alta	[DEMO] Tratamiento no administrado hoy	Alerta generada por simulador demo. Nivel: alta.	\N	\N	f65f94d5-2741-4946-acbe-97a2132c0563	\N	f	t	t	f	2026-05-24 09:16:23.795973+00	2026-05-24 12:16:23.795973+00	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f
197b2226-ec1b-4892-9849-366d1e7aba48	\N	baja	[DEMO] Mantenimiento preventivo robot próximo	Alerta generada por simulador demo. Nivel: baja.	\N	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	f	t	t	t	2026-05-28 22:16:23.797584+00	\N	\N
005fae36-2755-411c-90c3-014df1277896	fd70145f-8744-4baa-bca6-4f568f459b95	media	[DEMO] Retraso inicio ordeño turno tarde	Alerta generada por simulador demo. Nivel: media.	\N	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	f	t	t	f	2026-05-19 19:16:23.798143+00	2026-05-21 18:16:23.798143+00	513ad92d-a581-4d5b-b01e-7b3654f4482c
eae1899d-ead0-4a66-8897-89cdffed8b27	2372fdbc-a691-4872-a7d1-ddee17ac163d	baja	[DEMO] Recordatorio protocolo bioseguridad	Alerta generada por simulador demo. Nivel: baja.	\N	\N	92d13248-9188-43d4-92fe-2bacb22565d2	\N	f	t	t	f	2026-05-23 08:16:23.79867+00	2026-05-23 18:16:23.79867+00	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37
072629f4-644f-46d0-a169-c673f693d572	cd5e9282-f5a8-46ad-9e7a-a65fa159e6bd	media	[DEMO] Bebedero sin actividad zona becerrero	Alerta generada por simulador demo. Nivel: media.	\N	\N	c6f4a608-54b2-4ca8-affe-0a2e4d360399	\N	f	t	t	f	2026-05-18 15:16:23.799208+00	2026-05-20 15:16:23.799208+00	7f75e608-6c5b-429b-a36f-a644cc41501b
46c56182-4258-4505-9887-fd1743d9caea	\N	baja	[DEMO] Revisión mensual programación pendiente	Alerta generada por simulador demo. Nivel: baja.	\N	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	f	t	t	f	2026-05-21 04:16:23.79981+00	2026-05-22 16:16:23.79981+00	7f75e608-6c5b-429b-a36f-a644cc41501b
b4dc97bc-614f-4c03-932c-f886348f86b4	\N	alta	[DEMO] Tarea de ordeño retrasada más de 2h	Alerta generada por simulador demo. Nivel: alta.	\N	\N	3ee55362-8374-452c-ac80-5a93545bab2a	\N	f	t	t	t	2026-05-27 18:16:23.801794+00	\N	\N
67c76a6a-6a7f-44e6-8a6b-02d7a25b5dd5	fd70145f-8744-4baa-bca6-4f568f459b95	alta	[DEMO] RCS estimado supera umbral	Alerta generada por simulador demo. Nivel: alta.	\N	\N	fdd7b753-1eb4-401a-a7d0-edc697de625d	\N	f	t	t	t	2026-05-25 11:16:23.802214+00	\N	\N
e65ae040-3471-4a67-9241-99876c440735	3f706da8-7370-463a-82e5-7a01f86be77f	media	[DEMO] Bebedero sin actividad zona becerrero	Alerta generada por simulador demo. Nivel: media.	\N	\N	d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	\N	f	t	t	t	2026-05-17 20:16:23.803203+00	\N	\N
960d7c93-7f47-494d-9b03-f7b92a6649a0	b609d813-0583-426e-96b6-b97ee9ad6bdf	media	[DEMO] Desviación ración TMR detectada	Alerta generada por simulador demo. Nivel: media.	\N	\N	92d13248-9188-43d4-92fe-2bacb22565d2	\N	f	t	t	t	2026-05-19 16:16:23.80393+00	\N	\N
523cc2af-fb5f-4900-aebd-81e810d39c94	3f706da8-7370-463a-82e5-7a01f86be77f	alta	[DEMO] Animal sin ordeñar en última sesión	Alerta generada por simulador demo. Nivel: alta.	\N	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	f	t	t	t	2026-05-22 13:16:23.804391+00	\N	\N
f4b45bdf-33b2-443c-a2f2-6dd91ec82472	\N	media	[DEMO] Bebedero sin actividad zona becerrero	Alerta generada por simulador demo. Nivel: media.	\N	\N	\N	3836de7c-0b6f-4306-904d-825890b6f534	f	t	t	f	2026-05-23 05:16:23.804911+00	2026-05-23 12:16:23.804911+00	30b40a49-5e28-4ce5-acbb-df297a52e509
65139790-ff3b-4ede-bce7-eca02d33bf52	cd5e9282-f5a8-46ad-9e7a-a65fa159e6bd	media	[DEMO] Temperatura animal fuera de rango	Alerta generada por simulador demo. Nivel: media.	\N	\N	387e0bea-4d9a-40cc-a4f0-ac21503f93a8	\N	f	t	t	t	2026-05-18 00:16:23.805406+00	\N	\N
5cceeeef-4a09-42cb-8451-c7394992a574	bbb168ea-ba33-4aa1-b9ce-0bf9649a7f60	baja	[DEMO] Revisión mensual programación pendiente	Alerta generada por simulador demo. Nivel: baja.	\N	\N	2c611aa8-a92c-4556-8568-9294bab47d5d	\N	f	t	t	t	2026-05-27 14:16:23.805874+00	\N	\N
e210a3fe-aedb-4ebc-a800-7645db78df67	2372fdbc-a691-4872-a7d1-ddee17ac163d	alta	[DEMO] Animal sin ordeñar en última sesión	Alerta generada por simulador demo. Nivel: alta.	\N	\N	4047b88d-66c2-4192-8429-4eca6b5ff44f	\N	f	t	t	f	2026-05-14 20:16:23.800366+00	2026-05-29 12:24:24.156495+00	60da9a93-e0f2-403b-a534-e35383483df5
69679c0b-78d7-4709-b4d1-e162bfe8a0b1	\N	media	[DEMO] Desviación ración TMR detectada	Alerta generada por simulador demo. Nivel: media.	\N	\N	6d067c4b-3fca-414f-af92-76a0d5c7a813	\N	f	t	t	f	2026-05-14 21:16:23.800857+00	2026-05-29 12:24:44.212129+00	2d200ce2-5f48-4285-8d33-98f06db5b194
1dfbab76-0d39-4d77-b786-6e2db8f4445a	\N	media	[DEMO] Retraso inicio ordeño turno tarde	Alerta simulada. Nivel: media.	\N	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	f	t	t	t	2026-05-29 12:27:44.735106+00	\N	\N
ef403569-6ff3-4937-ba2a-fd45ec93d030	\N	alta	[DEMO] Tratamiento no administrado hoy	Alerta simulada. Nivel: alta.	\N	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	f	t	t	t	2026-05-29 12:29:04.924171+00	\N	\N
4d8649b4-39b5-4c0a-9300-0cfb1e33f32f	3f706da8-7370-463a-82e5-7a01f86be77f	media	[DEMO] Desviación ración TMR detectada	Alerta generada por simulador demo. Nivel: media.	\N	\N	b5297515-9959-455e-86e4-30052372eddd	\N	f	t	t	f	2026-05-15 00:16:23.796863+00	2026-05-29 12:29:45.031361+00	2d200ce2-5f48-4285-8d33-98f06db5b194
224ceaf5-ddac-47a1-8675-89bb5ad8766d	\N	alta	[DEMO] RCS estimado supera umbral	Alerta simulada. Nivel: alta.	\N	\N	\N	3836de7c-0b6f-4306-904d-825890b6f534	f	t	t	t	2026-05-29 12:31:05.185105+00	\N	\N
c3ed506e-bc8f-472c-9d26-62a05e3a4552	\N	media	[DEMO] Bebedero sin actividad zona becerrero	Alerta generada por simulador demo. Nivel: media.	\N	\N	\N	df0512cb-3963-4225-97dd-242b835a8118	f	t	t	f	2026-05-15 21:16:23.801319+00	2026-05-29 12:31:45.417303+00	c133cc24-f15a-4522-ad43-cc62e4a0283a
2622ea3d-152e-47f9-8072-c91df44e4900	\N	media	[DEMO] Temperatura animal fuera de rango	Alerta generada por simulador demo. Nivel: media.	\N	\N	6d067c4b-3fca-414f-af92-76a0d5c7a813	\N	f	t	t	f	2026-05-16 01:16:23.802777+00	2026-05-29 12:32:05.485929+00	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f
36e3f26a-9d8b-4ca3-a33e-ab02532dc04e	bbb168ea-ba33-4aa1-b9ce-0bf9649a7f60	alta	[DEMO] RCS estimado supera umbral	Alerta generada por simulador demo. Nivel: alta.	\N	\N	ab618b25-84fa-4e28-a07d-20ac6e868648	\N	f	t	t	f	2026-05-17 11:16:23.791963+00	2026-05-29 12:32:45.614556+00	c319a64d-36f2-4c7b-a4e2-e61f08b36d28
36b8653b-4554-4b9b-9958-eb4a41d47802	\N	media	[DEMO] Bebedero sin actividad zona becerrero	Alerta simulada. Nivel: media.	\N	\N	\N	3836de7c-0b6f-4306-904d-825890b6f534	f	t	t	t	2026-05-29 12:33:05.670934+00	\N	\N
\.


--
-- Data for Name: alertas_umbrales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alertas_umbrales (id, codigo, descripcion, metrica, operador, valor_umbral, unidad, nivel_alerta, push_whatsapp, pantalla_tv, tablet, activo, notas) FROM stdin;
b609d813-0583-426e-96b6-b97ee9ad6bdf	scc_alto	SCC estimado supera umbral de calidad	scc	>	250000.0000	cel/ml	alta	t	t	t	t	\N
cd5e9282-f5a8-46ad-9e7a-a65fa159e6bd	tarea_vencida	Tarea no completada transcurridas más de 2 horas de su hora planificada	minutos_retraso_tarea	>	120.0000	min	alta	t	t	t	t	\N
bbb168ea-ba33-4aa1-b9ce-0bf9649a7f60	tratamiento_no_dado	Administración de tratamiento activo no registrada en el día	checkboxes_pendientes	>	0.0000	und	alta	t	t	t	t	\N
2372fdbc-a691-4872-a7d1-ddee17ac163d	retraso_ordeno	Retraso en el inicio del ordeño respecto a hora planificada	minutos_retraso_ordeno	>	0.0000	min	media	f	t	t	t	\N
fd70145f-8744-4baa-bca6-4f568f459b95	desviacion_tmr	Desviación de la ración TMR superior al 5%	desviacion_pct_tmr	>	5.0000	%	media	f	t	t	t	\N
3f706da8-7370-463a-82e5-7a01f86be77f	recordatorio_protocolo	Recordatorio de protocolo periódico	protocolo_pendiente	>	0.0000	und	baja	f	t	f	t	\N
6eb44a57-02b6-4bf3-949b-45d061f8f0e3	estado_meteo	Información de estado meteorológico para pantalla TV	info_meteo	=	1.0000	\N	baja	f	t	f	t	\N
\.


--
-- Data for Name: animales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.animales (id, crotal_oficial, nombre, sexo, fecha_nacimiento, raza, estado, estado_reproductivo, madre_id, fecha_entrada, fecha_baja, motivo_baja, notas) FROM stdin;
e4d3741d-b1e6-4cae-9a1c-69dcd04c2302	DEM-0001	\N	hembra	2019-10-03	Jersey	produccion	vacia	\N	2019-10-12	\N	\N	[DEMO]
2ced7c23-acf4-43d7-9bac-af6d0158d58c	DEM-0002	\N	hembra	2023-07-14	Cruce Frisona-Jersey	produccion	en_celo	\N	2023-08-06	\N	\N	[DEMO]
6d067c4b-3fca-414f-af92-76a0d5c7a813	DEM-0003	\N	hembra	2021-07-24	Frisona	produccion	inseminada	\N	2021-08-06	\N	\N	[DEMO]
c0f7d046-4899-43d4-86dc-11d64560e316	DEM-0004	\N	hembra	2021-09-22	Frisona	produccion	en_celo	\N	2021-10-18	\N	\N	[DEMO]
454f410f-48c2-42b2-be0f-2ebfef72e1f7	DEM-0005	\N	hembra	2025-11-30	Cruce Frisona-Jersey	recria	\N	\N	2025-11-30	\N	\N	[DEMO]
0cc26162-5744-4617-8a37-65274b54c48d	DEM-0006	\N	hembra	2020-06-29	Frisona	seca	vacia	\N	2020-07-12	\N	\N	[DEMO]
11218539-9457-40cc-a87c-6d1ea5a52534	DEM-0007	\N	hembra	2021-09-22	Frisona	produccion	confirmada_gestante	\N	2021-10-06	\N	\N	[DEMO]
32cfcf51-5267-4df9-860e-550a35e8b7a4	DEM-0008	\N	hembra	2025-01-04	Jersey	recria	\N	\N	2025-01-04	\N	\N	[DEMO]
a8900363-371e-4e16-a58f-cc9659f7b99e	DEM-0009	\N	hembra	2025-06-03	Frisona	recria	\N	\N	2025-06-03	\N	\N	[DEMO]
d58dab0c-ba97-4376-93e1-baf6fffe87ee	DEM-0010	\N	hembra	2019-01-06	Cruce Frisona-Jersey	produccion	en_celo	\N	2019-01-28	\N	\N	[DEMO]
b5c59f11-f0ae-4477-92f7-6ebc9942f491	DEM-0011	\N	hembra	2021-09-22	Jersey	produccion	inseminada	\N	2021-10-10	\N	\N	[DEMO]
929630b3-dc54-475d-a50f-e2ad377f0fe8	DEM-0012	\N	hembra	2023-05-15	Frisona	gestante	confirmada_gestante	\N	2023-05-16	\N	\N	[DEMO]
b02ad120-19ba-4491-8ae5-df9672ece6e6	DEM-0013	\N	hembra	2023-02-14	Frisona	produccion	confirmada_gestante	\N	2023-03-05	\N	\N	[DEMO]
4047b88d-66c2-4192-8429-4eca6b5ff44f	DEM-0014	\N	hembra	2023-07-14	Jersey	produccion	vacia	\N	2023-08-04	\N	\N	[DEMO]
9b00f292-af6e-488b-8a37-7795bf2f3cca	DEM-0015	\N	hembra	2026-01-29	Cruce Frisona-Jersey	recria	\N	\N	2026-01-29	\N	\N	[DEMO]
2ecf6665-0c82-488d-9749-7941de974abf	DEM-0016	\N	hembra	2023-11-11	Jersey	seca	vacia	\N	2023-12-09	\N	\N	[DEMO]
482ca314-084c-4f01-aef1-7d2bc8cb37ff	DEM-0017	\N	hembra	2018-09-08	Frisona	produccion	inseminada	\N	2018-09-15	\N	\N	[DEMO]
1909c17b-0202-4563-aeb3-efdcce12c758	DEM-0018	\N	hembra	2022-05-20	Frisona	produccion	en_celo	\N	2022-05-29	\N	\N	[DEMO]
ab618b25-84fa-4e28-a07d-20ac6e868648	DEM-0019	\N	hembra	2023-12-11	Frisona	seca	vacia	\N	2023-12-26	\N	\N	[DEMO]
f2113bfa-4f8c-4d26-9438-7349516eb5da	DEM-0020	\N	hembra	2021-02-24	Cruce Frisona-Jersey	produccion	vacia	\N	2021-03-08	\N	\N	[DEMO]
fd456222-89c9-496b-84d8-ccd28a054320	DEM-0021	\N	hembra	2024-12-05	Jersey	recria	\N	\N	2024-12-05	\N	\N	[DEMO]
003a9fe9-e4a0-447f-bcdb-57439cd5e412	DEM-0022	\N	hembra	2021-07-24	Jersey	gestante	parto_reciente	\N	2021-08-13	\N	\N	[DEMO]
b5297515-9959-455e-86e4-30052372eddd	DEM-0023	\N	hembra	2019-11-02	Cruce Frisona-Jersey	produccion	vacia	\N	2019-11-21	\N	\N	[DEMO]
663aec4c-0d3d-496e-8da9-75425e7abb42	DEM-0024	\N	hembra	2022-08-18	Frisona	seca	vacia	\N	2022-08-22	\N	\N	[DEMO]
754c21c2-5528-4fe0-b94b-078ab53ba4f7	DEM-0025	\N	hembra	2023-02-14	Frisona	seca	vacia	\N	2023-02-16	\N	\N	[DEMO]
c1b81c70-506f-4989-95f8-1f271f5a67e3	DEM-0026	\N	hembra	2025-08-02	Jersey	recria	\N	\N	2025-08-02	\N	\N	[DEMO]
bd1f7206-4b66-4801-aa4b-6979be8bcb5f	DEM-0027	\N	hembra	2021-08-23	Cruce Frisona-Jersey	produccion	confirmada_gestante	\N	2021-09-21	\N	\N	[DEMO]
41098454-a4a4-45db-bc95-a2793218055b	DEM-0028	\N	hembra	2018-12-07	Jersey	seca	vacia	\N	2018-12-16	\N	\N	[DEMO]
6242a97b-f3b8-42f8-98fa-ab92058599ee	DEM-0029	\N	hembra	2021-07-24	Jersey	gestante	confirmada_gestante	\N	2021-08-17	\N	\N	[DEMO]
c0d6060f-b696-49b3-8a78-0de2f71826b0	DEM-0030	\N	hembra	2022-10-17	Frisona	produccion	inseminada	\N	2022-11-08	\N	\N	[DEMO]
6d743a75-3b83-454f-91eb-76bfb4439dd9	DEM-0031	\N	hembra	2019-03-07	Jersey	seca	confirmada_gestante	\N	2019-03-30	\N	\N	[DEMO]
f6f18149-270e-4c85-871a-96c00cb9ae2b	DEM-0032	\N	hembra	2021-03-26	Jersey	produccion	en_celo	\N	2021-04-19	\N	\N	[DEMO]
0d88dbf9-bce8-4dbf-bbb1-c728ee8caab2	DEM-0033	\N	hembra	2022-06-19	Jersey	produccion	en_celo	\N	2022-06-26	\N	\N	[DEMO]
506a81f0-17b8-4482-afae-3f4ac8e77892	DEM-0034	\N	hembra	2025-03-05	Frisona	recria	\N	\N	2025-03-05	\N	\N	[DEMO]
7ee50ae4-fd81-4002-ba07-9705968830d1	DEM-0035	\N	hembra	2022-10-17	Frisona	produccion	en_celo	\N	2022-10-31	\N	\N	[DEMO]
b17e7d41-51a7-4950-b1d4-fd3625e19b2f	DEM-0036	\N	hembra	2024-12-05	Cruce Frisona-Jersey	recria	\N	\N	2024-12-05	\N	\N	[DEMO]
836b7685-ad7c-48c5-aa09-f54590e75701	DEM-0037	\N	hembra	2022-09-17	Cruce Frisona-Jersey	seca	vacia	\N	2022-10-03	\N	\N	[DEMO]
d0ba5459-2ca0-4742-8bc9-ee3ecdf27f8d	DEM-0038	\N	hembra	2018-11-07	Frisona	produccion	confirmada_gestante	\N	2018-11-09	\N	\N	[DEMO]
92d13248-9188-43d4-92fe-2bacb22565d2	DEM-0039	\N	hembra	2019-03-07	Frisona	gestante	parto_reciente	\N	2019-03-27	\N	\N	[DEMO]
c6f4a608-54b2-4ca8-affe-0a2e4d360399	DEM-0040	\N	hembra	2023-11-11	Frisona	produccion	inseminada	\N	2023-11-28	\N	\N	[DEMO]
52be2f26-d802-4b14-ae5b-dcb306089bdc	DEM-0041	\N	hembra	2019-09-03	Frisona	produccion	en_celo	\N	2019-09-19	\N	\N	[DEMO]
14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5	DEM-0042	\N	hembra	2023-03-16	Frisona	seca	confirmada_gestante	\N	2023-03-30	\N	\N	[DEMO]
4ead6660-3efa-49c0-8ec2-6fad9e1aef40	DEM-0043	\N	hembra	2025-02-03	Frisona	recria	\N	\N	2025-02-03	\N	\N	[DEMO]
26f29af8-4eb8-4aa2-aaae-3bfce1c4839b	DEM-0044	\N	hembra	2020-04-30	Jersey	produccion	en_celo	\N	2020-05-23	\N	\N	[DEMO]
d06cd495-106f-4ab5-b661-bf0627247b78	DEM-0045	\N	hembra	2022-05-20	Frisona	baja	\N	\N	2022-06-12	2026-02-09	Accidente	[DEMO]
49b61755-8934-44da-9065-3ccaa355d5db	DEM-0046	\N	hembra	2020-08-28	Jersey	produccion	en_celo	\N	2020-09-13	\N	\N	[DEMO]
3ee55362-8374-452c-ac80-5a93545bab2a	DEM-0047	\N	hembra	2021-07-24	Frisona	seca	confirmada_gestante	\N	2021-08-17	\N	\N	[DEMO]
d1762cb2-302a-4dd7-97df-934978bad2bc	DEM-0048	\N	hembra	2020-11-26	Frisona	produccion	vacia	\N	2020-12-05	\N	\N	[DEMO]
1ef34732-92bc-47c3-896c-d5ef65704b1d	DEM-0049	\N	hembra	2022-07-19	Frisona	seca	confirmada_gestante	\N	2022-07-20	\N	\N	[DEMO]
26d26b4b-30bb-4860-9c60-15c5ddcb244c	DEM-0050	\N	hembra	2022-03-21	Frisona	produccion	inseminada	\N	2022-04-17	\N	\N	[DEMO]
6b02089e-b0dc-40cf-a70c-a0fd1f9f407f	DEM-0051	\N	hembra	2019-04-06	Frisona	produccion	inseminada	\N	2019-04-10	\N	\N	[DEMO]
5f6a9e48-7748-4a42-be2b-3fbaed701adc	DEM-0052	\N	hembra	2023-06-14	Frisona	gestante	confirmada_gestante	\N	2023-06-16	\N	\N	[DEMO]
d1ebde4a-8a42-4cd3-8762-e5317430d542	DEM-0053	\N	hembra	2025-05-04	Frisona	recria	\N	\N	2025-05-04	\N	\N	[DEMO]
a4fd9a5f-764a-4193-836f-3b3fdc11873b	DEM-0054	\N	hembra	2026-03-30	Cruce Frisona-Jersey	recria	\N	\N	2026-03-30	\N	\N	[DEMO]
0e161c89-fa5d-48ce-b985-0ba8cee7482d	DEM-0055	\N	hembra	2019-03-07	Frisona	produccion	confirmada_gestante	\N	2019-03-31	\N	\N	[DEMO]
299618a7-5c8b-4ed3-a6fa-5280adffe5e2	DEM-0056	\N	hembra	2020-03-31	Jersey	seca	vacia	\N	2020-04-22	\N	\N	[DEMO]
fdd7b753-1eb4-401a-a7d0-edc697de625d	DEM-0057	\N	hembra	2023-11-11	Frisona	produccion	confirmada_gestante	\N	2023-12-11	\N	\N	[DEMO]
74ba687b-d88d-4950-abbc-6c11988c464b	DEM-0058	\N	hembra	2026-01-29	Frisona	recria	\N	\N	2026-01-29	\N	\N	[DEMO]
60617164-bf9a-4125-b9f2-97603d14e2f8	DEM-0059	\N	hembra	2021-09-22	Frisona	seca	confirmada_gestante	\N	2021-09-25	\N	\N	[DEMO]
511a43e4-da3e-4ebb-a40f-554774f79dc1	DEM-0060	\N	hembra	2022-07-19	Cruce Frisona-Jersey	produccion	inseminada	\N	2022-07-26	\N	\N	[DEMO]
b93dabf3-c815-4e61-af0e-b441ae2b0a46	DEM-0061	\N	hembra	2019-04-06	Frisona	produccion	en_celo	\N	2019-04-19	\N	\N	[DEMO]
e1e1ba00-6b9e-42b0-ad38-557ead469163	DEM-0062	\N	hembra	2026-02-28	Jersey	recria	\N	\N	2026-02-28	\N	\N	[DEMO]
7893dd48-7944-44bf-8d90-ff51288993fd	DEM-0063	\N	hembra	2020-11-26	Cruce Frisona-Jersey	produccion	vacia	\N	2020-12-16	\N	\N	[DEMO]
bca99578-d4de-422a-b04f-1ae3da4d3b43	DEM-0064	\N	hembra	2021-05-25	Frisona	gestante	confirmada_gestante	\N	2021-06-06	\N	\N	[DEMO]
58fb05ea-fd35-4a8d-838c-8d7fa5f58653	DEM-0065	\N	hembra	2020-11-26	Cruce Frisona-Jersey	produccion	en_celo	\N	2020-12-08	\N	\N	[DEMO]
3b265584-42f8-44e0-a098-59a2cae3d2db	DEM-0066	\N	hembra	2022-12-16	Jersey	produccion	confirmada_gestante	\N	2022-12-31	\N	\N	[DEMO]
7d13f564-6ae2-4d35-9d0e-83408643e6bd	DEM-0067	\N	hembra	2019-11-02	Frisona	seca	confirmada_gestante	\N	2019-11-25	\N	\N	[DEMO]
acb096b0-83a9-4575-b0e3-260d5a80ee54	DEM-0068	\N	hembra	2021-01-25	Cruce Frisona-Jersey	produccion	vacia	\N	2021-02-17	\N	\N	[DEMO]
dda0bd71-8c75-4eda-a9e0-a5ec640c2645	DEM-0069	\N	hembra	2019-06-05	Cruce Frisona-Jersey	produccion	confirmada_gestante	\N	2019-06-05	\N	\N	[DEMO]
6ed12cf0-d9ad-4896-a0f9-40a2ead7d4a5	DEM-0070	\N	hembra	2025-04-04	Jersey	recria	\N	\N	2025-04-04	\N	\N	[DEMO]
0765dd1d-c2aa-4087-8fb9-6cf783266edb	DEM-0071	\N	hembra	2022-01-20	Frisona	gestante	parto_reciente	\N	2022-01-26	\N	\N	[DEMO]
c07a25a5-8117-4270-8fe9-aaf73a253071	DEM-0072	\N	hembra	2020-03-01	Frisona	produccion	inseminada	\N	2020-03-15	\N	\N	[DEMO]
0d62ba03-2611-452d-bf34-3a0934bee5f4	DEM-0073	\N	hembra	2023-05-15	Jersey	produccion	en_celo	\N	2023-06-12	\N	\N	[DEMO]
387e0bea-4d9a-40cc-a4f0-ac21503f93a8	DEM-0074	\N	hembra	2021-04-25	Frisona	produccion	en_celo	\N	2021-05-02	\N	\N	[DEMO]
6fc5a4de-7cd0-41a6-a58a-6b21b719f1a7	DEM-0075	\N	hembra	2018-12-07	Cruce Frisona-Jersey	produccion	vacia	\N	2018-12-20	\N	\N	[DEMO]
7bf86988-01c6-4cd5-b116-80dfde1277c1	DEM-0076	\N	hembra	2018-07-10	Frisona	produccion	inseminada	\N	2018-07-29	\N	\N	[DEMO]
87fb22d7-4391-4404-b641-dff004bed87f	DEM-0077	\N	hembra	2019-10-03	Cruce Frisona-Jersey	seca	vacia	\N	2019-10-29	\N	\N	[DEMO]
d095654e-d0e8-4540-82f1-c2085332850b	DEM-0078	\N	hembra	2026-04-29	Frisona	recria	\N	\N	2026-04-29	\N	\N	[DEMO]
d2ae0d6c-62cd-450e-a104-7ee7f7320480	DEM-0079	\N	hembra	2018-08-09	Frisona	seca	vacia	\N	2018-08-11	\N	\N	[DEMO]
47503ce1-adab-4a8f-a942-bee77c0dabdc	DEM-0080	\N	hembra	2021-10-22	Frisona	produccion	en_celo	\N	2021-11-17	\N	\N	[DEMO]
a345a474-de66-4499-be25-1f4604108ce7	DEM-0081	\N	hembra	2020-09-27	Cruce Frisona-Jersey	produccion	confirmada_gestante	\N	2020-10-27	\N	\N	[DEMO]
608f6c8d-8d57-4abe-8b78-946a32c6a037	DEM-0082	\N	hembra	2021-07-24	Jersey	produccion	en_celo	\N	2021-08-05	\N	\N	[DEMO]
561c4988-c9c5-49d7-8b6e-72a186c342b1	DEM-0083	\N	hembra	2025-10-01	Cruce Frisona-Jersey	recria	\N	\N	2025-10-01	\N	\N	[DEMO]
80c0ec2f-41c9-43e4-a2db-11f0ba7c790d	DEM-0084	\N	hembra	2023-04-15	Frisona	produccion	vacia	\N	2023-04-23	\N	\N	[DEMO]
2eff0653-a8aa-4b79-8a80-8c5bed9233f3	DEM-0085	\N	hembra	2019-09-03	Frisona	produccion	confirmada_gestante	\N	2019-10-02	\N	\N	[DEMO]
f54a614e-2dec-49ea-a29c-1f654d0f77bb	DEM-0086	\N	hembra	2018-11-07	Frisona	produccion	inseminada	\N	2018-11-23	\N	\N	[DEMO]
8485de9f-b75c-41cc-95c4-0fa4926b9987	DEM-0087	\N	hembra	2021-08-23	Cruce Frisona-Jersey	produccion	confirmada_gestante	\N	2021-09-06	\N	\N	[DEMO]
f65f94d5-2741-4946-acbe-97a2132c0563	DEM-0088	\N	hembra	2020-05-30	Jersey	produccion	en_celo	\N	2020-06-24	\N	\N	[DEMO]
eb67de13-28c1-4394-9f31-a1e3406ca176	DEM-0089	\N	hembra	2025-12-30	Frisona	recria	\N	\N	2025-12-30	\N	\N	[DEMO]
fb7fa4dd-669e-48b6-89e4-757b694f5b07	DEM-0090	\N	hembra	2021-05-25	Cruce Frisona-Jersey	produccion	inseminada	\N	2021-06-16	\N	\N	[DEMO]
62f76f1d-c125-423a-9592-328be33a4b37	DEM-0091	\N	hembra	2020-11-26	Jersey	produccion	vacia	\N	2020-12-10	\N	\N	[DEMO]
43c99312-c53e-478f-bb81-3302148f7c23	DEM-0092	\N	hembra	2021-05-25	Frisona	produccion	inseminada	\N	2021-06-12	\N	\N	[DEMO]
bdfc9cf7-e471-44a1-98d5-702c6f484a73	DEM-0093	\N	hembra	2023-10-12	Frisona	produccion	confirmada_gestante	\N	2023-10-26	\N	\N	[DEMO]
b977bad8-5e76-4ff5-86c6-d22021c984c7	DEM-0094	\N	hembra	2019-11-02	Frisona	produccion	inseminada	\N	2019-11-20	\N	\N	[DEMO]
66cf9283-9e0b-48f2-8b8f-9687bf6dfe99	DEM-0095	\N	hembra	2022-12-16	Cruce Frisona-Jersey	baja	\N	\N	2022-12-16	2026-04-17	Problema reproductivo	[DEMO]
d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	DEM-0096	\N	hembra	2019-11-02	Cruce Frisona-Jersey	seca	vacia	\N	2019-11-10	\N	\N	[DEMO]
9d2f8668-e36c-4578-81d6-001ada65572e	DEM-0097	\N	hembra	2019-03-07	Frisona	seca	confirmada_gestante	\N	2019-03-16	\N	\N	[DEMO]
1a845209-5c9d-4833-a874-f20e1fc49d54	DEM-0098	\N	hembra	2022-06-19	Cruce Frisona-Jersey	produccion	inseminada	\N	2022-07-19	\N	\N	[DEMO]
f888e29c-efcf-4c60-995a-d9279f958103	DEM-0099	\N	hembra	2024-12-05	Frisona	recria	\N	\N	2024-12-05	\N	\N	[DEMO]
86892057-2f7f-478f-bbcb-61110313ffd9	DEM-0100	\N	hembra	2022-08-18	Jersey	produccion	en_celo	\N	2022-09-15	\N	\N	[DEMO]
6381dfbb-7d0b-4360-ba02-62e5dd932437	DEM-0101	\N	hembra	2025-11-30	Frisona	recria	\N	\N	2025-11-30	\N	\N	[DEMO]
594223a0-9f8a-498e-8487-424895a3d0b0	DEM-0102	\N	hembra	2019-06-05	Jersey	produccion	confirmada_gestante	\N	2019-06-26	\N	\N	[DEMO]
4f921cd6-0fc9-4628-a46d-8ff93466e82c	DEM-0103	\N	hembra	2023-09-12	Frisona	produccion	inseminada	\N	2023-09-23	\N	\N	[DEMO]
f664da5c-e84f-4de3-abe2-954a07871fae	DEM-0104	\N	hembra	2018-12-07	Jersey	gestante	confirmada_gestante	\N	2019-01-02	\N	\N	[DEMO]
ff998675-ed1e-4229-aab0-3d86147177c2	DEM-0105	\N	hembra	2023-02-14	Frisona	produccion	inseminada	\N	2023-03-04	\N	\N	[DEMO]
edcb3743-9a2c-455e-84d2-b68d69c83fbb	DEM-0106	\N	hembra	2025-05-04	Jersey	recria	\N	\N	2025-05-04	\N	\N	[DEMO]
ee9d5c30-3592-449b-b211-9a1e1add7685	DEM-0107	\N	hembra	2025-01-04	Frisona	recria	\N	\N	2025-01-04	\N	\N	[DEMO]
9fcc4de5-8fec-4f04-85ea-57963cba6119	DEM-0108	\N	hembra	2019-01-06	Cruce Frisona-Jersey	gestante	parto_reciente	\N	2019-01-23	\N	\N	[DEMO]
2c611aa8-a92c-4556-8568-9294bab47d5d	DEM-0109	\N	hembra	2022-02-19	Jersey	produccion	confirmada_gestante	\N	2022-03-16	\N	\N	[DEMO]
9c643bba-a6d5-40c8-b023-f781c9763028	DEM-0110	\N	hembra	2023-06-14	Frisona	produccion	inseminada	\N	2023-07-02	\N	\N	[DEMO]
c78d9927-66e8-4aee-8e04-b83ec129c31d	DEM-0111	\N	hembra	2022-05-20	Frisona	produccion	confirmada_gestante	\N	2022-06-06	\N	\N	[DEMO]
c659f4da-3f7d-46e7-8993-0536c9640c3d	DEM-0112	\N	hembra	2019-05-06	Frisona	produccion	confirmada_gestante	\N	2019-05-11	\N	\N	[DEMO]
f530bb0a-99a5-420f-9e18-6cb1dbd1973e	DEM-0113	\N	hembra	2021-06-24	Cruce Frisona-Jersey	produccion	confirmada_gestante	\N	2021-07-06	\N	\N	[DEMO]
6784e799-962c-4527-b86a-c96905fff757	DEM-0114	\N	hembra	2023-08-13	Frisona	produccion	confirmada_gestante	\N	2023-08-18	\N	\N	[DEMO]
24aaa09d-d02d-470e-a6c9-33f1559eee31	DEM-0115	\N	hembra	2025-06-03	Frisona	recria	\N	\N	2025-06-03	\N	\N	[DEMO]
002ec462-63a3-4b84-b040-e153b51b3dde	DEM-0116	\N	hembra	2025-01-04	Jersey	recria	\N	\N	2025-01-04	\N	\N	[DEMO]
0cf23273-77eb-459b-abc4-d9475392e8af	DEM-0117	\N	hembra	2018-12-07	Jersey	gestante	parto_reciente	\N	2018-12-15	\N	\N	[DEMO]
121e0d34-5536-4a93-948b-d9581d928d3d	DEM-0118	\N	hembra	2021-09-22	Jersey	produccion	en_celo	\N	2021-10-19	\N	\N	[DEMO]
129b3aee-511f-4fa5-b8a4-f71b8e8faacb	DEM-0119	\N	hembra	2026-04-29	Cruce Frisona-Jersey	recria	\N	\N	2026-04-29	\N	\N	[DEMO]
a58bf738-0ced-454e-a89e-779af50bdde6	DEM-0120	\N	hembra	2021-09-22	Frisona	produccion	vacia	\N	2021-10-16	\N	\N	[DEMO]
\.


--
-- Data for Name: asignaciones_turno; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.asignaciones_turno (id, turno_id, empleado_id, zona_id, rol) FROM stdin;
d6800d63-103b-4fb3-9da4-990a763dbe6a	339bc962-3dc2-46a3-b6aa-470b4fe83215	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
26dc7001-3ac6-4e9d-8f41-e2c29956267f	339bc962-3dc2-46a3-b6aa-470b4fe83215	60da9a93-e0f2-403b-a534-e35383483df5	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
2e08526f-85cb-4f8b-baec-cf6bcd783b75	339bc962-3dc2-46a3-b6aa-470b4fe83215	30b40a49-5e28-4ce5-acbb-df297a52e509	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
59b50d6e-81ec-4187-86d1-1cb98f6776f9	d345ccb9-ce5e-44d9-8884-3520023fecb0	513ad92d-a581-4d5b-b01e-7b3654f4482c	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
f30d8f15-fc60-41c1-956c-5f58307ee59a	d345ccb9-ce5e-44d9-8884-3520023fecb0	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
a14f6904-b273-4cf2-a342-aad3f2753bf0	d345ccb9-ce5e-44d9-8884-3520023fecb0	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
8be3f0af-50fc-491f-9e93-80f63998f984	d345ccb9-ce5e-44d9-8884-3520023fecb0	43958ec8-b358-4c41-bb4c-9b55cacfc8db	df0512cb-3963-4225-97dd-242b835a8118	veterinario
df33dabe-cbce-4bcc-8efc-ea5f01255fcc	acc685f4-6f01-4ddb-987c-7e23c56b956a	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
582ced82-d1ea-4960-9d5d-6fa0659204ed	acc685f4-6f01-4ddb-987c-7e23c56b956a	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
4977c710-1e6b-4665-9502-3f1d9750282f	acc685f4-6f01-4ddb-987c-7e23c56b956a	513ad92d-a581-4d5b-b01e-7b3654f4482c	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
f721bb8a-e4dc-4b93-9c36-be197313fd01	acc685f4-6f01-4ddb-987c-7e23c56b956a	30b40a49-5e28-4ce5-acbb-df297a52e509	df0512cb-3963-4225-97dd-242b835a8118	veterinario
a8d4695e-40e4-4e7f-8f0e-68dd71e115c5	acc685f4-6f01-4ddb-987c-7e23c56b956a	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
3b5de9d3-2ff6-4f6c-b7d3-850ed212be6c	b62b0f67-a981-4870-af04-34e1138ae507	7f75e608-6c5b-429b-a36f-a644cc41501b	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
a161d817-fefb-4bdd-8804-907921ed5087	b62b0f67-a981-4870-af04-34e1138ae507	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
bb29797f-e62c-418c-8485-0bbf9d235262	b62b0f67-a981-4870-af04-34e1138ae507	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
04eb00bd-97f9-444e-8912-e29e438ef457	b62b0f67-a981-4870-af04-34e1138ae507	43958ec8-b358-4c41-bb4c-9b55cacfc8db	df0512cb-3963-4225-97dd-242b835a8118	veterinario
70642140-26af-4757-9769-dce599997e44	b62b0f67-a981-4870-af04-34e1138ae507	60da9a93-e0f2-403b-a534-e35383483df5	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
fe59a2e1-7ef4-4c0c-ae24-ae7644e5acce	e5631bcf-ed4d-49d4-a0f5-ffb8745975a5	60da9a93-e0f2-403b-a534-e35383483df5	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
4cb2ef6a-50a4-4088-a3a9-41ca00c4dcfb	e5631bcf-ed4d-49d4-a0f5-ffb8745975a5	30b40a49-5e28-4ce5-acbb-df297a52e509	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
3244b060-7162-4b8a-8f69-9cefde6c9ed7	e5631bcf-ed4d-49d4-a0f5-ffb8745975a5	2d200ce2-5f48-4285-8d33-98f06db5b194	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
27546a36-a992-4b59-be61-dcb504b91aae	e5631bcf-ed4d-49d4-a0f5-ffb8745975a5	c133cc24-f15a-4522-ad43-cc62e4a0283a	df0512cb-3963-4225-97dd-242b835a8118	veterinario
52c1799d-c63b-40fd-ac23-4e1281f5c951	ba261344-97be-4f10-b39a-3d424d3f59df	c133cc24-f15a-4522-ad43-cc62e4a0283a	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
f1915faa-9bb6-4af5-9952-22778b91624c	ba261344-97be-4f10-b39a-3d424d3f59df	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
6f901bb2-ef9e-4d81-8593-c68593ae4172	ba261344-97be-4f10-b39a-3d424d3f59df	513ad92d-a581-4d5b-b01e-7b3654f4482c	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
8d793da1-3918-4fef-8998-4feba6225735	ba261344-97be-4f10-b39a-3d424d3f59df	7f75e608-6c5b-429b-a36f-a644cc41501b	df0512cb-3963-4225-97dd-242b835a8118	veterinario
16a52bb6-a1ba-4148-8eed-93a36dddff34	b3d6328c-5b51-4f87-bff5-ec10552ebe8c	513ad92d-a581-4d5b-b01e-7b3654f4482c	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
14d47f5c-62f2-41be-aafd-38e5656041ba	b3d6328c-5b51-4f87-bff5-ec10552ebe8c	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
e9bd66ff-7301-404f-a954-dcf3694f6b3a	b3d6328c-5b51-4f87-bff5-ec10552ebe8c	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
853cebfe-e7f9-4e99-bfcb-817f5920c6ac	b3d6328c-5b51-4f87-bff5-ec10552ebe8c	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	df0512cb-3963-4225-97dd-242b835a8118	veterinario
8a28fee2-b9c6-4dc5-8797-ceeebc4af70a	b3d6328c-5b51-4f87-bff5-ec10552ebe8c	30b40a49-5e28-4ce5-acbb-df297a52e509	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
e58cef17-a75a-4afc-8a31-60ccfb3320b5	00182ede-3684-45ab-b570-3d226b9a2d6c	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
f37b88b2-9f34-4986-9607-40487880e6c9	00182ede-3684-45ab-b570-3d226b9a2d6c	30b40a49-5e28-4ce5-acbb-df297a52e509	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
c683688a-3c0e-406b-84e2-d7866553dd78	00182ede-3684-45ab-b570-3d226b9a2d6c	7f75e608-6c5b-429b-a36f-a644cc41501b	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
0b63cc58-5e9b-4347-8f89-df9d1d8c0ddf	00182ede-3684-45ab-b570-3d226b9a2d6c	43958ec8-b358-4c41-bb4c-9b55cacfc8db	df0512cb-3963-4225-97dd-242b835a8118	veterinario
6b715d50-a3bc-444a-a977-2853e5c2e957	00182ede-3684-45ab-b570-3d226b9a2d6c	2d200ce2-5f48-4285-8d33-98f06db5b194	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
e44e9a4d-5d56-4172-b129-c48073e93f7a	0bb0b848-67ef-4789-9fd9-4524e693af73	2d200ce2-5f48-4285-8d33-98f06db5b194	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
8f1238c4-80d8-4673-a97c-848c875abb04	0bb0b848-67ef-4789-9fd9-4524e693af73	c133cc24-f15a-4522-ad43-cc62e4a0283a	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
cd366097-cac2-4089-992b-7a7f23c7b76e	0bb0b848-67ef-4789-9fd9-4524e693af73	513ad92d-a581-4d5b-b01e-7b3654f4482c	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
67892006-594a-47cd-9857-28d3f1c178b7	e0ab538b-bbe5-48c3-b1a1-7c3fadc7870b	513ad92d-a581-4d5b-b01e-7b3654f4482c	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
e87c902f-37fc-452f-95ba-12219e4399ca	e0ab538b-bbe5-48c3-b1a1-7c3fadc7870b	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
8b1e6dee-7897-4bc3-aca8-f82b19608a54	e0ab538b-bbe5-48c3-b1a1-7c3fadc7870b	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
0a829048-b7c7-430b-800d-0f96a5b5a2b2	e0ab538b-bbe5-48c3-b1a1-7c3fadc7870b	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	df0512cb-3963-4225-97dd-242b835a8118	veterinario
e8163826-934a-4373-b2e6-71bd5cb35ee9	e0ab538b-bbe5-48c3-b1a1-7c3fadc7870b	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
ff617117-a81a-49bd-bbd7-43d5ae1c05fa	e1d4f30f-08df-41e0-9982-9991d36321f1	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
b062f510-1a98-4a6d-a253-9f0b95f1cb4b	e1d4f30f-08df-41e0-9982-9991d36321f1	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
25b86bd5-e0e3-4a48-aa7c-5a729b60ba41	e1d4f30f-08df-41e0-9982-9991d36321f1	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
2b079e55-ae0c-4a5e-a2be-d14a1ea0b0e1	49718c23-1aa8-4a1a-91b0-3263ed7f904d	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
4349a068-70e9-4aea-ba57-48529ae72731	49718c23-1aa8-4a1a-91b0-3263ed7f904d	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
56715b97-988c-46de-a5ca-696b28ede0b8	49718c23-1aa8-4a1a-91b0-3263ed7f904d	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
7ee3eaed-c707-4e23-a777-52dbdf6658df	49718c23-1aa8-4a1a-91b0-3263ed7f904d	7f75e608-6c5b-429b-a36f-a644cc41501b	df0512cb-3963-4225-97dd-242b835a8118	veterinario
6793c7b3-f35b-4732-ab3c-d60d6c3ecb9e	49718c23-1aa8-4a1a-91b0-3263ed7f904d	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
6f6f7605-e06a-49c3-9caa-51bfc7b49078	f223e2c1-5c23-4f07-8d13-675153f5b7f2	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
14ebe068-ae28-4d27-b867-7f013df6e771	f223e2c1-5c23-4f07-8d13-675153f5b7f2	7f75e608-6c5b-429b-a36f-a644cc41501b	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
b42b7777-e5b2-41d1-bf23-22672362449b	f223e2c1-5c23-4f07-8d13-675153f5b7f2	2d200ce2-5f48-4285-8d33-98f06db5b194	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
be563a50-0e8d-4b61-9c90-3abb8185a2ca	0d11162c-254f-49c7-909f-404af1c286f4	60da9a93-e0f2-403b-a534-e35383483df5	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
be6d5b2d-a465-442c-9740-b5afcdf48834	0d11162c-254f-49c7-909f-404af1c286f4	513ad92d-a581-4d5b-b01e-7b3654f4482c	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
fd7f2960-0763-42f8-bb20-cba6bd3aa7e1	0d11162c-254f-49c7-909f-404af1c286f4	43958ec8-b358-4c41-bb4c-9b55cacfc8db	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
8f28fda6-5e58-421f-b709-27d0660f4ba1	0d11162c-254f-49c7-909f-404af1c286f4	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	df0512cb-3963-4225-97dd-242b835a8118	veterinario
9c44a93a-5875-41ed-b7aa-a2a1a4606f5f	0d11162c-254f-49c7-909f-404af1c286f4	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
108aa7e9-757d-469a-a44c-ff525d1cb477	6ff946f4-d102-4e1d-88d9-eac1dc7f7a03	30b40a49-5e28-4ce5-acbb-df297a52e509	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
9d0ab88b-78f5-40b1-991e-497c20934966	6ff946f4-d102-4e1d-88d9-eac1dc7f7a03	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
0e4b104e-580d-45c0-be55-1d3994ea6e73	6ff946f4-d102-4e1d-88d9-eac1dc7f7a03	43958ec8-b358-4c41-bb4c-9b55cacfc8db	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
83a2c2da-6de7-43c3-afd2-07335d20c0b5	6ff946f4-d102-4e1d-88d9-eac1dc7f7a03	c133cc24-f15a-4522-ad43-cc62e4a0283a	df0512cb-3963-4225-97dd-242b835a8118	veterinario
da37aaed-93f9-43e9-883e-b7fda9edd7ea	2aabfc2d-a7c8-4218-82e5-b74575d28885	60da9a93-e0f2-403b-a534-e35383483df5	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
33fd14f9-cc27-42ae-9c57-5d3a19a21fd5	2aabfc2d-a7c8-4218-82e5-b74575d28885	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
858bfb58-8491-4ca7-aa87-40d640adc5b8	2aabfc2d-a7c8-4218-82e5-b74575d28885	7f75e608-6c5b-429b-a36f-a644cc41501b	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
9983afc8-9bed-45c6-b0a7-ac3e09088712	2aabfc2d-a7c8-4218-82e5-b74575d28885	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	df0512cb-3963-4225-97dd-242b835a8118	veterinario
c2b618db-68c2-489f-a8c1-937ffa4cb2c6	2aabfc2d-a7c8-4218-82e5-b74575d28885	30b40a49-5e28-4ce5-acbb-df297a52e509	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
89252743-bcee-415e-ae97-d735fd376314	57da959a-a8b9-4293-93a2-057f3c89f005	30b40a49-5e28-4ce5-acbb-df297a52e509	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
caa3cce8-78ee-42fb-a98c-6ae83e87527f	57da959a-a8b9-4293-93a2-057f3c89f005	43958ec8-b358-4c41-bb4c-9b55cacfc8db	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
bbd61cfd-7042-43c8-a17a-772a703a35ad	57da959a-a8b9-4293-93a2-057f3c89f005	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
ccfa177e-3252-4bf9-82af-fe2bcba2c70d	57da959a-a8b9-4293-93a2-057f3c89f005	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	df0512cb-3963-4225-97dd-242b835a8118	veterinario
34a57f9f-4b34-4e55-836f-4da1928ecf50	57da959a-a8b9-4293-93a2-057f3c89f005	7f75e608-6c5b-429b-a36f-a644cc41501b	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
68b15226-77da-4be9-bb62-aa7423ad8b24	978b6bce-96a6-4f06-8513-2911f6a1a13f	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
56619f68-a56b-4773-9cc9-15c94adf962c	978b6bce-96a6-4f06-8513-2911f6a1a13f	2d200ce2-5f48-4285-8d33-98f06db5b194	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
13ccc7a9-389a-4dc3-ab7c-0028825ef816	978b6bce-96a6-4f06-8513-2911f6a1a13f	30b40a49-5e28-4ce5-acbb-df297a52e509	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
1793e15a-91ef-48ee-8f72-46c46add194a	978b6bce-96a6-4f06-8513-2911f6a1a13f	43958ec8-b358-4c41-bb4c-9b55cacfc8db	df0512cb-3963-4225-97dd-242b835a8118	veterinario
d99b4955-8800-4cac-a554-9c4beb4a99b6	a4703e6b-3940-4c8d-bc5d-816ee35d596a	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
2f4edc2d-0edb-4ac2-88ad-ac784212e2df	a4703e6b-3940-4c8d-bc5d-816ee35d596a	2d200ce2-5f48-4285-8d33-98f06db5b194	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
9cf60f94-43f8-4cc5-b2be-84a6d36539af	a4703e6b-3940-4c8d-bc5d-816ee35d596a	7f75e608-6c5b-429b-a36f-a644cc41501b	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
26c23f57-d5fe-45a0-ac41-2d64f815e40b	a4703e6b-3940-4c8d-bc5d-816ee35d596a	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	df0512cb-3963-4225-97dd-242b835a8118	veterinario
892dfd24-4b2f-4d2a-ae4b-c1769365a69d	88654be7-71da-4fff-b8a3-a16b94575fe7	43958ec8-b358-4c41-bb4c-9b55cacfc8db	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
d822631b-17bc-4f60-9d7d-8fa65150b3b7	88654be7-71da-4fff-b8a3-a16b94575fe7	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
a2681719-a773-4592-869e-385a2f45319e	88654be7-71da-4fff-b8a3-a16b94575fe7	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
de390889-9e1b-47a0-a52d-b464384da5e3	88654be7-71da-4fff-b8a3-a16b94575fe7	2d200ce2-5f48-4285-8d33-98f06db5b194	df0512cb-3963-4225-97dd-242b835a8118	veterinario
656d898c-f54a-4244-b2fc-d51206dc44be	88654be7-71da-4fff-b8a3-a16b94575fe7	513ad92d-a581-4d5b-b01e-7b3654f4482c	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
c2d5fc70-eecf-4024-abb8-8d0cc5156b1d	62d452a6-1bde-4a64-a18d-75361fbf8adb	30b40a49-5e28-4ce5-acbb-df297a52e509	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
68e9c63d-f3f0-4afc-b9cf-5f29e63d3e40	62d452a6-1bde-4a64-a18d-75361fbf8adb	43958ec8-b358-4c41-bb4c-9b55cacfc8db	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
db69259a-81b6-4228-ae18-524be89260e5	62d452a6-1bde-4a64-a18d-75361fbf8adb	513ad92d-a581-4d5b-b01e-7b3654f4482c	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
ba4b2c50-f335-4a9b-886f-d6026b51c973	62d452a6-1bde-4a64-a18d-75361fbf8adb	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	df0512cb-3963-4225-97dd-242b835a8118	veterinario
e1da5c89-7d5f-4dd9-96b0-98e1a1601c10	74b836ff-a22f-4a9b-8f8b-6e11fb945544	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
821c0d10-e777-4f94-ad31-c2206aebf9bb	74b836ff-a22f-4a9b-8f8b-6e11fb945544	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
fbdf7626-2d5d-4aa6-88ab-28dbf1d7b36f	74b836ff-a22f-4a9b-8f8b-6e11fb945544	c133cc24-f15a-4522-ad43-cc62e4a0283a	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
0f8b98bf-5a26-43fe-ba30-3d048b46991c	194ee587-a195-4706-a7a0-58b9306fef0e	513ad92d-a581-4d5b-b01e-7b3654f4482c	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
03c3251b-3ddb-45a0-bcac-71a917c254f1	194ee587-a195-4706-a7a0-58b9306fef0e	30b40a49-5e28-4ce5-acbb-df297a52e509	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
8ee5d059-474b-4c45-aff2-4a20adce6b5c	194ee587-a195-4706-a7a0-58b9306fef0e	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
5a8fa68c-0560-4c09-9dc7-71e7d3f31c39	85381953-f4cc-4664-8682-e448ca14b414	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
628cd636-14d9-446e-83ad-44b2b584b15d	85381953-f4cc-4664-8682-e448ca14b414	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
d9ba6490-3c6f-47a4-bc30-717f7c20f37d	85381953-f4cc-4664-8682-e448ca14b414	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
d376cdff-5aa9-47f2-bead-6c39dbda6029	85381953-f4cc-4664-8682-e448ca14b414	43958ec8-b358-4c41-bb4c-9b55cacfc8db	df0512cb-3963-4225-97dd-242b835a8118	veterinario
9deaac53-0ba6-4261-96b4-d119215a38dc	29101baf-3a7f-404e-8e7e-1bbf6c6cbcbd	2d200ce2-5f48-4285-8d33-98f06db5b194	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
4983968a-cdcc-4956-933d-41e634839f68	29101baf-3a7f-404e-8e7e-1bbf6c6cbcbd	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
ec6df256-3676-4f48-976d-4df251048be8	29101baf-3a7f-404e-8e7e-1bbf6c6cbcbd	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
d4658728-79bb-4b4f-a548-955b0007d855	29101baf-3a7f-404e-8e7e-1bbf6c6cbcbd	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	df0512cb-3963-4225-97dd-242b835a8118	veterinario
1c67d87f-59a7-46fd-b463-56047a9f29e4	29101baf-3a7f-404e-8e7e-1bbf6c6cbcbd	7f75e608-6c5b-429b-a36f-a644cc41501b	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
0b9f659a-aac7-43bc-8840-eebd0e33c261	fb0b42ad-ca20-4a77-af02-ceb711e255df	513ad92d-a581-4d5b-b01e-7b3654f4482c	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
4e0fa0de-390b-429b-b04a-6d1e01ade4e2	fb0b42ad-ca20-4a77-af02-ceb711e255df	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
e76d2de9-fe90-4836-a35c-a90d4d1aee57	fb0b42ad-ca20-4a77-af02-ceb711e255df	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
81158c51-a6b1-42f1-bc85-2ab8d7d30813	fb0b42ad-ca20-4a77-af02-ceb711e255df	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	df0512cb-3963-4225-97dd-242b835a8118	veterinario
a25636ba-e081-4ad8-9151-659e57d5d5a8	fb0b42ad-ca20-4a77-af02-ceb711e255df	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
17ef21e4-a59f-4c15-9e93-d126779cce99	497df18c-6b71-4e0f-a0ab-faa911c97c1b	43958ec8-b358-4c41-bb4c-9b55cacfc8db	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
1b97f40d-a3f1-4ba8-a353-a02ac760dbca	497df18c-6b71-4e0f-a0ab-faa911c97c1b	c133cc24-f15a-4522-ad43-cc62e4a0283a	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
24d0ae82-7028-45f3-9dca-9964033eff77	497df18c-6b71-4e0f-a0ab-faa911c97c1b	7f75e608-6c5b-429b-a36f-a644cc41501b	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
7bf767d3-fe25-4a18-88be-e180f9d83be7	7ebf78b1-ca69-4552-9e5c-b02a20611819	c133cc24-f15a-4522-ad43-cc62e4a0283a	521c30a0-4751-4157-87d0-6aaf2c9c882d	responsable_ordeno
8e43ab51-700a-4bae-bdd4-9c859093f1c1	7ebf78b1-ca69-4552-9e5c-b02a20611819	30b40a49-5e28-4ce5-acbb-df297a52e509	3836de7c-0b6f-4306-904d-825890b6f534	auxiliar_recria
70d201c7-31b4-4adb-8bf2-eef7e967ef90	7ebf78b1-ca69-4552-9e5c-b02a20611819	60da9a93-e0f2-403b-a534-e35383483df5	f102e952-9109-4668-a381-bc6693bc851b	auxiliar_ordeno
356e35c3-18b1-4441-a1e9-586379b8f811	7ebf78b1-ca69-4552-9e5c-b02a20611819	513ad92d-a581-4d5b-b01e-7b3654f4482c	df0512cb-3963-4225-97dd-242b835a8118	veterinario
8d52bc7c-d805-4078-b8d5-711559aaa37e	7ebf78b1-ca69-4552-9e5c-b02a20611819	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	597ad6cc-663d-4eb8-8d08-286d22050b1d	mantenimiento
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (id, ts, tabla_afectada, operacion, registro_id, datos_anteriores, datos_nuevos, usuario_bd, hash_sha256) FROM stdin;
1	2026-05-29 12:13:42.942388+00	animales	INSERT	e4d3741d-b1e6-4cae-9a1c-69dcd04c2302	\N	{"id": "e4d3741d-b1e6-4cae-9a1c-69dcd04c2302", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-10-12", "crotal_oficial": "DEM-0001", "fecha_nacimiento": "2019-10-03", "estado_reproductivo": "vacia"}	postgres	5d72e919237a2c2f486ac8f48b44e64369e156be9930fa558995533b9a0c3dd2
2	2026-05-29 12:13:42.942388+00	animales	INSERT	2ced7c23-acf4-43d7-9bac-af6d0158d58c	\N	{"id": "2ced7c23-acf4-43d7-9bac-af6d0158d58c", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-08-06", "crotal_oficial": "DEM-0002", "fecha_nacimiento": "2023-07-14", "estado_reproductivo": "en_celo"}	postgres	dec28f2d8311ade908d716d4eebfce34f841fbbbdc0d017bb9108150f00b2a45
3	2026-05-29 12:13:42.942388+00	animales	INSERT	6d067c4b-3fca-414f-af92-76a0d5c7a813	\N	{"id": "6d067c4b-3fca-414f-af92-76a0d5c7a813", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-08-06", "crotal_oficial": "DEM-0003", "fecha_nacimiento": "2021-07-24", "estado_reproductivo": "inseminada"}	postgres	8c9b1b1e340f2501c50685713d0686099d9fc897b661cdeaaaf355e562e2a8bf
4	2026-05-29 12:13:42.942388+00	animales	INSERT	c0f7d046-4899-43d4-86dc-11d64560e316	\N	{"id": "c0f7d046-4899-43d4-86dc-11d64560e316", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-10-18", "crotal_oficial": "DEM-0004", "fecha_nacimiento": "2021-09-22", "estado_reproductivo": "en_celo"}	postgres	35c9dc2c750ce7801032816efa7bad3e19fff3a1ed9132d66d3b4408515dbce6
5	2026-05-29 12:13:42.942388+00	animales	INSERT	454f410f-48c2-42b2-be0f-2ebfef72e1f7	\N	{"id": "454f410f-48c2-42b2-be0f-2ebfef72e1f7", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-11-30", "crotal_oficial": "DEM-0005", "fecha_nacimiento": "2025-11-30", "estado_reproductivo": null}	postgres	a765dd4501cce3239c8ddb59a179c568a2124b3daea3434a922ed991ad3ef377
6	2026-05-29 12:13:42.942388+00	animales	INSERT	0cc26162-5744-4617-8a37-65274b54c48d	\N	{"id": "0cc26162-5744-4617-8a37-65274b54c48d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-07-12", "crotal_oficial": "DEM-0006", "fecha_nacimiento": "2020-06-29", "estado_reproductivo": "vacia"}	postgres	653229ccd2cd425e305c1f6f12317b468c86814fcc1cc29bb52c0554493a077d
7	2026-05-29 12:13:42.942388+00	animales	INSERT	11218539-9457-40cc-a87c-6d1ea5a52534	\N	{"id": "11218539-9457-40cc-a87c-6d1ea5a52534", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-10-06", "crotal_oficial": "DEM-0007", "fecha_nacimiento": "2021-09-22", "estado_reproductivo": "confirmada_gestante"}	postgres	93c1ce56b2836f2bca893284f5170d6b6bf662a38a2f5cac1016ab09886cd359
8	2026-05-29 12:13:42.942388+00	animales	INSERT	32cfcf51-5267-4df9-860e-550a35e8b7a4	\N	{"id": "32cfcf51-5267-4df9-860e-550a35e8b7a4", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-01-04", "crotal_oficial": "DEM-0008", "fecha_nacimiento": "2025-01-04", "estado_reproductivo": null}	postgres	2b7b1c713b8fae67165eda305ced46006d33667a09fa347833bec66ac94f0c24
9	2026-05-29 12:13:42.942388+00	animales	INSERT	a8900363-371e-4e16-a58f-cc9659f7b99e	\N	{"id": "a8900363-371e-4e16-a58f-cc9659f7b99e", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-06-03", "crotal_oficial": "DEM-0009", "fecha_nacimiento": "2025-06-03", "estado_reproductivo": null}	postgres	b9f42cb36f85bd5a9e31df12fa19930b03579da7cd30fd900b041a7a76bbd354
10	2026-05-29 12:13:42.942388+00	animales	INSERT	d58dab0c-ba97-4376-93e1-baf6fffe87ee	\N	{"id": "d58dab0c-ba97-4376-93e1-baf6fffe87ee", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-01-28", "crotal_oficial": "DEM-0010", "fecha_nacimiento": "2019-01-06", "estado_reproductivo": "en_celo"}	postgres	1c5214d97ff8eac538c2108c98fd7eba924a72ed2390274eb842354906af370e
11	2026-05-29 12:13:42.942388+00	animales	INSERT	b5c59f11-f0ae-4477-92f7-6ebc9942f491	\N	{"id": "b5c59f11-f0ae-4477-92f7-6ebc9942f491", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-10-10", "crotal_oficial": "DEM-0011", "fecha_nacimiento": "2021-09-22", "estado_reproductivo": "inseminada"}	postgres	a561ce835bc1648e3cb8a9098550e0df6ba4fa52d724cc38ba5daa9ea3ce4241
12	2026-05-29 12:13:42.942388+00	animales	INSERT	929630b3-dc54-475d-a50f-e2ad377f0fe8	\N	{"id": "929630b3-dc54-475d-a50f-e2ad377f0fe8", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-05-16", "crotal_oficial": "DEM-0012", "fecha_nacimiento": "2023-05-15", "estado_reproductivo": "confirmada_gestante"}	postgres	53067242cdf811e0e99d033942947a40bc5890e5d442c8f2804205473fc195b2
13	2026-05-29 12:13:42.942388+00	animales	INSERT	b02ad120-19ba-4491-8ae5-df9672ece6e6	\N	{"id": "b02ad120-19ba-4491-8ae5-df9672ece6e6", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-03-05", "crotal_oficial": "DEM-0013", "fecha_nacimiento": "2023-02-14", "estado_reproductivo": "confirmada_gestante"}	postgres	1bd014116821d52871041c25f5a30309b558311fc93609e731308f4f858b911a
14	2026-05-29 12:13:42.942388+00	animales	INSERT	4047b88d-66c2-4192-8429-4eca6b5ff44f	\N	{"id": "4047b88d-66c2-4192-8429-4eca6b5ff44f", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-08-04", "crotal_oficial": "DEM-0014", "fecha_nacimiento": "2023-07-14", "estado_reproductivo": "vacia"}	postgres	83321175ff47e1325ba66a4e3c871695f93d5bf610d6c7113ab63e055c778f0b
15	2026-05-29 12:13:42.942388+00	animales	INSERT	9b00f292-af6e-488b-8a37-7795bf2f3cca	\N	{"id": "9b00f292-af6e-488b-8a37-7795bf2f3cca", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-01-29", "crotal_oficial": "DEM-0015", "fecha_nacimiento": "2026-01-29", "estado_reproductivo": null}	postgres	4ae5ce9ccee79f8db7711c453da0e1b0e2d3f4cf26dfe0e2db70fb81e8b49a15
16	2026-05-29 12:13:42.942388+00	animales	INSERT	2ecf6665-0c82-488d-9749-7941de974abf	\N	{"id": "2ecf6665-0c82-488d-9749-7941de974abf", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-12-09", "crotal_oficial": "DEM-0016", "fecha_nacimiento": "2023-11-11", "estado_reproductivo": "vacia"}	postgres	21a46d02f4ef75c437a74268c873329f928f190a0f6a898c62d1e0f3747244e3
17	2026-05-29 12:13:42.942388+00	animales	INSERT	482ca314-084c-4f01-aef1-7d2bc8cb37ff	\N	{"id": "482ca314-084c-4f01-aef1-7d2bc8cb37ff", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-09-15", "crotal_oficial": "DEM-0017", "fecha_nacimiento": "2018-09-08", "estado_reproductivo": "inseminada"}	postgres	6886706b3e4dbd62b8c0193fbd0d1d082f86bc17f5594c3fcd9c7aae852ff8a3
18	2026-05-29 12:13:42.942388+00	animales	INSERT	1909c17b-0202-4563-aeb3-efdcce12c758	\N	{"id": "1909c17b-0202-4563-aeb3-efdcce12c758", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-05-29", "crotal_oficial": "DEM-0018", "fecha_nacimiento": "2022-05-20", "estado_reproductivo": "en_celo"}	postgres	3a8ec7a1652bee97dad9aa276b7eb114b07e01830d30a26dd6d2a3d05c086413
19	2026-05-29 12:13:42.942388+00	animales	INSERT	ab618b25-84fa-4e28-a07d-20ac6e868648	\N	{"id": "ab618b25-84fa-4e28-a07d-20ac6e868648", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-12-26", "crotal_oficial": "DEM-0019", "fecha_nacimiento": "2023-12-11", "estado_reproductivo": "vacia"}	postgres	bed3fb1012d50f4f4c3c4ec270cb7fa2233cd65f3871937a4b33cef7445e4798
20	2026-05-29 12:13:42.942388+00	animales	INSERT	f2113bfa-4f8c-4d26-9438-7349516eb5da	\N	{"id": "f2113bfa-4f8c-4d26-9438-7349516eb5da", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-03-08", "crotal_oficial": "DEM-0020", "fecha_nacimiento": "2021-02-24", "estado_reproductivo": "vacia"}	postgres	2b9da091c0d7b792e68a732ebf22004183eebe21644aa71062133ce83f8bec10
21	2026-05-29 12:13:42.942388+00	animales	INSERT	fd456222-89c9-496b-84d8-ccd28a054320	\N	{"id": "fd456222-89c9-496b-84d8-ccd28a054320", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2024-12-05", "crotal_oficial": "DEM-0021", "fecha_nacimiento": "2024-12-05", "estado_reproductivo": null}	postgres	0debab8c05f6dfc5ac92363cdf1561905e1d80eaf12f64d9041a4b6bf5619a2b
22	2026-05-29 12:13:42.942388+00	animales	INSERT	003a9fe9-e4a0-447f-bcdb-57439cd5e412	\N	{"id": "003a9fe9-e4a0-447f-bcdb-57439cd5e412", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-08-13", "crotal_oficial": "DEM-0022", "fecha_nacimiento": "2021-07-24", "estado_reproductivo": "parto_reciente"}	postgres	4efaa656d19bb0250cf3e051f726023407237780b09113a79e10389184dd0a37
23	2026-05-29 12:13:42.942388+00	animales	INSERT	b5297515-9959-455e-86e4-30052372eddd	\N	{"id": "b5297515-9959-455e-86e4-30052372eddd", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-11-21", "crotal_oficial": "DEM-0023", "fecha_nacimiento": "2019-11-02", "estado_reproductivo": "vacia"}	postgres	7120ffa142dc2a704c0d25cf492fbebaf34d47b544c06c04f4bca201807ba8e9
24	2026-05-29 12:13:42.942388+00	animales	INSERT	663aec4c-0d3d-496e-8da9-75425e7abb42	\N	{"id": "663aec4c-0d3d-496e-8da9-75425e7abb42", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-08-22", "crotal_oficial": "DEM-0024", "fecha_nacimiento": "2022-08-18", "estado_reproductivo": "vacia"}	postgres	2853888ddf01f68db873976b0d3b5015f899d7cc32920aa2e97a3b613b2b8397
25	2026-05-29 12:13:42.942388+00	animales	INSERT	754c21c2-5528-4fe0-b94b-078ab53ba4f7	\N	{"id": "754c21c2-5528-4fe0-b94b-078ab53ba4f7", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-02-16", "crotal_oficial": "DEM-0025", "fecha_nacimiento": "2023-02-14", "estado_reproductivo": "vacia"}	postgres	8186ef1a53d534d9ed34c8537897a1929e38e95d4c547000023153a7e0aa17a7
26	2026-05-29 12:13:42.942388+00	animales	INSERT	c1b81c70-506f-4989-95f8-1f271f5a67e3	\N	{"id": "c1b81c70-506f-4989-95f8-1f271f5a67e3", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-08-02", "crotal_oficial": "DEM-0026", "fecha_nacimiento": "2025-08-02", "estado_reproductivo": null}	postgres	16e6ffad617810e7e10a18eef2f36e0baaa989d0c7639ce46a0c389b031223ff
27	2026-05-29 12:13:42.942388+00	animales	INSERT	bd1f7206-4b66-4801-aa4b-6979be8bcb5f	\N	{"id": "bd1f7206-4b66-4801-aa4b-6979be8bcb5f", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-09-21", "crotal_oficial": "DEM-0027", "fecha_nacimiento": "2021-08-23", "estado_reproductivo": "confirmada_gestante"}	postgres	e2717be3906cd6e52d14ec47ab979294dc1ae76db7aef24ec157b46410ab6d0e
28	2026-05-29 12:13:42.942388+00	animales	INSERT	41098454-a4a4-45db-bc95-a2793218055b	\N	{"id": "41098454-a4a4-45db-bc95-a2793218055b", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-12-16", "crotal_oficial": "DEM-0028", "fecha_nacimiento": "2018-12-07", "estado_reproductivo": "vacia"}	postgres	b79425d83eecef4251f79e840054940425391c19c87bf20940f290ba440a3c11
29	2026-05-29 12:13:42.942388+00	animales	INSERT	6242a97b-f3b8-42f8-98fa-ab92058599ee	\N	{"id": "6242a97b-f3b8-42f8-98fa-ab92058599ee", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-08-17", "crotal_oficial": "DEM-0029", "fecha_nacimiento": "2021-07-24", "estado_reproductivo": "confirmada_gestante"}	postgres	6c69c1caa878d2ba51f5eeb9a486efce6d8214fe579e7f5a7c76cb1656b67fc0
30	2026-05-29 12:13:42.942388+00	animales	INSERT	c0d6060f-b696-49b3-8a78-0de2f71826b0	\N	{"id": "c0d6060f-b696-49b3-8a78-0de2f71826b0", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-11-08", "crotal_oficial": "DEM-0030", "fecha_nacimiento": "2022-10-17", "estado_reproductivo": "inseminada"}	postgres	1b3dace79a399256f17bb5e63b070cd11cfda562b3644cb6861b3d2b4f4d255e
31	2026-05-29 12:13:42.942388+00	animales	INSERT	6d743a75-3b83-454f-91eb-76bfb4439dd9	\N	{"id": "6d743a75-3b83-454f-91eb-76bfb4439dd9", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-03-30", "crotal_oficial": "DEM-0031", "fecha_nacimiento": "2019-03-07", "estado_reproductivo": "confirmada_gestante"}	postgres	983c04db3993399af3c22397b4041016ce47784df46ec656102ea7c76dfd5e06
32	2026-05-29 12:13:42.942388+00	animales	INSERT	f6f18149-270e-4c85-871a-96c00cb9ae2b	\N	{"id": "f6f18149-270e-4c85-871a-96c00cb9ae2b", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-04-19", "crotal_oficial": "DEM-0032", "fecha_nacimiento": "2021-03-26", "estado_reproductivo": "en_celo"}	postgres	049d1f261127a86fbe527af44ab33886b9873aa73876f1a633f539ff0528900e
33	2026-05-29 12:13:42.942388+00	animales	INSERT	0d88dbf9-bce8-4dbf-bbb1-c728ee8caab2	\N	{"id": "0d88dbf9-bce8-4dbf-bbb1-c728ee8caab2", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-06-26", "crotal_oficial": "DEM-0033", "fecha_nacimiento": "2022-06-19", "estado_reproductivo": "en_celo"}	postgres	772e2981bf03337daf6d861561397ba9e26443020179fceaed364ae7cb80920f
34	2026-05-29 12:13:42.942388+00	animales	INSERT	506a81f0-17b8-4482-afae-3f4ac8e77892	\N	{"id": "506a81f0-17b8-4482-afae-3f4ac8e77892", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-03-05", "crotal_oficial": "DEM-0034", "fecha_nacimiento": "2025-03-05", "estado_reproductivo": null}	postgres	c2602db87ba499c5f8b1dfa480d7f650c5343dfa630e09006d3764c390b130df
35	2026-05-29 12:13:42.942388+00	animales	INSERT	7ee50ae4-fd81-4002-ba07-9705968830d1	\N	{"id": "7ee50ae4-fd81-4002-ba07-9705968830d1", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-10-31", "crotal_oficial": "DEM-0035", "fecha_nacimiento": "2022-10-17", "estado_reproductivo": "en_celo"}	postgres	aa51629cd5ed964b12a0890510d136be4504f043c1bbce13b617eee3840d4001
36	2026-05-29 12:13:42.942388+00	animales	INSERT	b17e7d41-51a7-4950-b1d4-fd3625e19b2f	\N	{"id": "b17e7d41-51a7-4950-b1d4-fd3625e19b2f", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2024-12-05", "crotal_oficial": "DEM-0036", "fecha_nacimiento": "2024-12-05", "estado_reproductivo": null}	postgres	63abfa83ea66de76a8282410497eb2140a0e7bb8123d8a6c84fdc435d3584b0e
37	2026-05-29 12:13:42.942388+00	animales	INSERT	836b7685-ad7c-48c5-aa09-f54590e75701	\N	{"id": "836b7685-ad7c-48c5-aa09-f54590e75701", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-10-03", "crotal_oficial": "DEM-0037", "fecha_nacimiento": "2022-09-17", "estado_reproductivo": "vacia"}	postgres	95f3d983423e7549f869b63ea3d25d405733f53b0b21ccc64efb59133c906997
38	2026-05-29 12:13:42.942388+00	animales	INSERT	d0ba5459-2ca0-4742-8bc9-ee3ecdf27f8d	\N	{"id": "d0ba5459-2ca0-4742-8bc9-ee3ecdf27f8d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-11-09", "crotal_oficial": "DEM-0038", "fecha_nacimiento": "2018-11-07", "estado_reproductivo": "confirmada_gestante"}	postgres	5572a28397d4f1bd8da45c4e515c8695dfc0706d50bb409c89bb4966373fa326
39	2026-05-29 12:13:42.942388+00	animales	INSERT	92d13248-9188-43d4-92fe-2bacb22565d2	\N	{"id": "92d13248-9188-43d4-92fe-2bacb22565d2", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-03-27", "crotal_oficial": "DEM-0039", "fecha_nacimiento": "2019-03-07", "estado_reproductivo": "parto_reciente"}	postgres	acd155de258dfa709e5db35a367497275afe174bc607bca486fb0d201c99788b
40	2026-05-29 12:13:42.942388+00	animales	INSERT	c6f4a608-54b2-4ca8-affe-0a2e4d360399	\N	{"id": "c6f4a608-54b2-4ca8-affe-0a2e4d360399", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-11-28", "crotal_oficial": "DEM-0040", "fecha_nacimiento": "2023-11-11", "estado_reproductivo": "inseminada"}	postgres	cdd4f8edd847ee3877ad3ff155c567c784ee1f13010533a84c41d42922b59652
41	2026-05-29 12:13:42.942388+00	animales	INSERT	52be2f26-d802-4b14-ae5b-dcb306089bdc	\N	{"id": "52be2f26-d802-4b14-ae5b-dcb306089bdc", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-09-19", "crotal_oficial": "DEM-0041", "fecha_nacimiento": "2019-09-03", "estado_reproductivo": "en_celo"}	postgres	f0ddbfea0d061f45222f0fc0929418e97b138fe27f0bd675f84f0ce4e473535d
42	2026-05-29 12:13:42.942388+00	animales	INSERT	14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5	\N	{"id": "14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-03-30", "crotal_oficial": "DEM-0042", "fecha_nacimiento": "2023-03-16", "estado_reproductivo": "confirmada_gestante"}	postgres	429a611d3409cd2683e88d4ae1639d91ee8bae20e21c7b1e669839facf80c191
43	2026-05-29 12:13:42.942388+00	animales	INSERT	4ead6660-3efa-49c0-8ec2-6fad9e1aef40	\N	{"id": "4ead6660-3efa-49c0-8ec2-6fad9e1aef40", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-02-03", "crotal_oficial": "DEM-0043", "fecha_nacimiento": "2025-02-03", "estado_reproductivo": null}	postgres	ba7ac40d06ae8ce3b15183d44f67d8cee07f5ef30d3c83978dd00ae571f2ca2c
44	2026-05-29 12:13:42.942388+00	animales	INSERT	26f29af8-4eb8-4aa2-aaae-3bfce1c4839b	\N	{"id": "26f29af8-4eb8-4aa2-aaae-3bfce1c4839b", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-05-23", "crotal_oficial": "DEM-0044", "fecha_nacimiento": "2020-04-30", "estado_reproductivo": "en_celo"}	postgres	3e62009739d883227e1cca6400a2ca0926d59d1c8ac6650fe87a04da28f2b4fd
45	2026-05-29 12:13:42.942388+00	animales	INSERT	d06cd495-106f-4ab5-b661-bf0627247b78	\N	{"id": "d06cd495-106f-4ab5-b661-bf0627247b78", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "baja", "nombre": null, "madre_id": null, "fecha_baja": "2026-02-09", "motivo_baja": "Accidente", "fecha_entrada": "2022-06-12", "crotal_oficial": "DEM-0045", "fecha_nacimiento": "2022-05-20", "estado_reproductivo": null}	postgres	041c1f82c4fa1ba8b779dd8b4572f60dc3807bba108a1fde1514e85d321b8613
46	2026-05-29 12:13:42.942388+00	animales	INSERT	49b61755-8934-44da-9065-3ccaa355d5db	\N	{"id": "49b61755-8934-44da-9065-3ccaa355d5db", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-09-13", "crotal_oficial": "DEM-0046", "fecha_nacimiento": "2020-08-28", "estado_reproductivo": "en_celo"}	postgres	e2b679dab1d35917ed9ede5dd9acd70bd1a1ea28ea877fc884f1ec21a6481070
47	2026-05-29 12:13:42.942388+00	animales	INSERT	3ee55362-8374-452c-ac80-5a93545bab2a	\N	{"id": "3ee55362-8374-452c-ac80-5a93545bab2a", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-08-17", "crotal_oficial": "DEM-0047", "fecha_nacimiento": "2021-07-24", "estado_reproductivo": "confirmada_gestante"}	postgres	60d4455cdd9bce746ad01f3fe2d6705a86708b7c28ef3d30dd8ce0ff15f81cc7
48	2026-05-29 12:13:42.942388+00	animales	INSERT	d1762cb2-302a-4dd7-97df-934978bad2bc	\N	{"id": "d1762cb2-302a-4dd7-97df-934978bad2bc", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-12-05", "crotal_oficial": "DEM-0048", "fecha_nacimiento": "2020-11-26", "estado_reproductivo": "vacia"}	postgres	4ef8d47b4159abba2d6ca938f4808a96f0d38ecece3844339a4c164b1564de8b
49	2026-05-29 12:13:42.942388+00	animales	INSERT	1ef34732-92bc-47c3-896c-d5ef65704b1d	\N	{"id": "1ef34732-92bc-47c3-896c-d5ef65704b1d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-07-20", "crotal_oficial": "DEM-0049", "fecha_nacimiento": "2022-07-19", "estado_reproductivo": "confirmada_gestante"}	postgres	04fa4f08b413322e8e74c41c82e325a87119bebb907f12fa98fccfd9dff6b5e9
50	2026-05-29 12:13:42.942388+00	animales	INSERT	26d26b4b-30bb-4860-9c60-15c5ddcb244c	\N	{"id": "26d26b4b-30bb-4860-9c60-15c5ddcb244c", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-04-17", "crotal_oficial": "DEM-0050", "fecha_nacimiento": "2022-03-21", "estado_reproductivo": "inseminada"}	postgres	2b8a74564aacd6ed81cc9da64f389288d9df198e5e69cd83afdbb148cf2c257b
51	2026-05-29 12:13:42.942388+00	animales	INSERT	6b02089e-b0dc-40cf-a70c-a0fd1f9f407f	\N	{"id": "6b02089e-b0dc-40cf-a70c-a0fd1f9f407f", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-04-10", "crotal_oficial": "DEM-0051", "fecha_nacimiento": "2019-04-06", "estado_reproductivo": "inseminada"}	postgres	10d2f2a3121d41b35f9ba39667a4849def03e7ad4ad72457d568bd69b7e2ece3
52	2026-05-29 12:13:42.942388+00	animales	INSERT	5f6a9e48-7748-4a42-be2b-3fbaed701adc	\N	{"id": "5f6a9e48-7748-4a42-be2b-3fbaed701adc", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-06-16", "crotal_oficial": "DEM-0052", "fecha_nacimiento": "2023-06-14", "estado_reproductivo": "confirmada_gestante"}	postgres	677caad16389cc8911de73c6f83aab70fc6a7be6d650c30c65c8d65920c475d9
53	2026-05-29 12:13:42.942388+00	animales	INSERT	d1ebde4a-8a42-4cd3-8762-e5317430d542	\N	{"id": "d1ebde4a-8a42-4cd3-8762-e5317430d542", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-04", "crotal_oficial": "DEM-0053", "fecha_nacimiento": "2025-05-04", "estado_reproductivo": null}	postgres	c91ae9513779e03a46633aaab66d6007e1e0e05d32e4c59c309d40b0e5e6aca4
54	2026-05-29 12:13:42.942388+00	animales	INSERT	a4fd9a5f-764a-4193-836f-3b3fdc11873b	\N	{"id": "a4fd9a5f-764a-4193-836f-3b3fdc11873b", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-03-30", "crotal_oficial": "DEM-0054", "fecha_nacimiento": "2026-03-30", "estado_reproductivo": null}	postgres	28d751e18dd2a644b39889e358e48d1f5a4cf2572157dd1430e570145a2d68ac
55	2026-05-29 12:13:42.942388+00	animales	INSERT	0e161c89-fa5d-48ce-b985-0ba8cee7482d	\N	{"id": "0e161c89-fa5d-48ce-b985-0ba8cee7482d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-03-31", "crotal_oficial": "DEM-0055", "fecha_nacimiento": "2019-03-07", "estado_reproductivo": "confirmada_gestante"}	postgres	867d88d609491a82cf6b91dd34ac9f9252f25fc7200e3407fb6fd52ecf063fb5
56	2026-05-29 12:13:42.942388+00	animales	INSERT	299618a7-5c8b-4ed3-a6fa-5280adffe5e2	\N	{"id": "299618a7-5c8b-4ed3-a6fa-5280adffe5e2", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-04-22", "crotal_oficial": "DEM-0056", "fecha_nacimiento": "2020-03-31", "estado_reproductivo": "vacia"}	postgres	d171ffd4ef271115504cff0661bc27a06b267641a67af7aa9fe9fc594bd0bd8b
57	2026-05-29 12:13:42.942388+00	animales	INSERT	fdd7b753-1eb4-401a-a7d0-edc697de625d	\N	{"id": "fdd7b753-1eb4-401a-a7d0-edc697de625d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-12-11", "crotal_oficial": "DEM-0057", "fecha_nacimiento": "2023-11-11", "estado_reproductivo": "confirmada_gestante"}	postgres	afee947afac3e06f25cb5d8c69108796c5169c60d900560ed72aa8916ac1e0d2
58	2026-05-29 12:13:42.942388+00	animales	INSERT	74ba687b-d88d-4950-abbc-6c11988c464b	\N	{"id": "74ba687b-d88d-4950-abbc-6c11988c464b", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-01-29", "crotal_oficial": "DEM-0058", "fecha_nacimiento": "2026-01-29", "estado_reproductivo": null}	postgres	a31c8ecfb030b4687003e50e5fd7dd99ae8d735d76f2f507c700723a5b4a0113
59	2026-05-29 12:13:42.942388+00	animales	INSERT	60617164-bf9a-4125-b9f2-97603d14e2f8	\N	{"id": "60617164-bf9a-4125-b9f2-97603d14e2f8", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-09-25", "crotal_oficial": "DEM-0059", "fecha_nacimiento": "2021-09-22", "estado_reproductivo": "confirmada_gestante"}	postgres	8c1be55228c7323bd572122a741331ba36e683beb53ae36d50c14ed7db995711
60	2026-05-29 12:13:42.942388+00	animales	INSERT	511a43e4-da3e-4ebb-a40f-554774f79dc1	\N	{"id": "511a43e4-da3e-4ebb-a40f-554774f79dc1", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-07-26", "crotal_oficial": "DEM-0060", "fecha_nacimiento": "2022-07-19", "estado_reproductivo": "inseminada"}	postgres	ef3fa2148c946e42df219550abc3a055139ed4823c8fb49d58838b211d4bff6b
61	2026-05-29 12:13:42.942388+00	animales	INSERT	b93dabf3-c815-4e61-af0e-b441ae2b0a46	\N	{"id": "b93dabf3-c815-4e61-af0e-b441ae2b0a46", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-04-19", "crotal_oficial": "DEM-0061", "fecha_nacimiento": "2019-04-06", "estado_reproductivo": "en_celo"}	postgres	2cae49191d47357b035e6303532e1b512577c4eb3c0331c31b7b4d0f28ba0e6b
62	2026-05-29 12:13:42.942388+00	animales	INSERT	e1e1ba00-6b9e-42b0-ad38-557ead469163	\N	{"id": "e1e1ba00-6b9e-42b0-ad38-557ead469163", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-02-28", "crotal_oficial": "DEM-0062", "fecha_nacimiento": "2026-02-28", "estado_reproductivo": null}	postgres	ba70e694e3f51224c3736d23927934f1ba8748b74f37a9356965ed578c40c4bb
63	2026-05-29 12:13:42.942388+00	animales	INSERT	7893dd48-7944-44bf-8d90-ff51288993fd	\N	{"id": "7893dd48-7944-44bf-8d90-ff51288993fd", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-12-16", "crotal_oficial": "DEM-0063", "fecha_nacimiento": "2020-11-26", "estado_reproductivo": "vacia"}	postgres	8c0c1d7ebaed922433ac330ff6b5f49e687528a70fad2d2dc1bfc030e0cb405f
64	2026-05-29 12:13:42.942388+00	animales	INSERT	bca99578-d4de-422a-b04f-1ae3da4d3b43	\N	{"id": "bca99578-d4de-422a-b04f-1ae3da4d3b43", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-06-06", "crotal_oficial": "DEM-0064", "fecha_nacimiento": "2021-05-25", "estado_reproductivo": "confirmada_gestante"}	postgres	d38503b9ef6d1e2724c039de2a66421652ba4b8f56d800dcf793d6183b6f63a5
65	2026-05-29 12:13:42.942388+00	animales	INSERT	58fb05ea-fd35-4a8d-838c-8d7fa5f58653	\N	{"id": "58fb05ea-fd35-4a8d-838c-8d7fa5f58653", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-12-08", "crotal_oficial": "DEM-0065", "fecha_nacimiento": "2020-11-26", "estado_reproductivo": "en_celo"}	postgres	bb3a2bc5397df097ba7462aa2439c0df441d70670d73a64869ae468416c3df28
66	2026-05-29 12:13:42.942388+00	animales	INSERT	3b265584-42f8-44e0-a098-59a2cae3d2db	\N	{"id": "3b265584-42f8-44e0-a098-59a2cae3d2db", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-12-31", "crotal_oficial": "DEM-0066", "fecha_nacimiento": "2022-12-16", "estado_reproductivo": "confirmada_gestante"}	postgres	033fefd0c1e804b4e7b7ebd708dc6f10a062f54cb045a754923289484ae4860e
67	2026-05-29 12:13:42.942388+00	animales	INSERT	7d13f564-6ae2-4d35-9d0e-83408643e6bd	\N	{"id": "7d13f564-6ae2-4d35-9d0e-83408643e6bd", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-11-25", "crotal_oficial": "DEM-0067", "fecha_nacimiento": "2019-11-02", "estado_reproductivo": "confirmada_gestante"}	postgres	1e0aea1bbc9e7780c8546d42f06065fe36cfbbfafb595ad9c2c6f2534ae77ffe
68	2026-05-29 12:13:42.942388+00	animales	INSERT	acb096b0-83a9-4575-b0e3-260d5a80ee54	\N	{"id": "acb096b0-83a9-4575-b0e3-260d5a80ee54", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-02-17", "crotal_oficial": "DEM-0068", "fecha_nacimiento": "2021-01-25", "estado_reproductivo": "vacia"}	postgres	05f33534e843369439ccf77c3a764cfa91b8891b1f4cbe2a4dd3c8493fc52237
69	2026-05-29 12:13:42.942388+00	animales	INSERT	dda0bd71-8c75-4eda-a9e0-a5ec640c2645	\N	{"id": "dda0bd71-8c75-4eda-a9e0-a5ec640c2645", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-06-05", "crotal_oficial": "DEM-0069", "fecha_nacimiento": "2019-06-05", "estado_reproductivo": "confirmada_gestante"}	postgres	94a9dd22ad65e8a985c53cc097ec8b54f4fd58b50c2b189179491e16149e1e18
70	2026-05-29 12:13:42.942388+00	animales	INSERT	6ed12cf0-d9ad-4896-a0f9-40a2ead7d4a5	\N	{"id": "6ed12cf0-d9ad-4896-a0f9-40a2ead7d4a5", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-04-04", "crotal_oficial": "DEM-0070", "fecha_nacimiento": "2025-04-04", "estado_reproductivo": null}	postgres	59e1af70991fbcf099d31ca4acff6804fcd88e2609df18da590858391c2dec21
71	2026-05-29 12:13:42.942388+00	animales	INSERT	0765dd1d-c2aa-4087-8fb9-6cf783266edb	\N	{"id": "0765dd1d-c2aa-4087-8fb9-6cf783266edb", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-01-26", "crotal_oficial": "DEM-0071", "fecha_nacimiento": "2022-01-20", "estado_reproductivo": "parto_reciente"}	postgres	5b2d8f86c2519f875f7289483ac5a5f0897a708abdcfc138e41d90d25a058a58
72	2026-05-29 12:13:42.942388+00	animales	INSERT	c07a25a5-8117-4270-8fe9-aaf73a253071	\N	{"id": "c07a25a5-8117-4270-8fe9-aaf73a253071", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-03-15", "crotal_oficial": "DEM-0072", "fecha_nacimiento": "2020-03-01", "estado_reproductivo": "inseminada"}	postgres	a793df76a89abff19d2b1067e6ada19e579d18dfa98cb239fc95477a0e26868e
73	2026-05-29 12:13:42.942388+00	animales	INSERT	0d62ba03-2611-452d-bf34-3a0934bee5f4	\N	{"id": "0d62ba03-2611-452d-bf34-3a0934bee5f4", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-06-12", "crotal_oficial": "DEM-0073", "fecha_nacimiento": "2023-05-15", "estado_reproductivo": "en_celo"}	postgres	7809bb7c316717649c09d498508d0d79106a40ef367a6896ea70addb39a3fc9b
74	2026-05-29 12:13:42.942388+00	animales	INSERT	387e0bea-4d9a-40cc-a4f0-ac21503f93a8	\N	{"id": "387e0bea-4d9a-40cc-a4f0-ac21503f93a8", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-05-02", "crotal_oficial": "DEM-0074", "fecha_nacimiento": "2021-04-25", "estado_reproductivo": "en_celo"}	postgres	4652b4f54206486000986bcaaff874ede7f6017db8d2218fff438d943646625b
75	2026-05-29 12:13:42.942388+00	animales	INSERT	6fc5a4de-7cd0-41a6-a58a-6b21b719f1a7	\N	{"id": "6fc5a4de-7cd0-41a6-a58a-6b21b719f1a7", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-12-20", "crotal_oficial": "DEM-0075", "fecha_nacimiento": "2018-12-07", "estado_reproductivo": "vacia"}	postgres	76de5293b1032ec35b796ac66b0527b69c54ef644754151eab84b6ac128e2652
76	2026-05-29 12:13:42.942388+00	animales	INSERT	7bf86988-01c6-4cd5-b116-80dfde1277c1	\N	{"id": "7bf86988-01c6-4cd5-b116-80dfde1277c1", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-07-29", "crotal_oficial": "DEM-0076", "fecha_nacimiento": "2018-07-10", "estado_reproductivo": "inseminada"}	postgres	459efcabdd21fd80055ef9f487a0b75bf71dd4fd440563eb13312529470e38c3
77	2026-05-29 12:13:42.942388+00	animales	INSERT	87fb22d7-4391-4404-b641-dff004bed87f	\N	{"id": "87fb22d7-4391-4404-b641-dff004bed87f", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-10-29", "crotal_oficial": "DEM-0077", "fecha_nacimiento": "2019-10-03", "estado_reproductivo": "vacia"}	postgres	3f46cdc383864a72d2a86ea0fec432139faf0255d2c85117387693a24a2c48bf
78	2026-05-29 12:13:42.942388+00	animales	INSERT	d095654e-d0e8-4540-82f1-c2085332850b	\N	{"id": "d095654e-d0e8-4540-82f1-c2085332850b", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-29", "crotal_oficial": "DEM-0078", "fecha_nacimiento": "2026-04-29", "estado_reproductivo": null}	postgres	ac6345739eb13090ff61bca327905e544a2b7ed7550986bff89540f6bef51f52
79	2026-05-29 12:13:42.942388+00	animales	INSERT	d2ae0d6c-62cd-450e-a104-7ee7f7320480	\N	{"id": "d2ae0d6c-62cd-450e-a104-7ee7f7320480", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-08-11", "crotal_oficial": "DEM-0079", "fecha_nacimiento": "2018-08-09", "estado_reproductivo": "vacia"}	postgres	87cb3dbb1afee7566334be5d41a5eb25bc3f9c4d22413edb09e42766ee678609
80	2026-05-29 12:13:42.942388+00	animales	INSERT	47503ce1-adab-4a8f-a942-bee77c0dabdc	\N	{"id": "47503ce1-adab-4a8f-a942-bee77c0dabdc", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-11-17", "crotal_oficial": "DEM-0080", "fecha_nacimiento": "2021-10-22", "estado_reproductivo": "en_celo"}	postgres	2663920ea90d29bf4381b8cdfcf55817fb6555c88aa0e05bbbab1647b9e00bfc
81	2026-05-29 12:13:42.942388+00	animales	INSERT	a345a474-de66-4499-be25-1f4604108ce7	\N	{"id": "a345a474-de66-4499-be25-1f4604108ce7", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-10-27", "crotal_oficial": "DEM-0081", "fecha_nacimiento": "2020-09-27", "estado_reproductivo": "confirmada_gestante"}	postgres	4b1f6ffcc3432d3eb52a989cdd3d638391fb2104d85e5292c4fd0e064dc57192
82	2026-05-29 12:13:42.942388+00	animales	INSERT	608f6c8d-8d57-4abe-8b78-946a32c6a037	\N	{"id": "608f6c8d-8d57-4abe-8b78-946a32c6a037", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-08-05", "crotal_oficial": "DEM-0082", "fecha_nacimiento": "2021-07-24", "estado_reproductivo": "en_celo"}	postgres	56c43ba138fba8c36741363dab5485c6c86f62bcdc469cbe56d701e788e6b11c
83	2026-05-29 12:13:42.942388+00	animales	INSERT	561c4988-c9c5-49d7-8b6e-72a186c342b1	\N	{"id": "561c4988-c9c5-49d7-8b6e-72a186c342b1", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-10-01", "crotal_oficial": "DEM-0083", "fecha_nacimiento": "2025-10-01", "estado_reproductivo": null}	postgres	f08bce6f1908402a7bf2cf58b336223fb963ac4c404e2981bf4fe718368ac42b
84	2026-05-29 12:13:42.942388+00	animales	INSERT	80c0ec2f-41c9-43e4-a2db-11f0ba7c790d	\N	{"id": "80c0ec2f-41c9-43e4-a2db-11f0ba7c790d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-04-23", "crotal_oficial": "DEM-0084", "fecha_nacimiento": "2023-04-15", "estado_reproductivo": "vacia"}	postgres	63058caf65a101e1eca5f2e619f311630514b7d41a0c02d64308f6dbc95b5656
85	2026-05-29 12:13:42.942388+00	animales	INSERT	2eff0653-a8aa-4b79-8a80-8c5bed9233f3	\N	{"id": "2eff0653-a8aa-4b79-8a80-8c5bed9233f3", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-10-02", "crotal_oficial": "DEM-0085", "fecha_nacimiento": "2019-09-03", "estado_reproductivo": "confirmada_gestante"}	postgres	ec1990279697d8b4f3ffe4ef6c454f447beff55258a87eac6ca6f4f5fe9d3f31
86	2026-05-29 12:13:42.942388+00	animales	INSERT	f54a614e-2dec-49ea-a29c-1f654d0f77bb	\N	{"id": "f54a614e-2dec-49ea-a29c-1f654d0f77bb", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-11-23", "crotal_oficial": "DEM-0086", "fecha_nacimiento": "2018-11-07", "estado_reproductivo": "inseminada"}	postgres	71945cc5e9609df1c80db604b89d6623e0631c1f5c1c36484fc81fe66dd0400a
87	2026-05-29 12:13:42.942388+00	animales	INSERT	8485de9f-b75c-41cc-95c4-0fa4926b9987	\N	{"id": "8485de9f-b75c-41cc-95c4-0fa4926b9987", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-09-06", "crotal_oficial": "DEM-0087", "fecha_nacimiento": "2021-08-23", "estado_reproductivo": "confirmada_gestante"}	postgres	77b108a151ce4bca15ef5e4b1216ba307628008d43736729019b8be096acf7dc
88	2026-05-29 12:13:42.942388+00	animales	INSERT	f65f94d5-2741-4946-acbe-97a2132c0563	\N	{"id": "f65f94d5-2741-4946-acbe-97a2132c0563", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-06-24", "crotal_oficial": "DEM-0088", "fecha_nacimiento": "2020-05-30", "estado_reproductivo": "en_celo"}	postgres	2c707a9081f6d0e7c1e941faa3b23da3116acca189bcf2ff1985c4ef6e97576d
89	2026-05-29 12:13:42.942388+00	animales	INSERT	eb67de13-28c1-4394-9f31-a1e3406ca176	\N	{"id": "eb67de13-28c1-4394-9f31-a1e3406ca176", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-12-30", "crotal_oficial": "DEM-0089", "fecha_nacimiento": "2025-12-30", "estado_reproductivo": null}	postgres	b3bc800a70dbd3086adcb6f97a3133f360bd26232cfa44a276e691977a2ceb9c
90	2026-05-29 12:13:42.942388+00	animales	INSERT	fb7fa4dd-669e-48b6-89e4-757b694f5b07	\N	{"id": "fb7fa4dd-669e-48b6-89e4-757b694f5b07", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-06-16", "crotal_oficial": "DEM-0090", "fecha_nacimiento": "2021-05-25", "estado_reproductivo": "inseminada"}	postgres	dbf39553ce4df7fc8ac8e4bced0e58dc034518e96a0944824baab349c2eb3463
91	2026-05-29 12:13:42.942388+00	animales	INSERT	62f76f1d-c125-423a-9592-328be33a4b37	\N	{"id": "62f76f1d-c125-423a-9592-328be33a4b37", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2020-12-10", "crotal_oficial": "DEM-0091", "fecha_nacimiento": "2020-11-26", "estado_reproductivo": "vacia"}	postgres	509b15dff690f961589e7df5d712e4361752af960002f167625041f3ee3b2cce
92	2026-05-29 12:13:42.942388+00	animales	INSERT	43c99312-c53e-478f-bb81-3302148f7c23	\N	{"id": "43c99312-c53e-478f-bb81-3302148f7c23", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-06-12", "crotal_oficial": "DEM-0092", "fecha_nacimiento": "2021-05-25", "estado_reproductivo": "inseminada"}	postgres	c8f51bde4d3d8a3b908e933caa64eebd92906999200b10c4a82fc4d0627f4b44
93	2026-05-29 12:13:42.942388+00	animales	INSERT	bdfc9cf7-e471-44a1-98d5-702c6f484a73	\N	{"id": "bdfc9cf7-e471-44a1-98d5-702c6f484a73", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-10-26", "crotal_oficial": "DEM-0093", "fecha_nacimiento": "2023-10-12", "estado_reproductivo": "confirmada_gestante"}	postgres	3f3698fa255d6cadb4e100aa3dea092478c2d6c53bcabb2f66c9939af72ec050
94	2026-05-29 12:13:42.942388+00	animales	INSERT	b977bad8-5e76-4ff5-86c6-d22021c984c7	\N	{"id": "b977bad8-5e76-4ff5-86c6-d22021c984c7", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-11-20", "crotal_oficial": "DEM-0094", "fecha_nacimiento": "2019-11-02", "estado_reproductivo": "inseminada"}	postgres	9afe0557daa822ff3dd9119ee7444e9cad5b8035a32fe9aff1981eb6559dc840
95	2026-05-29 12:13:42.942388+00	animales	INSERT	66cf9283-9e0b-48f2-8b8f-9687bf6dfe99	\N	{"id": "66cf9283-9e0b-48f2-8b8f-9687bf6dfe99", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "baja", "nombre": null, "madre_id": null, "fecha_baja": "2026-04-17", "motivo_baja": "Problema reproductivo", "fecha_entrada": "2022-12-16", "crotal_oficial": "DEM-0095", "fecha_nacimiento": "2022-12-16", "estado_reproductivo": null}	postgres	3d81505489850e22b94a5d290dd8b76bdcd32087fc1807db4cc3e8be4463d35d
96	2026-05-29 12:13:42.942388+00	animales	INSERT	d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	\N	{"id": "d153ced6-2a4b-4f8a-99ea-dbce009d2dd5", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-11-10", "crotal_oficial": "DEM-0096", "fecha_nacimiento": "2019-11-02", "estado_reproductivo": "vacia"}	postgres	b93886e3c97129a2063c1d50003dcd17ab95a229561401f86951d124b4fd0962
97	2026-05-29 12:13:42.942388+00	animales	INSERT	9d2f8668-e36c-4578-81d6-001ada65572e	\N	{"id": "9d2f8668-e36c-4578-81d6-001ada65572e", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "seca", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-03-16", "crotal_oficial": "DEM-0097", "fecha_nacimiento": "2019-03-07", "estado_reproductivo": "confirmada_gestante"}	postgres	165fd2704705e3aba864036f73f30d7db0c0799796a03ab07a21146622396640
98	2026-05-29 12:13:42.942388+00	animales	INSERT	1a845209-5c9d-4833-a874-f20e1fc49d54	\N	{"id": "1a845209-5c9d-4833-a874-f20e1fc49d54", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-07-19", "crotal_oficial": "DEM-0098", "fecha_nacimiento": "2022-06-19", "estado_reproductivo": "inseminada"}	postgres	7d707919a063ab0eefec6f3d43f611f9aea1d625cbd777649beb23d7d671ac80
99	2026-05-29 12:13:42.942388+00	animales	INSERT	f888e29c-efcf-4c60-995a-d9279f958103	\N	{"id": "f888e29c-efcf-4c60-995a-d9279f958103", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2024-12-05", "crotal_oficial": "DEM-0099", "fecha_nacimiento": "2024-12-05", "estado_reproductivo": null}	postgres	46bb124b6e8dcdb4f01ec203a87a6e0ab9cc3d63d3353a5b9c954cab89bc721c
100	2026-05-29 12:13:42.942388+00	animales	INSERT	86892057-2f7f-478f-bbcb-61110313ffd9	\N	{"id": "86892057-2f7f-478f-bbcb-61110313ffd9", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-09-15", "crotal_oficial": "DEM-0100", "fecha_nacimiento": "2022-08-18", "estado_reproductivo": "en_celo"}	postgres	32adf34596a1799340d6a8f4b8b9d6d9bc0e6e7c29edc1417f42ec450c7020ae
101	2026-05-29 12:13:42.942388+00	animales	INSERT	6381dfbb-7d0b-4360-ba02-62e5dd932437	\N	{"id": "6381dfbb-7d0b-4360-ba02-62e5dd932437", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-11-30", "crotal_oficial": "DEM-0101", "fecha_nacimiento": "2025-11-30", "estado_reproductivo": null}	postgres	4e83c7d78ef778674fb65ac053f12834f7d386b8844903538c0ef9ad1b058d27
102	2026-05-29 12:13:42.942388+00	animales	INSERT	594223a0-9f8a-498e-8487-424895a3d0b0	\N	{"id": "594223a0-9f8a-498e-8487-424895a3d0b0", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-06-26", "crotal_oficial": "DEM-0102", "fecha_nacimiento": "2019-06-05", "estado_reproductivo": "confirmada_gestante"}	postgres	c74de6d0b4c1d507c7c9e9c8c1734d6a1baaf014f1520f65a106a68b3641f3d4
103	2026-05-29 12:13:42.942388+00	animales	INSERT	4f921cd6-0fc9-4628-a46d-8ff93466e82c	\N	{"id": "4f921cd6-0fc9-4628-a46d-8ff93466e82c", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-09-23", "crotal_oficial": "DEM-0103", "fecha_nacimiento": "2023-09-12", "estado_reproductivo": "inseminada"}	postgres	c17c36ce0b1998aabad39f9472f01fd4bbb3807557d0ab0b970ba159ef221b15
104	2026-05-29 12:13:42.942388+00	animales	INSERT	f664da5c-e84f-4de3-abe2-954a07871fae	\N	{"id": "f664da5c-e84f-4de3-abe2-954a07871fae", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-01-02", "crotal_oficial": "DEM-0104", "fecha_nacimiento": "2018-12-07", "estado_reproductivo": "confirmada_gestante"}	postgres	84da352f7c9c11b8d4949e65fda15cdc7e715ae3ef24eb0c1d731260a9bcdcdd
105	2026-05-29 12:13:42.942388+00	animales	INSERT	ff998675-ed1e-4229-aab0-3d86147177c2	\N	{"id": "ff998675-ed1e-4229-aab0-3d86147177c2", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-03-04", "crotal_oficial": "DEM-0105", "fecha_nacimiento": "2023-02-14", "estado_reproductivo": "inseminada"}	postgres	4f589f986c2d99c9c7d1aa6b060115e5f0fe05bf5b84a9886646f3e1cd71f09e
106	2026-05-29 12:13:42.942388+00	animales	INSERT	edcb3743-9a2c-455e-84d2-b68d69c83fbb	\N	{"id": "edcb3743-9a2c-455e-84d2-b68d69c83fbb", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-05-04", "crotal_oficial": "DEM-0106", "fecha_nacimiento": "2025-05-04", "estado_reproductivo": null}	postgres	eec2c1452e3de16607b34d427ef3fe935c592cce10d6d48714f3b14a81a874b0
107	2026-05-29 12:13:42.942388+00	animales	INSERT	ee9d5c30-3592-449b-b211-9a1e1add7685	\N	{"id": "ee9d5c30-3592-449b-b211-9a1e1add7685", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-01-04", "crotal_oficial": "DEM-0107", "fecha_nacimiento": "2025-01-04", "estado_reproductivo": null}	postgres	a46309167eba6e2d982561346a52d826017cd9a9255c1a11c39a0d70c2146012
108	2026-05-29 12:13:42.942388+00	animales	INSERT	9fcc4de5-8fec-4f04-85ea-57963cba6119	\N	{"id": "9fcc4de5-8fec-4f04-85ea-57963cba6119", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-01-23", "crotal_oficial": "DEM-0108", "fecha_nacimiento": "2019-01-06", "estado_reproductivo": "parto_reciente"}	postgres	cd4e70c9874dbfd88ec3a460f6f352487074d77e0722360a8d1cebc045f19a4b
109	2026-05-29 12:13:42.942388+00	animales	INSERT	2c611aa8-a92c-4556-8568-9294bab47d5d	\N	{"id": "2c611aa8-a92c-4556-8568-9294bab47d5d", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-03-16", "crotal_oficial": "DEM-0109", "fecha_nacimiento": "2022-02-19", "estado_reproductivo": "confirmada_gestante"}	postgres	7997783c8d51dffe89f9e0ade39a934e394a880140e29ec371c6308eec7ca32b
110	2026-05-29 12:13:42.942388+00	animales	INSERT	9c643bba-a6d5-40c8-b023-f781c9763028	\N	{"id": "9c643bba-a6d5-40c8-b023-f781c9763028", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-07-02", "crotal_oficial": "DEM-0110", "fecha_nacimiento": "2023-06-14", "estado_reproductivo": "inseminada"}	postgres	f9fd2c533843406c460bbeedee56fa4b86b13ec90605b558854df7d6f041a01a
111	2026-05-29 12:13:42.942388+00	animales	INSERT	c78d9927-66e8-4aee-8e04-b83ec129c31d	\N	{"id": "c78d9927-66e8-4aee-8e04-b83ec129c31d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2022-06-06", "crotal_oficial": "DEM-0111", "fecha_nacimiento": "2022-05-20", "estado_reproductivo": "confirmada_gestante"}	postgres	fa9bee16b59cc5b36a8f19acd0402d5a01580d603330b07a8b0245b03ff56179
112	2026-05-29 12:13:42.942388+00	animales	INSERT	c659f4da-3f7d-46e7-8993-0536c9640c3d	\N	{"id": "c659f4da-3f7d-46e7-8993-0536c9640c3d", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2019-05-11", "crotal_oficial": "DEM-0112", "fecha_nacimiento": "2019-05-06", "estado_reproductivo": "confirmada_gestante"}	postgres	7ac5298b2caf015f40c7c7ce5a9f5339704150cdf735e78fcba69c71793d7224
113	2026-05-29 12:13:42.942388+00	animales	INSERT	f530bb0a-99a5-420f-9e18-6cb1dbd1973e	\N	{"id": "f530bb0a-99a5-420f-9e18-6cb1dbd1973e", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-07-06", "crotal_oficial": "DEM-0113", "fecha_nacimiento": "2021-06-24", "estado_reproductivo": "confirmada_gestante"}	postgres	64db0cf42b5756ec4dc963441231ccf3353836e44d782d913eba2c2811618a80
114	2026-05-29 12:13:42.942388+00	animales	INSERT	6784e799-962c-4527-b86a-c96905fff757	\N	{"id": "6784e799-962c-4527-b86a-c96905fff757", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2023-08-18", "crotal_oficial": "DEM-0114", "fecha_nacimiento": "2023-08-13", "estado_reproductivo": "confirmada_gestante"}	postgres	95f0056a0342f225d2b186a595699a20d3b4e68a797e3e5ca7b9ac6d66f724b4
115	2026-05-29 12:13:42.942388+00	animales	INSERT	24aaa09d-d02d-470e-a6c9-33f1559eee31	\N	{"id": "24aaa09d-d02d-470e-a6c9-33f1559eee31", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-06-03", "crotal_oficial": "DEM-0115", "fecha_nacimiento": "2025-06-03", "estado_reproductivo": null}	postgres	74ad7d7bd3803eb65ea3019a79e68054286a98ac089d0f70955d2223e1df6fee
116	2026-05-29 12:13:42.942388+00	animales	INSERT	002ec462-63a3-4b84-b040-e153b51b3dde	\N	{"id": "002ec462-63a3-4b84-b040-e153b51b3dde", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2025-01-04", "crotal_oficial": "DEM-0116", "fecha_nacimiento": "2025-01-04", "estado_reproductivo": null}	postgres	17236ae6bb78007002d99234526c974e833360e12d0968da26b937db928107e9
117	2026-05-29 12:13:42.942388+00	animales	INSERT	0cf23273-77eb-459b-abc4-d9475392e8af	\N	{"id": "0cf23273-77eb-459b-abc4-d9475392e8af", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "gestante", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2018-12-15", "crotal_oficial": "DEM-0117", "fecha_nacimiento": "2018-12-07", "estado_reproductivo": "parto_reciente"}	postgres	cb41f4c4a2d3d4b73652df46ea7b0fb252a4ba5d54ea3f20ccec691cd8ce5629
118	2026-05-29 12:13:42.942388+00	animales	INSERT	121e0d34-5536-4a93-948b-d9581d928d3d	\N	{"id": "121e0d34-5536-4a93-948b-d9581d928d3d", "raza": "Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-10-19", "crotal_oficial": "DEM-0118", "fecha_nacimiento": "2021-09-22", "estado_reproductivo": "en_celo"}	postgres	614fa5489c4ae7dffcd7c18e8e6cedeb49e480be78fcabd5a7fef89e2ef55946
119	2026-05-29 12:13:42.942388+00	animales	INSERT	129b3aee-511f-4fa5-b8a4-f71b8e8faacb	\N	{"id": "129b3aee-511f-4fa5-b8a4-f71b8e8faacb", "raza": "Cruce Frisona-Jersey", "sexo": "hembra", "notas": "[DEMO]", "estado": "recria", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2026-04-29", "crotal_oficial": "DEM-0119", "fecha_nacimiento": "2026-04-29", "estado_reproductivo": null}	postgres	6489de6433e7f8bd7d73eaed14cd9ac6fa6031dd37423664a0ff3fc79c41766e
120	2026-05-29 12:13:42.942388+00	animales	INSERT	a58bf738-0ced-454e-a89e-779af50bdde6	\N	{"id": "a58bf738-0ced-454e-a89e-779af50bdde6", "raza": "Frisona", "sexo": "hembra", "notas": "[DEMO]", "estado": "produccion", "nombre": null, "madre_id": null, "fecha_baja": null, "motivo_baja": null, "fecha_entrada": "2021-10-16", "crotal_oficial": "DEM-0120", "fecha_nacimiento": "2021-09-22", "estado_reproductivo": "vacia"}	postgres	51dd305b64167f0e482565fb3906f1af06637ef050676706f56ce3f5b9bb8b47
132	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	c63beadb-649c-49eb-ab8e-8fd80bc8aa2d	\N	{"id": "c63beadb-649c-49eb-ab8e-8fd80bc8aa2d", "dosis": "5 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": true, "farmaco": "Electrolitos rehidratación", "animal_id": "6b02089e-b0dc-40cf-a70c-a0fd1f9f407f", "checkboxes": [], "fecha_inicio": "2026-05-27", "prescrito_por": "c319a64d-36f2-4c7b-a4e2-e61f08b36d28", "fecha_fin_real": null, "dias_tratamiento": 5, "fecha_fin_prevista": "2026-06-01", "via_administracion": "oral", "evento_sanitario_id": null}	postgres	5fd8e1381fa8ea7e8ac41e4c0bf11abd708c2d5473b9e34a32554e760f2991e1
133	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	9fc8d7a0-e7c2-4382-a0a3-37907be6a56a	\N	{"id": "9fc8d7a0-e7c2-4382-a0a3-37907be6a56a", "dosis": "1 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": true, "farmaco": "Oxitetraciclina 200mg/ml", "animal_id": "2ecf6665-0c82-488d-9749-7941de974abf", "checkboxes": [], "fecha_inicio": "2026-05-27", "prescrito_por": "2d200ce2-5f48-4285-8d33-98f06db5b194", "fecha_fin_real": null, "dias_tratamiento": 4, "fecha_fin_prevista": "2026-05-31", "via_administracion": "IM", "evento_sanitario_id": null}	postgres	2a0ab4bc2c783c66f84e2dc94f23ea545b831a17dec7c7c4cac3102bb7b350f4
134	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	23621ecc-2cfc-4607-803f-97eb8dc937d7	\N	{"id": "23621ecc-2cfc-4607-803f-97eb8dc937d7", "dosis": "1 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": true, "farmaco": "Propóleo tópico", "animal_id": "80c0ec2f-41c9-43e4-a2db-11f0ba7c790d", "checkboxes": [], "fecha_inicio": "2026-05-28", "prescrito_por": "7f75e608-6c5b-429b-a36f-a644cc41501b", "fecha_fin_real": null, "dias_tratamiento": 10, "fecha_fin_prevista": "2026-06-07", "via_administracion": "topica", "evento_sanitario_id": null}	postgres	3656e799b48b33bf641ec2b8386e5225f2812cadc5604192a4eeb8cd4ecc1bad
135	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	2b6475b8-f4b9-482d-ae1c-b67cb8b538cd	\N	{"id": "2b6475b8-f4b9-482d-ae1c-b67cb8b538cd", "dosis": "1 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": true, "farmaco": "Ketoprofeno 100mg/ml", "animal_id": "26d26b4b-30bb-4860-9c60-15c5ddcb244c", "checkboxes": [], "fecha_inicio": "2026-05-27", "prescrito_por": "43958ec8-b358-4c41-bb4c-9b55cacfc8db", "fecha_fin_real": null, "dias_tratamiento": 3, "fecha_fin_prevista": "2026-05-30", "via_administracion": "IV", "evento_sanitario_id": null}	postgres	9bf1f7dbae6f3fdee06bfddd415eefcd79f2b8cec7b5740afcbb5531b3bdca3c
136	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	c258dc77-5840-4b08-9d86-58ada07175be	\N	{"id": "c258dc77-5840-4b08-9d86-58ada07175be", "dosis": "1 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": true, "farmaco": "Ketoprofeno 100mg/ml", "animal_id": "d153ced6-2a4b-4f8a-99ea-dbce009d2dd5", "checkboxes": [], "fecha_inicio": "2026-05-29", "prescrito_por": "513ad92d-a581-4d5b-b01e-7b3654f4482c", "fecha_fin_real": null, "dias_tratamiento": 3, "fecha_fin_prevista": "2026-06-01", "via_administracion": "IV", "evento_sanitario_id": null}	postgres	5900873b8f6452e3ae8f3523522a163ca450ba4279460aed1ff88e8f9678cd1f
137	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	318a9a79-a840-419a-8af2-98ab93f40fc5	\N	{"id": "318a9a79-a840-419a-8af2-98ab93f40fc5", "dosis": "1 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": true, "farmaco": "Meloxicam 20mg/ml", "animal_id": "3ee55362-8374-452c-ac80-5a93545bab2a", "checkboxes": [], "fecha_inicio": "2026-05-28", "prescrito_por": "6e67bdeb-6e1e-490d-a29d-d69f6155ab99", "fecha_fin_real": null, "dias_tratamiento": 3, "fecha_fin_prevista": "2026-05-31", "via_administracion": "IV", "evento_sanitario_id": null}	postgres	f0246040ffe875212d838a2763d724e41861e68b35a4d41f31372b07fa7e8e5d
138	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	49fdd478-74b9-42a5-8f3f-9ec34fbec9f6	\N	{"id": "49fdd478-74b9-42a5-8f3f-9ec34fbec9f6", "dosis": "4 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": true, "farmaco": "Cloxacilina 500mg", "animal_id": "47503ce1-adab-4a8f-a942-bee77c0dabdc", "checkboxes": [], "fecha_inicio": "2026-05-28", "prescrito_por": "b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37", "fecha_fin_real": null, "dias_tratamiento": 5, "fecha_fin_prevista": "2026-06-02", "via_administracion": "intramamaria", "evento_sanitario_id": null}	postgres	4947fac261c2fd1e1c00d30664d5420e3789bcd9f1e17e607ebca1a681c37edc
139	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	dd9f6596-99af-4e94-b690-1faf4a46b5d8	\N	{"id": "dd9f6596-99af-4e94-b690-1faf4a46b5d8", "dosis": "4 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": false, "farmaco": "Meloxicam 20mg/ml", "animal_id": "f664da5c-e84f-4de3-abe2-954a07871fae", "checkboxes": [], "fecha_inicio": "2026-05-17", "prescrito_por": "6e67bdeb-6e1e-490d-a29d-d69f6155ab99", "fecha_fin_real": "2026-05-20", "dias_tratamiento": 3, "fecha_fin_prevista": "2026-05-20", "via_administracion": "IV", "evento_sanitario_id": null}	postgres	ded53eaf47bc330cd7a06943ec66d7e7d44c085c693d8fcc81400c46f7738ce6
140	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	4e986562-45bc-4ef7-8b7d-f6570a4ceb05	\N	{"id": "4e986562-45bc-4ef7-8b7d-f6570a4ceb05", "dosis": "2 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": false, "farmaco": "Oxitetraciclina 200mg/ml", "animal_id": "14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5", "checkboxes": [], "fecha_inicio": "2026-04-06", "prescrito_por": "60da9a93-e0f2-403b-a534-e35383483df5", "fecha_fin_real": "2026-04-11", "dias_tratamiento": 4, "fecha_fin_prevista": "2026-04-10", "via_administracion": "IM", "evento_sanitario_id": null}	postgres	8d7cd1fcaeb58d4fe6f1b417fd454c57db1e40b6e3f6b7055fd55ecd5376d9eb
141	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	c281aefb-e3ef-4e06-91f5-57c1bee08afe	\N	{"id": "c281aefb-e3ef-4e06-91f5-57c1bee08afe", "dosis": "4 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": false, "farmaco": "Propóleo tópico", "animal_id": "41098454-a4a4-45db-bc95-a2793218055b", "checkboxes": [], "fecha_inicio": "2026-04-14", "prescrito_por": "f0025158-31bd-47b3-b90a-3c3d08ed1dd8", "fecha_fin_real": "2026-04-24", "dias_tratamiento": 10, "fecha_fin_prevista": "2026-04-24", "via_administracion": "topica", "evento_sanitario_id": null}	postgres	8ab14d26ae33516bb8d542b3181f3c3585c506bc0188ac0c26d46d223d595dba
142	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	e8e436b5-cbf7-4e05-9ef4-bc0c410b1b44	\N	{"id": "e8e436b5-cbf7-4e05-9ef4-bc0c410b1b44", "dosis": "3 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": false, "farmaco": "Cloxacilina 500mg", "animal_id": "003a9fe9-e4a0-447f-bcdb-57439cd5e412", "checkboxes": [], "fecha_inicio": "2026-03-30", "prescrito_por": "bce871fe-c311-4bf1-a14f-ddf3b31b5f8f", "fecha_fin_real": "2026-04-06", "dias_tratamiento": 5, "fecha_fin_prevista": "2026-04-04", "via_administracion": "intramamaria", "evento_sanitario_id": null}	postgres	bafa1cf24c0400600dfd737af18182152337abaff22b096caa82aed8a83534a4
143	2026-05-29 12:16:23.581956+00	tratamientos_activos	INSERT	2bd7e622-7d04-466b-8d94-deb16cd70f89	\N	{"id": "2bd7e622-7d04-466b-8d94-deb16cd70f89", "dosis": "2 dosis/día", "notas": "[DEMO] tratamiento demo", "activo": false, "farmaco": "Propóleo tópico", "animal_id": "bca99578-d4de-422a-b04f-1ae3da4d3b43", "checkboxes": [], "fecha_inicio": "2026-04-07", "prescrito_por": "6e67bdeb-6e1e-490d-a29d-d69f6155ab99", "fecha_fin_real": "2026-04-17", "dias_tratamiento": 10, "fecha_fin_prevista": "2026-04-17", "via_administracion": "topica", "evento_sanitario_id": null}	postgres	152cde933a15012c9fd381a022f7b945442ef3dbe52766712bda902778acb0cc
144	2026-05-29 12:16:23.75923+00	incidencias	INSERT	57104782-3b3a-46db-bb3e-fcc8774675c5	\N	{"id": "57104782-3b3a-46db-bb3e-fcc8774675c5", "tipo": "calidad_leche", "estado": "resuelta", "titulo": "[DEMO] RCS elevado en tanque lote mañana", "subtipo": null, "zona_id": "521c30a0-4751-4157-87d0-6aaf2c9c882d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-19T12:16:23.766175+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-18T13:16:23.766175+00:00", "maquinaria_id": null, "reportado_por": "f0025158-31bd-47b3-b90a-3c3d08ed1dd8"}	postgres	56d4cf8e7aaa82de239c51687f27bbbbc9d02dabb92bc43adb4c8532683cb724
145	2026-05-29 12:16:23.75923+00	incidencias	INSERT	fef76430-4f32-4296-9326-f4a2fd2321b2	\N	{"id": "fef76430-4f32-4296-9326-f4a2fd2321b2", "tipo": "pedidos", "estado": "abierta", "titulo": "[DEMO] Stock crítico desinfectante pezones", "subtipo": null, "zona_id": "df0512cb-3963-4225-97dd-242b835a8118", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-02T01:16:23.770207+00:00", "maquinaria_id": null, "reportado_por": "2d200ce2-5f48-4285-8d33-98f06db5b194"}	postgres	df2f1a23026a1ae79c9bfdae1073d61ec24d6161c27db77cf5a0fcf029b8f6b7
146	2026-05-29 12:16:23.75923+00	incidencias	INSERT	460f04af-e5a2-4fbb-91e2-039bdd9981a1	\N	{"id": "460f04af-e5a2-4fbb-91e2-039bdd9981a1", "tipo": "alimentacion", "estado": "en_gestion", "titulo": "[DEMO] Rotura tolva concentrado", "subtipo": null, "zona_id": "521c30a0-4751-4157-87d0-6aaf2c9c882d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-22T06:16:23.771055+00:00", "maquinaria_id": null, "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	1f4cd7e9b5318cdbb2e21e721e1351ed0fd38c000db0c0a785b59a8380823694
147	2026-05-29 12:16:23.75923+00	incidencias	INSERT	3b291fca-8d4c-4d00-b2af-fa224da22ec6	\N	{"id": "3b291fca-8d4c-4d00-b2af-fa224da22ec6", "tipo": "calidad_leche", "estado": "abierta", "titulo": "[DEMO] Resto antibiótico detectado control", "subtipo": null, "zona_id": "597ad6cc-663d-4eb8-8d08-286d22050b1d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-23T02:16:23.771809+00:00", "maquinaria_id": null, "reportado_por": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	postgres	d627e3c98d782262770ab7dcbd9a2ccb211c0bfdf67c92cae915466c54cbced0
148	2026-05-29 12:16:23.75923+00	incidencias	INSERT	ea517d4a-e7ff-4086-b3d0-adb827aedc8c	\N	{"id": "ea517d4a-e7ff-4086-b3d0-adb827aedc8c", "tipo": "calidad_leche", "estado": "en_gestion", "titulo": "[DEMO] Conductividad anómala cuarto posterior", "subtipo": null, "zona_id": "df0512cb-3963-4225-97dd-242b835a8118", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-07T23:16:23.772407+00:00", "maquinaria_id": null, "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	c222f0837d2262f973d3d4fce5452a3bdd0e9062802b70fe06a47bd32d155753
149	2026-05-29 12:16:23.75923+00	incidencias	INSERT	4da19053-3362-41c2-9115-91f7484af1d4	\N	{"id": "4da19053-3362-41c2-9115-91f7484af1d4", "tipo": "sanidad_animal", "estado": "abierta", "titulo": "[DEMO] Animal con fiebre post-parto", "subtipo": null, "zona_id": null, "acciones": [], "foto_url": null, "animal_id": "41098454-a4a4-45db-bc95-a2793218055b", "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-04-29T01:16:23.77313+00:00", "maquinaria_id": null, "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	8ca340b033013e6a36ab3565b55492881b1d10381c1b6db6389bb046be157a20
150	2026-05-29 12:16:23.75923+00	incidencias	INSERT	c84d0257-09f6-419e-bf69-a0d348c67c46	\N	{"id": "c84d0257-09f6-419e-bf69-a0d348c67c46", "tipo": "averia_maquinaria", "estado": "resuelta", "titulo": "[DEMO] Avería bomba de vacío principal", "subtipo": null, "zona_id": "3836de7c-0b6f-4306-904d-825890b6f534", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-08T00:16:23.773889+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-05T21:16:23.773889+00:00", "maquinaria_id": "c0078401-da96-4091-b26d-b69f4509abed", "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	40af37d148e8d7c69d2a88394cfe56c372fbc1a287e62232becb925fcb42cd7c
151	2026-05-29 12:16:23.75923+00	incidencias	INSERT	b2300f7a-842c-4896-a2dc-d5b1386e6b52	\N	{"id": "b2300f7a-842c-4896-a2dc-d5b1386e6b52", "tipo": "alimentacion", "estado": "cerrada", "titulo": "[DEMO] Silo forraje con humedad excesiva", "subtipo": null, "zona_id": "3836de7c-0b6f-4306-904d-825890b6f534", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-04-28T21:16:23.774712+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-04-28T19:16:23.774712+00:00", "maquinaria_id": null, "reportado_por": "2d200ce2-5f48-4285-8d33-98f06db5b194"}	postgres	6f192e39a34365d2e52c2ee6be81d0290059c74b47e48995a423269193bba90d
152	2026-05-29 12:16:23.75923+00	incidencias	INSERT	117a1471-578b-49d4-a7a8-d93a53c1a583	\N	{"id": "117a1471-578b-49d4-a7a8-d93a53c1a583", "tipo": "averia_maquinaria", "estado": "en_gestion", "titulo": "[DEMO] Motor carro mezclador ruidoso", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-27T09:16:23.775292+00:00", "maquinaria_id": "45fb58d3-75be-4b9a-a676-92af4911fee4", "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	5d741a790d45eae589854f3259eabf5f0f22d1b183820788bc4e719e0838dfdf
153	2026-05-29 12:16:23.75923+00	incidencias	INSERT	8f17373c-76bb-46c8-a0fb-162cb127d520	\N	{"id": "8f17373c-76bb-46c8-a0fb-162cb127d520", "tipo": "pedidos", "estado": "cerrada", "titulo": "[DEMO] Stock crítico desinfectante pezones", "subtipo": null, "zona_id": "3836de7c-0b6f-4306-904d-825890b6f534", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-18T18:16:23.776232+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-16T07:16:23.776232+00:00", "maquinaria_id": null, "reportado_por": "b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37"}	postgres	9af6eb4a90bb66f347c3b58d37cbc76ce6ebcb2e892ec4c8e733e2c495bf201e
154	2026-05-29 12:16:23.75923+00	incidencias	INSERT	e5ae3c34-4a70-40e7-9ef8-c3793de41213	\N	{"id": "e5ae3c34-4a70-40e7-9ef8-c3793de41213", "tipo": "calidad_leche", "estado": "resuelta", "titulo": "[DEMO] Conductividad anómala cuarto posterior", "subtipo": null, "zona_id": "df0512cb-3963-4225-97dd-242b835a8118", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-02T05:16:23.777641+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-01T19:16:23.777641+00:00", "maquinaria_id": null, "reportado_por": "c319a64d-36f2-4c7b-a4e2-e61f08b36d28"}	postgres	23365d886506488ac8f4004a7e5f8d68cf1f0585eb2628da4c509bebaefd8154
155	2026-05-29 12:16:23.75923+00	incidencias	INSERT	72838dd9-ae62-4f1a-b37f-335e7aed4af3	\N	{"id": "72838dd9-ae62-4f1a-b37f-335e7aed4af3", "tipo": "infraestructura", "estado": "cerrada", "titulo": "[DEMO] Fuga de agua en bebedero zona recría", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-01T22:16:23.778623+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-04-28T22:16:23.778623+00:00", "maquinaria_id": null, "reportado_por": "bce871fe-c311-4bf1-a14f-ddf3b31b5f8f"}	postgres	6b0ed0b74cad6c790d015d030bc3fb0b979cdb0f395b903f98700339ea89a506
156	2026-05-29 12:16:23.75923+00	incidencias	INSERT	4e152825-e020-4107-bc86-e293fb209106	\N	{"id": "4e152825-e020-4107-bc86-e293fb209106", "tipo": "sanidad_animal", "estado": "en_gestion", "titulo": "[DEMO] Cojera leve detectada en animal", "subtipo": null, "zona_id": null, "acciones": [], "foto_url": null, "animal_id": "f664da5c-e84f-4de3-abe2-954a07871fae", "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-13T09:16:23.779654+00:00", "maquinaria_id": null, "reportado_por": "b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37"}	postgres	28d4581b77da3a9e719e3f6ef678674e207bcfde95f290b18406e1d9a88b2486
157	2026-05-29 12:16:23.75923+00	incidencias	INSERT	305ab9c5-10ba-4d47-ae13-524cf96f8767	\N	{"id": "305ab9c5-10ba-4d47-ae13-524cf96f8767", "tipo": "infraestructura", "estado": "en_gestion", "titulo": "[DEMO] Fuga de agua en bebedero zona recría", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-28T20:16:23.780516+00:00", "maquinaria_id": null, "reportado_por": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	postgres	09dd82c0c781a0af7408546fdf3f2e68c5c4bee5af474b9c7334608e65062863
158	2026-05-29 12:16:23.75923+00	incidencias	INSERT	591b599b-3526-4e0f-a07e-dc501b4d7527	\N	{"id": "591b599b-3526-4e0f-a07e-dc501b4d7527", "tipo": "infraestructura", "estado": "resuelta", "titulo": "[DEMO] Iluminación defectuosa sala ordeño", "subtipo": null, "zona_id": "597ad6cc-663d-4eb8-8d08-286d22050b1d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-19T08:16:23.781443+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-18T06:16:23.781443+00:00", "maquinaria_id": null, "reportado_por": "7f75e608-6c5b-429b-a36f-a644cc41501b"}	postgres	1ed8f81a62b783c1c6c1cc33ef736658964de6aad649ca4abd4f5c5acc902fd7
159	2026-05-29 12:16:23.75923+00	incidencias	INSERT	482f3d27-7b53-4425-b5da-1edda1e2c051	\N	{"id": "482f3d27-7b53-4425-b5da-1edda1e2c051", "tipo": "averia_maquinaria", "estado": "resuelta", "titulo": "[DEMO] Fallo en lavado automático robot 3", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-25T08:16:23.782626+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-23T21:16:23.782626+00:00", "maquinaria_id": "22d2faa8-7be2-4683-a753-03d7a3615508", "reportado_por": "bce871fe-c311-4bf1-a14f-ddf3b31b5f8f"}	postgres	565fd0e73cdaaae6a56f86772ef053460e2d17e0957f25f6262e792b2ef9f79a
172	2026-05-29 12:16:23.808681+00	pedidos	INSERT	dd730fe6-dac2-40d4-a1f3-69cf2ae92669	\N	{"id": "dd730fe6-dac2-40d4-a1f3-69cf2ae92669", "notas": "[DEMO]", "estado": "cancelado", "insumo": "[DEMO] Guantes nitrilo azul talla L", "unidad": "caja", "cantidad": 10.00, "proveedor": "Suministros Ganaderos SA", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-03T12:16:23.821809+00:00", "ts_aprobacion": null, "coste_estimado": 120.00, "solicitante_id": "b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37"}	postgres	9a64d92374b69a5fb69c59b32f5076435fe8cdb0ec6c432a3078fe4067a295a8
160	2026-05-29 12:16:23.75923+00	incidencias	INSERT	922d6401-331f-40b4-9ebf-20abb5995b95	\N	{"id": "922d6401-331f-40b4-9ebf-20abb5995b95", "tipo": "sanidad_animal", "estado": "resuelta", "titulo": "[DEMO] Diarrea neonatal ternero", "subtipo": null, "zona_id": null, "acciones": [], "foto_url": null, "animal_id": "a345a474-de66-4499-be25-1f4604108ce7", "severidad": "media", "ts_cierre": "2026-05-19T00:16:23.783407+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-18T22:16:23.783407+00:00", "maquinaria_id": null, "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	720c8ddeddf878aa7bf3fb1a2757007231d7900fa55a1e547289fe52b123041c
161	2026-05-29 12:16:23.75923+00	incidencias	INSERT	3eb47343-8e83-4f62-a0e6-aec5eba4a0f8	\N	{"id": "3eb47343-8e83-4f62-a0e6-aec5eba4a0f8", "tipo": "pedidos", "estado": "en_gestion", "titulo": "[DEMO] Stock crítico desinfectante pezones", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-05T15:16:23.78407+00:00", "maquinaria_id": null, "reportado_por": "c319a64d-36f2-4c7b-a4e2-e61f08b36d28"}	postgres	7ad5269eabe2be4c419c176db036b2d15d19d7f52f64807effcc981ed1e6f534
162	2026-05-29 12:16:23.808681+00	pedidos	INSERT	aec1808e-e617-42b3-8a69-caf6c0abab6e	\N	{"id": "aec1808e-e617-42b3-8a69-caf6c0abab6e", "notas": "[DEMO]", "estado": "solicitado", "insumo": "[DEMO] Filtros manga leche 50ud", "unidad": "paquete", "cantidad": 5.00, "proveedor": "AgroVet", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-24T12:16:23.81258+00:00", "ts_aprobacion": null, "coste_estimado": 92.50, "solicitante_id": "60da9a93-e0f2-403b-a534-e35383483df5"}	postgres	00ffbcbfc84267e447a5bd71e135cc9154fb858f9cc57f7d3df947ec2ba9166f
163	2026-05-29 12:16:23.808681+00	pedidos	INSERT	d7d12ac5-e7ad-4a72-84fb-e96b9c148485	\N	{"id": "d7d12ac5-e7ad-4a72-84fb-e96b9c148485", "notas": "[DEMO]", "estado": "solicitado", "insumo": "[DEMO] Aceite lubricante bomba vacío", "unidad": "L", "cantidad": 5.00, "proveedor": "Industrial Lugo", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-20T12:16:23.815802+00:00", "ts_aprobacion": null, "coste_estimado": 75.00, "solicitante_id": "513ad92d-a581-4d5b-b01e-7b3654f4482c"}	postgres	b0a1a242d1f06f6de8a237452bdd6b1998521b9b20f3120a93f142a153ba3dc0
164	2026-05-29 12:16:23.808681+00	pedidos	INSERT	536845b1-56d1-42f8-9d18-4e2902950969	\N	{"id": "536845b1-56d1-42f8-9d18-4e2902950969", "notas": "[DEMO]", "estado": "solicitado", "insumo": "[DEMO] Paja de trigo granulada", "unidad": "fardo", "cantidad": 20.00, "proveedor": "Agrícola del Norte", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-23T12:16:23.816593+00:00", "ts_aprobacion": null, "coste_estimado": 120.00, "solicitante_id": "bce871fe-c311-4bf1-a14f-ddf3b31b5f8f"}	postgres	dd165b20b50043902e72a994743d7cf830786005fa10537bfd8d3bcd17797257
165	2026-05-29 12:16:23.808681+00	pedidos	INSERT	c11b2813-993e-4ddd-95fc-e19d4ff1c418	\N	{"id": "c11b2813-993e-4ddd-95fc-e19d4ff1c418", "notas": "[DEMO]", "estado": "aprobado", "insumo": "[DEMO] Pezoneras VMS DeLaval", "unidad": "ud", "cantidad": 48.00, "proveedor": "DeLaval Ibérica", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-24T12:16:23.817246+00:00", "ts_aprobacion": "2026-05-24T19:16:23.817246+00:00", "coste_estimado": 168.00, "solicitante_id": "bce871fe-c311-4bf1-a14f-ddf3b31b5f8f"}	postgres	a08091b4e0e0b703cfbdb7bc3631ffd7259c98adaae98ff81dd1edd4e95a179b
166	2026-05-29 12:16:23.808681+00	pedidos	INSERT	bbedde2c-40eb-4f3e-a441-662f4ff8ccf9	\N	{"id": "bbedde2c-40eb-4f3e-a441-662f4ff8ccf9", "notas": "[DEMO]", "estado": "aprobado", "insumo": "[DEMO] Detergente ácido neutralizador", "unidad": "L", "cantidad": 15.00, "proveedor": "Ecolab", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-21T12:16:23.817911+00:00", "ts_aprobacion": "2026-05-22T07:16:23.817911+00:00", "coste_estimado": 117.00, "solicitante_id": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	postgres	eccc3ca585fa336cd2c0e0e6a9447c729cb0d35a73b9f92a7502fbadb309f20d
167	2026-05-29 12:16:23.808681+00	pedidos	INSERT	47e985f2-9cd4-4b20-b8ae-7fc9d73339fb	\N	{"id": "47e985f2-9cd4-4b20-b8ae-7fc9d73339fb", "notas": "[DEMO]", "estado": "en_transito", "insumo": "[DEMO] Leche en polvo maternizadora", "unidad": "kg", "cantidad": 50.00, "proveedor": "NANTA", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-20T12:16:23.818549+00:00", "ts_aprobacion": "2026-05-21T02:16:23.818549+00:00", "coste_estimado": 195.00, "solicitante_id": "bce871fe-c311-4bf1-a14f-ddf3b31b5f8f"}	postgres	a460c9928f29413fe3fd7f8cd97fbf1bab74e639dd63f5a70d1b8cfc9e119661
168	2026-05-29 12:16:23.808681+00	pedidos	INSERT	a5c928a7-3865-496d-9807-600e7a9761c3	\N	{"id": "a5c928a7-3865-496d-9807-600e7a9761c3", "notas": "[DEMO]", "estado": "en_transito", "insumo": "[DEMO] Detergente alcalino limpieza robot", "unidad": "L", "cantidad": 20.00, "proveedor": "Ecolab", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-03T12:16:23.819175+00:00", "ts_aprobacion": "2026-05-04T04:16:23.819175+00:00", "coste_estimado": 164.00, "solicitante_id": "60da9a93-e0f2-403b-a534-e35383483df5"}	postgres	52417f888f85902f68c467d62d628b9ad49f562708ff06320b5d3c3eadc8e544
169	2026-05-29 12:16:23.808681+00	pedidos	INSERT	557cb482-26fc-4d48-afd4-c387cc539d40	\N	{"id": "557cb482-26fc-4d48-afd4-c387cc539d40", "notas": "[DEMO]", "estado": "recibido", "insumo": "[DEMO] Cornamenta registro electrónico", "unidad": "ud", "cantidad": 25.00, "proveedor": "Allflex", "coste_real": 229.82, "descripcion": null, "ts_recepcion": "2026-05-16T02:16:23.819766+00:00", "ts_solicitud": "2026-05-11T12:16:23.819766+00:00", "ts_aprobacion": "2026-05-12T02:16:23.819766+00:00", "coste_estimado": 212.50, "solicitante_id": "f0025158-31bd-47b3-b90a-3c3d08ed1dd8"}	postgres	1e3bb9b8c2a6578f9c8f284ef6901b4f9f6807a6c01644da2e1e1f5b46167afb
170	2026-05-29 12:16:23.808681+00	pedidos	INSERT	b1fd164c-17a6-4724-930b-ec81dc854725	\N	{"id": "b1fd164c-17a6-4724-930b-ec81dc854725", "notas": "[DEMO]", "estado": "recibido", "insumo": "[DEMO] Catéter intramamario desechable", "unidad": "caja100", "cantidad": 2.00, "proveedor": "Hipra", "coste_real": 81.76, "descripcion": null, "ts_recepcion": "2026-05-15T22:16:23.820647+00:00", "ts_solicitud": "2026-05-09T12:16:23.820647+00:00", "ts_aprobacion": "2026-05-09T22:16:23.820647+00:00", "coste_estimado": 84.00, "solicitante_id": "43958ec8-b358-4c41-bb4c-9b55cacfc8db"}	postgres	6df0ae3c339857e8a70972be981b7883ff739c2f1b7fb51e5a33a7d0966c8494
171	2026-05-29 12:16:23.808681+00	pedidos	INSERT	8fa23fa2-a411-475b-b6a0-a5ac26e784b3	\N	{"id": "8fa23fa2-a411-475b-b6a0-a5ac26e784b3", "notas": "[DEMO]", "estado": "recibido", "insumo": "[DEMO] Pienso recría 4-12 semanas", "unidad": "kg", "cantidad": 500.00, "proveedor": "NANTA", "coste_real": 245.84, "descripcion": null, "ts_recepcion": "2026-05-12T08:16:23.821251+00:00", "ts_solicitud": "2026-05-08T12:16:23.821251+00:00", "ts_aprobacion": "2026-05-09T08:16:23.821251+00:00", "coste_estimado": 225.00, "solicitante_id": "6e67bdeb-6e1e-490d-a29d-d69f6155ab99"}	postgres	9e0e7bc4d28368697acbc4648a86f2e7a94fcb0fa582f01868639991cc86e67c
173	2026-05-29 12:25:04.315608+00	incidencias	UPDATE	3eb47343-8e83-4f62-a0e6-aec5eba4a0f8	{"id": "3eb47343-8e83-4f62-a0e6-aec5eba4a0f8", "tipo": "pedidos", "estado": "en_gestion", "titulo": "[DEMO] Stock crítico desinfectante pezones", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-05T15:16:23.78407+00:00", "maquinaria_id": null, "reportado_por": "c319a64d-36f2-4c7b-a4e2-e61f08b36d28"}	{"id": "3eb47343-8e83-4f62-a0e6-aec5eba4a0f8", "tipo": "pedidos", "estado": "resuelta", "titulo": "[DEMO] Stock crítico desinfectante pezones", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-29T12:25:04.330114+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-05T15:16:23.78407+00:00", "maquinaria_id": null, "reportado_por": "c319a64d-36f2-4c7b-a4e2-e61f08b36d28"}	postgres	822e7201c1b55100ff40a3e5c6c7814497732fd6b94f54265025c4a87bed5e8a
174	2026-05-29 12:27:04.602971+00	incidencias	UPDATE	117a1471-578b-49d4-a7a8-d93a53c1a583	{"id": "117a1471-578b-49d4-a7a8-d93a53c1a583", "tipo": "averia_maquinaria", "estado": "en_gestion", "titulo": "[DEMO] Motor carro mezclador ruidoso", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-27T09:16:23.775292+00:00", "maquinaria_id": "45fb58d3-75be-4b9a-a676-92af4911fee4", "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	{"id": "117a1471-578b-49d4-a7a8-d93a53c1a583", "tipo": "averia_maquinaria", "estado": "resuelta", "titulo": "[DEMO] Motor carro mezclador ruidoso", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "alta", "ts_cierre": "2026-05-29T12:27:04.604697+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-27T09:16:23.775292+00:00", "maquinaria_id": "45fb58d3-75be-4b9a-a676-92af4911fee4", "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	616adf6490a8f9ee6a96ef90304dbf25af6a5e0ef9b507f98d0911777c20e11e
175	2026-05-29 12:27:24.666919+00	pedidos	UPDATE	a5c928a7-3865-496d-9807-600e7a9761c3	{"id": "a5c928a7-3865-496d-9807-600e7a9761c3", "notas": "[DEMO]", "estado": "en_transito", "insumo": "[DEMO] Detergente alcalino limpieza robot", "unidad": "L", "cantidad": 20.00, "proveedor": "Ecolab", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-03T12:16:23.819175+00:00", "ts_aprobacion": "2026-05-04T04:16:23.819175+00:00", "coste_estimado": 164.00, "solicitante_id": "60da9a93-e0f2-403b-a534-e35383483df5"}	{"id": "a5c928a7-3865-496d-9807-600e7a9761c3", "notas": "[DEMO]", "estado": "recibido", "insumo": "[DEMO] Detergente alcalino limpieza robot", "unidad": "L", "cantidad": 20.00, "proveedor": "Ecolab", "coste_real": null, "descripcion": null, "ts_recepcion": "2026-05-29T12:27:24.666919+00:00", "ts_solicitud": "2026-05-03T12:16:23.819175+00:00", "ts_aprobacion": "2026-05-04T04:16:23.819175+00:00", "coste_estimado": 164.00, "solicitante_id": "60da9a93-e0f2-403b-a534-e35383483df5"}	postgres	aa701bf4ab05298c4b42fa7309c508d419eef7eeba3f3e3c301a5309b81072ad
176	2026-05-29 12:28:04.776373+00	pedidos	UPDATE	d7d12ac5-e7ad-4a72-84fb-e96b9c148485	{"id": "d7d12ac5-e7ad-4a72-84fb-e96b9c148485", "notas": "[DEMO]", "estado": "solicitado", "insumo": "[DEMO] Aceite lubricante bomba vacío", "unidad": "L", "cantidad": 5.00, "proveedor": "Industrial Lugo", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-20T12:16:23.815802+00:00", "ts_aprobacion": null, "coste_estimado": 75.00, "solicitante_id": "513ad92d-a581-4d5b-b01e-7b3654f4482c"}	{"id": "d7d12ac5-e7ad-4a72-84fb-e96b9c148485", "notas": "[DEMO]", "estado": "aprobado", "insumo": "[DEMO] Aceite lubricante bomba vacío", "unidad": "L", "cantidad": 5.00, "proveedor": "Industrial Lugo", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-20T12:16:23.815802+00:00", "ts_aprobacion": "2026-05-29T12:28:04.776373+00:00", "coste_estimado": 75.00, "solicitante_id": "513ad92d-a581-4d5b-b01e-7b3654f4482c"}	postgres	6a1a345102c2a88c46b22f7566914170af212e3394fa2d49e96ce1b66ed2ef79
177	2026-05-29 12:28:24.822528+00	incidencias	UPDATE	460f04af-e5a2-4fbb-91e2-039bdd9981a1	{"id": "460f04af-e5a2-4fbb-91e2-039bdd9981a1", "tipo": "alimentacion", "estado": "en_gestion", "titulo": "[DEMO] Rotura tolva concentrado", "subtipo": null, "zona_id": "521c30a0-4751-4157-87d0-6aaf2c9c882d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-22T06:16:23.771055+00:00", "maquinaria_id": null, "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	{"id": "460f04af-e5a2-4fbb-91e2-039bdd9981a1", "tipo": "alimentacion", "estado": "resuelta", "titulo": "[DEMO] Rotura tolva concentrado", "subtipo": null, "zona_id": "521c30a0-4751-4157-87d0-6aaf2c9c882d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": "2026-05-29T12:28:24.825687+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-22T06:16:23.771055+00:00", "maquinaria_id": null, "reportado_por": "c133cc24-f15a-4522-ad43-cc62e4a0283a"}	postgres	548eeaa8ee3b7920d8554328b3a642dee9da562f4446a9d683e8a5caf0017df5
178	2026-05-29 12:29:04.936925+00	incidencias	INSERT	eb4c208a-7a86-4b9d-a2fc-1a5f583f1477	\N	{"id": "eb4c208a-7a86-4b9d-a2fc-1a5f583f1477", "tipo": "infraestructura", "estado": "abierta", "titulo": "[DEMO] Puerta automatizada atascada paridera", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia generada por simulador demo.", "ts_apertura": "2026-05-29T12:29:04.936728+00:00", "maquinaria_id": null, "reportado_por": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	postgres	610e4d458753eb7f5dd21d9e999656d751f6df511a9bea6acd46332bc3c14f32
179	2026-05-29 12:30:05.05503+00	incidencias	UPDATE	305ab9c5-10ba-4d47-ae13-524cf96f8767	{"id": "305ab9c5-10ba-4d47-ae13-524cf96f8767", "tipo": "infraestructura", "estado": "en_gestion", "titulo": "[DEMO] Fuga de agua en bebedero zona recría", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-28T20:16:23.780516+00:00", "maquinaria_id": null, "reportado_por": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	{"id": "305ab9c5-10ba-4d47-ae13-524cf96f8767", "tipo": "infraestructura", "estado": "resuelta", "titulo": "[DEMO] Fuga de agua en bebedero zona recría", "subtipo": null, "zona_id": "f102e952-9109-4668-a381-bc6693bc851b", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": "2026-05-29T12:30:05.05667+00:00", "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-28T20:16:23.780516+00:00", "maquinaria_id": null, "reportado_por": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	postgres	55dc27087641fd117a8775cf3afa8d24b48236eb0d64fd41fdba4da6ab51e11d
180	2026-05-29 12:30:25.088497+00	incidencias	UPDATE	fef76430-4f32-4296-9326-f4a2fd2321b2	{"id": "fef76430-4f32-4296-9326-f4a2fd2321b2", "tipo": "pedidos", "estado": "abierta", "titulo": "[DEMO] Stock crítico desinfectante pezones", "subtipo": null, "zona_id": "df0512cb-3963-4225-97dd-242b835a8118", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-02T01:16:23.770207+00:00", "maquinaria_id": null, "reportado_por": "2d200ce2-5f48-4285-8d33-98f06db5b194"}	{"id": "fef76430-4f32-4296-9326-f4a2fd2321b2", "tipo": "pedidos", "estado": "en_gestion", "titulo": "[DEMO] Stock crítico desinfectante pezones", "subtipo": null, "zona_id": "df0512cb-3963-4225-97dd-242b835a8118", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "baja", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-02T01:16:23.770207+00:00", "maquinaria_id": null, "reportado_por": "2d200ce2-5f48-4285-8d33-98f06db5b194"}	postgres	8b1ba6439e3e17583da6f1f552fece6775bce6fe386a113d9cba7a3639656766
181	2026-05-29 12:30:45.121642+00	incidencias	UPDATE	3b291fca-8d4c-4d00-b2af-fa224da22ec6	{"id": "3b291fca-8d4c-4d00-b2af-fa224da22ec6", "tipo": "calidad_leche", "estado": "abierta", "titulo": "[DEMO] Resto antibiótico detectado control", "subtipo": null, "zona_id": "597ad6cc-663d-4eb8-8d08-286d22050b1d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-23T02:16:23.771809+00:00", "maquinaria_id": null, "reportado_por": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	{"id": "3b291fca-8d4c-4d00-b2af-fa224da22ec6", "tipo": "calidad_leche", "estado": "en_gestion", "titulo": "[DEMO] Resto antibiótico detectado control", "subtipo": null, "zona_id": "597ad6cc-663d-4eb8-8d08-286d22050b1d", "acciones": [], "foto_url": null, "animal_id": null, "severidad": "media", "ts_cierre": null, "asignado_a": null, "descripcion": "Incidencia demo registrada automáticamente para demostración del TFM.", "ts_apertura": "2026-05-23T02:16:23.771809+00:00", "maquinaria_id": null, "reportado_por": "30b40a49-5e28-4ce5-acbb-df297a52e509"}	postgres	45b2cd95fdbfbcc36e46a084c7ac98ad21e996eb692b80da9bf722be7634cb3c
182	2026-05-29 12:33:05.682463+00	pedidos	UPDATE	d7d12ac5-e7ad-4a72-84fb-e96b9c148485	{"id": "d7d12ac5-e7ad-4a72-84fb-e96b9c148485", "notas": "[DEMO]", "estado": "aprobado", "insumo": "[DEMO] Aceite lubricante bomba vacío", "unidad": "L", "cantidad": 5.00, "proveedor": "Industrial Lugo", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-20T12:16:23.815802+00:00", "ts_aprobacion": "2026-05-29T12:28:04.776373+00:00", "coste_estimado": 75.00, "solicitante_id": "513ad92d-a581-4d5b-b01e-7b3654f4482c"}	{"id": "d7d12ac5-e7ad-4a72-84fb-e96b9c148485", "notas": "[DEMO]", "estado": "en_transito", "insumo": "[DEMO] Aceite lubricante bomba vacío", "unidad": "L", "cantidad": 5.00, "proveedor": "Industrial Lugo", "coste_real": null, "descripcion": null, "ts_recepcion": null, "ts_solicitud": "2026-05-20T12:16:23.815802+00:00", "ts_aprobacion": "2026-05-29T12:28:04.776373+00:00", "coste_estimado": 75.00, "solicitante_id": "513ad92d-a581-4d5b-b01e-7b3654f4482c"}	postgres	ede0af01ab8c75219c44758f520fef27ad824a3ef58ccffed25383a25cd7acbe
\.


--
-- Data for Name: boxes_recria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.boxes_recria (id, box_numero, ternero_id, fecha_entrada, fecha_salida, activo, alertas_box, notas) FROM stdin;
\.


--
-- Data for Name: core_alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_alerts (id, animal_id, tipo_alerta, severidad, descripcion, recomendacion, estado, confianza_prediccion, requiere_escalacion, fecha_creacion, fecha_revision, revisada, notas_operario, accion_tomada, veterinario_responsable) FROM stdin;
\.


--
-- Data for Name: core_animals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_animals (id, crotal_oficial, nombre, sexo, fecha_nacimiento, raza, estado, estado_reproductivo, fecha_entrada, fecha_baja, motivo_baja, notas) FROM stdin;
\.


--
-- Data for Name: core_employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_employees (id, nombre, apellidos, role, zona_principal_id, activo) FROM stdin;
\.


--
-- Data for Name: core_incidents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_incidents (id, tipo, zona_id, animal_id, descripcion, prioridad, estado, fecha_creacion, fecha_resolucion, resolucion, reportado_por) FROM stdin;
\.


--
-- Data for Name: core_lactations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_lactations (id, animal_id, numero_lactacion, fecha_inicio, fecha_fin, dias_transcurridos, produccion_promedio, produccion_total, grasa_promedio, proteina_promedio, rcs_promedio, activa) FROM stdin;
\.


--
-- Data for Name: core_machinery; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_machinery (id, nombre, tipo, zona_id, estado, proxima_revision, observaciones) FROM stdin;
\.


--
-- Data for Name: core_tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_tasks (id, tarea_catalogo_id, tarea_catalogo, zona_id, fecha_programada, fecha_ejecucion, estado, ejecutado_por, tiempo_ejecucion_minutos, resultado, observaciones, problemas_encontrados, acciones_correctivas, checklist_completado, checklist_datos, es_urgente, motivo_retraso, requiere_seguimiento, fecha_seguimiento) FROM stdin;
\.


--
-- Data for Name: core_treatments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_treatments (id, animal_id, medicamento, dosis, via_administracion, fecha_inicio, fecha_fin, periodo_retirada_dias, fecha_fin_retirada, activo, motivo, veterinario, observaciones) FROM stdin;
\.


--
-- Data for Name: core_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.core_zones (id, nombre, codigo, descripcion, tipo, tiene_pantalla_tv, tiene_tablet, activa) FROM stdin;
\.


--
-- Data for Name: datos_metereologicos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datos_metereologicos (id, fecha_hora, temperatura_media, temperatura_maxima, temperatura_minima, humedad_relativa, precipitacion, velocidad_viento, presion_atmosferica, estado_cielo, ubicacion, latitud, longitud, fuente) FROM stdin;
\.


--
-- Data for Name: empleados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.empleados (id, nombre, apellidos, rol, cualificaciones, telefono, email, activo, fecha_alta, fecha_baja) FROM stdin;
b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	Carlos	Rodríguez Peña	encargado	{VMS,TMR}	\N	carlos.rodríguez@tools4milk.demo	t	2024-10-07	\N
7f75e608-6c5b-429b-a36f-a644cc41501b	Ana	López Vázquez	encargado	{VMS,veterinaria}	\N	ana.lópez@tools4milk.demo	t	2025-01-24	\N
60da9a93-e0f2-403b-a534-e35383483df5	Miguel	García Fernández	auxiliar	{}	\N	miguel.garcía@tools4milk.demo	t	2023-10-22	\N
bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	Rosa	Martínez Iglesias	auxiliar	{TMR}	\N	rosa.martínez@tools4milk.demo	t	2024-02-10	\N
f0025158-31bd-47b3-b90a-3c3d08ed1dd8	Xoán	Castro Otero	auxiliar	{}	\N	xoán.castro@tools4milk.demo	t	2026-04-21	\N
2d200ce2-5f48-4285-8d33-98f06db5b194	Pilar	Díaz Nóvoa	auxiliar	{VMS}	\N	pilar.díaz@tools4milk.demo	t	2024-12-13	\N
c133cc24-f15a-4522-ad43-cc62e4a0283a	Beatriz	Suárez Méndez	veterinario	{veterinaria}	\N	beatriz.suárez@tools4milk.demo	t	2025-10-09	\N
6e67bdeb-6e1e-490d-a29d-d69f6155ab99	Tomás	González Ramos	veterinario	{veterinaria}	\N	tomás.gonzález@tools4milk.demo	t	2026-02-11	\N
30b40a49-5e28-4ce5-acbb-df297a52e509	Andrés	Fernández Blanco	mecanico	{VMS}	\N	andrés.fernández@tools4milk.demo	t	2024-12-13	\N
43958ec8-b358-4c41-bb4c-9b55cacfc8db	Lucía	Álvarez Pardo	mecanico	{}	\N	lucía.álvarez@tools4milk.demo	t	2025-01-19	\N
c319a64d-36f2-4c7b-a4e2-e61f08b36d28	Jorge	Soto Brea	auxiliar	{TMR}	\N	jorge.soto@tools4milk.demo	t	2024-03-30	\N
513ad92d-a581-4d5b-b01e-7b3654f4482c	Elena	Vidal Caamaño	veterinario	{veterinaria}	\N	elena.vidal@tools4milk.demo	t	2024-05-16	\N
\.


--
-- Data for Name: eventos_reproductivos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.eventos_reproductivos (id, animal_id, tipo, fecha, hora, empleado_id, detalles, notas, creado_en) FROM stdin;
\.


--
-- Data for Name: eventos_sanitarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.eventos_sanitarios (id, animal_id, tipo_patologia, fecha_inicio, fecha_fin, tratamiento, farmaco, dosis, via_administracion, periodo_retirada_hasta, resuelto, coste, veterinario_id, notas) FROM stdin;
\.


--
-- Data for Name: eventos_sanitarios_recria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.eventos_sanitarios_recria (id, animal_id, fecha, edad_dias, score_neumonia, score_diarrea, score_ombligo, peso_kg, tratamiento, observaciones, empleado_id) FROM stdin;
\.


--
-- Data for Name: genomica; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genomica (id, animal_id, fecha_extraccion, tipo_muestra, laboratorio, referencia_lab, fecha_resultado, resultados_ref, notas) FROM stdin;
\.


--
-- Data for Name: incidencias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.incidencias (id, tipo, subtipo, severidad, estado, titulo, descripcion, zona_id, maquinaria_id, animal_id, reportado_por, asignado_a, ts_apertura, ts_cierre, foto_url, acciones) FROM stdin;
57104782-3b3a-46db-bb3e-fcc8774675c5	calidad_leche	\N	media	resuelta	[DEMO] RCS elevado en tanque lote mañana	Incidencia demo registrada automáticamente para demostración del TFM.	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	\N	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	\N	2026-05-18 13:16:23.766175+00	2026-05-19 12:16:23.766175+00	\N	[]
ea517d4a-e7ff-4086-b3d0-adb827aedc8c	calidad_leche	\N	alta	en_gestion	[DEMO] Conductividad anómala cuarto posterior	Incidencia demo registrada automáticamente para demostración del TFM.	df0512cb-3963-4225-97dd-242b835a8118	\N	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	\N	2026-05-07 23:16:23.772407+00	\N	\N	[]
4da19053-3362-41c2-9115-91f7484af1d4	sanidad_animal	\N	baja	abierta	[DEMO] Animal con fiebre post-parto	Incidencia demo registrada automáticamente para demostración del TFM.	\N	\N	41098454-a4a4-45db-bc95-a2793218055b	c133cc24-f15a-4522-ad43-cc62e4a0283a	\N	2026-04-29 01:16:23.77313+00	\N	\N	[]
c84d0257-09f6-419e-bf69-a0d348c67c46	averia_maquinaria	\N	media	resuelta	[DEMO] Avería bomba de vacío principal	Incidencia demo registrada automáticamente para demostración del TFM.	3836de7c-0b6f-4306-904d-825890b6f534	c0078401-da96-4091-b26d-b69f4509abed	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	\N	2026-05-05 21:16:23.773889+00	2026-05-08 00:16:23.773889+00	\N	[]
b2300f7a-842c-4896-a2dc-d5b1386e6b52	alimentacion	\N	media	cerrada	[DEMO] Silo forraje con humedad excesiva	Incidencia demo registrada automáticamente para demostración del TFM.	3836de7c-0b6f-4306-904d-825890b6f534	\N	\N	2d200ce2-5f48-4285-8d33-98f06db5b194	\N	2026-04-28 19:16:23.774712+00	2026-04-28 21:16:23.774712+00	\N	[]
8f17373c-76bb-46c8-a0fb-162cb127d520	pedidos	\N	media	cerrada	[DEMO] Stock crítico desinfectante pezones	Incidencia demo registrada automáticamente para demostración del TFM.	3836de7c-0b6f-4306-904d-825890b6f534	\N	\N	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	\N	2026-05-16 07:16:23.776232+00	2026-05-18 18:16:23.776232+00	\N	[]
e5ae3c34-4a70-40e7-9ef8-c3793de41213	calidad_leche	\N	media	resuelta	[DEMO] Conductividad anómala cuarto posterior	Incidencia demo registrada automáticamente para demostración del TFM.	df0512cb-3963-4225-97dd-242b835a8118	\N	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	\N	2026-05-01 19:16:23.777641+00	2026-05-02 05:16:23.777641+00	\N	[]
72838dd9-ae62-4f1a-b37f-335e7aed4af3	infraestructura	\N	media	cerrada	[DEMO] Fuga de agua en bebedero zona recría	Incidencia demo registrada automáticamente para demostración del TFM.	f102e952-9109-4668-a381-bc6693bc851b	\N	\N	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	\N	2026-04-28 22:16:23.778623+00	2026-05-01 22:16:23.778623+00	\N	[]
4e152825-e020-4107-bc86-e293fb209106	sanidad_animal	\N	baja	en_gestion	[DEMO] Cojera leve detectada en animal	Incidencia demo registrada automáticamente para demostración del TFM.	\N	\N	f664da5c-e84f-4de3-abe2-954a07871fae	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	\N	2026-05-13 09:16:23.779654+00	\N	\N	[]
591b599b-3526-4e0f-a07e-dc501b4d7527	infraestructura	\N	media	resuelta	[DEMO] Iluminación defectuosa sala ordeño	Incidencia demo registrada automáticamente para demostración del TFM.	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	\N	7f75e608-6c5b-429b-a36f-a644cc41501b	\N	2026-05-18 06:16:23.781443+00	2026-05-19 08:16:23.781443+00	\N	[]
482f3d27-7b53-4425-b5da-1edda1e2c051	averia_maquinaria	\N	media	resuelta	[DEMO] Fallo en lavado automático robot 3	Incidencia demo registrada automáticamente para demostración del TFM.	f102e952-9109-4668-a381-bc6693bc851b	22d2faa8-7be2-4683-a753-03d7a3615508	\N	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	\N	2026-05-23 21:16:23.782626+00	2026-05-25 08:16:23.782626+00	\N	[]
922d6401-331f-40b4-9ebf-20abb5995b95	sanidad_animal	\N	media	resuelta	[DEMO] Diarrea neonatal ternero	Incidencia demo registrada automáticamente para demostración del TFM.	\N	\N	a345a474-de66-4499-be25-1f4604108ce7	c133cc24-f15a-4522-ad43-cc62e4a0283a	\N	2026-05-18 22:16:23.783407+00	2026-05-19 00:16:23.783407+00	\N	[]
3eb47343-8e83-4f62-a0e6-aec5eba4a0f8	pedidos	\N	baja	resuelta	[DEMO] Stock crítico desinfectante pezones	Incidencia demo registrada automáticamente para demostración del TFM.	f102e952-9109-4668-a381-bc6693bc851b	\N	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	\N	2026-05-05 15:16:23.78407+00	2026-05-29 12:25:04.330114+00	\N	[]
117a1471-578b-49d4-a7a8-d93a53c1a583	averia_maquinaria	\N	alta	resuelta	[DEMO] Motor carro mezclador ruidoso	Incidencia demo registrada automáticamente para demostración del TFM.	f102e952-9109-4668-a381-bc6693bc851b	45fb58d3-75be-4b9a-a676-92af4911fee4	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	\N	2026-05-27 09:16:23.775292+00	2026-05-29 12:27:04.604697+00	\N	[]
460f04af-e5a2-4fbb-91e2-039bdd9981a1	alimentacion	\N	baja	resuelta	[DEMO] Rotura tolva concentrado	Incidencia demo registrada automáticamente para demostración del TFM.	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	\N	2026-05-22 06:16:23.771055+00	2026-05-29 12:28:24.825687+00	\N	[]
eb4c208a-7a86-4b9d-a2fc-1a5f583f1477	infraestructura	\N	media	abierta	[DEMO] Puerta automatizada atascada paridera	Incidencia generada por simulador demo.	f102e952-9109-4668-a381-bc6693bc851b	\N	\N	30b40a49-5e28-4ce5-acbb-df297a52e509	\N	2026-05-29 12:29:04.936728+00	\N	\N	[]
305ab9c5-10ba-4d47-ae13-524cf96f8767	infraestructura	\N	media	resuelta	[DEMO] Fuga de agua en bebedero zona recría	Incidencia demo registrada automáticamente para demostración del TFM.	f102e952-9109-4668-a381-bc6693bc851b	\N	\N	30b40a49-5e28-4ce5-acbb-df297a52e509	\N	2026-05-28 20:16:23.780516+00	2026-05-29 12:30:05.05667+00	\N	[]
fef76430-4f32-4296-9326-f4a2fd2321b2	pedidos	\N	baja	en_gestion	[DEMO] Stock crítico desinfectante pezones	Incidencia demo registrada automáticamente para demostración del TFM.	df0512cb-3963-4225-97dd-242b835a8118	\N	\N	2d200ce2-5f48-4285-8d33-98f06db5b194	\N	2026-05-02 01:16:23.770207+00	\N	\N	[]
3b291fca-8d4c-4d00-b2af-fa224da22ec6	calidad_leche	\N	media	en_gestion	[DEMO] Resto antibiótico detectado control	Incidencia demo registrada automáticamente para demostración del TFM.	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	\N	30b40a49-5e28-4ce5-acbb-df297a52e509	\N	2026-05-23 02:16:23.771809+00	\N	\N	[]
\.


--
-- Data for Name: lactaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lactaciones (id, animal_id, numero, fecha_parto, fecha_secado, produccion_total_kg, notas) FROM stdin;
b22b0efe-4696-438c-b756-144e38efea6f	e4d3741d-b1e6-4cae-9a1c-69dcd04c2302	1	2023-06-01	2024-04-13	7354.40	[DEMO]
d02d696e-e1e8-4f9d-b5b3-95eadd0fa2dc	e4d3741d-b1e6-4cae-9a1c-69dcd04c2302	2	2024-07-03	2025-04-25	9087.20	[DEMO]
771c8eca-cf0f-4487-8c6f-9b163526e7f0	e4d3741d-b1e6-4cae-9a1c-69dcd04c2302	3	2025-06-08	\N	11821.50	[DEMO]
462d87ec-d677-4685-b46a-d279abdc23b2	2ced7c23-acf4-43d7-9bac-af6d0158d58c	1	2023-12-08	\N	21672.00	[DEMO]
64576989-81b2-483c-909e-2dec8b1a3a5f	6d067c4b-3fca-414f-af92-76a0d5c7a813	1	2023-08-19	2024-06-14	9600.00	[DEMO]
9ae4077a-fced-46d9-b4d8-1d2fac5e132f	6d067c4b-3fca-414f-af92-76a0d5c7a813	2	2024-06-16	2025-04-04	8205.20	[DEMO]
813dfd05-0abc-4767-9e44-d7a4337ba2e2	6d067c4b-3fca-414f-af92-76a0d5c7a813	3	2025-09-15	\N	8371.20	[DEMO]
cd5837d0-ba30-42a3-b325-96c2933a2c61	c0f7d046-4899-43d4-86dc-11d64560e316	1	2022-07-20	\N	43679.00	[DEMO]
65c9e0a1-3dbd-47e1-81ee-0e4d0c628b04	11218539-9457-40cc-a87c-6d1ea5a52534	1	2024-05-12	2025-02-17	7306.00	[DEMO]
27bdf94c-547d-485c-ab31-5f49d63a8ab6	11218539-9457-40cc-a87c-6d1ea5a52534	2	2025-04-22	2026-01-27	5992.00	[DEMO]
baed8579-cfed-48c4-802d-2cbc98af1a0d	11218539-9457-40cc-a87c-6d1ea5a52534	3	2026-06-13	2027-04-26	7005.70	[DEMO]
cc7d30c2-8057-41fd-bae8-95d7df42de71	11218539-9457-40cc-a87c-6d1ea5a52534	4	2026-11-13	\N	34.10	[DEMO]
a301c748-5534-4656-87d6-284fe63095b8	d58dab0c-ba97-4376-93e1-baf6fffe87ee	1	2022-09-26	2023-07-16	6006.50	[DEMO]
01d51794-c46c-4849-bead-bf8d16117efa	d58dab0c-ba97-4376-93e1-baf6fffe87ee	2	2023-08-09	2024-06-05	9632.00	[DEMO]
6a42bf4f-6ea0-4dfd-8801-68b2d8cca290	d58dab0c-ba97-4376-93e1-baf6fffe87ee	3	2024-09-03	\N	23357.70	[DEMO]
f1d7eed5-2f3b-450d-ab7c-f2e575fe0133	b5c59f11-f0ae-4477-92f7-6ebc9942f491	1	2024-04-07	2025-02-21	7296.00	[DEMO]
2c802626-9300-4820-9b07-da49716fdadd	b5c59f11-f0ae-4477-92f7-6ebc9942f491	2	2025-04-16	2026-03-02	10816.00	[DEMO]
e33c8ab7-ad5e-478c-b618-3a931b38a95e	b5c59f11-f0ae-4477-92f7-6ebc9942f491	3	2026-04-23	2027-02-06	7340.60	[DEMO]
1f31f6ca-8259-4a58-bce7-9433af370361	b5c59f11-f0ae-4477-92f7-6ebc9942f491	4	2027-01-19	\N	24.10	[DEMO]
bf4449af-c4b9-48bf-b2bb-578676916704	b02ad120-19ba-4491-8ae5-df9672ece6e6	1	2024-03-21	\N	19895.10	[DEMO]
ddadc4b4-63a5-4033-81e7-fdfd6ea89e03	4047b88d-66c2-4192-8429-4eca6b5ff44f	1	2023-04-22	2024-02-11	8260.00	[DEMO]
7f7c88fa-0c25-4dec-926c-c3d5af91dcb3	4047b88d-66c2-4192-8429-4eca6b5ff44f	2	2024-03-11	2025-01-08	7999.20	[DEMO]
d2cff5f5-2965-4f1b-a39b-d3faf9f1d440	4047b88d-66c2-4192-8429-4eca6b5ff44f	3	2025-06-28	\N	11825.50	[DEMO]
af5e923a-b104-46d1-88d6-a71f2e62507b	482ca314-084c-4f01-aef1-7d2bc8cb37ff	1	2023-05-09	\N	30801.60	[DEMO]
2253fa64-3ea9-44f2-a8e0-78d0fac8e9a6	1909c17b-0202-4563-aeb3-efdcce12c758	1	2023-05-13	2024-03-21	9922.10	[DEMO]
a87e30d2-f948-4a3d-a46a-8216677aea56	1909c17b-0202-4563-aeb3-efdcce12c758	2	2024-04-05	\N	18972.80	[DEMO]
022bc5e3-7ce3-47de-a880-311488825df8	f2113bfa-4f8c-4d26-9438-7349516eb5da	1	2022-12-03	2023-10-10	8148.20	[DEMO]
34ae0036-5601-4733-adf4-abc4850cd13d	f2113bfa-4f8c-4d26-9438-7349516eb5da	2	2023-10-07	\N	30301.00	[DEMO]
61735caa-ffe2-407e-8579-6c753b2ae8ca	b5297515-9959-455e-86e4-30052372eddd	1	2023-10-15	\N	36174.60	[DEMO]
4071f204-260c-4b38-acf6-703e609a006b	bd1f7206-4b66-4801-aa4b-6979be8bcb5f	1	2020-04-25	2021-02-02	7159.90	[DEMO]
293d02f8-7995-4b0a-86af-7ba2444bc2cd	bd1f7206-4b66-4801-aa4b-6979be8bcb5f	2	2021-05-07	2022-03-23	8832.00	[DEMO]
ed0fcad6-9298-4912-a5b5-b4be01443d7b	bd1f7206-4b66-4801-aa4b-6979be8bcb5f	3	2021-12-20	\N	47009.00	[DEMO]
f12d3cf2-1f8f-405f-8808-b1815e91f892	c0d6060f-b696-49b3-8a78-0de2f71826b0	1	2020-08-20	2021-06-07	6896.70	[DEMO]
9da0aca6-f71f-4069-a331-2b7f7593d175	c0d6060f-b696-49b3-8a78-0de2f71826b0	2	2021-07-09	2022-04-22	8351.70	[DEMO]
c0d3b2d3-65f2-401c-a101-9f6898ee952c	c0d6060f-b696-49b3-8a78-0de2f71826b0	3	2022-04-18	2023-02-12	8910.00	[DEMO]
18182ce8-a6cd-467b-b837-cde3a7f80040	c0d6060f-b696-49b3-8a78-0de2f71826b0	4	2023-03-08	\N	35104.40	[DEMO]
c2df41ba-0fb7-4a30-a40b-4b232949b1a3	f6f18149-270e-4c85-871a-96c00cb9ae2b	1	2020-06-08	2021-04-02	8582.40	[DEMO]
ac0a9a78-125b-4362-aa45-7b00259079c9	f6f18149-270e-4c85-871a-96c00cb9ae2b	2	2021-07-03	\N	47998.80	[DEMO]
8258b0aa-bf2e-474d-b495-10c26fcd71e7	0d88dbf9-bce8-4dbf-bbb1-c728ee8caab2	1	2021-10-26	\N	63688.00	[DEMO]
45bfddb5-a471-40a1-984d-0b60478e3d62	7ee50ae4-fd81-4002-ba07-9705968830d1	1	2023-11-16	2024-09-06	7552.00	[DEMO]
94c5402c-41e6-4a56-99e3-a2008c63f42b	7ee50ae4-fd81-4002-ba07-9705968830d1	2	2024-12-01	2025-09-08	6575.40	[DEMO]
4e7d80b2-9e04-4c8f-8e41-8ee3808821f3	7ee50ae4-fd81-4002-ba07-9705968830d1	3	2025-11-21	2026-09-22	8662.00	[DEMO]
365d6f71-752a-4890-9131-b501d6642143	7ee50ae4-fd81-4002-ba07-9705968830d1	4	2026-12-06	\N	36.70	[DEMO]
4fc2dec1-6b87-402c-bfc7-6b864861c9ce	d0ba5459-2ca0-4742-8bc9-ee3ecdf27f8d	1	2023-10-15	2024-07-21	6468.00	[DEMO]
fd66b3df-121f-41db-ac13-473ee3dd716e	d0ba5459-2ca0-4742-8bc9-ee3ecdf27f8d	2	2024-08-13	2025-06-14	7960.50	[DEMO]
bcd03a4c-bed3-4d7f-8fd6-e48c2c7644b4	d0ba5459-2ca0-4742-8bc9-ee3ecdf27f8d	3	2025-07-24	2026-05-20	6180.00	[DEMO]
674cf6f6-3f32-4739-8ddf-45f54ed52c08	d0ba5459-2ca0-4742-8bc9-ee3ecdf27f8d	4	2027-01-06	\N	37.50	[DEMO]
1e7b4661-10b3-493c-a03c-c483747e0ae3	c6f4a608-54b2-4ca8-affe-0a2e4d360399	1	2020-10-31	2021-08-25	10608.80	[DEMO]
8f282adf-a858-4caa-b4a6-daad87db4324	c6f4a608-54b2-4ca8-affe-0a2e4d360399	2	2021-10-11	2022-08-22	9891.00	[DEMO]
e36c7f51-5e45-4a65-8330-4b6bace7062a	c6f4a608-54b2-4ca8-affe-0a2e4d360399	3	2022-06-25	2023-04-26	7594.50	[DEMO]
45ee5b63-3456-4bc8-a36f-3368ed64f81b	c6f4a608-54b2-4ca8-affe-0a2e4d360399	4	2023-11-18	\N	26582.40	[DEMO]
38784b99-21be-44ff-9fec-a73ad924504a	52be2f26-d802-4b14-ae5b-dcb306089bdc	1	2024-09-28	2025-08-07	6760.80	[DEMO]
efb5ca24-5485-49a1-88be-9b6e1f07d884	52be2f26-d802-4b14-ae5b-dcb306089bdc	2	2025-10-06	2026-07-23	8613.00	[DEMO]
c7a75988-b8ad-470b-a840-c5a1d15f09d3	52be2f26-d802-4b14-ae5b-dcb306089bdc	3	2026-06-08	2027-03-31	6008.80	[DEMO]
f0792e21-5b3f-4e12-9fad-479c483ff05b	52be2f26-d802-4b14-ae5b-dcb306089bdc	4	2027-12-30	\N	37.60	[DEMO]
a9ce76b3-5d5c-4d35-b2f0-f56d176eec16	26f29af8-4eb8-4aa2-aaae-3bfce1c4839b	1	2023-03-25	\N	32624.10	[DEMO]
f7516ecd-7d24-4b9b-a4c0-4b5f0c86d502	49b61755-8934-44da-9065-3ccaa355d5db	1	2023-11-03	2024-09-11	9953.40	[DEMO]
304bce04-aca6-4848-a811-e8a37917a0ab	49b61755-8934-44da-9065-3ccaa355d5db	2	2024-11-16	\N	20012.20	[DEMO]
4bd432dd-0bf5-499e-bbfa-9ab6f6656adf	d1762cb2-302a-4dd7-97df-934978bad2bc	1	2024-05-15	2025-03-03	8818.40	[DEMO]
8fd3234b-c918-4cad-825b-9beabafc94ca	d1762cb2-302a-4dd7-97df-934978bad2bc	2	2025-05-08	\N	14475.00	[DEMO]
45879d46-4550-4ed7-a3c1-8eca5e335bc9	26d26b4b-30bb-4860-9c60-15c5ddcb244c	1	2022-05-10	\N	43660.00	[DEMO]
52c95466-ddd7-4cdc-9acb-cc9a0f6e058e	6b02089e-b0dc-40cf-a70c-a0fd1f9f407f	1	2021-08-13	2022-05-31	9428.40	[DEMO]
9d78114e-3a29-40d8-a3ac-7b55fdf3eaa0	6b02089e-b0dc-40cf-a70c-a0fd1f9f407f	2	2022-08-21	2023-07-03	10617.60	[DEMO]
3e13f89a-4469-41ff-a87a-de1c8c90c63d	6b02089e-b0dc-40cf-a70c-a0fd1f9f407f	3	2023-04-07	\N	35817.60	[DEMO]
77db8a5d-e0aa-4235-8974-e73319c1704a	0e161c89-fa5d-48ce-b985-0ba8cee7482d	1	2021-08-20	2022-06-13	6771.60	[DEMO]
124409cf-d480-4d5f-8ee2-3117fad4a89b	0e161c89-fa5d-48ce-b985-0ba8cee7482d	2	2022-06-19	2023-04-13	9059.20	[DEMO]
9b3c3d25-3f67-46a8-8839-7cf533420d56	0e161c89-fa5d-48ce-b985-0ba8cee7482d	3	2023-07-25	\N	31689.50	[DEMO]
abd13886-7a2b-40e7-aec9-3a1d0e0b6e24	fdd7b753-1eb4-401a-a7d0-edc697de625d	1	2021-08-03	2022-06-17	7059.60	[DEMO]
d61fdaf3-f134-430c-9520-08c723a30f7f	fdd7b753-1eb4-401a-a7d0-edc697de625d	2	2022-06-09	2023-04-05	9870.00	[DEMO]
8097d0be-f3a4-43d2-832e-46dad211d6a4	fdd7b753-1eb4-401a-a7d0-edc697de625d	3	2023-04-29	\N	39635.20	[DEMO]
98bed9bd-3bf0-49dd-9519-abc20905b17d	511a43e4-da3e-4ebb-a40f-554774f79dc1	1	2020-10-31	2021-08-12	6013.50	[DEMO]
d50fe718-29d8-41c2-8abf-f5225dc8b3fc	511a43e4-da3e-4ebb-a40f-554774f79dc1	2	2021-10-18	2022-08-21	8227.60	[DEMO]
ff70c625-11a3-47b8-906b-9093e363a24d	511a43e4-da3e-4ebb-a40f-554774f79dc1	3	2023-01-03	2023-10-16	9695.40	[DEMO]
abbba8f2-3d16-4c6d-a629-db39d32f0eb2	511a43e4-da3e-4ebb-a40f-554774f79dc1	4	2023-05-28	\N	30606.30	[DEMO]
509e49d7-a864-4d07-b344-05be05980df2	b93dabf3-c815-4e61-af0e-b441ae2b0a46	1	2021-10-15	2022-08-20	9362.70	[DEMO]
cf7641aa-fca9-494d-8477-e276098fb999	b93dabf3-c815-4e61-af0e-b441ae2b0a46	2	2022-10-06	2023-08-04	9815.00	[DEMO]
79d32e89-e478-4c19-afbf-37de34acd264	b93dabf3-c815-4e61-af0e-b441ae2b0a46	3	2023-12-22	2024-11-02	10965.20	[DEMO]
3e0d6edb-9149-4817-8847-bdc2161a59a4	b93dabf3-c815-4e61-af0e-b441ae2b0a46	4	2024-05-20	\N	20913.70	[DEMO]
0f430703-db3e-4b76-9c53-d8d964c6e440	7893dd48-7944-44bf-8d90-ff51288993fd	1	2024-01-18	2024-10-30	9838.40	[DEMO]
927691c0-b2e4-41e6-8c59-e8c8fd5a3656	7893dd48-7944-44bf-8d90-ff51288993fd	2	2025-02-04	2025-12-11	10075.00	[DEMO]
34611c2a-baa8-419a-a989-61252af861c2	7893dd48-7944-44bf-8d90-ff51288993fd	3	2025-11-06	\N	6344.40	[DEMO]
0165ebb3-11aa-4e90-bc15-fe75b826102f	58fb05ea-fd35-4a8d-838c-8d7fa5f58653	1	2024-09-10	2025-06-17	9716.00	[DEMO]
da20779a-4236-424a-bb96-d3ac552216dd	58fb05ea-fd35-4a8d-838c-8d7fa5f58653	2	2025-08-18	\N	10252.40	[DEMO]
3aef9f58-96cc-48a9-86fd-f04a0d17d549	3b265584-42f8-44e0-a098-59a2cae3d2db	1	2022-07-01	2023-04-27	8850.00	[DEMO]
7f7bedae-1acd-42f6-8d0f-48a37fc9855c	3b265584-42f8-44e0-a098-59a2cae3d2db	2	2023-07-28	2024-05-11	6912.00	[DEMO]
12b39fd8-2fc6-40f5-9dac-76532e7c4fe3	3b265584-42f8-44e0-a098-59a2cae3d2db	3	2024-04-25	\N	27274.80	[DEMO]
eb8a61bd-1751-4c43-bbdd-cd81378a2a8c	acb096b0-83a9-4575-b0e3-260d5a80ee54	1	2025-02-19	2025-12-31	9103.50	[DEMO]
182e6d65-06dd-4129-9306-eb6fb9a88edf	acb096b0-83a9-4575-b0e3-260d5a80ee54	2	2026-02-02	2026-12-16	7481.20	[DEMO]
cddc3b98-f2e9-42c8-b35b-72502ee02a9f	acb096b0-83a9-4575-b0e3-260d5a80ee54	3	2026-10-16	2027-08-24	7176.00	[DEMO]
393f0db8-e9e5-493b-ad4a-248be08db78a	acb096b0-83a9-4575-b0e3-260d5a80ee54	4	2027-09-01	\N	37.10	[DEMO]
bd387f72-c360-4a78-8ab8-54da03de2d55	dda0bd71-8c75-4eda-a9e0-a5ec640c2645	1	2022-08-27	\N	44283.30	[DEMO]
1f33e793-9665-4e8b-88d3-e6053b595c6c	c07a25a5-8117-4270-8fe9-aaf73a253071	1	2023-11-29	\N	25262.40	[DEMO]
6ae50103-fe66-47e0-86bf-9240305e0d70	0d62ba03-2611-452d-bf34-3a0934bee5f4	1	2021-06-09	2022-04-09	9788.80	[DEMO]
f33d7dd8-1645-42d1-a43b-0d30e576f2e7	0d62ba03-2611-452d-bf34-3a0934bee5f4	2	2022-04-05	\N	57267.00	[DEMO]
56f48bc7-d3f9-47b4-acc8-efe89c6ad5de	387e0bea-4d9a-40cc-a4f0-ac21503f93a8	1	2024-08-27	2025-06-22	6069.70	[DEMO]
4c688178-0561-4d33-aabf-d31855a19276	387e0bea-4d9a-40cc-a4f0-ac21503f93a8	2	2025-07-13	2026-04-23	6191.20	[DEMO]
043dcfbb-33cd-48e9-b45e-8c0ad089bfb8	387e0bea-4d9a-40cc-a4f0-ac21503f93a8	3	2026-08-11	2027-05-28	8236.00	[DEMO]
bacf2f07-3b25-47d0-9116-724365c4f7be	387e0bea-4d9a-40cc-a4f0-ac21503f93a8	4	2027-08-03	\N	32.40	[DEMO]
7bbddeed-9b4d-4a00-a7a2-4aa2a878899c	6fc5a4de-7cd0-41a6-a58a-6b21b719f1a7	1	2021-08-10	\N	66088.10	[DEMO]
610b8a20-5689-483d-b4d5-b5013c3c61c0	7bf86988-01c6-4cd5-b116-80dfde1277c1	1	2019-11-13	2020-09-17	7168.80	[DEMO]
d32694ed-bd59-4b03-9f61-958eb155b786	7bf86988-01c6-4cd5-b116-80dfde1277c1	2	2020-10-29	2021-08-30	6161.00	[DEMO]
3badd9c3-c8cf-44f4-8ef3-a08ecee6d726	7bf86988-01c6-4cd5-b116-80dfde1277c1	3	2021-11-14	2022-09-03	7412.90	[DEMO]
338300bb-d86c-4d6b-8f6e-9b21069f6747	7bf86988-01c6-4cd5-b116-80dfde1277c1	4	2023-01-20	\N	45815.00	[DEMO]
0cbeff32-e3c2-4115-8ec5-61729ccd9219	47503ce1-adab-4a8f-a942-bee77c0dabdc	1	2024-06-17	\N	25311.60	[DEMO]
f8a6702b-9fe8-4d38-badf-209af0e7acc2	a345a474-de66-4499-be25-1f4604108ce7	1	2024-02-20	2024-12-20	9120.00	[DEMO]
a3700493-ed88-4691-b03b-bed3d097a4cd	a345a474-de66-4499-be25-1f4604108ce7	2	2024-12-28	\N	12459.70	[DEMO]
dbf02c5f-e666-4f24-9215-a42e3d1efd03	608f6c8d-8d57-4abe-8b78-946a32c6a037	1	2021-11-13	2022-09-09	6990.00	[DEMO]
6f2906fd-d27f-4b5e-8fe0-f190944bc11c	608f6c8d-8d57-4abe-8b78-946a32c6a037	2	2022-10-30	\N	41431.90	[DEMO]
6b77f9cd-6456-4efa-b27c-c5144b4cdabb	80c0ec2f-41c9-43e4-a2db-11f0ba7c790d	1	2024-10-05	2025-07-21	6907.10	[DEMO]
e61dd625-c4b2-450c-9059-1aa935c86588	80c0ec2f-41c9-43e4-a2db-11f0ba7c790d	2	2025-10-16	\N	5895.00	[DEMO]
b9e775d2-b930-4561-b701-3e51d18e19b3	2eff0653-a8aa-4b79-8a80-8c5bed9233f3	1	2023-09-07	2024-06-25	9139.60	[DEMO]
4af3b605-c880-4ba9-899d-2b06ae6af1d5	2eff0653-a8aa-4b79-8a80-8c5bed9233f3	2	2024-07-25	2025-05-20	6757.40	[DEMO]
d4d6f694-5acc-4d89-a422-2727040aa580	2eff0653-a8aa-4b79-8a80-8c5bed9233f3	3	2025-07-10	2026-05-13	9854.70	[DEMO]
d6152461-c869-497f-92a0-73fa24fe40e0	2eff0653-a8aa-4b79-8a80-8c5bed9233f3	4	2026-03-04	\N	3156.20	[DEMO]
d3fceae6-cc5e-438a-b471-95f407286876	f54a614e-2dec-49ea-a29c-1f654d0f77bb	1	2023-03-09	\N	28836.50	[DEMO]
3f4a92a2-14d8-4a62-ac9d-fc4bda19af7b	8485de9f-b75c-41cc-95c4-0fa4926b9987	1	2021-10-08	\N	54208.00	[DEMO]
d703a983-e81e-4c85-87b0-9b6b42d9dc5a	f65f94d5-2741-4946-acbe-97a2132c0563	1	2022-11-22	2023-10-08	7136.00	[DEMO]
18764e03-a827-4bc0-8c2c-8d8d57ee9fca	f65f94d5-2741-4946-acbe-97a2132c0563	2	2023-10-20	\N	31987.20	[DEMO]
2790b651-1efa-4a5e-aabb-f911698c4687	fb7fa4dd-669e-48b6-89e4-757b694f5b07	1	2024-06-19	\N	25453.10	[DEMO]
b950ef9b-f8a1-45ae-b5dd-9a22a8dd6523	62f76f1d-c125-423a-9592-328be33a4b37	1	2024-02-02	2024-11-20	8876.80	[DEMO]
f4fbcb76-0540-4c2d-addc-b86944a7087c	62f76f1d-c125-423a-9592-328be33a4b37	2	2025-01-14	2025-10-24	7556.10	[DEMO]
352cd0c9-80c2-4bfa-8bde-50f805e62464	62f76f1d-c125-423a-9592-328be33a4b37	3	2025-11-15	\N	5947.50	[DEMO]
d4f516c9-b86c-4f3f-847e-8877eeef58d2	43c99312-c53e-478f-bb81-3302148f7c23	1	2020-08-12	2021-06-23	6709.50	[DEMO]
a3fd04ed-dfb7-4fea-b7b2-45d08ac6efb1	43c99312-c53e-478f-bb81-3302148f7c23	2	2021-08-02	2022-06-07	6210.90	[DEMO]
2d10845b-2b4b-47e2-8035-988c65f41486	43c99312-c53e-478f-bb81-3302148f7c23	3	2022-06-23	\N	38341.20	[DEMO]
0b85171b-6316-4833-9a80-4b2946a231f6	bdfc9cf7-e471-44a1-98d5-702c6f484a73	1	2022-07-22	\N	43476.30	[DEMO]
aaa1821d-e6ac-4b7d-975a-dcb39eb228df	b977bad8-5e76-4ff5-86c6-d22021c984c7	1	2021-03-21	\N	64240.50	[DEMO]
4ddd5c73-4dae-4137-ab5f-47b1e4e180c0	1a845209-5c9d-4833-a874-f20e1fc49d54	1	2023-10-07	2024-07-24	7100.40	[DEMO]
2e592fb1-c287-46f3-953b-20723bfe4160	1a845209-5c9d-4833-a874-f20e1fc49d54	2	2024-08-03	\N	18791.20	[DEMO]
649bd727-3226-4f11-b721-9ed7bfab8b99	86892057-2f7f-478f-bbcb-61110313ffd9	1	2022-04-04	2023-01-25	6156.80	[DEMO]
26d8c425-df78-4ee7-b3d3-83ad1bccad52	86892057-2f7f-478f-bbcb-61110313ffd9	2	2023-04-07	\N	26518.80	[DEMO]
13a60ff6-0ac3-40ef-859f-8064e42f1399	594223a0-9f8a-498e-8487-424895a3d0b0	1	2022-12-16	2023-10-31	9889.00	[DEMO]
b8931235-931c-4c0c-bf1b-04c27f731126	594223a0-9f8a-498e-8487-424895a3d0b0	2	2024-01-05	2024-10-18	7576.80	[DEMO]
ab30657d-e308-49d0-8c94-5e77cacd8648	594223a0-9f8a-498e-8487-424895a3d0b0	3	2024-12-09	\N	17527.20	[DEMO]
e3313df4-8fda-4bfa-8337-bf0ad9bd6584	4f921cd6-0fc9-4628-a46d-8ff93466e82c	1	2022-07-30	2023-05-31	10766.50	[DEMO]
30ce70b7-6a76-432c-84bd-02f639e7c6d5	4f921cd6-0fc9-4628-a46d-8ff93466e82c	2	2023-07-12	2024-05-25	8808.60	[DEMO]
54607690-6e69-4fde-b8b0-bfbbfeaa58d9	4f921cd6-0fc9-4628-a46d-8ff93466e82c	3	2024-05-10	2025-02-14	7140.00	[DEMO]
881ed358-f939-435b-961b-550eb1fe1f89	4f921cd6-0fc9-4628-a46d-8ff93466e82c	4	2025-05-21	\N	9809.90	[DEMO]
25ef1e94-e642-4c29-b79a-4396142dc025	ff998675-ed1e-4229-aab0-3d86147177c2	1	2024-01-23	2024-11-09	8730.00	[DEMO]
1c4e1ade-d977-47f7-a253-81ce5436b4a4	ff998675-ed1e-4229-aab0-3d86147177c2	2	2025-02-03	2025-12-10	10881.00	[DEMO]
572071db-7b79-42f7-8155-dee621bde1a0	ff998675-ed1e-4229-aab0-3d86147177c2	3	2026-02-19	2026-12-11	8112.50	[DEMO]
fbb82707-4253-4e66-b987-6e206ddfc754	ff998675-ed1e-4229-aab0-3d86147177c2	4	2027-01-10	\N	30.60	[DEMO]
8f681110-9725-456a-b00b-0becd89f869b	2c611aa8-a92c-4556-8568-9294bab47d5d	1	2023-02-08	\N	41727.60	[DEMO]
27137d65-d589-4a4a-ade1-248e4ffeb5cb	9c643bba-a6d5-40c8-b023-f781c9763028	1	2023-12-11	\N	29340.00	[DEMO]
1eb61955-a7a0-4d73-b93b-9c597deaf69f	c78d9927-66e8-4aee-8e04-b83ec129c31d	1	2024-09-23	2025-07-26	9822.60	[DEMO]
21f03134-93b7-4716-91c8-04994c41582a	c78d9927-66e8-4aee-8e04-b83ec129c31d	2	2025-07-24	\N	10722.30	[DEMO]
1e34bff6-493a-4261-b3b3-4338ff22783c	c659f4da-3f7d-46e7-8993-0536c9640c3d	1	2023-04-30	2024-03-08	10266.40	[DEMO]
f6321641-d3b8-4261-ace3-5e19bc477248	c659f4da-3f7d-46e7-8993-0536c9640c3d	2	2024-04-30	\N	24212.10	[DEMO]
032c8138-6772-4780-b7fb-a36fec292fe5	f530bb0a-99a5-420f-9e18-6cb1dbd1973e	1	2020-03-18	2021-01-06	7408.80	[DEMO]
a9277870-2fdc-4ce6-8397-9622434f839e	f530bb0a-99a5-420f-9e18-6cb1dbd1973e	2	2021-03-27	2022-01-01	8932.00	[DEMO]
71317898-0b2f-4554-8d1a-f3508044afc3	f530bb0a-99a5-420f-9e18-6cb1dbd1973e	3	2022-05-27	2023-03-09	9466.60	[DEMO]
533e23a0-11ce-4591-961e-a74bdb8b2632	f530bb0a-99a5-420f-9e18-6cb1dbd1973e	4	2023-03-03	\N	36791.30	[DEMO]
13b76903-0792-4511-a3cb-40ab452cbd13	6784e799-962c-4527-b86a-c96905fff757	1	2019-12-22	2020-11-06	7104.00	[DEMO]
d00a4a31-43ed-4091-b910-0d9a21e69443	6784e799-962c-4527-b86a-c96905fff757	2	2020-11-25	2021-09-23	7368.80	[DEMO]
66619ee0-718c-4240-bcf1-00047a56b3a5	6784e799-962c-4527-b86a-c96905fff757	3	2022-01-26	2022-11-09	9758.00	[DEMO]
e01ba74c-c0f7-4e0a-8a4f-09d2d1fee9a0	6784e799-962c-4527-b86a-c96905fff757	4	2022-06-24	\N	40036.50	[DEMO]
327e5107-d670-466c-9a8e-981fa9bddd9c	121e0d34-5536-4a93-948b-d9581d928d3d	1	2020-07-24	2021-05-02	8234.40	[DEMO]
67bee761-0cee-4eaa-bafd-8230a8788161	121e0d34-5536-4a93-948b-d9581d928d3d	2	2021-07-01	\N	40880.40	[DEMO]
6d686569-25b5-4c96-811a-5b857b5fc5a2	a58bf738-0ced-454e-a89e-779af50bdde6	1	2025-02-06	2025-12-10	8196.90	[DEMO]
7ad5dff5-9c95-4e5b-82d2-e1a0ceba8d9b	a58bf738-0ced-454e-a89e-779af50bdde6	2	2026-03-13	\N	2579.50	[DEMO]
ac8c8e7e-1ca5-4457-9ef6-11ee50c4a0d0	0cc26162-5744-4617-8a37-65274b54c48d	1	2022-05-26	2023-03-12	9222.00	[DEMO]
057eeab0-6432-41ee-8a55-195848e497d1	0cc26162-5744-4617-8a37-65274b54c48d	2	2023-04-14	\N	36283.80	[DEMO]
0b61b5d0-f08f-4c71-a49a-ba990ea72e10	2ecf6665-0c82-488d-9749-7941de974abf	1	2020-04-17	2021-02-15	9545.60	[DEMO]
8ed17067-a5ef-4ad9-9505-7680efb8ccf4	2ecf6665-0c82-488d-9749-7941de974abf	2	2021-03-20	\N	43228.80	[DEMO]
bc444313-6f85-4ccb-b2f6-49467e25a08a	ab618b25-84fa-4e28-a07d-20ac6e868648	1	2024-04-13	2025-01-20	5752.80	[DEMO]
bf13a322-964a-495a-9331-1ed0bf132dfd	ab618b25-84fa-4e28-a07d-20ac6e868648	2	2025-02-10	\N	17359.10	[DEMO]
26441495-46aa-4e23-87cb-bee0010cfd62	663aec4c-0d3d-496e-8da9-75425e7abb42	1	2023-01-20	2023-11-23	8289.00	[DEMO]
5488de40-365f-4288-9397-817b36bd65cf	663aec4c-0d3d-496e-8da9-75425e7abb42	2	2024-01-14	2024-11-09	6540.00	[DEMO]
ab859b4c-5eed-4fa8-bde1-16d6837ed2fa	663aec4c-0d3d-496e-8da9-75425e7abb42	3	2025-03-06	\N	14323.10	[DEMO]
f9456e00-5af1-4528-b136-ac978c9abb9a	754c21c2-5528-4fe0-b94b-078ab53ba4f7	1	2021-02-14	\N	57707.00	[DEMO]
8f742157-894b-4973-9d7c-be1880b61fcb	41098454-a4a4-45db-bc95-a2793218055b	1	2024-08-06	2025-06-03	6471.50	[DEMO]
2f663f8c-c368-44de-ab03-9407fe69b599	41098454-a4a4-45db-bc95-a2793218055b	2	2025-06-05	2026-04-12	7712.80	[DEMO]
a79c0233-42be-418d-9838-c69c7c0a2c95	41098454-a4a4-45db-bc95-a2793218055b	3	2026-04-22	\N	1017.50	[DEMO]
8b45b612-54e1-4a35-80a3-ad030c24480f	6d743a75-3b83-454f-91eb-76bfb4439dd9	1	2020-04-16	2021-03-02	10464.00	[DEMO]
86db82f6-1d14-4804-816a-23bd783dd046	6d743a75-3b83-454f-91eb-76bfb4439dd9	2	2021-04-25	2022-03-08	7005.70	[DEMO]
1edde23e-85a0-4e6f-8a0a-dc737dbbaaa4	6d743a75-3b83-454f-91eb-76bfb4439dd9	3	2022-04-26	\N	51393.60	[DEMO]
cbb3bb74-69f5-41dc-972c-62fb74f6662c	836b7685-ad7c-48c5-aa09-f54590e75701	1	2021-10-15	2022-08-10	10046.40	[DEMO]
72af82e1-9cb1-4da9-8363-e24600d78194	836b7685-ad7c-48c5-aa09-f54590e75701	2	2022-11-07	2023-08-18	8662.00	[DEMO]
dcc46cc0-2f3d-453e-9375-4e5e6d34c88f	836b7685-ad7c-48c5-aa09-f54590e75701	3	2023-08-10	2024-06-08	8544.60	[DEMO]
9a7e195f-b5d7-403d-9581-36bfa2e1d140	836b7685-ad7c-48c5-aa09-f54590e75701	4	2024-10-26	\N	13514.00	[DEMO]
e94f3bbb-ee42-44b1-8cdb-d2cbe4d3bddc	14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5	1	2024-03-23	2025-01-16	10345.40	[DEMO]
666855b6-fb60-4c14-8bb9-0283e661d033	14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5	2	2025-03-16	2025-12-29	7776.00	[DEMO]
8ae57788-65aa-43a3-be24-f53f09e641c5	14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5	3	2026-05-02	\N	707.40	[DEMO]
01c598b5-7938-434f-9069-60575e8f46a6	3ee55362-8374-452c-ac80-5a93545bab2a	1	2023-12-09	2024-10-01	6415.20	[DEMO]
adf7af9b-77e3-491f-83ec-02cd000e3165	3ee55362-8374-452c-ac80-5a93545bab2a	2	2024-11-19	2025-09-06	6518.40	[DEMO]
cd6fcd5c-1faa-4cf2-9336-656e25e5b992	3ee55362-8374-452c-ac80-5a93545bab2a	3	2025-10-01	2026-08-08	8801.30	[DEMO]
e0f9506c-b320-4fe3-8270-4ee7d5c70351	3ee55362-8374-452c-ac80-5a93545bab2a	4	2026-11-29	\N	29.70	[DEMO]
3e8cf3b6-3597-4d66-a034-6588adb62e50	1ef34732-92bc-47c3-896c-d5ef65704b1d	1	2020-12-17	\N	63250.20	[DEMO]
23bda24f-f650-43b9-b5f9-7ca3a8debf43	299618a7-5c8b-4ed3-a6fa-5280adffe5e2	1	2021-01-31	2021-11-15	6019.20	[DEMO]
c7d2f085-56b0-4b26-b427-1690b077cdf0	299618a7-5c8b-4ed3-a6fa-5280adffe5e2	2	2022-01-07	2022-10-16	10095.60	[DEMO]
c69d7033-8e80-4249-a091-79d3d66f8f9f	299618a7-5c8b-4ed3-a6fa-5280adffe5e2	3	2023-04-05	2024-02-15	6983.60	[DEMO]
93c71096-5d97-4995-b593-533f8c619617	299618a7-5c8b-4ed3-a6fa-5280adffe5e2	4	2024-01-13	\N	28437.60	[DEMO]
22dafaba-b301-43a3-aa3e-132c924d8e80	60617164-bf9a-4125-b9f2-97603d14e2f8	1	2025-03-13	2025-12-25	9069.20	[DEMO]
44921c16-a956-4776-a391-34bd5e1dc904	60617164-bf9a-4125-b9f2-97603d14e2f8	2	2026-02-15	2026-12-17	7289.50	[DEMO]
50f011bb-b32a-4947-9eda-a6bf5cf5bd4c	60617164-bf9a-4125-b9f2-97603d14e2f8	3	2027-02-25	2028-01-01	6386.00	[DEMO]
13967866-f811-49c5-a30b-302bd996fced	60617164-bf9a-4125-b9f2-97603d14e2f8	4	2027-10-05	\N	28.10	[DEMO]
629568f1-c3b1-47d3-9fb2-13ca25daebc1	7d13f564-6ae2-4d35-9d0e-83408643e6bd	1	2023-10-13	\N	30304.40	[DEMO]
743955c8-69a0-4b40-bb43-bf0f095ee1f6	87fb22d7-4391-4404-b641-dff004bed87f	1	2024-11-16	2025-09-12	7140.00	[DEMO]
faee1dfe-ed96-44af-a414-0bf49938560d	87fb22d7-4391-4404-b641-dff004bed87f	2	2025-10-26	2026-09-08	10936.50	[DEMO]
683b310a-247b-48b6-a61a-988c4f69cc63	87fb22d7-4391-4404-b641-dff004bed87f	3	2026-09-13	2027-07-27	9827.00	[DEMO]
892f2b50-0326-48a4-afb5-019193e4fc64	87fb22d7-4391-4404-b641-dff004bed87f	4	2028-02-02	\N	31.40	[DEMO]
5d728561-9161-40e1-86aa-20cafa40173e	d2ae0d6c-62cd-450e-a104-7ee7f7320480	1	2021-08-08	2022-05-29	8202.60	[DEMO]
5694bc64-20ab-4f36-bf30-5527408630bd	d2ae0d6c-62cd-450e-a104-7ee7f7320480	2	2022-07-17	2023-05-14	6953.10	[DEMO]
dd1de6d6-0f96-48cb-a87f-81c22fafa5ca	d2ae0d6c-62cd-450e-a104-7ee7f7320480	3	2023-04-14	\N	29323.70	[DEMO]
9b0fc957-3b35-4b7a-a5bd-fced3805c128	d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	1	2022-04-18	2023-03-01	7512.90	[DEMO]
84518e0b-7bdf-4d4d-ae80-557fe571c93f	d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	2	2023-02-26	2024-01-06	7253.40	[DEMO]
11baf170-3d3e-4ed4-a26c-4dd508263ce5	d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	3	2023-12-29	2024-10-29	6893.00	[DEMO]
4c4c2026-0b18-41fd-adb2-080985220ee6	d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	4	2025-04-05	\N	15293.50	[DEMO]
62a22f2d-1962-4546-819a-8f845438a466	9d2f8668-e36c-4578-81d6-001ada65572e	1	2022-02-25	2022-12-27	10095.50	[DEMO]
49658130-d8a2-48b1-81a6-747950bbee4b	9d2f8668-e36c-4578-81d6-001ada65572e	2	2023-01-31	2023-12-04	6232.10	[DEMO]
7830c256-d7da-440f-8760-05149a55ff96	9d2f8668-e36c-4578-81d6-001ada65572e	3	2024-02-23	2024-12-01	6232.20	[DEMO]
4b53d3d1-1e02-4d17-86d4-e16811e1b012	9d2f8668-e36c-4578-81d6-001ada65572e	4	2024-10-06	\N	20700.00	[DEMO]
5b85fea5-94b2-47b6-9ac4-8870a9e5e2c5	929630b3-dc54-475d-a50f-e2ad377f0fe8	1	2021-11-23	2022-10-04	6772.50	[DEMO]
8fdf21c1-d2b1-4665-8118-c6ebd055ec8d	929630b3-dc54-475d-a50f-e2ad377f0fe8	2	2022-12-20	2023-10-19	10059.60	[DEMO]
86cdeddc-df94-4e68-89b3-734731fa47e9	929630b3-dc54-475d-a50f-e2ad377f0fe8	3	2023-09-20	\N	32307.80	[DEMO]
b595cbc0-f2e5-458c-9c10-5cb47d961e7a	003a9fe9-e4a0-447f-bcdb-57439cd5e412	1	2020-05-18	2021-03-23	11062.20	[DEMO]
90cb9076-0a48-4223-81e8-36f25ee1ae5a	003a9fe9-e4a0-447f-bcdb-57439cd5e412	2	2021-04-25	\N	66216.00	[DEMO]
7b269d78-44cc-4350-911a-b2d76c2560f9	6242a97b-f3b8-42f8-98fa-ab92058599ee	1	2020-11-13	\N	45719.80	[DEMO]
e0a5ab1e-0cf3-489f-8476-fb0305b2c367	92d13248-9188-43d4-92fe-2bacb22565d2	1	2024-06-15	2025-04-05	8290.80	[DEMO]
2fb9b83f-d8a6-476a-bf07-9fdce5248632	92d13248-9188-43d4-92fe-2bacb22565d2	2	2025-07-06	2026-04-18	7436.00	[DEMO]
d86bdd36-f3e1-47b2-8e71-f623af7ff1fa	92d13248-9188-43d4-92fe-2bacb22565d2	3	2026-06-19	\N	29.50	[DEMO]
d0d58827-2086-4f1a-8517-eedd692047f2	5f6a9e48-7748-4a42-be2b-3fbaed701adc	1	2022-04-23	2023-03-07	9635.40	[DEMO]
05edfe8b-c3f9-49d5-b673-e43a8d239cfe	5f6a9e48-7748-4a42-be2b-3fbaed701adc	2	2023-03-23	\N	31052.10	[DEMO]
5f6eb5c3-7974-4d9c-8fae-12d11aae233b	bca99578-d4de-422a-b04f-1ae3da4d3b43	1	2022-10-24	2023-08-27	9363.50	[DEMO]
cb4b1c8c-5827-4dba-a6a1-aa273e857853	bca99578-d4de-422a-b04f-1ae3da4d3b43	2	2023-09-20	\N	31620.40	[DEMO]
db24f714-1d4d-4e8c-ab0e-0cc3e3a028e1	0765dd1d-c2aa-4087-8fb9-6cf783266edb	1	2024-11-05	2025-08-22	6293.00	[DEMO]
975331be-54d3-4830-befa-6c971d390cc1	0765dd1d-c2aa-4087-8fb9-6cf783266edb	2	2025-11-18	2026-09-06	7796.40	[DEMO]
755433af-a6e0-47c8-8fc3-82ef8b373251	0765dd1d-c2aa-4087-8fb9-6cf783266edb	3	2026-12-01	\N	23.60	[DEMO]
4cb55065-936a-4361-ab7a-a58cf8835aa9	f664da5c-e84f-4de3-abe2-954a07871fae	1	2021-06-24	2022-04-29	7385.10	[DEMO]
1cd1ddaa-d8e6-4d90-b14b-d0ad7b7b6ee3	f664da5c-e84f-4de3-abe2-954a07871fae	2	2022-04-30	2023-02-12	8784.00	[DEMO]
ee802520-9cf1-4782-8db3-a6bd001fae46	f664da5c-e84f-4de3-abe2-954a07871fae	3	2023-08-01	\N	31476.00	[DEMO]
643aa049-d61d-48d9-a7ee-2a993e0d5611	9fcc4de5-8fec-4f04-85ea-57963cba6119	1	2021-06-10	\N	61313.20	[DEMO]
cd4e85eb-c44c-44e3-acd5-a1e50046665d	0cf23273-77eb-459b-abc4-d9475392e8af	1	2022-01-27	2022-11-09	9981.40	[DEMO]
bd73cff9-2a14-4555-8b99-19dad657f2d7	0cf23273-77eb-459b-abc4-d9475392e8af	2	2023-02-02	2023-11-25	7429.60	[DEMO]
7df18cdc-5b61-48e0-8afd-266f74cbe78d	0cf23273-77eb-459b-abc4-d9475392e8af	3	2024-02-06	2024-11-17	6669.00	[DEMO]
ef2792c6-a2b9-444e-8fd4-45efe0c3c5ce	0cf23273-77eb-459b-abc4-d9475392e8af	4	2024-09-01	\N	22542.50	[DEMO]
\.


--
-- Data for Name: lecturas_carro_mezclador; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lecturas_carro_mezclador (ts, mezcla_id, ingrediente, peso_objetivo, peso_real, operario_id) FROM stdin;
\.


--
-- Data for Name: lecturas_meteorologia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lecturas_meteorologia (ts, estacion_id, temperatura_c, humedad_relativa, precipitacion_mm, viento_km_h, direccion_viento, radiacion_wm2) FROM stdin;
2026-05-26 12:16:23.847237+00	DEMO_LUGO_01	11.2	85.7	4.8	4.9	335	196.7
2026-05-26 13:16:23.84993+00	DEMO_LUGO_01	13.3	88.2	0.9	13.1	337	263.2
2026-05-26 14:16:23.850628+00	DEMO_LUGO_01	11.0	87.4	2.0	17.6	11	155.4
2026-05-26 15:16:23.851131+00	DEMO_LUGO_01	12.2	87.8	0.0	18.7	0	126.4
2026-05-26 16:16:23.851614+00	DEMO_LUGO_01	13.7	87.9	0.0	14.3	327	393.0
2026-05-26 17:16:23.852074+00	DEMO_LUGO_01	12.5	88.8	3.1	16.2	35	247.8
2026-05-26 18:16:23.852941+00	DEMO_LUGO_01	10.9	83.4	0.0	5.9	341	109.5
2026-05-26 19:16:23.853475+00	DEMO_LUGO_01	11.8	81.1	0.0	6.6	120	185.5
2026-05-26 20:16:23.854004+00	DEMO_LUGO_01	12.7	87.0	0.3	15.7	124	303.6
2026-05-26 21:16:23.854418+00	DEMO_LUGO_01	10.7	85.0	0.7	18.1	219	159.8
2026-05-26 22:16:23.855031+00	DEMO_LUGO_01	13.5	85.0	0.0	6.4	173	208.9
2026-05-26 23:16:23.855771+00	DEMO_LUGO_01	11.0	81.8	0.0	16.7	48	207.6
2026-05-27 00:16:23.856603+00	DEMO_LUGO_01	13.4	87.4	0.0	22.0	326	228.2
2026-05-27 01:16:23.857043+00	DEMO_LUGO_01	13.9	89.6	0.0	12.4	175	75.6
2026-05-27 02:16:23.857449+00	DEMO_LUGO_01	13.0	89.9	5.9	8.3	278	309.2
2026-05-27 03:16:23.857849+00	DEMO_LUGO_01	10.5	85.3	0.0	19.5	259	58.7
2026-05-27 04:16:23.858269+00	DEMO_LUGO_01	13.2	82.4	0.0	10.5	321	91.8
2026-05-27 05:16:23.858672+00	DEMO_LUGO_01	13.1	84.4	4.9	5.5	227	185.6
2026-05-27 06:16:23.859069+00	DEMO_LUGO_01	14.3	88.7	2.4	8.5	183	230.0
2026-05-27 07:16:23.859538+00	DEMO_LUGO_01	10.2	89.1	0.0	19.0	234	78.1
2026-05-27 08:16:23.860014+00	DEMO_LUGO_01	13.2	86.4	0.0	20.0	256	146.4
2026-05-27 09:16:23.861058+00	DEMO_LUGO_01	14.2	88.7	0.0	8.7	218	247.8
2026-05-27 10:16:23.861543+00	DEMO_LUGO_01	10.9	83.5	0.0	15.5	89	378.4
2026-05-27 11:16:23.862288+00	DEMO_LUGO_01	13.2	84.1	5.5	14.2	269	204.1
2026-05-27 12:16:23.863014+00	DEMO_LUGO_01	10.7	89.0	0.0	6.4	14	284.4
2026-05-27 13:16:23.863745+00	DEMO_LUGO_01	9.9	86.3	0.0	16.2	322	337.6
2026-05-27 14:16:23.864822+00	DEMO_LUGO_01	13.1	84.4	2.1	14.4	323	226.7
2026-05-27 15:16:23.865423+00	DEMO_LUGO_01	10.2	90.2	0.0	14.5	254	160.9
2026-05-27 16:16:23.865841+00	DEMO_LUGO_01	12.4	83.3	5.8	10.4	44	174.3
2026-05-27 17:16:23.86628+00	DEMO_LUGO_01	13.7	82.5	5.8	4.4	58	179.2
2026-05-27 18:16:23.866732+00	DEMO_LUGO_01	12.5	91.0	0.0	18.5	113	91.7
2026-05-27 19:16:23.867135+00	DEMO_LUGO_01	11.1	81.7	5.6	18.2	0	137.2
2026-05-27 20:16:23.867534+00	DEMO_LUGO_01	13.8	89.1	5.1	8.3	291	167.3
2026-05-27 21:16:23.867955+00	DEMO_LUGO_01	13.5	86.8	0.0	13.5	290	281.0
2026-05-27 22:16:23.868364+00	DEMO_LUGO_01	11.9	88.6	0.0	11.9	171	265.8
2026-05-27 23:16:23.868769+00	DEMO_LUGO_01	14.2	82.0	0.0	9.5	18	169.4
2026-05-28 00:16:23.869152+00	DEMO_LUGO_01	11.4	84.9	0.0	6.8	241	36.6
2026-05-28 01:16:23.869612+00	DEMO_LUGO_01	11.5	84.5	0.0	14.7	323	40.6
2026-05-28 02:16:23.869988+00	DEMO_LUGO_01	13.2	84.9	0.0	14.3	17	87.5
2026-05-28 03:16:23.87036+00	DEMO_LUGO_01	13.4	89.2	0.0	17.2	207	234.4
2026-05-28 04:16:23.870778+00	DEMO_LUGO_01	10.2	84.0	3.3	12.1	202	174.2
2026-05-28 05:16:23.871242+00	DEMO_LUGO_01	9.6	88.9	0.0	18.0	77	350.2
2026-05-28 06:16:23.871634+00	DEMO_LUGO_01	11.2	89.4	0.0	11.3	182	155.2
2026-05-28 07:16:23.872013+00	DEMO_LUGO_01	12.3	82.4	0.0	21.8	2	162.8
2026-05-28 08:16:23.872395+00	DEMO_LUGO_01	12.8	85.4	2.4	17.7	292	101.7
2026-05-28 09:16:23.87279+00	DEMO_LUGO_01	12.0	85.1	0.0	13.0	43	250.3
2026-05-28 10:16:23.873228+00	DEMO_LUGO_01	12.2	81.8	3.1	6.3	274	115.0
2026-05-28 11:16:23.873669+00	DEMO_LUGO_01	11.1	81.2	0.0	5.2	345	195.4
2026-05-28 12:16:23.874066+00	DEMO_LUGO_01	10.1	84.4	2.1	15.7	141	38.6
2026-05-28 13:16:23.874509+00	DEMO_LUGO_01	13.2	89.6	0.0	16.8	73	42.8
2026-05-28 14:16:23.87497+00	DEMO_LUGO_01	13.6	85.7	5.4	19.2	159	228.9
2026-05-28 15:16:23.875357+00	DEMO_LUGO_01	10.1	83.2	0.0	20.9	139	192.7
2026-05-28 16:16:23.87573+00	DEMO_LUGO_01	14.2	85.1	2.2	12.0	306	18.6
2026-05-28 17:16:23.876134+00	DEMO_LUGO_01	10.4	88.5	0.0	5.7	322	228.4
2026-05-28 18:16:23.876512+00	DEMO_LUGO_01	13.8	82.6	1.7	7.0	273	44.0
2026-05-28 19:16:23.876908+00	DEMO_LUGO_01	9.6	88.4	0.0	20.4	133	382.1
2026-05-28 20:16:23.877302+00	DEMO_LUGO_01	13.7	88.9	0.0	4.8	264	319.1
2026-05-28 21:16:23.877742+00	DEMO_LUGO_01	14.2	83.7	2.5	8.2	199	377.0
2026-05-28 22:16:23.87823+00	DEMO_LUGO_01	12.1	86.1	5.1	15.2	301	307.9
2026-05-28 23:16:23.8787+00	DEMO_LUGO_01	13.5	81.7	0.0	21.9	350	340.4
2026-05-29 00:16:23.879204+00	DEMO_LUGO_01	10.5	86.9	0.0	19.5	333	182.9
2026-05-29 01:16:23.879832+00	DEMO_LUGO_01	10.0	84.0	3.9	19.1	106	324.5
2026-05-29 02:16:23.88062+00	DEMO_LUGO_01	14.2	83.6	3.2	18.2	235	157.8
2026-05-29 03:16:23.881059+00	DEMO_LUGO_01	10.0	84.0	0.0	7.7	281	297.6
2026-05-29 04:16:23.882054+00	DEMO_LUGO_01	12.5	88.1	0.0	15.9	286	171.6
2026-05-29 05:16:23.882638+00	DEMO_LUGO_01	13.1	85.3	0.0	10.9	41	282.6
2026-05-29 06:16:23.883245+00	DEMO_LUGO_01	14.1	81.8	2.1	11.1	32	295.3
2026-05-29 07:16:23.883706+00	DEMO_LUGO_01	14.3	81.7	0.0	7.8	319	303.0
2026-05-29 08:16:23.88414+00	DEMO_LUGO_01	10.5	86.8	0.0	11.3	2	247.5
2026-05-29 09:16:23.884608+00	DEMO_LUGO_01	9.9	89.9	0.0	18.2	149	229.2
2026-05-29 10:16:23.885115+00	DEMO_LUGO_01	12.4	81.5	2.4	10.2	105	337.1
2026-05-29 11:16:23.885584+00	DEMO_LUGO_01	13.9	83.7	0.0	10.4	259	276.7
2026-05-29 12:18:19.705821+00	DEMO_LUGO_01	14.6	84.9	0.0	19.6	301	98.6
2026-05-29 12:25:04.299076+00	DEMO_LUGO_01	15.3	84.7	2.0	8.8	250	295.5
2026-05-29 12:25:24.426454+00	DEMO_LUGO_01	15.8	85.3	0.0	8.8	65	256.7
2026-05-29 12:29:24.968402+00	DEMO_LUGO_01	16.3	85.4	3.3	12.7	51	84.5
2026-05-29 12:29:45.021721+00	DEMO_LUGO_01	15.8	86.0	0.3	15.5	60	309.2
2026-05-29 12:30:05.06439+00	DEMO_LUGO_01	15.6	84.9	0.3	17.1	141	257.0
2026-05-29 12:31:05.226974+00	DEMO_LUGO_01	16.4	85.1	0.0	8.0	201	319.4
2026-05-29 12:31:25.301545+00	DEMO_LUGO_01	17.0	85.2	0.9	18.6	69	29.3
2026-05-29 12:32:05.472316+00	DEMO_LUGO_01	16.5	83.5	0.0	4.1	119	117.0
\.


--
-- Data for Name: lecturas_robot_ordeno; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lecturas_robot_ordeno (ts, robot_id, animal_id, lactacion_id, produccion_kg, conductividad, flujo_max, scc, duracion_min, intentos_fallidos, alerta_robot) FROM stdin;
\.


--
-- Data for Name: maquinaria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.maquinaria (id, nombre, tipo, zona_id, marca, modelo, numero_serie, fecha_instalacion, activa, notas) FROM stdin;
34431d4b-d701-4c83-a42e-bf6d006879d1	Amamantadora	amamantadora	521c30a0-4751-4157-87d0-6aaf2c9c882d	Förster	HL 102	\N	\N	t	\N
ea750fb0-6a3a-4ece-bcd3-677cae4d10f1	Carro TMR	carro_mezclador	521c30a0-4751-4157-87d0-6aaf2c9c882d	Trioliet	Solomix 2	\N	\N	t	\N
05eb4010-90d8-4c9a-820d-30a43b7fcc1f	VMS 1	robot_ordeno	df0512cb-3963-4225-97dd-242b835a8118	DeLaval	VMS V300	\N	\N	t	\N
0797d387-7c18-4bfa-a846-10d7750da5e5	VMS 2	robot_ordeno	df0512cb-3963-4225-97dd-242b835a8118	DeLaval	VMS V300	\N	\N	t	\N
1dd0eda1-bbee-49fd-905b-5bf6da1cfe13	VMS 3	robot_ordeno	df0512cb-3963-4225-97dd-242b835a8118	DeLaval	VMS V300	\N	\N	t	\N
51f66a56-219f-40bd-9ff6-f819f205b37b	Tanque de leche 6000L	otro	3836de7c-0b6f-4306-904d-825890b6f534	DeLaval	DXCE6000	\N	\N	t	[DEMO] Equipo demo
22d2faa8-7be2-4683-a753-03d7a3615508	Bomba de vacío principal	bomba	3836de7c-0b6f-4306-904d-825890b6f534	DeLaval	VP3000	\N	\N	t	[DEMO] Equipo demo
6cadd95e-5983-40c6-813c-b380da82c437	Amamantadora digital	amamantadora	597ad6cc-663d-4eb8-8d08-286d22050b1d	Förster	HL200 Pro	\N	\N	t	[DEMO] Equipo demo
45fb58d3-75be-4b9a-a676-92af4911fee4	Arrobadera automática	otro	3836de7c-0b6f-4306-904d-825890b6f534	Lely	Discovery 120	\N	\N	t	[DEMO] Equipo demo
0d2d74f0-b864-490b-a633-eea2a09d890f	Equipo de alimentación	carro_mezclador	521c30a0-4751-4157-87d0-6aaf2c9c882d	Trioliet	Unifeed 10	\N	\N	t	[DEMO] Equipo demo
c0078401-da96-4091-b26d-b69f4509abed	Sensor temperatura ambiental	otro	df0512cb-3963-4225-97dd-242b835a8118	Skov	CS-3000	\N	\N	t	[DEMO] Equipo demo
81549b0a-98c3-4276-a431-9f1dda78e0bb	Bomba impulsión purines	bomba	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	\N	\N	\N	t	[DEMO] Equipo demo
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedidos (id, insumo, descripcion, cantidad, unidad, estado, solicitante_id, ts_solicitud, ts_aprobacion, ts_recepcion, proveedor, coste_estimado, coste_real, notas) FROM stdin;
aec1808e-e617-42b3-8a69-caf6c0abab6e	[DEMO] Filtros manga leche 50ud	\N	5.00	paquete	solicitado	60da9a93-e0f2-403b-a534-e35383483df5	2026-05-24 12:16:23.81258+00	\N	\N	AgroVet	92.50	\N	[DEMO]
536845b1-56d1-42f8-9d18-4e2902950969	[DEMO] Paja de trigo granulada	\N	20.00	fardo	solicitado	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	2026-05-23 12:16:23.816593+00	\N	\N	Agrícola del Norte	120.00	\N	[DEMO]
c11b2813-993e-4ddd-95fc-e19d4ff1c418	[DEMO] Pezoneras VMS DeLaval	\N	48.00	ud	aprobado	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	2026-05-24 12:16:23.817246+00	2026-05-24 19:16:23.817246+00	\N	DeLaval Ibérica	168.00	\N	[DEMO]
bbedde2c-40eb-4f3e-a441-662f4ff8ccf9	[DEMO] Detergente ácido neutralizador	\N	15.00	L	aprobado	30b40a49-5e28-4ce5-acbb-df297a52e509	2026-05-21 12:16:23.817911+00	2026-05-22 07:16:23.817911+00	\N	Ecolab	117.00	\N	[DEMO]
47e985f2-9cd4-4b20-b8ae-7fc9d73339fb	[DEMO] Leche en polvo maternizadora	\N	50.00	kg	en_transito	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	2026-05-20 12:16:23.818549+00	2026-05-21 02:16:23.818549+00	\N	NANTA	195.00	\N	[DEMO]
557cb482-26fc-4d48-afd4-c387cc539d40	[DEMO] Cornamenta registro electrónico	\N	25.00	ud	recibido	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	2026-05-11 12:16:23.819766+00	2026-05-12 02:16:23.819766+00	2026-05-16 02:16:23.819766+00	Allflex	212.50	229.82	[DEMO]
b1fd164c-17a6-4724-930b-ec81dc854725	[DEMO] Catéter intramamario desechable	\N	2.00	caja100	recibido	43958ec8-b358-4c41-bb4c-9b55cacfc8db	2026-05-09 12:16:23.820647+00	2026-05-09 22:16:23.820647+00	2026-05-15 22:16:23.820647+00	Hipra	84.00	81.76	[DEMO]
8fa23fa2-a411-475b-b6a0-a5ac26e784b3	[DEMO] Pienso recría 4-12 semanas	\N	500.00	kg	recibido	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	2026-05-08 12:16:23.821251+00	2026-05-09 08:16:23.821251+00	2026-05-12 08:16:23.821251+00	NANTA	225.00	245.84	[DEMO]
dd730fe6-dac2-40d4-a1f3-69cf2ae92669	[DEMO] Guantes nitrilo azul talla L	\N	10.00	caja	cancelado	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	2026-05-03 12:16:23.821809+00	\N	\N	Suministros Ganaderos SA	120.00	\N	[DEMO]
a5c928a7-3865-496d-9807-600e7a9761c3	[DEMO] Detergente alcalino limpieza robot	\N	20.00	L	recibido	60da9a93-e0f2-403b-a534-e35383483df5	2026-05-03 12:16:23.819175+00	2026-05-04 04:16:23.819175+00	2026-05-29 12:27:24.666919+00	Ecolab	164.00	\N	[DEMO]
d7d12ac5-e7ad-4a72-84fb-e96b9c148485	[DEMO] Aceite lubricante bomba vacío	\N	5.00	L	en_transito	513ad92d-a581-4d5b-b01e-7b3654f4482c	2026-05-20 12:16:23.815802+00	2026-05-29 12:28:04.776373+00	\N	Industrial Lugo	75.00	\N	[DEMO]
\.


--
-- Data for Name: resumenes_relevo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resumenes_relevo (id, turno_saliente_id, turno_entrante_id, ts_generacion, incidencias_abiertas, tareas_pendientes, alertas_pendientes, notas_saliente, confirmado_por, ts_confirmacion) FROM stdin;
772b1f91-cc1f-43c4-8f37-8300dce40140	339bc962-3dc2-46a3-b6aa-470b4fe83215	d345ccb9-ce5e-44d9-8884-3520023fecb0	2026-05-20 09:16:23.831934+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	\N	\N
fa13b73f-689f-4444-baea-b28045434648	acc685f4-6f01-4ddb-987c-7e23c56b956a	b62b0f67-a981-4870-af04-34e1138ae507	2026-05-21 10:16:23.835185+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	2d200ce2-5f48-4285-8d33-98f06db5b194	2026-05-21 10:29:23.835185+00
f95b095a-ffbf-453e-8122-be18728d4e26	e5631bcf-ed4d-49d4-a0f5-ffb8745975a5	ba261344-97be-4f10-b39a-3d424d3f59df	2026-05-22 09:16:23.836126+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	7f75e608-6c5b-429b-a36f-a644cc41501b	2026-05-22 09:52:23.836126+00
dffcb61a-51e4-4a94-87cb-2527b32052cb	b3d6328c-5b51-4f87-bff5-ec10552ebe8c	00182ede-3684-45ab-b570-3d226b9a2d6c	2026-05-23 09:16:23.836812+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	\N	\N
f3ce2690-5fc9-411f-b468-2bd44173d2e7	0bb0b848-67ef-4789-9fd9-4524e693af73	e0ab538b-bbe5-48c3-b1a1-7c3fadc7870b	2026-05-24 10:16:23.837457+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	\N	\N
eba4ceb6-8d5c-4427-9d96-13f3cd81a580	e1d4f30f-08df-41e0-9982-9991d36321f1	49718c23-1aa8-4a1a-91b0-3263ed7f904d	2026-05-25 11:16:23.838204+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	30b40a49-5e28-4ce5-acbb-df297a52e509	2026-05-25 11:52:23.838204+00
dcb75f9e-f323-4488-8823-236eeaf3d770	f223e2c1-5c23-4f07-8d13-675153f5b7f2	0d11162c-254f-49c7-909f-404af1c286f4	2026-05-26 10:16:23.838755+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	\N	\N
1167ae3c-062b-4e28-91e0-494c784d24a3	6ff946f4-d102-4e1d-88d9-eac1dc7f7a03	2aabfc2d-a7c8-4218-82e5-b74575d28885	2026-05-27 12:16:23.839723+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	2026-05-27 13:06:23.839723+00
d4bb1e3a-6824-4462-a85e-a6d03a528587	57da959a-a8b9-4293-93a2-057f3c89f005	978b6bce-96a6-4f06-8513-2911f6a1a13f	2026-05-28 09:16:23.840429+00	[]	[]	[]	[DEMO] Relevo sin incidencias relevantes.	\N	\N
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version, applied_at) FROM stdin;
0000_users.sql	2026-05-27 21:44:45.377001
0001_core_frontend.sql	2026-05-27 21:44:45.377001
0002_user_roles.sql	2026-05-27 21:44:45.377001
\.


--
-- Data for Name: tareas_catalogo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tareas_catalogo (id, codigo, nombre, descripcion, cualificacion_requerida, duracion_estimada_min, activa) FROM stdin;
957b910c-6e8d-49a6-8e00-e4c10e4a3109	lavado_robot	Lavado de robot de ordeño	\N	VMS	45	t
980b1b32-82b4-4dd0-beb5-336b29489e5b	desinfeccion_camas	Desinfección de camas	\N	\N	60	t
5b40eaff-7355-40d7-8110-35e2a17262de	limpieza_bebederos	Limpieza de bebederos	\N	\N	30	t
406456cd-724d-44c8-8fad-af6188aff749	preparacion_racion	Preparación ración unifeed (TMR)	\N	TMR	40	t
6edc8fa1-5eda-43cf-9367-956889cec20d	revision_terneros	Revisión diaria terneros	\N	\N	30	t
5912a23c-e0ac-4624-834d-89e7bb80bb3d	control_tratamientos	Control y administración tratamientos	\N	veterinaria	20	t
20e9c54c-9745-4047-b835-71d457136da9	recogida_muestras	Recogida muestras de leche	\N	\N	15	t
\.


--
-- Data for Name: tareas_ejecuciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tareas_ejecuciones (id, catalogo_id, recurrente_id, empleado_id, zona_id, maquinaria_id, estado, ts_planificada, ts_inicio, ts_fin, notas, creado_en) FROM stdin;
bf30599c-dda5-4150-a8e5-1375bf96a4cf	5b40eaff-7355-40d7-8110-35e2a17262de	\N	\N	3836de7c-0b6f-4306-904d-825890b6f534	\N	completada	2026-05-24 15:00:17.33387+00	2026-05-24 15:14:17.33387+00	2026-05-24 16:14:17.33387+00	[DEMO]	2026-05-28 05:16:23.718462+00
070c207f-e35e-43fd-ac8f-cda0ca019cff	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	60da9a93-e0f2-403b-a534-e35383483df5	3836de7c-0b6f-4306-904d-825890b6f534	\N	completada	2026-05-23 16:27:16.989141+00	2026-05-23 16:36:16.989141+00	2026-05-23 17:45:16.989141+00	[DEMO]	2026-05-27 17:16:23.72062+00
8c27bde0-134d-4352-b490-90007d099bde	6edc8fa1-5eda-43cf-9367-956889cec20d	\N	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	f102e952-9109-4668-a381-bc6693bc851b	\N	completada	2026-05-24 04:18:01.333546+00	2026-05-24 04:48:01.333546+00	2026-05-24 05:40:01.333546+00	[DEMO]	2026-05-28 09:16:23.721255+00
beaea8e0-2bfd-41bb-91f3-7300ce9e700b	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	3836de7c-0b6f-4306-904d-825890b6f534	\N	completada	2026-05-28 05:00:54.362418+00	2026-05-28 05:11:54.362418+00	2026-05-28 06:34:54.362418+00	[DEMO]	2026-05-28 13:16:23.72199+00
2893eccd-24e4-4d14-887c-1ce89dfed4ac	5b40eaff-7355-40d7-8110-35e2a17262de	\N	\N	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	vencida	2026-05-27 19:45:57.419541+00	\N	\N	[DEMO]	2026-05-29 10:16:23.722666+00
c7ee3863-9ae9-4861-89a6-39f02fb7ccb2	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	f102e952-9109-4668-a381-bc6693bc851b	\N	pendiente	2026-05-29 18:14:10.153033+00	\N	\N	[DEMO]	2026-05-29 00:16:23.723263+00
a4e97326-7013-45c5-b729-d59559105ed2	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 15:11:29.7177+00	\N	\N	[DEMO]	2026-05-27 18:16:23.723818+00
b9a219a6-8f98-4bb8-a9fc-e41ad9d7eb0c	20e9c54c-9745-4047-b835-71d457136da9	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	\N	completada	2026-05-23 01:30:42.076225+00	2026-05-23 01:57:42.076225+00	2026-05-23 02:42:42.076225+00	[DEMO]	2026-05-28 15:16:23.724304+00
90d3a9dc-6fea-44a7-a9a3-5ad1bab300aa	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	\N	en_curso	2026-05-29 11:33:49.532017+00	2026-05-29 11:47:49.532017+00	\N	[DEMO]	2026-05-27 15:16:23.724772+00
e52e6f15-8830-46bd-9942-8914fb401002	20e9c54c-9745-4047-b835-71d457136da9	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	vencida	2026-05-28 12:18:33.69983+00	\N	\N	[DEMO]	2026-05-27 12:16:23.725354+00
4012ec88-2abe-4d9e-8c8a-74774a749221	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	\N	df0512cb-3963-4225-97dd-242b835a8118	\N	vencida	2026-05-27 16:43:03.663839+00	\N	\N	[DEMO]	2026-05-28 18:16:23.72583+00
988d4145-dab2-4e1c-b087-9ec23a18454e	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	2d200ce2-5f48-4285-8d33-98f06db5b194	df0512cb-3963-4225-97dd-242b835a8118	\N	pendiente	2026-05-29 13:41:53.372629+00	\N	\N	[DEMO]	2026-05-28 04:16:23.726284+00
cabcfbcc-9415-4dd0-9c64-b53da2885ed1	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	f102e952-9109-4668-a381-bc6693bc851b	\N	en_curso	2026-05-29 11:14:48.115685+00	2026-05-29 11:27:48.115685+00	\N	[DEMO]	2026-05-28 18:16:23.727033+00
dae241f9-ee32-4241-996f-02ced4bd3729	20e9c54c-9745-4047-b835-71d457136da9	\N	\N	3836de7c-0b6f-4306-904d-825890b6f534	\N	completada	2026-05-23 07:24:04.344104+00	2026-05-23 07:41:04.344104+00	2026-05-23 08:23:04.344104+00	[DEMO]	2026-05-29 02:16:23.727539+00
a6c99967-0863-4c3a-8763-fd4ff99ebaa9	20e9c54c-9745-4047-b835-71d457136da9	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 13:58:37.01153+00	\N	\N	[DEMO]	2026-05-29 12:16:23.728557+00
108ea5b1-cdae-4bec-8bdd-5c98634275bd	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 20:02:50.684327+00	\N	\N	[DEMO]	2026-05-28 23:16:23.729675+00
326b06fa-383a-4964-a915-545ab1e141ec	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	3836de7c-0b6f-4306-904d-825890b6f534	\N	vencida	2026-05-28 20:00:27.411218+00	\N	\N	[DEMO]	2026-05-29 04:16:23.73049+00
50759c5f-dfa4-4991-912c-fe064f4a9a2c	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	\N	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 16:18:19.767678+00	\N	\N	[DEMO]	2026-05-27 19:16:23.731099+00
9cf8c4ca-c07c-4ecc-b144-b225e868aa63	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	f102e952-9109-4668-a381-bc6693bc851b	\N	cancelada	2026-05-27 14:52:19.131443+00	\N	\N	[DEMO]	2026-05-28 08:16:23.731575+00
830c0984-ff72-4e1f-9c38-a1a757b2ab79	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	60da9a93-e0f2-403b-a534-e35383483df5	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	completada	2026-05-27 09:07:13.797921+00	2026-05-27 09:22:13.797921+00	2026-05-27 10:30:13.797921+00	[DEMO]	2026-05-27 14:16:23.732292+00
f9008a7b-baca-4036-b3ab-0db21c1167d7	20e9c54c-9745-4047-b835-71d457136da9	\N	513ad92d-a581-4d5b-b01e-7b3654f4482c	f102e952-9109-4668-a381-bc6693bc851b	\N	vencida	2026-05-28 01:11:08.354173+00	\N	\N	[DEMO]	2026-05-28 17:16:23.732805+00
668526a1-1120-4cb1-a499-cc330512818f	20e9c54c-9745-4047-b835-71d457136da9	\N	60da9a93-e0f2-403b-a534-e35383483df5	3836de7c-0b6f-4306-904d-825890b6f534	\N	completada	2026-05-26 15:30:50.201309+00	2026-05-26 15:51:50.201309+00	2026-05-26 16:11:50.201309+00	[DEMO]	2026-05-27 23:16:23.733285+00
43ca4fa4-7ade-450a-a506-3d5f91a44c36	6edc8fa1-5eda-43cf-9367-956889cec20d	\N	60da9a93-e0f2-403b-a534-e35383483df5	df0512cb-3963-4225-97dd-242b835a8118	\N	completada	2026-05-27 01:10:06.269854+00	2026-05-27 01:15:06.269854+00	2026-05-27 02:45:06.269854+00	[DEMO]	2026-05-28 22:16:23.733752+00
143ad0e9-d136-4c15-8f9f-8b4c4446172f	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	60da9a93-e0f2-403b-a534-e35383483df5	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	pendiente	2026-05-29 18:53:11.566273+00	\N	\N	[DEMO]	2026-05-29 03:16:23.734206+00
b7df402b-b119-4656-be64-bef3c5507195	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	pendiente	2026-05-29 13:44:56.588732+00	\N	\N	[DEMO]	2026-05-28 19:16:23.734713+00
d7a76e8e-6dc3-4979-85c7-6ba06922cea1	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	cancelada	2026-05-26 14:11:23.940205+00	\N	\N	[DEMO]	2026-05-29 10:16:23.735153+00
eef53aac-13de-4dc8-a3b0-d2b3d84666b5	20e9c54c-9745-4047-b835-71d457136da9	\N	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	pendiente	2026-05-29 17:07:20.923894+00	\N	\N	[DEMO]	2026-05-27 14:16:23.735591+00
39029e32-130b-4e8a-b0cd-bd02473feab3	5b40eaff-7355-40d7-8110-35e2a17262de	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	en_curso	2026-05-29 10:13:15.417025+00	2026-05-29 10:23:15.417025+00	\N	[DEMO]	2026-05-28 23:16:23.736065+00
31f2cb06-0d8b-4153-98f7-8101d2c7afe0	5b40eaff-7355-40d7-8110-35e2a17262de	\N	513ad92d-a581-4d5b-b01e-7b3654f4482c	f102e952-9109-4668-a381-bc6693bc851b	\N	completada	2026-05-27 04:00:31.916317+00	2026-05-27 04:23:31.916317+00	2026-05-27 05:20:31.916317+00	[DEMO]	2026-05-28 10:16:23.736583+00
f9ea129b-29f8-44da-936a-ee91a5fa06a4	406456cd-724d-44c8-8fad-af6188aff749	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	completada	2026-05-24 22:30:24.233562+00	2026-05-24 22:38:24.233562+00	2026-05-24 23:57:24.233562+00	[DEMO]	2026-05-29 02:16:23.737061+00
36ddfdee-08dc-4800-bc36-cbc21703c5ea	406456cd-724d-44c8-8fad-af6188aff749	\N	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	pendiente	2026-05-29 15:29:17.0201+00	\N	\N	[DEMO]	2026-05-28 08:16:23.73773+00
addee36f-d1c2-4dac-92c4-61e1f00f374e	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	df0512cb-3963-4225-97dd-242b835a8118	\N	pendiente	2026-05-29 18:18:21.173882+00	\N	\N	[DEMO]	2026-05-28 01:16:23.73823+00
5a3b9d86-1823-4dfb-a952-a1166314c94c	406456cd-724d-44c8-8fad-af6188aff749	\N	513ad92d-a581-4d5b-b01e-7b3654f4482c	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	completada	2026-05-23 15:25:57.750219+00	2026-05-23 15:52:57.750219+00	2026-05-23 16:12:57.750219+00	[DEMO]	2026-05-28 07:16:23.738706+00
45431d84-9bc6-443d-a13f-c68835f164ee	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	completada	2026-05-24 18:06:33.833569+00	2026-05-24 18:24:33.833569+00	2026-05-24 18:56:33.833569+00	[DEMO]	2026-05-28 10:16:23.739189+00
347b485f-3aa0-4f90-b248-274e6b1fc226	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	\N	completada	2026-05-24 09:00:39.340257+00	2026-05-24 09:24:39.340257+00	2026-05-24 10:22:39.340257+00	[DEMO]	2026-05-27 16:16:23.739654+00
6a5affd8-03b6-4eb8-8971-2f022be4535a	6edc8fa1-5eda-43cf-9367-956889cec20d	\N	43958ec8-b358-4c41-bb4c-9b55cacfc8db	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	vencida	2026-05-28 16:14:47.006119+00	\N	\N	[DEMO]	2026-05-28 17:16:23.7401+00
154c0f57-0cc3-4f80-a0cf-7478a31669f3	5b40eaff-7355-40d7-8110-35e2a17262de	\N	\N	df0512cb-3963-4225-97dd-242b835a8118	\N	vencida	2026-05-28 09:17:10.62937+00	\N	\N	[DEMO]	2026-05-28 11:16:23.740613+00
f4699755-91f6-42ee-9cb3-b7dfc9d303a9	6edc8fa1-5eda-43cf-9367-956889cec20d	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	df0512cb-3963-4225-97dd-242b835a8118	\N	completada	2026-05-25 22:53:22.815126+00	2026-05-25 23:05:22.815126+00	2026-05-25 23:23:22.815126+00	[DEMO]	2026-05-27 20:16:23.741062+00
804a220c-1114-4f47-b6c3-4d6843e91dbc	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 17:06:50.297218+00	\N	\N	[DEMO]	2026-05-27 14:16:23.741566+00
96412ff3-666a-4bac-bd96-d0ffbd65646d	406456cd-724d-44c8-8fad-af6188aff749	\N	30b40a49-5e28-4ce5-acbb-df297a52e509	df0512cb-3963-4225-97dd-242b835a8118	\N	en_curso	2026-05-29 09:30:20.461031+00	2026-05-29 09:46:20.461031+00	\N	[DEMO]	2026-05-27 17:16:23.74212+00
bcbf8501-d085-4b32-8e1c-2956cdee8dcb	6edc8fa1-5eda-43cf-9367-956889cec20d	\N	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 14:57:44.975851+00	\N	\N	[DEMO]	2026-05-28 14:16:23.742593+00
687a2987-f45e-41e5-ac4c-b29b60427272	406456cd-724d-44c8-8fad-af6188aff749	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	df0512cb-3963-4225-97dd-242b835a8118	\N	pendiente	2026-05-29 19:26:04.826342+00	\N	\N	[DEMO]	2026-05-27 22:16:23.743058+00
3aa91032-17f8-4de5-a0ac-d7e6dd560988	6edc8fa1-5eda-43cf-9367-956889cec20d	\N	2d200ce2-5f48-4285-8d33-98f06db5b194	f102e952-9109-4668-a381-bc6693bc851b	\N	pendiente	2026-05-29 14:12:30.99567+00	\N	\N	[DEMO]	2026-05-28 05:16:23.743519+00
2b9fe9ae-40d7-403e-80b2-3455222bc486	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	2d200ce2-5f48-4285-8d33-98f06db5b194	df0512cb-3963-4225-97dd-242b835a8118	\N	pendiente	2026-05-29 16:45:21.740223+00	\N	\N	[DEMO]	2026-05-28 20:16:23.743956+00
dacd6e4a-c968-44d8-b39b-5a0efd342400	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	df0512cb-3963-4225-97dd-242b835a8118	\N	pendiente	2026-05-29 16:49:55.307637+00	\N	\N	[DEMO]	2026-05-28 10:16:23.744428+00
b3daaf69-b8c4-4ccf-93db-7a0e5218d5c0	5b40eaff-7355-40d7-8110-35e2a17262de	\N	c133cc24-f15a-4522-ad43-cc62e4a0283a	f102e952-9109-4668-a381-bc6693bc851b	\N	pendiente	2026-05-29 13:49:26.691716+00	\N	\N	[DEMO]	2026-05-28 05:16:23.745252+00
02c17f3b-8c84-44d5-92b7-300451633708	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	df0512cb-3963-4225-97dd-242b835a8118	\N	completada	2026-05-23 04:47:10.949166+00	2026-05-23 05:11:10.949166+00	2026-05-23 06:29:10.949166+00	[DEMO]	2026-05-28 15:16:23.74655+00
00f3fdbe-9301-4991-ae14-bc7ebe88f104	406456cd-724d-44c8-8fad-af6188aff749	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	\N	pendiente	2026-05-29 19:29:54.767037+00	\N	\N	[DEMO]	2026-05-28 01:16:23.747127+00
6b27b85e-eaf0-4981-858f-17063a82a20d	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	\N	df0512cb-3963-4225-97dd-242b835a8118	\N	completada	2026-05-24 22:37:38.249721+00	2026-05-24 22:43:38.249721+00	2026-05-25 00:02:38.249721+00	[DEMO]	2026-05-28 15:16:23.747614+00
e0277c35-e967-43ae-b8a3-b1f24823820e	5b40eaff-7355-40d7-8110-35e2a17262de	\N	513ad92d-a581-4d5b-b01e-7b3654f4482c	df0512cb-3963-4225-97dd-242b835a8118	\N	completada	2026-05-23 01:24:29.06867+00	2026-05-23 01:50:29.06867+00	2026-05-23 02:42:29.06867+00	[DEMO]	2026-05-28 12:16:23.74822+00
c4f60349-bf14-4768-9711-c804ddbd1c1e	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	\N	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	vencida	2026-05-27 13:24:37.521656+00	\N	\N	[DEMO]	2026-05-28 04:16:23.748919+00
9d80aa35-ceb3-4b23-9457-06e1111d249f	406456cd-724d-44c8-8fad-af6188aff749	\N	30b40a49-5e28-4ce5-acbb-df297a52e509	df0512cb-3963-4225-97dd-242b835a8118	\N	pendiente	2026-05-29 13:34:41.212871+00	\N	\N	[DEMO]	2026-05-27 17:16:23.749559+00
4cbc81d9-47e8-40bc-983b-93b5fd45057e	5b40eaff-7355-40d7-8110-35e2a17262de	\N	\N	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	completada	2026-05-23 21:55:13.745951+00	2026-05-23 22:02:13.745951+00	2026-05-23 23:16:13.745951+00	[DEMO]	2026-05-28 00:16:23.750159+00
19e28863-bf5d-4f51-b339-d3825277fc31	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	df0512cb-3963-4225-97dd-242b835a8118	\N	vencida	2026-05-28 11:48:04.63102+00	\N	\N	[DEMO]	2026-05-28 00:16:23.75062+00
c4531dec-9759-4537-b937-1873738fd85a	20e9c54c-9745-4047-b835-71d457136da9	\N	60da9a93-e0f2-403b-a534-e35383483df5	f102e952-9109-4668-a381-bc6693bc851b	\N	pendiente	2026-05-29 17:58:49.659459+00	\N	\N	[DEMO]	2026-05-27 13:16:23.751091+00
f4b6632b-3d91-4824-92f6-b0462416bef2	20e9c54c-9745-4047-b835-71d457136da9	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	df0512cb-3963-4225-97dd-242b835a8118	\N	cancelada	2026-05-26 19:49:34.619908+00	\N	\N	[DEMO]	2026-05-29 12:16:23.751532+00
2937df1f-e5d7-4367-a923-a0c1c8caf581	406456cd-724d-44c8-8fad-af6188aff749	\N	\N	3836de7c-0b6f-4306-904d-825890b6f534	\N	completada	2026-05-24 10:36:54.319475+00	2026-05-24 11:06:54.319475+00	2026-05-24 11:54:54.319475+00	[DEMO]	2026-05-28 17:16:23.751982+00
f986001a-0748-4a72-a9f3-386442a06cb4	20e9c54c-9745-4047-b835-71d457136da9	\N	30b40a49-5e28-4ce5-acbb-df297a52e509	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	vencida	2026-05-28 16:50:53.259223+00	\N	\N	[DEMO]	2026-05-28 14:16:23.752424+00
56ab3024-0d86-427c-8918-a3709af2d338	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	pendiente	2026-05-29 13:58:23.863999+00	\N	\N	[DEMO]	2026-05-29 07:16:23.752932+00
272a5103-f140-496e-988c-f3543a1885a7	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	en_curso	2026-05-29 09:39:01.586364+00	2026-05-29 09:51:01.586364+00	\N	[DEMO]	2026-05-29 06:16:23.753418+00
75ae49ca-56c5-4d08-a984-3feac957f1ab	20e9c54c-9745-4047-b835-71d457136da9	\N	60da9a93-e0f2-403b-a534-e35383483df5	3836de7c-0b6f-4306-904d-825890b6f534	\N	en_curso	2026-05-29 11:23:58.787363+00	2026-05-29 11:25:58.787363+00	\N	[DEMO]	2026-05-28 17:16:23.753947+00
047ceb5e-9432-40d4-8dfb-5126c0338e62	5b40eaff-7355-40d7-8110-35e2a17262de	\N	\N	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	completada	2026-05-23 14:44:04.494597+00	2026-05-23 15:13:04.494597+00	2026-05-23 15:48:04.494597+00	[DEMO]	2026-05-28 20:16:23.754727+00
da0f0822-7437-4ac3-863d-5dd98d040bef	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 20:15:16.811636+00	\N	\N	[DEMO]	2026-05-27 23:16:23.755579+00
f298d571-d389-4981-9928-e66ee4d6a92d	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	f102e952-9109-4668-a381-bc6693bc851b	\N	completada	2026-05-26 05:08:42.49382+00	2026-05-26 05:27:42.49382+00	2026-05-26 06:52:42.49382+00	[DEMO]	2026-05-29 09:16:23.756024+00
ca80eede-ade3-4072-81bc-ae1485cdb9af	406456cd-724d-44c8-8fad-af6188aff749	\N	\N	f102e952-9109-4668-a381-bc6693bc851b	\N	completada	2026-05-23 17:22:02.769148+00	2026-05-23 17:50:02.769148+00	2026-05-23 18:43:02.769148+00	[DEMO]	2026-05-27 23:16:23.75646+00
da5b587c-ff67-41a6-a9ef-dfb18eaff74c	406456cd-724d-44c8-8fad-af6188aff749	\N	513ad92d-a581-4d5b-b01e-7b3654f4482c	597ad6cc-663d-4eb8-8d08-286d22050b1d	\N	pendiente	2026-05-29 14:21:39.624761+00	\N	\N	[DEMO]	2026-05-29 12:17:39.624864+00
84dcb7df-0021-48f0-a696-38ee34b960ae	20e9c54c-9745-4047-b835-71d457136da9	\N	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	f102e952-9109-4668-a381-bc6693bc851b	\N	pendiente	2026-05-29 15:08:39.754025+00	\N	\N	[DEMO]	2026-05-29 12:18:39.7542+00
f86fc65b-75e1-415e-b2ef-9f1149d8baa3	5912a23c-e0ac-4624-834d-89e7bb80bb3d	\N	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	pendiente	2026-05-29 14:16:04.4866+00	\N	\N	[DEMO]	2026-05-29 12:26:04.486856+00
198b33d1-15f3-429e-8221-b9bd2f9965bb	20e9c54c-9745-4047-b835-71d457136da9	\N	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	pendiente	2026-05-29 15:08:44.56375+00	\N	\N	[DEMO]	2026-05-29 12:26:44.563908+00
3e7f5742-9914-44d2-8237-0cf9de595655	406456cd-724d-44c8-8fad-af6188aff749	\N	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	f102e952-9109-4668-a381-bc6693bc851b	\N	pendiente	2026-05-29 15:17:04.61225+00	\N	\N	[DEMO]	2026-05-29 12:27:04.612319+00
43325e97-dc86-4c6d-9b56-098918bac69f	6edc8fa1-5eda-43cf-9367-956889cec20d	\N	2d200ce2-5f48-4285-8d33-98f06db5b194	521c30a0-4751-4157-87d0-6aaf2c9c882d	\N	pendiente	2026-05-29 12:57:24.656502+00	\N	\N	[DEMO]	2026-05-29 12:27:24.656567+00
f1aba026-b7ac-4329-bf17-05304ecc65e3	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	7f75e608-6c5b-429b-a36f-a644cc41501b	3836de7c-0b6f-4306-904d-825890b6f534	\N	pendiente	2026-05-29 14:04:04.794044+00	\N	\N	[DEMO]	2026-05-29 12:28:04.79419+00
\.


--
-- Data for Name: tareas_recurrentes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tareas_recurrentes (id, catalogo_id, zona_id, maquinaria_id, frecuencia_expr, descripcion_frecuencia, activa, fecha_inicio, fecha_fin, notas) FROM stdin;
feee88bd-d5dd-42f5-a52e-1d9057c5fe28	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	\N	0 22 * * 1,4	Lunes y jueves a las 22:00	t	2026-05-27	\N	Lavado robots 1-2 (lun/jue)
45c7676c-62a3-4558-b30c-e113a4e520de	957b910c-6e8d-49a6-8e00-e4c10e4a3109	\N	\N	0 22 * * 2,5	Martes y viernes a las 22:00	t	2026-05-27	\N	Lavado robots 3 (mar/vie)
98049d00-6946-4d32-ba11-ca2a6d9067f0	980b1b32-82b4-4dd0-beb5-336b29489e5b	\N	\N	cada_N_dias:30	Cada 30 días	t	2026-05-27	\N	Desinfectante camas patio lactación
cdfc1971-5d0f-4424-9ed3-6d16aafd9a41	5b40eaff-7355-40d7-8110-35e2a17262de	\N	\N	0 10 * * 1,3,5	Lunes, miércoles y viernes a las 10:00	t	2026-05-27	\N	Bebederos L/X/V
\.


--
-- Data for Name: tratamientos_activos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tratamientos_activos (id, animal_id, evento_sanitario_id, farmaco, dosis, via_administracion, dias_tratamiento, fecha_inicio, fecha_fin_prevista, fecha_fin_real, activo, checkboxes, prescrito_por, notas) FROM stdin;
c63beadb-649c-49eb-ab8e-8fd80bc8aa2d	6b02089e-b0dc-40cf-a70c-a0fd1f9f407f	\N	Electrolitos rehidratación	5 dosis/día	oral	5	2026-05-27	2026-06-01	\N	t	[]	c319a64d-36f2-4c7b-a4e2-e61f08b36d28	[DEMO] tratamiento demo
9fc8d7a0-e7c2-4382-a0a3-37907be6a56a	2ecf6665-0c82-488d-9749-7941de974abf	\N	Oxitetraciclina 200mg/ml	1 dosis/día	IM	4	2026-05-27	2026-05-31	\N	t	[]	2d200ce2-5f48-4285-8d33-98f06db5b194	[DEMO] tratamiento demo
23621ecc-2cfc-4607-803f-97eb8dc937d7	80c0ec2f-41c9-43e4-a2db-11f0ba7c790d	\N	Propóleo tópico	1 dosis/día	topica	10	2026-05-28	2026-06-07	\N	t	[]	7f75e608-6c5b-429b-a36f-a644cc41501b	[DEMO] tratamiento demo
2b6475b8-f4b9-482d-ae1c-b67cb8b538cd	26d26b4b-30bb-4860-9c60-15c5ddcb244c	\N	Ketoprofeno 100mg/ml	1 dosis/día	IV	3	2026-05-27	2026-05-30	\N	t	[]	43958ec8-b358-4c41-bb4c-9b55cacfc8db	[DEMO] tratamiento demo
c258dc77-5840-4b08-9d86-58ada07175be	d153ced6-2a4b-4f8a-99ea-dbce009d2dd5	\N	Ketoprofeno 100mg/ml	1 dosis/día	IV	3	2026-05-29	2026-06-01	\N	t	[]	513ad92d-a581-4d5b-b01e-7b3654f4482c	[DEMO] tratamiento demo
318a9a79-a840-419a-8af2-98ab93f40fc5	3ee55362-8374-452c-ac80-5a93545bab2a	\N	Meloxicam 20mg/ml	1 dosis/día	IV	3	2026-05-28	2026-05-31	\N	t	[]	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	[DEMO] tratamiento demo
49fdd478-74b9-42a5-8f3f-9ec34fbec9f6	47503ce1-adab-4a8f-a942-bee77c0dabdc	\N	Cloxacilina 500mg	4 dosis/día	intramamaria	5	2026-05-28	2026-06-02	\N	t	[]	b87b4f5e-52af-4dfe-9c3b-e136d1dd7d37	[DEMO] tratamiento demo
dd9f6596-99af-4e94-b690-1faf4a46b5d8	f664da5c-e84f-4de3-abe2-954a07871fae	\N	Meloxicam 20mg/ml	4 dosis/día	IV	3	2026-05-17	2026-05-20	2026-05-20	f	[]	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	[DEMO] tratamiento demo
4e986562-45bc-4ef7-8b7d-f6570a4ceb05	14c6ccd8-8ebb-4b35-8ce1-ef5c37e223f5	\N	Oxitetraciclina 200mg/ml	2 dosis/día	IM	4	2026-04-06	2026-04-10	2026-04-11	f	[]	60da9a93-e0f2-403b-a534-e35383483df5	[DEMO] tratamiento demo
c281aefb-e3ef-4e06-91f5-57c1bee08afe	41098454-a4a4-45db-bc95-a2793218055b	\N	Propóleo tópico	4 dosis/día	topica	10	2026-04-14	2026-04-24	2026-04-24	f	[]	f0025158-31bd-47b3-b90a-3c3d08ed1dd8	[DEMO] tratamiento demo
e8e436b5-cbf7-4e05-9ef4-bc0c410b1b44	003a9fe9-e4a0-447f-bcdb-57439cd5e412	\N	Cloxacilina 500mg	3 dosis/día	intramamaria	5	2026-03-30	2026-04-04	2026-04-06	f	[]	bce871fe-c311-4bf1-a14f-ddf3b31b5f8f	[DEMO] tratamiento demo
2bd7e622-7d04-466b-8d94-deb16cd70f89	bca99578-d4de-422a-b04f-1ae3da4d3b43	\N	Propóleo tópico	2 dosis/día	topica	10	2026-04-07	2026-04-17	2026-04-17	f	[]	6e67bdeb-6e1e-490d-a29d-d69f6155ab99	[DEMO] tratamiento demo
\.


--
-- Data for Name: turnos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.turnos (id, fecha, tipo_turno, hora_inicio, hora_fin, notas) FROM stdin;
339bc962-3dc2-46a3-b6aa-470b4fe83215	2026-05-22	manana	06:00:00	14:00:00	[DEMO]
d345ccb9-ce5e-44d9-8884-3520023fecb0	2026-05-22	tarde	14:00:00	22:00:00	[DEMO]
acc685f4-6f01-4ddb-987c-7e23c56b956a	2026-05-23	manana	06:00:00	14:00:00	[DEMO]
b62b0f67-a981-4870-af04-34e1138ae507	2026-05-23	tarde	14:00:00	22:00:00	[DEMO]
e5631bcf-ed4d-49d4-a0f5-ffb8745975a5	2026-05-24	manana	06:00:00	14:00:00	[DEMO]
ba261344-97be-4f10-b39a-3d424d3f59df	2026-05-24	tarde	14:00:00	22:00:00	[DEMO]
b3d6328c-5b51-4f87-bff5-ec10552ebe8c	2026-05-25	manana	06:00:00	14:00:00	[DEMO]
00182ede-3684-45ab-b570-3d226b9a2d6c	2026-05-25	tarde	14:00:00	22:00:00	[DEMO]
0bb0b848-67ef-4789-9fd9-4524e693af73	2026-05-26	manana	06:00:00	14:00:00	[DEMO]
e0ab538b-bbe5-48c3-b1a1-7c3fadc7870b	2026-05-26	tarde	14:00:00	22:00:00	[DEMO]
e1d4f30f-08df-41e0-9982-9991d36321f1	2026-05-27	manana	06:00:00	14:00:00	[DEMO]
49718c23-1aa8-4a1a-91b0-3263ed7f904d	2026-05-27	tarde	14:00:00	22:00:00	[DEMO]
f223e2c1-5c23-4f07-8d13-675153f5b7f2	2026-05-28	manana	06:00:00	14:00:00	[DEMO]
0d11162c-254f-49c7-909f-404af1c286f4	2026-05-28	tarde	14:00:00	22:00:00	[DEMO]
6ff946f4-d102-4e1d-88d9-eac1dc7f7a03	2026-05-29	manana	06:00:00	14:00:00	[DEMO]
2aabfc2d-a7c8-4218-82e5-b74575d28885	2026-05-29	tarde	14:00:00	22:00:00	[DEMO]
57da959a-a8b9-4293-93a2-057f3c89f005	2026-05-30	manana	06:00:00	14:00:00	[DEMO]
978b6bce-96a6-4f06-8513-2911f6a1a13f	2026-05-30	tarde	14:00:00	22:00:00	[DEMO]
a4703e6b-3940-4c8d-bc5d-816ee35d596a	2026-05-31	manana	06:00:00	14:00:00	[DEMO]
88654be7-71da-4fff-b8a3-a16b94575fe7	2026-05-31	tarde	14:00:00	22:00:00	[DEMO]
62d452a6-1bde-4a64-a18d-75361fbf8adb	2026-06-01	manana	06:00:00	14:00:00	[DEMO]
74b836ff-a22f-4a9b-8f8b-6e11fb945544	2026-06-01	tarde	14:00:00	22:00:00	[DEMO]
194ee587-a195-4706-a7a0-58b9306fef0e	2026-06-02	manana	06:00:00	14:00:00	[DEMO]
85381953-f4cc-4664-8682-e448ca14b414	2026-06-02	tarde	14:00:00	22:00:00	[DEMO]
29101baf-3a7f-404e-8e7e-1bbf6c6cbcbd	2026-06-03	manana	06:00:00	14:00:00	[DEMO]
fb0b42ad-ca20-4a77-af02-ceb711e255df	2026-06-03	tarde	14:00:00	22:00:00	[DEMO]
497df18c-6b71-4e0f-a0ab-faa911c97c1b	2026-06-04	manana	06:00:00	14:00:00	[DEMO]
7ebf78b1-ca69-4552-9e5c-b02a20611819	2026-06-04	tarde	14:00:00	22:00:00	[DEMO]
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, username, email, hashed_password, role, activo, debe_cambiar_contrasena, fecha_creacion) FROM stdin;
306aa1a8-7593-41a9-ba2f-4084251895bf	admin	admin@tools4milk.local	$2b$12$/5m68gsLq7iQlH9hsHBo9Ot6w5danPqXGWkPYUPaO/FjPS0Rl.wR.	admin	t	f	2026-05-27 21:44:47.509398
edc6c690-f21b-4ef4-90da-9e3926b820c4	roberto.castro	roberto.castro@tools4milk.local	$2b$12$YS8laTEd22wLYg4sf/NSl.ZvhX.LlcXOSofvhrH11P2JIaH.D2akK	admin	t	f	2026-05-27 21:44:47.768494
68359e91-66ed-4d4e-bc49-a149dca1aad8	operario.zona	operario.zona@tools4milk.local	$2b$12$evt4p2Z72GShackunPLWUuZr.rJdJyQodiEZAMoDU2f.qVnID78DC	operario	t	f	2026-05-27 21:44:48.013052
ff3fb5ef-a806-44ef-a9eb-d4404afc8df7	laura.fernandez	laura.fernandez@tools4milk.local	$2b$12$VsItpi76aFrxS9hUce23tuNGkWrt3Rb15iq4fwyVT/Q/4jUyoIoMi	alimentacion	t	f	2026-05-27 21:44:48.261539
c0769e24-488b-46bb-a41d-4aabb111502e	dr.mendez	dr.mendez@tools4milk.local	$2b$12$V9l7esQ/syFOKlmXBvoPq.tyuAwGiFCrshJODt7HIH0241cmsg1FS	veterinario	t	f	2026-05-27 21:44:48.528809
\.


--
-- Data for Name: zonas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zonas (id, nombre, codigo, descripcion, tiene_pantalla_tv, tiene_tablet) FROM stdin;
df0512cb-3963-4225-97dd-242b835a8118	Nave	sala_ordeno	Sala de ordeño robótico VMS	t	t
521c30a0-4751-4157-87d0-6aaf2c9c882d	Becerrero	becerrero	Cría de terneros y becerros	t	t
3836de7c-0b6f-4306-904d-825890b6f534	Enfermería	enfermeria	Animales enfermos y en tratamiento	t	t
597ad6cc-663d-4eb8-8d08-286d22050b1d	Oficina	oficina	Gestión administrativa y técnica	t	t
f102e952-9109-4668-a381-bc6693bc851b	General	general	Área general sin pantalla asignada	f	f
\.


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 182, true);


--
-- Name: datos_metereologicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datos_metereologicos_id_seq', 1, false);


--
-- Name: alertas alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (id);


--
-- Name: alertas_umbrales alertas_umbrales_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas_umbrales
    ADD CONSTRAINT alertas_umbrales_codigo_key UNIQUE (codigo);


--
-- Name: alertas_umbrales alertas_umbrales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas_umbrales
    ADD CONSTRAINT alertas_umbrales_pkey PRIMARY KEY (id);


--
-- Name: animales animales_crotal_oficial_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.animales
    ADD CONSTRAINT animales_crotal_oficial_key UNIQUE (crotal_oficial);


--
-- Name: animales animales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.animales
    ADD CONSTRAINT animales_pkey PRIMARY KEY (id);


--
-- Name: asignaciones_turno asignaciones_turno_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_pkey PRIMARY KEY (id);


--
-- Name: asignaciones_turno asignaciones_turno_turno_id_empleado_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_turno_id_empleado_id_key UNIQUE (turno_id, empleado_id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: boxes_recria boxes_recria_box_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boxes_recria
    ADD CONSTRAINT boxes_recria_box_numero_key UNIQUE (box_numero);


--
-- Name: boxes_recria boxes_recria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boxes_recria
    ADD CONSTRAINT boxes_recria_pkey PRIMARY KEY (id);


--
-- Name: core_alerts core_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_alerts
    ADD CONSTRAINT core_alerts_pkey PRIMARY KEY (id);


--
-- Name: core_animals core_animals_crotal_oficial_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_animals
    ADD CONSTRAINT core_animals_crotal_oficial_key UNIQUE (crotal_oficial);


--
-- Name: core_animals core_animals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_animals
    ADD CONSTRAINT core_animals_pkey PRIMARY KEY (id);


--
-- Name: core_employees core_employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_employees
    ADD CONSTRAINT core_employees_pkey PRIMARY KEY (id);


--
-- Name: core_incidents core_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_incidents
    ADD CONSTRAINT core_incidents_pkey PRIMARY KEY (id);


--
-- Name: core_lactations core_lactations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_lactations
    ADD CONSTRAINT core_lactations_pkey PRIMARY KEY (id);


--
-- Name: core_machinery core_machinery_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_machinery
    ADD CONSTRAINT core_machinery_pkey PRIMARY KEY (id);


--
-- Name: core_tasks core_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_tasks
    ADD CONSTRAINT core_tasks_pkey PRIMARY KEY (id);


--
-- Name: core_treatments core_treatments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_treatments
    ADD CONSTRAINT core_treatments_pkey PRIMARY KEY (id);


--
-- Name: core_zones core_zones_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_zones
    ADD CONSTRAINT core_zones_codigo_key UNIQUE (codigo);


--
-- Name: core_zones core_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.core_zones
    ADD CONSTRAINT core_zones_pkey PRIMARY KEY (id);


--
-- Name: datos_metereologicos datos_metereologicos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datos_metereologicos
    ADD CONSTRAINT datos_metereologicos_pkey PRIMARY KEY (id);


--
-- Name: empleados empleados_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleados
    ADD CONSTRAINT empleados_pkey PRIMARY KEY (id);


--
-- Name: eventos_reproductivos eventos_reproductivos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_reproductivos
    ADD CONSTRAINT eventos_reproductivos_pkey PRIMARY KEY (id);


--
-- Name: eventos_sanitarios eventos_sanitarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_sanitarios
    ADD CONSTRAINT eventos_sanitarios_pkey PRIMARY KEY (id);


--
-- Name: eventos_sanitarios_recria eventos_sanitarios_recria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_sanitarios_recria
    ADD CONSTRAINT eventos_sanitarios_recria_pkey PRIMARY KEY (id);


--
-- Name: genomica genomica_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genomica
    ADD CONSTRAINT genomica_pkey PRIMARY KEY (id);


--
-- Name: incidencias incidencias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_pkey PRIMARY KEY (id);


--
-- Name: lactaciones lactaciones_animal_id_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lactaciones
    ADD CONSTRAINT lactaciones_animal_id_numero_key UNIQUE (animal_id, numero);


--
-- Name: lactaciones lactaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lactaciones
    ADD CONSTRAINT lactaciones_pkey PRIMARY KEY (id);


--
-- Name: lecturas_carro_mezclador lecturas_carro_mezclador_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lecturas_carro_mezclador
    ADD CONSTRAINT lecturas_carro_mezclador_pkey PRIMARY KEY (ts, mezcla_id, ingrediente);


--
-- Name: lecturas_meteorologia lecturas_meteorologia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lecturas_meteorologia
    ADD CONSTRAINT lecturas_meteorologia_pkey PRIMARY KEY (ts, estacion_id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_pkey PRIMARY KEY (ts, robot_id);


--
-- Name: maquinaria maquinaria_numero_serie_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maquinaria
    ADD CONSTRAINT maquinaria_numero_serie_key UNIQUE (numero_serie);


--
-- Name: maquinaria maquinaria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maquinaria
    ADD CONSTRAINT maquinaria_pkey PRIMARY KEY (id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- Name: resumenes_relevo resumenes_relevo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tareas_catalogo tareas_catalogo_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_catalogo
    ADD CONSTRAINT tareas_catalogo_codigo_key UNIQUE (codigo);


--
-- Name: tareas_catalogo tareas_catalogo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_catalogo
    ADD CONSTRAINT tareas_catalogo_pkey PRIMARY KEY (id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_pkey PRIMARY KEY (id);


--
-- Name: tareas_recurrentes tareas_recurrentes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_pkey PRIMARY KEY (id);


--
-- Name: tratamientos_activos tratamientos_activos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_pkey PRIMARY KEY (id);


--
-- Name: turnos turnos_fecha_tipo_turno_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_fecha_tipo_turno_key UNIQUE (fecha, tipo_turno);


--
-- Name: turnos turnos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.turnos
    ADD CONSTRAINT turnos_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_username_key UNIQUE (username);


--
-- Name: zonas zonas_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_codigo_key UNIQUE (codigo);


--
-- Name: zonas zonas_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_nombre_key UNIQUE (nombre);


--
-- Name: zonas zonas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zonas
    ADD CONSTRAINT zonas_pkey PRIMARY KEY (id);


--
-- Name: idx_alertas_activas; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alertas_activas ON public.alertas USING btree (activa, ts_generacion DESC) WHERE (activa = true);


--
-- Name: idx_alertas_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alertas_animal ON public.alertas USING btree (animal_id) WHERE (animal_id IS NOT NULL);


--
-- Name: idx_alertas_nivel; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alertas_nivel ON public.alertas USING btree (nivel);


--
-- Name: idx_animales_crotal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_animales_crotal ON public.animales USING btree (crotal_oficial);


--
-- Name: idx_animales_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_animales_estado ON public.animales USING btree (estado);


--
-- Name: idx_animales_estado_repro; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_animales_estado_repro ON public.animales USING btree (estado_reproductivo);


--
-- Name: idx_animales_madre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_animales_madre ON public.animales USING btree (madre_id);


--
-- Name: idx_audit_registro; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_registro ON public.audit_log USING btree (registro_id);


--
-- Name: idx_audit_tabla; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_tabla ON public.audit_log USING btree (tabla_afectada, ts DESC);


--
-- Name: idx_audit_ts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_ts ON public.audit_log USING btree (ts DESC);


--
-- Name: idx_boxes_alertas; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_boxes_alertas ON public.boxes_recria USING gin (alertas_box);


--
-- Name: idx_boxes_ternero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_boxes_ternero ON public.boxes_recria USING btree (ternero_id) WHERE (ternero_id IS NOT NULL);


--
-- Name: idx_carro_mezcla; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_carro_mezcla ON public.lecturas_carro_mezclador USING btree (mezcla_id, ts DESC);


--
-- Name: idx_ejecuciones_empleado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ejecuciones_empleado ON public.tareas_ejecuciones USING btree (empleado_id);


--
-- Name: idx_ejecuciones_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ejecuciones_estado ON public.tareas_ejecuciones USING btree (estado);


--
-- Name: idx_ejecuciones_planificada; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ejecuciones_planificada ON public.tareas_ejecuciones USING btree (ts_planificada);


--
-- Name: idx_ejecuciones_zona; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ejecuciones_zona ON public.tareas_ejecuciones USING btree (zona_id);


--
-- Name: idx_ev_recria_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_recria_animal ON public.eventos_sanitarios_recria USING btree (animal_id);


--
-- Name: idx_ev_recria_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_recria_fecha ON public.eventos_sanitarios_recria USING btree (fecha DESC);


--
-- Name: idx_ev_repro_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_repro_animal ON public.eventos_reproductivos USING btree (animal_id);


--
-- Name: idx_ev_repro_det; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_repro_det ON public.eventos_reproductivos USING gin (detalles);


--
-- Name: idx_ev_repro_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_repro_fecha ON public.eventos_reproductivos USING btree (fecha DESC);


--
-- Name: idx_ev_repro_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_repro_tipo ON public.eventos_reproductivos USING btree (tipo);


--
-- Name: idx_ev_sanitarios_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_sanitarios_animal ON public.eventos_sanitarios USING btree (animal_id);


--
-- Name: idx_ev_sanitarios_retirada; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_sanitarios_retirada ON public.eventos_sanitarios USING btree (periodo_retirada_hasta) WHERE (periodo_retirada_hasta IS NOT NULL);


--
-- Name: idx_ev_sanitarios_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ev_sanitarios_tipo ON public.eventos_sanitarios USING btree (tipo_patologia);


--
-- Name: idx_genomica_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_genomica_animal ON public.genomica USING btree (animal_id);


--
-- Name: idx_incidencias_acciones; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incidencias_acciones ON public.incidencias USING gin (acciones);


--
-- Name: idx_incidencias_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incidencias_animal ON public.incidencias USING btree (animal_id);


--
-- Name: idx_incidencias_apertura; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incidencias_apertura ON public.incidencias USING btree (ts_apertura DESC);


--
-- Name: idx_incidencias_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incidencias_estado ON public.incidencias USING btree (estado);


--
-- Name: idx_incidencias_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incidencias_tipo ON public.incidencias USING btree (tipo);


--
-- Name: idx_incidencias_zona; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incidencias_zona ON public.incidencias USING btree (zona_id);


--
-- Name: idx_lactaciones_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lactaciones_animal ON public.lactaciones USING btree (animal_id);


--
-- Name: idx_lactaciones_parto; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lactaciones_parto ON public.lactaciones USING btree (fecha_parto DESC);


--
-- Name: idx_pedidos_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_estado ON public.pedidos USING btree (estado);


--
-- Name: idx_pedidos_ts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_ts ON public.pedidos USING btree (ts_solicitud DESC);


--
-- Name: idx_robot_ordeno_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_robot_ordeno_animal ON public.lecturas_robot_ordeno USING btree (animal_id, ts DESC);


--
-- Name: idx_robot_ordeno_robot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_robot_ordeno_robot ON public.lecturas_robot_ordeno USING btree (robot_id, ts DESC);


--
-- Name: idx_tratamientos_activos; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tratamientos_activos ON public.tratamientos_activos USING btree (activo) WHERE (activo = true);


--
-- Name: idx_tratamientos_animal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tratamientos_animal ON public.tratamientos_activos USING btree (animal_id);


--
-- Name: ix_core_alerts_animal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_alerts_animal_id ON public.core_alerts USING btree (animal_id);


--
-- Name: ix_core_alerts_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_alerts_estado ON public.core_alerts USING btree (estado);


--
-- Name: ix_core_alerts_severidad; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_alerts_severidad ON public.core_alerts USING btree (severidad);


--
-- Name: ix_core_animals_crotal_oficial; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_animals_crotal_oficial ON public.core_animals USING btree (crotal_oficial);


--
-- Name: ix_core_animals_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_animals_estado ON public.core_animals USING btree (estado);


--
-- Name: ix_core_employees_activo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_employees_activo ON public.core_employees USING btree (activo);


--
-- Name: ix_core_incidents_animal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_incidents_animal_id ON public.core_incidents USING btree (animal_id);


--
-- Name: ix_core_incidents_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_incidents_estado ON public.core_incidents USING btree (estado);


--
-- Name: ix_core_incidents_prioridad; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_incidents_prioridad ON public.core_incidents USING btree (prioridad);


--
-- Name: ix_core_incidents_zona_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_incidents_zona_id ON public.core_incidents USING btree (zona_id);


--
-- Name: ix_core_lactations_animal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_lactations_animal_id ON public.core_lactations USING btree (animal_id);


--
-- Name: ix_core_machinery_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_machinery_estado ON public.core_machinery USING btree (estado);


--
-- Name: ix_core_tasks_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_tasks_estado ON public.core_tasks USING btree (estado);


--
-- Name: ix_core_tasks_zona_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_tasks_zona_id ON public.core_tasks USING btree (zona_id);


--
-- Name: ix_core_treatments_activo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_treatments_activo ON public.core_treatments USING btree (activo);


--
-- Name: ix_core_treatments_animal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_core_treatments_animal_id ON public.core_treatments USING btree (animal_id);


--
-- Name: ix_usuarios_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_usuarios_email ON public.usuarios USING btree (email);


--
-- Name: ix_usuarios_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_usuarios_role ON public.usuarios USING btree (role);


--
-- Name: ix_usuarios_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_usuarios_username ON public.usuarios USING btree (username);


--
-- Name: animales trg_audit_animales; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_animales AFTER INSERT OR DELETE OR UPDATE ON public.animales FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: eventos_sanitarios trg_audit_eventos_sanitarios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_eventos_sanitarios AFTER INSERT OR DELETE OR UPDATE ON public.eventos_sanitarios FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: incidencias trg_audit_incidencias; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_incidencias AFTER INSERT OR DELETE OR UPDATE ON public.incidencias FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: pedidos trg_audit_pedidos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_pedidos AFTER INSERT OR DELETE OR UPDATE ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: tratamientos_activos trg_audit_tratamientos_activos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_audit_tratamientos_activos AFTER INSERT OR DELETE OR UPDATE ON public.tratamientos_activos FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();


--
-- Name: alertas alertas_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: alertas alertas_resuelta_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_resuelta_por_fkey FOREIGN KEY (resuelta_por) REFERENCES public.empleados(id);


--
-- Name: alertas alertas_umbral_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_umbral_id_fkey FOREIGN KEY (umbral_id) REFERENCES public.alertas_umbrales(id);


--
-- Name: alertas alertas_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: animales animales_madre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.animales
    ADD CONSTRAINT animales_madre_id_fkey FOREIGN KEY (madre_id) REFERENCES public.animales(id);


--
-- Name: asignaciones_turno asignaciones_turno_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: asignaciones_turno asignaciones_turno_turno_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_turno_id_fkey FOREIGN KEY (turno_id) REFERENCES public.turnos(id) ON DELETE CASCADE;


--
-- Name: asignaciones_turno asignaciones_turno_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asignaciones_turno
    ADD CONSTRAINT asignaciones_turno_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: boxes_recria boxes_recria_ternero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boxes_recria
    ADD CONSTRAINT boxes_recria_ternero_id_fkey FOREIGN KEY (ternero_id) REFERENCES public.animales(id);


--
-- Name: eventos_reproductivos eventos_reproductivos_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_reproductivos
    ADD CONSTRAINT eventos_reproductivos_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: eventos_reproductivos eventos_reproductivos_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_reproductivos
    ADD CONSTRAINT eventos_reproductivos_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: eventos_sanitarios eventos_sanitarios_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_sanitarios
    ADD CONSTRAINT eventos_sanitarios_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: eventos_sanitarios_recria eventos_sanitarios_recria_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_sanitarios_recria
    ADD CONSTRAINT eventos_sanitarios_recria_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: eventos_sanitarios_recria eventos_sanitarios_recria_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_sanitarios_recria
    ADD CONSTRAINT eventos_sanitarios_recria_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: eventos_sanitarios eventos_sanitarios_veterinario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.eventos_sanitarios
    ADD CONSTRAINT eventos_sanitarios_veterinario_id_fkey FOREIGN KEY (veterinario_id) REFERENCES public.empleados(id);


--
-- Name: incidencias fk_incidencias_animal; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT fk_incidencias_animal FOREIGN KEY (animal_id) REFERENCES public.animales(id) ON DELETE SET NULL;


--
-- Name: genomica genomica_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genomica
    ADD CONSTRAINT genomica_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: incidencias incidencias_asignado_a_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_asignado_a_fkey FOREIGN KEY (asignado_a) REFERENCES public.empleados(id);


--
-- Name: incidencias incidencias_maquinaria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_maquinaria_id_fkey FOREIGN KEY (maquinaria_id) REFERENCES public.maquinaria(id);


--
-- Name: incidencias incidencias_reportado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_reportado_por_fkey FOREIGN KEY (reportado_por) REFERENCES public.empleados(id);


--
-- Name: incidencias incidencias_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incidencias
    ADD CONSTRAINT incidencias_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: lactaciones lactaciones_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lactaciones
    ADD CONSTRAINT lactaciones_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: lecturas_carro_mezclador lecturas_carro_mezclador_operario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lecturas_carro_mezclador
    ADD CONSTRAINT lecturas_carro_mezclador_operario_id_fkey FOREIGN KEY (operario_id) REFERENCES public.empleados(id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_lactacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_lactacion_id_fkey FOREIGN KEY (lactacion_id) REFERENCES public.lactaciones(id);


--
-- Name: lecturas_robot_ordeno lecturas_robot_ordeno_robot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lecturas_robot_ordeno
    ADD CONSTRAINT lecturas_robot_ordeno_robot_id_fkey FOREIGN KEY (robot_id) REFERENCES public.maquinaria(id);


--
-- Name: maquinaria maquinaria_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.maquinaria
    ADD CONSTRAINT maquinaria_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id) ON DELETE SET NULL;


--
-- Name: pedidos pedidos_solicitante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_solicitante_id_fkey FOREIGN KEY (solicitante_id) REFERENCES public.empleados(id);


--
-- Name: resumenes_relevo resumenes_relevo_confirmado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_confirmado_por_fkey FOREIGN KEY (confirmado_por) REFERENCES public.empleados(id);


--
-- Name: resumenes_relevo resumenes_relevo_turno_entrante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_turno_entrante_id_fkey FOREIGN KEY (turno_entrante_id) REFERENCES public.turnos(id);


--
-- Name: resumenes_relevo resumenes_relevo_turno_saliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resumenes_relevo
    ADD CONSTRAINT resumenes_relevo_turno_saliente_id_fkey FOREIGN KEY (turno_saliente_id) REFERENCES public.turnos(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_catalogo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_catalogo_id_fkey FOREIGN KEY (catalogo_id) REFERENCES public.tareas_catalogo(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.empleados(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_maquinaria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_maquinaria_id_fkey FOREIGN KEY (maquinaria_id) REFERENCES public.maquinaria(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_recurrente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_recurrente_id_fkey FOREIGN KEY (recurrente_id) REFERENCES public.tareas_recurrentes(id);


--
-- Name: tareas_ejecuciones tareas_ejecuciones_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_ejecuciones
    ADD CONSTRAINT tareas_ejecuciones_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: tareas_recurrentes tareas_recurrentes_catalogo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_catalogo_id_fkey FOREIGN KEY (catalogo_id) REFERENCES public.tareas_catalogo(id);


--
-- Name: tareas_recurrentes tareas_recurrentes_maquinaria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_maquinaria_id_fkey FOREIGN KEY (maquinaria_id) REFERENCES public.maquinaria(id);


--
-- Name: tareas_recurrentes tareas_recurrentes_zona_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tareas_recurrentes
    ADD CONSTRAINT tareas_recurrentes_zona_id_fkey FOREIGN KEY (zona_id) REFERENCES public.zonas(id);


--
-- Name: tratamientos_activos tratamientos_activos_animal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_animal_id_fkey FOREIGN KEY (animal_id) REFERENCES public.animales(id);


--
-- Name: tratamientos_activos tratamientos_activos_evento_sanitario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_evento_sanitario_id_fkey FOREIGN KEY (evento_sanitario_id) REFERENCES public.eventos_sanitarios(id);


--
-- Name: tratamientos_activos tratamientos_activos_prescrito_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tratamientos_activos
    ADD CONSTRAINT tratamientos_activos_prescrito_por_fkey FOREIGN KEY (prescrito_por) REFERENCES public.empleados(id);


--
-- PostgreSQL database dump complete
--

\unrestrict WybNZwSmdesk8SzSweOHIBmipVqaodA7G36cEKykoGwDpw1X2UyVXhYI1lQvog7

