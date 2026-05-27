from __future__ import annotations

import argparse
import random
import sys
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from pathlib import Path
from typing import Any
from uuid import uuid4

from faker import Faker
from sqlalchemy import select
from sqlalchemy.orm import Session

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.database import Base, engine  # noqa: E402
from app.models import (  # noqa: E402
    CoreAlert,
    CoreAnimal,
    CoreEmployee,
    CoreIncident,
    CoreLactation,
    CoreMachinery,
    CoreTask,
    CoreTreatment,
    CoreZone,
)
from app.time_utils import utc_now  # noqa: E402


faker = Faker("es_ES")
Faker.seed(260526)
random.seed(260526)


@dataclass(frozen=True)
class SeedConfig:
    animals: int = 100
    months: int = 12
    alerts: int = 10
    tasks: int = 20
    incidents: int = 20
    reset: bool = True


ZONES = [
    ("ordeno", "Sala de ordeno", "ORD", "produccion"),
    ("paridera", "Paridera", "PAR", "cuidados"),
    ("recria", "Recria", "REC", "crecimiento"),
    ("alimentacion", "Alimentacion", "ALI", "alimentacion"),
    ("enfermeria", "Enfermeria", "ENF", "sanidad"),
    ("almacen", "Almacen", "ALM", "logistica"),
]

TASK_CATALOG = [
    ("Revisar tanque de leche", "ordeno", "diaria"),
    ("Lavar pezoneras", "ordeno", "diaria"),
    ("Comprobar cama de paridera", "bienestar", "diaria"),
    ("Preparar racion de recria", "alimentacion", "diaria"),
    ("Revision de maquinaria", "mantenimiento", "semanal"),
    ("Control sanitario visual", "sanidad", "diaria"),
]

ALERT_TYPES = [
    ("calidad_leche", "RCS por encima del umbral operativo", "Revisar muestra individual y ubre."),
    ("salud", "Descenso brusco de actividad", "Evaluar temperatura y signos clinicos."),
    ("reproductiva", "Parto probable en las proximas horas", "Trasladar a paridera y vigilar."),
    ("produccion", "Produccion por debajo de su media", "Comprobar ingesta y rutina de ordeno."),
]

INCIDENT_TYPES = [
    "Sanitaria - animal enfermo",
    "Operativa - tarea no ejecutada",
    "Calidad - leche fuera de parametro",
    "Maquinaria - averia",
    "Alimentacion - error en racion",
]


def month_starts(count: int, today: date) -> list[date]:
    months: list[date] = []
    year = today.year
    month = today.month
    for offset in reversed(range(count)):
        y = year
        m = month - offset
        while m <= 0:
            m += 12
            y -= 1
        months.append(date(y, m, 1))
    return months


def as_datetime(day: date, hour: int = 8) -> datetime:
    return datetime.combine(day, time(hour=hour))


def reset_core_tables(db: Session) -> None:
    for model in [
        CoreAlert,
        CoreIncident,
        CoreTask,
        CoreTreatment,
        CoreLactation,
        CoreMachinery,
        CoreEmployee,
        CoreAnimal,
        CoreZone,
    ]:
        db.query(model).delete()
    db.commit()


def seed_zones(db: Session) -> list[CoreZone]:
    zones: list[CoreZone] = []
    for zone_id, name, code, zone_type in ZONES:
        zone = CoreZone(
            id=zone_id,
            nombre=name,
            codigo=code,
            descripcion=f"Zona de {zone_type} generada para pruebas operativas.",
            tipo=zone_type,
            tiene_pantalla_tv=zone_id in {"ordeno", "paridera", "recria", "alimentacion"},
            tiene_tablet=True,
            activa=True,
        )
        db.add(zone)
        zones.append(zone)
    db.commit()
    return zones


