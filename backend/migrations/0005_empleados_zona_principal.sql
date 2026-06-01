-- Migración para añadir zona_principal_id a empleados
-- Permite asignar una zona principal a cada empleado para compatibilidad en LeanFarming

-- Crear tabla empleados si no existe
CREATE TABLE IF NOT EXISTS empleados (
    id UUID PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellidos VARCHAR(150) NOT NULL,
    rol VARCHAR(40) NOT NULL,
    cualificaciones TEXT,
    telefono VARCHAR(20),
    email VARCHAR(150),
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    fecha_alta DATE NOT NULL,
    fecha_baja DATE
);

-- Añadir columna zona_principal_id si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'empleados'
        AND column_name = 'zona_principal_id'
    ) THEN
        ALTER TABLE empleados
        ADD COLUMN zona_principal_id UUID REFERENCES zonas(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Crear índice para búsquedas frecuentes por zona principal
CREATE INDEX IF NOT EXISTS ix_empleados_zona_principal_id ON empleados(zona_principal_id);
