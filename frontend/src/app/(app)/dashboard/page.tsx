"use client";

import { useQuery } from "@tanstack/react-query";
import {
  AlertTriangle,
  Beef,
  CheckCircle2,
  CloudSun,
  ClipboardList,
  Clock,
  MapPin,
  Milk,
  Pill,
  RefreshCw,
} from "lucide-react";
import Link from "next/link";
import { DonutStat, SparkArea } from "@/components/charts/MiniCharts";
import { api } from "@/lib/api";
import type { Alert, Lactation } from "@/lib/types";

type KpiTone = "critical" | "warning" | "good" | "info" | "neutral";

const toneClass: Record<KpiTone, string> = {
  critical: "text-state-critica",
  warning: "text-state-atencion",
  good: "text-tv-accent",
  info: "text-state-info",
  neutral: "text-tv-dim",
};

function PageHeader() {
  return (
    <div className="border-b border-tv-border px-6 py-5 lg:px-8">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
            Centro de control
          </div>
          <h1 className="mt-1 font-heading text-2xl font-bold text-white">
            Estado operativo de la explotacion
          </h1>
        </div>
        <div className="flex items-center gap-2 rounded-full border border-tv-border bg-tv-surface px-3 py-2 text-xs font-bold text-tv-dim">
          <RefreshCw className="h-3.5 w-3.5 text-tv-accent" />
          Actualizacion cada 30 s
        </div>
      </div>
    </div>
  );
}

function KpiCard({
  label,
  value,
  sublabel,
  tone,
  href,
  Icon,
}: {
  label: string;
  value: number | string;
  sublabel: string;
  tone: KpiTone;
  href?: string;
  Icon: typeof AlertTriangle;
}) {
  const content = (
    <div className="h-full rounded-lg border border-tv-border bg-tv-surface p-4 transition hover:border-tv-accent/35 hover:bg-tv-surface2">
      <div className="flex items-center justify-between gap-3">
        <span className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-tv-dim">
          {label}
        </span>
        <Icon className={`h-4 w-4 ${toneClass[tone]}`} strokeWidth={2} />
      </div>
      <div className={`mt-3 font-heading text-4xl font-bold ${toneClass[tone]}`}>
        {value}
      </div>
      <div className="mt-1 text-xs font-semibold text-tv-dim">{sublabel}</div>
    </div>
  );

  return href ? <Link href={href}>{content}</Link> : content;
}

