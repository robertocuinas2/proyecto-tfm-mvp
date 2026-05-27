INSERT INTO core_zones (id, nombre, codigo, descripcion, tipo, tiene_pantalla_tv, tiene_tablet, activa)
VALUES
    ('ordeno', 'Sala de ordeno', 'ORD', 'Produccion, calidad de leche y tanque.', 'produccion', TRUE, TRUE, TRUE),
    ('paridera', 'Paridera', 'PAR', 'Partos, preparto y atencion neonatal.', 'cuidados', TRUE, TRUE, TRUE),
    ('recria', 'Recria', 'REC', 'Terneras, crecimiento y salud de recria.', 'crecimiento', TRUE, TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO core_lactations (
    id, animal_id, numero_lactacion, fecha_inicio, fecha_fin,
    dias_transcurridos, produccion_promedio, produccion_total,
    grasa_promedio, proteina_promedio, rcs_promedio, activa
)
VALUES
    ('lac-001', 'animal-001', 3, '2025-10-02', NULL, 236, 34.2, 8071.2, 3.72, 3.31, 168000, TRUE),
    ('lac-002', 'animal-002', 2, '2025-11-18', NULL, 189, 30.8, 5821.2, 3.84, 3.39, 142000, TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO core_treatments (
    id, animal_id, medicamento, dosis, via_administracion, fecha_inicio,
    fecha_fin, periodo_retirada_dias, fecha_fin_retirada, activo,
    motivo, veterinario, observaciones
)
VALUES
    (
        'treat-001',
        'animal-002',
        'Suplemento mineral',
        '120 g/dia',
        'oral',
        '2026-05-20',
        NULL,
        0,
        NULL,
        TRUE,
        'Apoyo nutricional en tramo final de gestacion',
        'Dr. Mendez',
        'Revisar condicion corporal semanalmente.'
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO core_employees (id, nombre, apellidos, role, zona_principal_id, activo)
VALUES
    ('emp-001', 'Roberto', 'Castro', 'admin', 'ordeno', TRUE),
    ('emp-002', 'Laura', 'Fernandez', 'alimentacion', 'recria', TRUE),
    ('emp-003', 'Dr.', 'Mendez', 'veterinario', 'paridera', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO core_machinery (id, nombre, tipo, zona_id, estado, proxima_revision, observaciones)
VALUES
    ('mach-001', 'Robot de ordeno 1', 'ordeno', 'ordeno', 'operativa', '2026-06-10', 'Lavado automatico correcto.'),
    ('mach-002', 'Mezclador unifeed', 'alimentacion', 'recria', 'revision_programada', '2026-05-30', 'Comprobar cuchillas y bascula.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO core_animals (
    id, crotal_oficial, nombre, sexo, fecha_nacimiento, raza, estado,
    estado_reproductivo, fecha_entrada
)
VALUES
    ('animal-001', 'ES001', 'Luna', 'hembra', '2020-04-12', 'Frisona', 'produccion', 'lactante', '2020-04-12'),
    ('animal-002', 'ES002', 'Nube', 'hembra', '2021-09-03', 'Frisona', 'produccion', 'prenada', '2021-09-03'),
    ('animal-003', 'ES003', 'Brisa', 'hembra', '2025-01-19', 'Cruce', 'recria', NULL, '2025-01-19')
ON CONFLICT (id) DO NOTHING;

INSERT INTO core_tasks (
    id, tarea_catalogo_id, tarea_catalogo, zona_id, fecha_programada,
    estado, observaciones, checklist_completado, es_urgente, requiere_seguimiento
)
VALUES
    (
        'task-001',
        'cat-ord-001',
        '{"id":"cat-ord-001","nombre":"Revisar tanque","categoria":"ordeno","frecuencia":"diaria","zona_aplicable":"ordeno"}',
        'ordeno',
        NOW() + INTERVAL '1 hour',
        'programada',
        NULL,
        'false',
        TRUE,
        FALSE
    ),
    (
        'task-002',
        'cat-par-001',
        '{"id":"cat-par-001","nombre":"Control encamado","categoria":"bienestar","frecuencia":"diaria","zona_aplicable":"paridera"}',
        'paridera',
        NOW() - INTERVAL '4 hours',
        'retrasada',
        'Pendiente de revision',
        'false',
        FALSE,
        TRUE
    )
ON CONFLICT (id) DO NOTHING;