def seed_animals(db: Session, count: int, today: date) -> list[CoreAnimal]:
    names = [
        "Luna",
        "Nube",
        "Brisa",
        "Estrella",
        "Mora",
        "Dalia",
        "Vega",
        "Senda",
        "Cora",
        "Nora",
    ]
    animals: list[CoreAnimal] = []
    for index in range(1, count + 1):
        if index <= round(count * 0.68):
            estado = "produccion"
            years_old = random.randint(3, 8)
            estado_reproductivo = random.choice(["lactante", "prenada", "secado_proximo"])
        elif index <= round(count * 0.83):
            estado = "recria"
            years_old = random.randint(0, 1)
            estado_reproductivo = None
        elif index <= round(count * 0.95):
            estado = "crianza"
            years_old = random.randint(1, 2)
            estado_reproductivo = random.choice([None, "novilla"])
        else:
            estado = "baja"
            years_old = random.randint(5, 10)
            estado_reproductivo = None

        birth = today - timedelta(days=years_old * 365 + random.randint(1, 260))
        entry = birth + timedelta(days=random.randint(0, 90))
        animal = CoreAnimal(
            id=f"animal-{index:03d}",
            crotal_oficial=f"ES{270650000 + index}",
            nombre=f"{random.choice(names)} {index}",
            sexo="hembra" if index <= round(count * 0.96) else "macho",
            fecha_nacimiento=birth.isoformat(),
            raza=random.choice(["Frisona", "Rubia Gallega", "Cruce Frisona", "Parda Alpina"]),
            estado=estado,
            estado_reproductivo=estado_reproductivo,
            fecha_entrada=entry.isoformat(),
            fecha_baja=(today - timedelta(days=random.randint(5, 120))).isoformat() if estado == "baja" else None,
            motivo_baja=random.choice(["venta", "desvieje", "traslado"]) if estado == "baja" else None,
            notas=faker.sentence(nb_words=8),
        )
        db.add(animal)
        animals.append(animal)
    db.commit()
    return animals


def seed_lactations(db: Session, animals: list[CoreAnimal], months: int, today: date) -> list[CoreLactation]:
    productive = [animal for animal in animals if animal.estado == "produccion"]
    starts = month_starts(months, today)
    lactations: list[CoreLactation] = []
    for index, animal in enumerate(productive, start=1):
        start = starts[(index - 1) % len(starts)]
        days = max(30, (today - start).days)
        production_avg = round(random.uniform(20.5, 38.5), 1)
        lactation = CoreLactation(
            id=f"lac-{index:03d}",
            animal_id=animal.id,
            numero_lactacion=random.randint(1, 5),
            fecha_inicio=start.isoformat(),
            fecha_fin=None,
            dias_transcurridos=days,
            produccion_promedio=production_avg,
            produccion_total=round(production_avg * days, 1),
            grasa_promedio=round(random.uniform(3.45, 4.25), 2),
            proteina_promedio=round(random.uniform(3.05, 3.55), 2),
            rcs_promedio=random.choice([random.randint(80000, 220000), random.randint(230000, 520000)]),
            activa=True,
        )
        db.add(lactation)
        lactations.append(lactation)
    db.commit()
    return lactations


def seed_treatments(db: Session, animals: list[CoreAnimal], today: date) -> list[CoreTreatment]:
    candidates = [animal for animal in animals if animal.estado in {"produccion", "crianza"}]
    selected = random.sample(candidates, k=min(15, len(candidates)))
    treatments: list[CoreTreatment] = []
    medicines = ["Ceftiofur", "Meloxicam", "Suplemento mineral", "Calcio oral", "Pomada mamaria"]
    for index, animal in enumerate(selected, start=1):
        start = today - timedelta(days=random.randint(1, 80))
        withdrawal = random.choice([0, 3, 5, 7])
        treatment = CoreTreatment(
            id=f"treat-{index:03d}",
            animal_id=animal.id,
            medicamento=random.choice(medicines),
            dosis=random.choice(["10 ml", "20 ml", "120 g/dia", "1 aplicacion"]),
            via_administracion=random.choice(["oral", "intramamaria", "subcutanea", "intramuscular"]),
            fecha_inicio=start.isoformat(),
            fecha_fin=None if index % 3 else (start + timedelta(days=random.randint(2, 7))).isoformat(),
            periodo_retirada_dias=withdrawal,
            fecha_fin_retirada=(start + timedelta(days=withdrawal)).isoformat() if withdrawal else None,
            activo=index % 3 != 0,
            motivo=random.choice(["mamitis leve", "cojera", "postparto", "apoyo nutricional"]),
            veterinario=random.choice(["Dr. Mendez", "Dra. Vidal", "Dr. Pereira"]),
            observaciones=faker.sentence(nb_words=9),
        )
        db.add(treatment)
        treatments.append(treatment)
    db.commit()
    return treatments


