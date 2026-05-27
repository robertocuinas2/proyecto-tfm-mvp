"use client";

import { useQuery } from "@tanstack/react-query";
import {
  AlertTriangle,
  ChevronRight,
  ClipboardList,
  MapPin,
  Monitor,
  Tablet,
} from "lucide-react";
import Link from "next/link";
import { api } from "@/lib/api";
import type { Task, Zone } from "@/lib/types";

type ZoneStatus = "operativa" | "atencion" | "critica" | "pendiente";

const statusStyles: Record<ZoneStatus, string> = {
  operativa: "border-tv-accent/30 bg-tv-accent/10 text-tv-accent",
  atencion: "border-state-atencion/30 bg-state-atencion/10 text-state-atencion",
  critica: "border-state-critica/30 bg-state-critica/10 text-state-critica",
  pendiente: "border-tv-border bg-tv-surface2 text-tv-dim",
};

const statusDot: Record<ZoneStatus, string> = {
  operativa: "bg-tv-accent",
  atencion: "bg-state-atencion",
  critica: "bg-state-critica",
  pendiente: "bg-tv-dim",
};

function deriveStatus(tasks: Task[]): ZoneStatus {
  const delayed = tasks.filter((task) => task.estado === "retrasada");
  if (delayed.some((task) => task.es_urgente)) return "critica";
  if (delayed.length > 0) return "atencion";
  if (tasks.length === 0) return "pendiente";
  return "operativa";
}

function StatStrip({
  totalAlerts,
  criticalAlerts,
  totalDelayed,
  activeZones,
  tvZones,
}: {
  totalAlerts: number;
  criticalAlerts: number;
  totalDelayed: number;
  activeZones: number;
  tvZones: number;
}) {
  const stats = [
    {
      label: "Alertas pendientes",
      value: totalAlerts,
      sub: `${criticalAlerts} criticas`,
      color: criticalAlerts > 0 ? "text-state-critica" : "text-tv-accent",
      Icon: AlertTriangle,
    },
    {
      label: "Tareas retrasadas",
      value: totalDelayed,
      sub: "en toda la explotacion",
      color: totalDelayed > 0 ? "text-state-atencion" : "text-tv-accent",
      Icon: ClipboardList,
    },
    {
      label: "Zonas activas",
      value: activeZones,
      sub: `${tvZones} con TV`,
      color: "text-white",
      Icon: MapPin,
    },
  ];

  return (
    <div className="grid gap-3 lg:grid-cols-3">
      {stats.map(({ label, value, sub, color, Icon }) => (
        <div key={label} className="rounded-lg border border-tv-border bg-tv-surface p-4">
          <div className="flex items-center gap-2">
            <Icon className={`h-4 w-4 ${color}`} strokeWidth={2} />
            <span className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-tv-dim">
              {label}
            </span>
          </div>
          <div className={`mt-2 font-heading text-4xl font-bold ${color}`}>{value}</div>
          <div className="mt-1 text-xs font-semibold text-tv-dim">{sub}</div>
        </div>
      ))}
    </div>
  );
}