function SeverityBadge({ severity }: { severity: Alert["severidad"] }) {
  const map: Record<Alert["severidad"], string> = {
    critica: "bg-state-critica/15 text-state-critica",
    alta: "bg-state-atencion/15 text-state-atencion",
    media: "bg-state-info/15 text-state-info",
    baja: "bg-state-neutral/15 text-state-neutral",
  };

  return (
    <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold uppercase ${map[severity]}`}>
      {severity}
    </span>
  );
}

function formatNumber(value: number | null | undefined, digits = 0) {
  if (value == null || Number.isNaN(value)) return "-";
  return value.toLocaleString("es-ES", {
    maximumFractionDigits: digits,
    minimumFractionDigits: digits,
  });
}

function lactationTrend(items: Lactation[]) {
  return items
    .filter((item) => item.produccion_promedio != null)
    .slice(0, 10)
    .reverse()
    .map((item, index) => ({
      label: item.fecha_inicio?.slice(5, 10) ?? String(index + 1),
      value: Number(item.produccion_promedio),
    }));
}

export default function DashboardPage() {
  const summary = useQuery({
    queryKey: ["dashboard-summary"],
    queryFn: api.dashboardSummary,
    refetchInterval: 30_000,
    staleTime: 10_000,
  });

  const alerts = useQuery({
    queryKey: ["alerts-recent"],
    queryFn: () => api.alerts({ limit: 5 }),
    refetchInterval: 30_000,
    staleTime: 10_000,
  });

  const quality = useQuery({
    queryKey: ["quality-summary"],
    queryFn: api.qualitySummary,
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

  const lactations = useQuery({
    queryKey: ["dashboard-lactations-active"],
    queryFn: () => api.lactations({ activa: true, limit: 120 }),
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

  const weather = useQuery({
    queryKey: ["weather-current"],
    queryFn: api.weather,
    refetchInterval: 10 * 60_000,
    staleTime: 5 * 60_000,
  });

  const s = summary.data;
  const q = quality.data;
  const w = weather.data;
  const recentAlerts = alerts.data?.alertas?.slice(0, 5) ?? [];
  const trend = lactationTrend(lactations.data ?? []);
  const taskTotal =
    (s?.tareas.programadas ?? 0) +
    (s?.tareas.ejecutadas ?? 0) +
    (s?.tareas.retrasadas ?? 0);
  const taskDonePct = s
    ? Math.round((s.tareas.ejecutadas / Math.max(1, taskTotal)) * 100)
    : 0;

  return (
    <div className="min-h-full">
      <PageHeader />

      <div className="space-y-6 px-6 py-6 lg:px-8">
        {summary.isLoading ? (
          <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
            {Array.from({ length: 8 }).map((_, index) => (
              <div key={index} className="h-32 animate-pulse rounded-lg bg-tv-surface" />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
            <KpiCard
              Icon={AlertTriangle}
              href="/alerts"
              label="Alertas pendientes"
              value={s?.alertas.total_pendientes ?? "-"}
              sublabel={`${s?.alertas.criticas ?? 0} criticas, ${s?.alertas.altas ?? 0} altas`}
              tone={s && s.alertas.criticas > 0 ? "critical" : s && s.alertas.altas > 0 ? "warning" : "good"}
            />
            <KpiCard
              Icon={Clock}
              href="/tasks"
              label="Tareas retrasadas"
              value={s?.tareas.retrasadas ?? "-"}
              sublabel="Pendientes fuera de plazo"
              tone={s && s.tareas.retrasadas > 0 ? "warning" : "good"}
            />
            <KpiCard
              Icon={ClipboardList}
              href="/tasks"
              label="Tareas hoy"
              value={taskTotal}
              sublabel={`${s?.tareas.ejecutadas ?? 0} completadas`}
              tone="info"
            />
            <KpiCard
              Icon={Beef}
              href="/animals"
              label="Animales activos"
              value={s?.animales.activos ?? "-"}
              sublabel="Censo operativo"
              tone="neutral"
            />
            <KpiCard
              Icon={Pill}
              label="Tratamientos"
              value={s?.tratamientos.activos ?? "-"}
              sublabel="Activos actualmente"
              tone={s && s.tratamientos.activos > 15 ? "critical" : "info"}
            />
            <KpiCard
              Icon={CheckCircle2}
              href="/tasks"
              label="Cumplimiento"
              value={`${taskDonePct}%`}
              sublabel="Tareas ejecutadas"
              tone={taskDonePct > 65 ? "good" : "warning"}
            />
            <KpiCard
              Icon={Milk}
              href="/quality"
              label="Produccion"
              value={`${formatNumber(q?.produccion_promedio, 1)} L`}
              sublabel={`${q?.lactaciones_activas ?? 0} lactaciones activas`}
              tone="warning"
            />
            <KpiCard
              Icon={CloudSun}
              label="Clima"
              value={w?.temperatura_actual != null ? `${formatNumber(w.temperatura_actual, 1)} C` : "-"}
              sublabel={w?.descripcion ?? "Sin lectura reciente"}
              tone={weather.isError ? "critical" : "info"}
            />
          </div>
        )}

        <div className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
          <section className="rounded-lg border border-tv-border bg-tv-surface p-5">
            <div className="mb-5 flex items-center justify-between gap-4">
              <div>
                <div className="text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
                  Pulso operativo
                </div>
                <h2 className="mt-1 font-heading text-lg font-bold text-white">
                  Produccion y carga de trabajo
                </h2>
              </div>
              <span className="rounded-full bg-tv-accent/10 px-3 py-1 text-xs font-bold text-tv-accent">
                {q?.animales_en_control ?? 0} animales en control
              </span>
            </div>
            <div className="h-44">
              {trend.length >= 2 ? (
                <SparkArea height={130} data={trend} />
              ) : (
                <div className="grid h-full place-items-center rounded-lg border border-dashed border-tv-border text-sm font-semibold text-tv-dim">
                  Sin lactaciones suficientes para tendencia
                </div>
              )}
            </div>
          </section>

          <section className="rounded-lg border border-tv-border bg-tv-surface p-5">
            <div className="mb-5 text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
              Cumplimiento de tareas
            </div>
            <div className="grid gap-5 sm:grid-cols-[120px_1fr] sm:items-center xl:grid-cols-1">
              <DonutStat value={taskDonePct} label="ejec." />
              <div className="space-y-3">
                {[
                  { label: "Programadas", value: s?.tareas.programadas ?? 0, color: "bg-state-info" },
                  { label: "Ejecutadas", value: s?.tareas.ejecutadas ?? 0, color: "bg-state-ok" },
                  { label: "Retrasadas", value: s?.tareas.retrasadas ?? 0, color: "bg-state-critica" },
                ].map(({ label, value, color }) => {
                  const pct = Math.round((value / Math.max(1, taskTotal)) * 100);
                  return (
                    <div key={label}>
                      <div className="mb-1 flex items-center justify-between text-sm">
                        <span className="font-semibold text-tv-dim">{label}</span>
                        <span className="font-bold text-white">{value}</span>
                      </div>
                      <div className="h-2 rounded-full bg-tv-surface2">
                        <div className={`h-full rounded-full ${color}`} style={{ width: `${pct}%` }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </section>
        </div>

        <div className="grid gap-6 xl:grid-cols-2">
          <section className="rounded-lg border border-tv-border bg-tv-surface p-5">
            <div className="mb-4 flex items-center justify-between gap-4">
              <div className="flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 text-state-critica" />
                <h2 className="font-heading text-base font-bold text-white">Alertas recientes</h2>
              </div>
              <Link href="/alerts" className="text-xs font-semibold text-tv-accent hover:underline">
                Ver todas
              </Link>
            </div>

            {alerts.isLoading ? (
              <div className="space-y-2">
                {Array.from({ length: 3 }).map((_, index) => (
                  <div key={index} className="h-14 animate-pulse rounded-lg bg-tv-surface2" />
                ))}
              </div>
            ) : recentAlerts.length === 0 ? (
              <p className="py-8 text-center text-sm font-semibold text-tv-dim">
                No hay alertas pendientes.
              </p>
            ) : (
              <div className="space-y-2">
                {recentAlerts.map((alert) => (
                  <div key={alert.id} className="rounded-lg border border-tv-border bg-tv-surface2 px-4 py-3">
                    <div className="flex items-center gap-2">
                      <SeverityBadge severity={alert.severidad} />
                      <span className="text-xs capitalize text-tv-dim">{alert.tipo_alerta}</span>
                    </div>
                    <p className="mt-1 truncate text-sm font-semibold text-white">{alert.descripcion}</p>
                  </div>
                ))}
              </div>
            )}
          </section>

          <section className="rounded-lg border border-tv-border bg-tv-surface p-5">
            <div className="mb-4 flex items-center justify-between gap-4">
              <div className="flex items-center gap-2">
                <ClipboardList className="h-4 w-4 text-tv-accent" />
                <h2 className="font-heading text-base font-bold text-white">Accesos rapidos</h2>
              </div>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              {[
                { href: "/zones", label: "Ver zonas", Icon: MapPin },
                { href: "/tasks", label: "Gestionar tareas", Icon: ClipboardList },
                { href: "/alerts", label: "Revisar alertas", Icon: AlertTriangle },
                { href: "/leanfarming", label: "LeanFarming", Icon: CheckCircle2 },
              ].map(({ href, label, Icon }) => (
                <Link
                  key={href}
                  href={href}
                  className="flex items-center justify-between rounded-lg border border-tv-border bg-tv-surface2 px-4 py-3 text-sm font-bold text-white transition hover:border-tv-accent/40"
                >
                  {label}
                  <Icon className="h-4 w-4 text-tv-accent" />
                </Link>
              ))}
            </div>
          </section>
        </div>

        {summary.isError && (
          <div className="rounded-lg border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar datos. Verifica que el backend este en marcha.
          </div>
        )}
      </div>
    </div>
  );
}