def seed_employees(db: Session, zones: list[CoreZone]) -> list[CoreEmployee]:
    roles = ["admin", "veterinario", "operario", "alimentacion", "operario", "operario", "alimentacion", "veterinario"]
    employees: list[CoreEmployee] = []
    for index, role in enumerate(roles, start=1):
        first = faker.first_name()
        last = faker.last_name()
        employee = CoreEmployee(
            id=f"emp-{index:03d}",
            nombre=first,
            apellidos=last,
            role=role,
            zona_principal_id=random.choice(zones).id,
            activo=True,
        )
        db.add(employee)
        employees.append(employee)
    db.commit()
    return employees


def seed_machinery(db: Session, zones: list[CoreZone]) -> list[CoreMachinery]:
    machinery_specs = [
        ("Robot de ordeno 1", "ordeno"),
        ("Robot de ordeno 2", "ordeno"),
        ("Tanque frio", "calidad"),
        ("Mezclador unifeed", "alimentacion"),
        ("Cinta alimentacion", "alimentacion"),
        ("Bomba de vacio", "ordeno"),
        ("Tractor auxiliar", "logistica"),
        ("Bebedero inteligente", "bienestar"),
    ]
    machinery: list[CoreMachinery] = []
    for index, (name, kind) in enumerate(machinery_specs, start=1):
        item = CoreMachinery(
            id=f"mach-{index:03d}",
            nombre=name,
            tipo=kind,
            zona_id=random.choice(zones).id,
            estado=random.choice(["operativa", "operativa", "revision", "revision_programada"]),
            proxima_revision=(utc_now().date() + timedelta(days=random.randint(10, 90))).isoformat(),
            observaciones=faker.sentence(nb_words=7),
        )
        db.add(item)
        machinery.append(item)
    db.commit()
    return machinery