function ZoneCard({ zone, tasks }: { zone: Zone; tasks: Task[] }) {
  const programadas = tasks.filter((task) => task.estado === "programada").length;
  const retrasadas = tasks.filter((task) => task.estado === "retrasada").length;
  const ejecutadas = tasks.filter((task) => task.estado === "ejecutada").length;
  const urgentes = tasks.filter((task) => task.es_urgente && task.estado !== "ejecutada").length;
  const status = deriveStatus(tasks);
  const total = Math.max(1, programadas + retrasadas + ejecutadas);
  const completion = Math.round((ejecutadas / total) * 100);

  return (
    <Link
      href={`/zones/${zone.id}`}
      className="group block rounded-lg border border-tv-border bg-tv-surface p-4 transition hover:border-tv-accent/40 hover:bg-tv-surface2"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <span className={`h-2.5 w-2.5 shrink-0 rounded-full ${statusDot[status]}`} />
            <span className="font-mono text-[11px] font-bold uppercase tracking-widest text-tv-dim">
              {zone.codigo}
            </span>
          </div>
          <h2 className="mt-1 truncate font-heading text-lg font-bold text-white">{zone.nombre}</h2>
          {zone.descripcion && (
            <p className="mt-1 line-clamp-2 text-xs leading-5 text-tv-dim">{zone.descripcion}</p>
          )}
        </div>
        <span className={`shrink-0 rounded-full border px-2.5 py-1 text-[10px] font-extrabold uppercase ${statusStyles[status]}`}>
          {status}
        </span>
      </div>

      <div className="mt-4">
        <div className="mb-1 flex items-center justify-between text-xs font-semibold text-tv-dim">
          <span>{ejecutadas} / {total} tareas completadas</span>
          <span>{completion}%</span>
        </div>
        <div className="h-1.5 rounded-full bg-tv-surface2">
          <div className="h-full rounded-full bg-tv-accent" style={{ width: `${completion}%` }} />
        </div>
      </div>

      <div className="mt-4 grid grid-cols-4 gap-2">
        {[
          { label: "Prog.", value: programadas, color: "text-state-info" },
          { label: "Retras.", value: retrasadas, color: "text-state-critica" },
          { label: "Hechas", value: ejecutadas, color: "text-state-ok" },
          { label: "Urg.", value: urgentes, color: "text-state-atencion" },
        ].map(({ label, value, color }) => (
          <div key={label} className="rounded-lg bg-tv-surface2 px-2 py-2 text-center">
            <div className={`font-heading text-xl font-bold ${color}`}>{value}</div>
            <div className="mt-0.5 text-[10px] font-bold uppercase text-tv-dim">{label}</div>
          </div>
        ))}
      </div>

      <div className="mt-4 flex items-center gap-2">
        {zone.tiene_pantalla_tv && (
          <span className="inline-flex items-center gap-1 rounded-full bg-tv-surface2 px-2.5 py-1 text-[11px] font-semibold text-tv-dim">
            <Monitor className="h-3 w-3" /> TV
          </span>
        )}
        {zone.tiene_tablet && (
          <span className="inline-flex items-center gap-1 rounded-full bg-tv-surface2 px-2.5 py-1 text-[11px] font-semibold text-tv-dim">
            <Tablet className="h-3 w-3" /> Tablet
          </span>
        )}
        <span className="ml-auto inline-flex items-center gap-1 text-xs font-bold text-tv-accent opacity-80 transition group-hover:opacity-100">
          Abrir <ChevronRight className="h-3.5 w-3.5" />
        </span>
      </div>
    </Link>
  );
}

export default function ZonesPage() {
  const { data: zones, isLoading: zonesLoading } = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: 60_000,
  });

  const { data: allTasks } = useQuery({
    queryKey: ["tasks-all"],
    queryFn: () => api.tasks({ limit: 500 }),
    staleTime: 30_000,
    refetchInterval: 30_000,
  });

  const { data: alertsData } = useQuery({
    queryKey: ["alerts-pending"],
    queryFn: () => api.alerts({ limit: 100 }),
    staleTime: 30_000,
    refetchInterval: 30_000,
  });

  const tasks = allTasks ?? [];
  const zoneList = zones ?? [];
  const totalAlerts = alertsData?.total ?? 0;
  const criticalAlerts = (alertsData?.alertas ?? []).filter(
    (alert) => alert.severidad === "critica" && alert.estado === "pendiente",
  ).length;
  const totalDelayed = tasks.filter((task) => task.estado === "retrasada").length;
  const tvZones = zoneList.filter((zone) => zone.tiene_pantalla_tv).length;

  return (
    <div className="min-h-full">
      <div className="border-b border-tv-border px-6 py-5 lg:px-8">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
              <MapPin className="h-4 w-4 text-tv-accent" />
              Mapa operativo
            </div>
            <h1 className="mt-1 font-heading text-2xl font-bold text-white">Zonas de trabajo</h1>
          </div>
          {zones && (
            <span className="rounded-full border border-tv-border bg-tv-surface px-3 py-1.5 text-sm font-bold text-white">
              {zones.length} zonas
            </span>
          )}
        </div>
      </div>

      <div className="space-y-6 px-6 py-6 lg:px-8">
        {!zonesLoading && (
          <StatStrip
            activeZones={zoneList.length}
            criticalAlerts={criticalAlerts}
            totalAlerts={totalAlerts}
            totalDelayed={totalDelayed}
            tvZones={tvZones}
          />
        )}

        {zonesLoading ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {Array.from({ length: 6 }).map((_, index) => (
              <div key={index} className="h-56 animate-pulse rounded-lg bg-tv-surface" />
            ))}
          </div>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {zoneList.map((zone) => (
              <ZoneCard
                key={zone.id}
                zone={zone}
                tasks={tasks.filter((task) => task.zona_id === zone.id)}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
