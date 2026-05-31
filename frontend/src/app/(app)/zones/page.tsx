"use client";

import { useQuery } from "@tanstack/react-query";
import {
  AlertOctagon,
  AlertTriangle,
  ClipboardList,
  MapPin,
  Monitor,
  Settings2,
  Tablet,
  Wrench,
} from "lucide-react";
import Link from "next/link";
import { useMemo } from "react";
import { KpiCard } from "@/components/ui/kpi-card";
import { PageHeader } from "@/components/ui/page-header";
import { WeatherPanel } from "@/components/ui/WeatherPanel";
import { api } from "@/lib/api";
import { TV_REFETCH, TV_STALE } from "@/lib/tv-constants";
import type { Incident, Machinery, Task, Zone } from "@/lib/types";

// ── Zone status helpers ──────────────────────────────────────────────────────

type ZoneStatus = "critica" | "atencion" | "operativa" | "inactiva";

function deriveZoneStatus(
  tasks: Task[],
  incidents: Incident[],
  active?: boolean,
): ZoneStatus {
  if (active === false) return "inactiva";
  const delayed = tasks.filter((t) => t.estado === "retrasada");
  const openInc = incidents.filter((i) => i.estado === "abierta" || i.estado === "en_gestion");
  const hasCritical = delayed.some((t) => t.es_urgente) || openInc.some((i) => i.prioridad === "critica");
  if (hasCritical) return "critica";
  if (delayed.length > 0 || openInc.length > 0) return "atencion";
  if (tasks.length > 0) return "operativa";
  return "operativa"; // default if has zone but no tasks
}

const statusStylesLight: Record<ZoneStatus, { badge: string; dot: string; label: string }> = {
  critica:  { badge: "border-state-critica/30 bg-state-critica/8 text-state-critica",   dot: "bg-state-critica",   label: "Crítica" },
  atencion: { badge: "border-state-atencion/30 bg-state-atencion/8 text-state-atencion", dot: "bg-state-atencion",  label: "Atención" },
  operativa:{ badge: "border-state-ok/30 bg-state-ok/8 text-state-ok",                   dot: "bg-state-ok",        label: "Operativa" },
  inactiva: { badge: "border-app-border bg-app-bg text-app-dim",                          dot: "bg-app-dim",         label: "Inactiva" },
};

// ── Zone card ────────────────────────────────────────────────────────────────

