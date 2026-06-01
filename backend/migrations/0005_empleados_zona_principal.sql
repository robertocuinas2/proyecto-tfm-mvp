-- Migración: añadir zona_principal_id a tabla empleados
-- Permite asignar zona habitual a cada empleado para compatibilidad en LeanFarming
-- PostgreSQL 9.6+ soporta ADD COLUMN IF NOT EXISTS de forma nativa
ALTER TABLE empleados ADD COLUMN IF NOT EXISTS zona_principal_id UUID REFERENCES zonas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS ix_empleados_zona_principal_id ON empleados(zona_principal_id);
