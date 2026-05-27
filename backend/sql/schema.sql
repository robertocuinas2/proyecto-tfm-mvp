CREATE TABLE IF NOT EXISTS core_animals (
    id VARCHAR(80) PRIMARY KEY,
    crotal_oficial VARCHAR(80) UNIQUE NOT NULL,
    nombre VARCHAR(120),
    sexo VARCHAR(40) NOT NULL,
    fecha_nacimiento VARCHAR(20) NOT NULL,
    raza VARCHAR(80),
    estado VARCHAR(40) NOT NULL,
    estado_reproductivo VARCHAR(80),
    fecha_entrada VARCHAR(20) NOT NULL,
    fecha_baja VARCHAR(20),
    motivo_baja VARCHAR(255),
    notas TEXT
);

CREATE INDEX IF NOT EXISTS ix_core_animals_estado ON core_animals (estado);
CREATE INDEX IF NOT EXISTS ix_core_animals_crotal ON core_animals (crotal_oficial);

CREATE TABLE IF NOT EXISTS core_zones (
    id VARCHAR(80) PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    tipo VARCHAR(80),
    tiene_pantalla_tv BOOLEAN NOT NULL DEFAULT TRUE,
    tiene_tablet BOOLEAN NOT NULL DEFAULT TRUE,
    activa BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core_tasks (
    id VARCHAR(80) PRIMARY KEY,
    tarea_catalogo_id VARCHAR(80) NOT NULL,
    tarea_catalogo JSONB,
    zona_id VARCHAR(80),
    fecha_programada TIMESTAMPTZ NOT NULL,
    fecha_ejecucion TIMESTAMPTZ,
    estado VARCHAR(40) NOT NULL,
    ejecutado_por VARCHAR(120),
    tiempo_ejecucion_minutos VARCHAR(40),
    resultado VARCHAR(120),
    observaciones TEXT,
    problemas_encontrados TEXT,
    acciones_correctivas TEXT,
    checklist_completado VARCHAR(10) NOT NULL DEFAULT 'false',
    checklist_datos TEXT,
    es_urgente BOOLEAN NOT NULL DEFAULT FALSE,
    motivo_retraso TEXT,
    requiere_seguimiento BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_seguimiento TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_core_tasks_estado ON core_tasks (estado);
CREATE INDEX IF NOT EXISTS ix_core_tasks_zona ON core_tasks (zona_id);
CREATE INDEX IF NOT EXISTS ix_core_tasks_fecha ON core_tasks (fecha_programada);

CREATE TABLE IF NOT EXISTS core_alerts (
    id VARCHAR(80) PRIMARY KEY,
    animal_id VARCHAR(80) NOT NULL,
    tipo_alerta VARCHAR(120) NOT NULL,
    severidad VARCHAR(40) NOT NULL,
    descripcion TEXT NOT NULL,
    recomendacion TEXT,
    estado VARCHAR(40) NOT NULL DEFAULT 'pendiente',
    confianza_prediccion DOUBLE PRECISION,
    requiere_escalacion BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion TIMESTAMPTZ NOT NULL,
    fecha_revision TIMESTAMPTZ,
    revisada BOOLEAN NOT NULL DEFAULT FALSE,
    notas_operario TEXT,
    accion_tomada TEXT,
    veterinario_responsable VARCHAR(120)
);

CREATE INDEX IF NOT EXISTS ix_core_alerts_animal ON core_alerts (animal_id);
CREATE INDEX IF NOT EXISTS ix_core_alerts_estado ON core_alerts (estado);
CREATE INDEX IF NOT EXISTS ix_core_alerts_severidad ON core_alerts (severidad);

CREATE TABLE IF NOT EXISTS core_incidents (
    id VARCHAR(80) PRIMARY KEY,
    tipo VARCHAR(120) NOT NULL,
    zona_id VARCHAR(80),
    animal_id VARCHAR(80),
    descripcion TEXT NOT NULL,
    prioridad VARCHAR(40) NOT NULL,
    estado VARCHAR(40) NOT NULL DEFAULT 'abierta',
    fecha_creacion TIMESTAMPTZ NOT NULL,
    fecha_resolucion TIMESTAMPTZ,
    resolucion TEXT,
    reportado_por VARCHAR(120)
);

CREATE INDEX IF NOT EXISTS ix_core_incidents_zona ON core_incidents (zona_id);
CREATE INDEX IF NOT EXISTS ix_core_incidents_animal ON core_incidents (animal_id);
CREATE INDEX IF NOT EXISTS ix_core_incidents_estado ON core_incidents (estado);

CREATE TABLE IF NOT EXISTS core_lactations (
    id VARCHAR(80) PRIMARY KEY,
    animal_id VARCHAR(80) NOT NULL,
    numero_lactacion INTEGER,
    fecha_inicio VARCHAR(20),
    fecha_fin VARCHAR(20),
    dias_transcurridos INTEGER,
    produccion_promedio DOUBLE PRECISION,
    produccion_total DOUBLE PRECISION,
    grasa_promedio DOUBLE PRECISION,
    proteina_promedio DOUBLE PRECISION,
    rcs_promedio DOUBLE PRECISION,
    activa BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS ix_core_lactations_animal ON core_lactations (animal_id);

CREATE TABLE IF NOT EXISTS core_treatments (
    id VARCHAR(80) PRIMARY KEY,
    animal_id VARCHAR(80) NOT NULL,
    medicamento VARCHAR(160),
    dosis VARCHAR(120),
    via_administracion VARCHAR(80),
    fecha_inicio VARCHAR(20) NOT NULL,
    fecha_fin VARCHAR(20),
    periodo_retirada_dias INTEGER,
    fecha_fin_retirada VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    motivo TEXT,
    veterinario VARCHAR(120),
    observaciones TEXT
);

CREATE INDEX IF NOT EXISTS ix_core_treatments_animal ON core_treatments (animal_id);
CREATE INDEX IF NOT EXISTS ix_core_treatments_activo ON core_treatments (activo);

CREATE TABLE IF NOT EXISTS core_employees (
    id VARCHAR(80) PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    apellidos VARCHAR(160),
    role VARCHAR(80),
    zona_principal_id VARCHAR(80),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS ix_core_employees_activo ON core_employees (activo);

CREATE TABLE IF NOT EXISTS core_machinery (
    id VARCHAR(80) PRIMARY KEY,
    nombre VARCHAR(160) NOT NULL,
    tipo VARCHAR(80) NOT NULL,
    zona_id VARCHAR(80),
    estado VARCHAR(80) NOT NULL DEFAULT 'operativa',
    proxima_revision VARCHAR(20),
    observaciones TEXT
);

CREATE INDEX IF NOT EXISTS ix_core_machinery_estado ON core_machinery (estado);