function ZoneCard({
  zone,
  tasks,
  incidents,
  machinery,
}: {
  zone: Zone;
  tasks: Task[];
  incidents: Incident[];
  machinery: Machinery[];
}) {
  const pending = tasks.filter((t) => t.estado === "programada" || t.estado === "retrasada");
  const retrasadas = tasks.filter((t) => t.estado === "retrasada");
  const ejecutadas = tasks.filter((t) => t.estado === "ejecutada");
  const openInc = incidents.filter((i) => i.estado === "abierta" || i.estado === "en_gestion");
  const status = deriveZoneStatus(tasks, incidents, zone.activa);
  const s = statusStylesLight[status];
  const total = pending.length + ejecutadas.length;
  const completion = total > 0 ? Math.round((ejecutadas.length / total) * 100) : 0;

  return (
    <div className="rounded-[14px] border border-app-border bg-white shadow-card transition hover:shadow-panel">
      {/* Zone header */}
      <Link href={`/zones/${zone.id}`} className="block px-5 py-4">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className={`h-2.5 w-2.5 shrink-0 rounded-full ${s.dot}`} />
              <span className="font-mono text-[11px] font-bold uppercase tracking-widest text-app-dim">
                {zone.codigo}
              </span>
            </div>
            <h2 className="mt-1 font-heading text-lg font-bold text-app-text">{zone.nombre}</h2>
            {zone.descripcion && (
              <p className="mt-0.5 line-clamp-1 text-xs text-app-dim">{zone.descripcion}</p>
            )}
          </div>
          <span className={`shrink-0 rounded-full border px-2.5 py-0.5 text-[10px] font-extrabold uppercase ${s.badge}`}>
            {s.label}
          </span>
        </div>

        {/* Progress bar */}
        {total > 0 && (
          <div className="mt-3">
            <div className="mb-1 flex justify-between text-[11px] font-semibold text-app-dim">
              <span>{ejecutadas.length}/{total} tareas completadas</span>
              <span>{completion}%</span>
            </div>
            <div className="h-1.5 rounded-full bg-app-surface2">
              <div className="h-full rounded-full bg-brand transition-all" style={{ width: `${completion}%` }} />
            </div>
          </div>
        )}
      </Link>

      {/* Stats row */}
      <div className="grid grid-cols-3 border-t border-app-border divide-x divide-app-border">
        <div className="flex flex-col items-center py-3 text-center">
          <ClipboardList className={`h-3.5 w-3.5 ${retrasadas.length > 0 ? "text-state-critica" : "text-app-dim"}`} />
          <span className={`mt-1 font-heading text-base font-bold ${retrasadas.length > 0 ? "text-state-critica" : "text-app-text"}`}>
            {pending.length}
          </span>
          <span className="text-[10px] text-app-dim">Pendientes</span>
        </div>
        <div className="flex flex-col items-center py-3 text-center">
          <AlertOctagon className={`h-3.5 w-3.5 ${openInc.length > 0 ? "text-state-atencion" : "text-app-dim"}`} />
          <span className={`mt-1 font-heading text-base font-bold ${openInc.length > 0 ? "text-state-atencion" : "text-app-text"}`}>
            {openInc.length}
          </span>
          <span className="text-[10px] text-app-dim">Incidencias</span>
        </div>
        <div className="flex flex-col items-center py-3 text-center">
          <Wrench className="h-3.5 w-3.5 text-app-dim" />
          <span className="mt-1 font-heading text-base font-bold text-app-text">
            {machinery.length}
          </span>
          <span className="text-[10px] text-app-dim">Máquinas</span>
        </div>
      </div>

      {/* Footer with device indicators + actions */}
      <div className="flex items-center justify-between gap-2 border-t border-app-border px-4 py-2.5">
        <div className="flex gap-2">
          {zone.tiene_pantalla_tv && (
            <span className="flex items-center gap-1 rounded-full bg-state-info/8 px-2 py-0.5 text-[10px] font-semibold text-state-info">
              <Monitor className="h-3 w-3" /> TV
            </span>
          )}
          {zone.tiene_tablet && (
            <span className="flex items-center gap-1 rounded-full bg-state-ok/8 px-2 py-0.5 text-[10px] font-semibold text-state-ok">
              <Tablet className="h-3 w-3" /> Tablet
            </span>
          )}
          {zone.tipo && (
            <span className="rounded-full bg-app-bg px-2 py-0.5 text-[10px] capitalize text-app-dim">{zone.tipo}</span>
          )}
        </div>
        <Link
          href={`/zones/${zone.id}`}
          className="text-xs font-semibold text-brand hover:underline"
        >
          Ver zona →
        </Link>
      </div>
    </div>
  );
}

// ── Main page ─────────────────────────────────────────────────────────────────