def seed_tasks(db: Session, zones: list[CoreZone], employees: list[CoreEmployee], count: int, today: date) -> list[CoreTask]:
    tasks: list[CoreTask] = []
    statuses = ["programada", "programada", "retrasada", "ejecutada", "ejecutada"]
    for index in range(1, count + 1):
        zone = random.choice(zones)
        name, category, frequency = random.choice(TASK_CATALOG)
        planned_day = today + timedelta(days=random.randint(-10, 10))
        status = random.choice(statuses)
        execution_date = as_datetime(planned_day, random.randint(8, 18)) if status == "ejecutada" else None
        task = CoreTask(
            id=f"task-{index:03d}",
            tarea_catalogo_id=f"cat-{index:03d}",
            tarea_catalogo={
                "id": f"cat-{index:03d}",
                "nombre": name,
                "categoria": category,
                "frecuencia": frequency,
                "zona_aplicable": zone.id,
            },
            zona_id=zone.id,
            fecha_programada=as_datetime(planned_day, random.randint(6, 18)),
            fecha_ejecucion=execution_date,
            estado=status,
            ejecutado_por=random.choice(employees).nombre if execution_date else None,
            tiempo_ejecucion_minutos=str(random.randint(12, 65)) if execution_date else None,
            resultado="ok" if execution_date else None,
            observaciones=faker.sentence(nb_words=8),
            problemas_encontrados=None,
            acciones_correctivas=None,
            checklist_completado="true" if execution_date else "false",
            checklist_datos=None,
            es_urgente=index <= max(2, count // 5),
            motivo_retraso="Pendiente por prioridad superior" if status == "retrasada" else None,
            requiere_seguimiento=status == "retrasada",
            fecha_seguimiento=as_datetime(today + timedelta(days=1), 9) if status == "retrasada" else None,
        )
        db.add(task)
        tasks.append(task)
    db.commit()
    return tasks


def seed_alerts(db: Session, animals: list[CoreAnimal], count: int, today: date) -> list[CoreAlert]:
    candidates = [animal for animal in animals if animal.estado in {"produccion", "crianza"}]
    selected = random.sample(candidates, k=min(count, len(candidates)))
    alerts: list[CoreAlert] = []
    for index, animal in enumerate(selected, start=1):
        alert_type, description, recommendation = random.choice(ALERT_TYPES)
        created_at = as_datetime(today - timedelta(days=random.randint(0, 20)), random.randint(6, 20))
        status = random.choice(["pendiente", "pendiente", "revisada"])
        alert = CoreAlert(
            id=f"alert-{index:03d}",
            animal_id=animal.id,
            tipo_alerta=alert_type,
            severidad=random.choice(["media", "alta", "critica"]),
            descripcion=description,
            recomendacion=recommendation,
            estado=status,
            confianza_prediccion=round(random.uniform(0.62, 0.94), 2),
            requiere_escalacion=status == "pendiente" and index % 3 == 0,
            fecha_creacion=created_at,
            fecha_revision=created_at + timedelta(hours=4) if status != "pendiente" else None,
            revisada=status != "pendiente",
            notas_operario="Revisada por rutina" if status != "pendiente" else None,
            accion_tomada=None,
            veterinario_responsable=random.choice(["Dr. Mendez", "Dra. Vidal"]) if index % 2 else None,
        )
        db.add(alert)
        alerts.append(alert)
    db.commit()
    return alerts


def seed_incidents(
    db: Session,
    animals: list[CoreAnimal],
    zones: list[CoreZone],
    employees: list[CoreEmployee],
    count: int,
    today: date,
) -> list[CoreIncident]:
    incidents: list[CoreIncident] = []
    active_animals = [animal for animal in animals if animal.estado != "baja"]
    for index in range(1, count + 1):
        created_at = as_datetime(today - timedelta(days=random.randint(0, 60)), random.randint(6, 21))
        status = random.choice(["abierta", "en_proceso", "resuelta", "cerrada"])
        incident = CoreIncident(
            id=f"inc-{index:03d}",
            tipo=random.choice(INCIDENT_TYPES),
            zona_id=random.choice(zones).id,
            animal_id=random.choice(active_animals).id if index % 2 else None,
            descripcion=faker.sentence(nb_words=14),
            prioridad=random.choice(["baja", "media", "alta", "critica"]),
            estado=status,
            fecha_creacion=created_at,
            fecha_resolucion=created_at + timedelta(days=random.randint(1, 5)) if status in {"resuelta", "cerrada"} else None,
            resolucion=faker.sentence(nb_words=10) if status in {"resuelta", "cerrada"} else None,
            reportado_por=random.choice(employees).nombre,
        )
        db.add(incident)
        incidents.append(incident)
    db.commit()
    return incidents


def validate_integrity(db: Session, config: SeedConfig) -> dict[str, Any]:
    animals = db.scalars(select(CoreAnimal)).all()
    zones = db.scalars(select(CoreZone)).all()
    lactations = db.scalars(select(CoreLactation)).all()
    treatments = db.scalars(select(CoreTreatment)).all()
    alerts = db.scalars(select(CoreAlert)).all()
    tasks = db.scalars(select(CoreTask)).all()
    incidents = db.scalars(select(CoreIncident)).all()
    employees = db.scalars(select(CoreEmployee)).all()
    machinery = db.scalars(select(CoreMachinery)).all()

    animal_ids = {item.id for item in animals}
    zone_ids = {item.id for item in zones}
    errors: list[str] = []

    expected_counts = {
        "animals": config.animals,
        "alerts": config.alerts,
        "tasks": config.tasks,
        "incidents": config.incidents,
    }
    actual_counts = {
        "animals": len(animals),
        "zones": len(zones),
        "lactations": len(lactations),
        "treatments": len(treatments),
        "alerts": len(alerts),
        "tasks": len(tasks),
        "incidents": len(incidents),
        "employees": len(employees),
        "machinery": len(machinery),
    }

    for key, expected in expected_counts.items():
        if actual_counts[key] != expected:
            errors.append(f"{key}: expected {expected}, found {actual_counts[key]}")

    for item in lactations:
        if item.animal_id not in animal_ids:
            errors.append(f"lactation {item.id} references missing animal {item.animal_id}")
    for item in treatments:
        if item.animal_id not in animal_ids:
            errors.append(f"treatment {item.id} references missing animal {item.animal_id}")
    for item in alerts:
        if item.animal_id not in animal_ids:
            errors.append(f"alert {item.id} references missing animal {item.animal_id}")
    for item in tasks:
        if item.zona_id and item.zona_id not in zone_ids:
            errors.append(f"task {item.id} references missing zone {item.zona_id}")
    for item in incidents:
        if item.zona_id and item.zona_id not in zone_ids:
            errors.append(f"incident {item.id} references missing zone {item.zona_id}")
        if item.animal_id and item.animal_id not in animal_ids:
            errors.append(f"incident {item.id} references missing animal {item.animal_id}")
    for item in employees:
        if item.zona_principal_id and item.zona_principal_id not in zone_ids:
            errors.append(f"employee {item.id} references missing zone {item.zona_principal_id}")
    for item in machinery:
        if item.zona_id and item.zona_id not in zone_ids:
            errors.append(f"machinery {item.id} references missing zone {item.zona_id}")

    months = {
        item.fecha_inicio[:7]
        for item in lactations
        if item.fecha_inicio
    }
    if len(months) != config.months:
        errors.append(f"months: expected {config.months}, found {len(months)}")

    return {
        "ok": not errors,
        "counts": actual_counts,
        "months_covered": sorted(months),
        "errors": errors,
    }


def seed(config: SeedConfig) -> dict[str, Any]:
    Base.metadata.create_all(bind=engine)
    with Session(engine) as db:
        if config.reset:
            reset_core_tables(db)
        zones = seed_zones(db)
        animals = seed_animals(db, config.animals, utc_now().date())
        seed_lactations(db, animals, config.months, utc_now().date())
        seed_treatments(db, animals, utc_now().date())
        employees = seed_employees(db, zones)
        seed_machinery(db, zones)
        seed_tasks(db, zones, employees, config.tasks, utc_now().date())
        seed_alerts(db, animals, config.alerts, utc_now().date())
        seed_incidents(db, animals, zones, employees, config.incidents, utc_now().date())
        report = validate_integrity(db, config)
        if not report["ok"]:
            raise RuntimeError(f"Seed integrity failed: {report['errors']}")
        return report


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed coherent Faker data for Tools4Milk.")
    parser.add_argument("--animals", type=int, default=100)
    parser.add_argument("--months", type=int, default=12)
    parser.add_argument("--alerts", type=int, default=10)
    parser.add_argument("--tasks", type=int, default=20)
    parser.add_argument("--incidents", type=int, default=20)
    parser.add_argument("--no-reset", action="store_true")
    args = parser.parse_args()

    report = seed(
        SeedConfig(
            animals=args.animals,
            months=args.months,
            alerts=args.alerts,
            tasks=args.tasks,
            incidents=args.incidents,
            reset=not args.no_reset,
        )
    )
    print("Seed completed")
    print(report)


if __name__ == "__main__":
    main()
