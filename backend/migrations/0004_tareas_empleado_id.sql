-- Migración segura para añadir columna empleado_id a tareas_ejecuciones
-- Permite la asignación de tareas a empleados en el módulo LeanFarming

-- Verificar si la tabla existe
CREATE TABLE IF NOT EXISTS tareas_ejecuciones (
    id UUID PRIMARY KEY,
    catalogo_id UUID NOT NULL,
    recurrente_id UUID,
    zona_id UUID,
    maquinaria_id UUID,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    ts_planificada TIMESTAMP WITH TIME ZONE NOT NULL,
    ts_inicio TIMESTAMP WITH TIME ZONE,
    ts_fin TIMESTAMP WITH TIME ZONE,
    notas TEXT,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Añadir columna empleado_id si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'tareas_ejecuciones'
        AND column_name = 'empleado_id'
    ) THEN
        ALTER TABLE tareas_ejecuciones
        ADD COLUMN empleado_id UUID REFERENCES empleados(id);
    END IF;
END $$;

-- Crear índice para búsquedas frecuentes por empleado
CREATE INDEX IF NOT EXISTS ix_tareas_ejecuciones_empleado_id ON tareas_ejecuciones(empleado_id);