export default function ZonesPage() {
  const zonesQ = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: TV_STALE.CATALOG,
  });

  const tasksQ = useQuery({
    queryKey: ["tasks-all"],
    queryFn: () => api.tasks({ limit: 500 }),
    staleTime: TV_STALE.NORMAL,
    refetchInterval: TV_REFETCH.NORMAL,
  });

  const incidentsQ = useQuery({
    queryKey: ["tv-incidents"],
    queryFn: () => api.incidents({ limit: 200 }),
    staleTime: TV_STALE.NORMAL,
    refetchInterval: TV_REFETCH.NORMAL,
  });

  const machineryQ = useQuery({
    queryKey: ["machinery-all"],
    queryFn: () => api.machinery({ limit: 200 }),
    staleTime: TV_STALE.CATALOG,
  });

  const alertsQ = useQuery({
    queryKey: ["alerts-pending"],
    queryFn: () => api.alerts({ limit: 100 }),
    staleTime: TV_STALE.NORMAL,
    refetchInterval: TV_REFETCH.FAST,
  });

  const zones = zonesQ.data ?? [];
  const allTasks = useMemo(() => tasksQ.data ?? [], [tasksQ.data]);
  const allIncidents = useMemo(() => (incidentsQ.data ?? []) as Incident[], [incidentsQ.data]);
  const allMachinery = useMemo(() => (machineryQ.data ?? []) as Machinery[], [machineryQ.data]);
  const allAlerts = alertsQ.data?.alertas ?? [];

  // Grouped lookups (client-side)
  const tasksByZone = useMemo(() => {
    const map = new Map<string, Task[]>();
    for (const t of allTasks) {
      if (!t.zona_id) continue;
      const arr = map.get(t.zona_id) ?? [];
      arr.push(t);
      map.set(t.zona_id, arr);
    }
    return map;
  }, [allTasks]);

  const incidentsByZone = useMemo(() => {
    const map = new Map<string, Incident[]>();
    for (const i of allIncidents) {
      if (!i.zona_id) continue;
      const arr = map.get(i.zona_id) ?? [];
      arr.push(i);
      map.set(i.zona_id, arr);
    }
    return map;
  }, [allIncidents]);

  const machineryByZone = useMemo(() => {
    const map = new Map<string, Machinery[]>();
    for (const m of allMachinery) {
      if (!m.zona_id) continue;
      const arr = map.get(m.zona_id) ?? [];
      arr.push(m);
      map.set(m.zona_id, arr);
    }
    return map;
  }, [allMachinery]);

  // KPI calculations
  const tvZones = zones.filter((z) => z.tiene_pantalla_tv).length;
  const tabletZones = zones.filter((z) => z.tiene_tablet).length;
  const activeZones = zones.filter((z) => z.activa !== false).length;
  const criticalAlerts = allAlerts.filter((a) => a.severidad === "critica" && a.estado === "pendiente").length;
  const openIncidents = allIncidents.filter((i) => i.estado === "abierta" || i.estado === "en_gestion").length;

  return (
    <div className="min-h-full">
      <PageHeader eyebrow="Mapa operativo" title="Zonas de trabajo" EyebrowIcon={MapPin}>
        <div className="flex items-center gap-2">
          {zones.length > 0 && (
            <span className="rounded-full border border-app-border bg-white px-3 py-1.5 text-sm font-bold text-app-text">
              {zones.length} zonas
            </span>
          )}
          <Link
            href="/settings"
            className="inline-flex items-center gap-1.5 rounded-[10px] border border-app-border bg-app-bg px-3 py-2 text-xs font-semibold text-app-dim transition hover:border-brand/30 hover:text-brand"
          >
            <Settings2 className="h-3.5 w-3.5" />
            Configurar
          </Link>
        </div>
      </PageHeader>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        {/* KPIs */}
        {!zonesQ.isLoading && (
          <div className="grid grid-cols-2 gap-4 xl:grid-cols-5">
            <KpiCard label="Zonas totales" value={zones.length} />
            <KpiCard label="Zonas activas" value={activeZones} tone="success" />
            <KpiCard label="Con TV" value={tvZones} Icon={Monitor} tone="info" />
            <KpiCard label="Con tablet" value={tabletZones} Icon={Tablet} tone="info" />
            <KpiCard
              label="Alertas críticas"
              value={criticalAlerts}
              Icon={AlertTriangle}
              tone={criticalAlerts > 0 ? "critical" : "success"}
            />
          </div>
        )}

        {/* Weather panel (compact) */}
        <WeatherPanel compact />

        {/* Zones grid */}
        {zonesQ.isLoading ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-52 animate-pulse rounded-[14px] bg-app-surface2" />
            ))}
          </div>
        ) : zones.length === 0 ? (
          <div className="rounded-[14px] border border-app-border bg-white py-16 text-center shadow-card">
            <MapPin className="mx-auto h-12 w-12 text-app-dim" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-app-text">Sin zonas configuradas</p>
            <p className="mt-1 text-sm text-app-dim">
              Crea zonas desde{" "}
              <Link href="/settings" className="font-semibold text-brand hover:underline">Configuración</Link>.
            </p>
          </div>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {zones.map((zone) => (
              <ZoneCard
                key={zone.id}
                zone={zone}
                tasks={tasksByZone.get(zone.id) ?? []}
                incidents={incidentsByZone.get(zone.id) ?? []}
                machinery={machineryByZone.get(zone.id) ?? []}
              />
            ))}
          </div>
        )}

        {/* Incidents summary (if any) */}
        {openIncidents > 0 && (
          <div className="flex items-center gap-3 rounded-[14px] border border-state-atencion/20 bg-state-atencion/5 px-5 py-3">
            <AlertOctagon className="h-5 w-5 text-state-atencion" />
            <p className="text-sm font-semibold text-state-atencion">
              {openIncidents} incidencias abiertas en la explotación.{" "}
              <Link href="/incidents" className="underline hover:no-underline">
                Ver todas
              </Link>
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
