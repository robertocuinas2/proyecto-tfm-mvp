"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, Droplets, Filter, Target, TrendingDown, TrendingUp } from "lucide-react";
import { useMemo, useState } from "react";
import { DonutStat, SparkArea } from "@/components/charts/MiniCharts";
import { Pagination } from "@/components/common/Pagination";
import { api } from "@/lib/api";
import { DEFAULT_PAGE_SIZE, getSkip } from "@/lib/pagination";
import type { Animal, Lactation } from "@/lib/types";

type MetricStatus = "ok" | "warning" | "critical";
type MetricKey = "grasa" | "proteina" | "produccion" | "rcs";
type IndicatorKey = "rcs" | "produccion" | "dias" | "total";

const compositionMetrics: {
  key: MetricKey;
  label: string;
  unit: string;
  ideal: string;
  digits: number;
}[] = [
  { key: "grasa", label: "Grasa", unit: "%", ideal: "3.8-4.2", digits: 2 },
  { key: "proteina", label: "Proteina", unit: "%", ideal: "3.1-3.5", digits: 2 },
  { key: "produccion", label: "Produccion", unit: "L/dia", ideal: "24-36", digits: 1 },
  { key: "rcs", label: "RCS", unit: "cel/mL", ideal: "< 250k", digits: 0 },
];

const qualityIndicators: {
  key: IndicatorKey;
  label: string;
  unit: string;
  warning?: number;
  critical?: number;
  digits: number;
}[] = [
  { key: "rcs", label: "Celulas somaticas", unit: "cel/mL", warning: 250000, critical: 400000, digits: 0 },
  { key: "produccion", label: "Produccion media", unit: "L/dia", warning: 20, critical: 16, digits: 1 },
  { key: "dias", label: "Dias en leche", unit: "dias", warning: 260, critical: 320, digits: 0 },
  { key: "total", label: "Produccion total", unit: "L", digits: 0 },
];

function formatNumber(value: number | null | undefined, digits = 0) {
  if (value == null || Number.isNaN(value)) return "N/D";
  return value.toLocaleString("es-ES", {
    maximumFractionDigits: digits,
    minimumFractionDigits: digits,
  });
}

function statusClass(status: MetricStatus) {
  if (status === "critical") return "border-state-critica/30 bg-state-critica/10 text-state-critica";
  if (status === "warning") return "border-state-atencion/30 bg-state-atencion/10 text-state-atencion";
  return "border-state-ok/30 bg-state-ok/10 text-state-ok";
}

function getMetricValue(metric: MetricKey, lactation?: Lactation) {
  if (!lactation) return null;
  if (metric === "grasa") return lactation.grasa_promedio;
  if (metric === "proteina") return lactation.proteina_promedio;
  if (metric === "produccion") return lactation.produccion_promedio;
  return lactation.rcs_promedio;
}

function getIndicatorValue(metric: IndicatorKey, lactation?: Lactation) {
  if (!lactation) return null;
  if (metric === "rcs") return lactation.rcs_promedio;
  if (metric === "produccion") return lactation.produccion_promedio;
  if (metric === "dias") return lactation.dias_transcurridos;
  return lactation.produccion_total;
}

function metricStatus(metric: MetricKey, value: number | null | undefined): MetricStatus {
  if (value == null) return "warning";
  if (metric === "grasa") return value < 3.4 || value > 4.6 ? "warning" : "ok";
  if (metric === "proteina") return value < 3.0 || value > 3.8 ? "warning" : "ok";
  if (metric === "produccion") return value < 16 ? "critical" : value < 20 ? "warning" : "ok";
  return value >= 400000 ? "critical" : value >= 250000 ? "warning" : "ok";
}

function indicatorStatus(metric: (typeof qualityIndicators)[number], value: number | null | undefined): MetricStatus {
  if (value == null) return "warning";
  if (metric.key === "produccion") {
    if (metric.critical != null && value <= metric.critical) return "critical";
    if (metric.warning != null && value <= metric.warning) return "warning";
    return "ok";
  }
  if (metric.critical != null && value >= metric.critical) return "critical";
  if (metric.warning != null && value >= metric.warning) return "warning";
  return "ok";
}

function qualityScore(lactation?: Lactation) {
  if (!lactation) return 0;
  let score = 100;
  const rcs = lactation.rcs_promedio ?? 0;
  const production = lactation.produccion_promedio ?? 0;
  const fat = lactation.grasa_promedio ?? 0;
  const protein = lactation.proteina_promedio ?? 0;

  if (rcs >= 400000) score -= 30;
  else if (rcs >= 250000) score -= 15;
  if (production > 0 && production < 20) score -= 12;
  if (fat > 0 && (fat < 3.4 || fat > 4.6)) score -= 8;
  if (protein > 0 && (protein < 3.0 || protein > 3.8)) score -= 8;
  return Math.max(0, Math.min(100, score));
}

function CompositionCard({
  lactation,
  metric,
}: {
  lactation?: Lactation;
  metric: (typeof compositionMetrics)[number];
}) {
  const value = getMetricValue(metric.key, lactation);
  const status = metricStatus(metric.key, value);

  return (
    <div className="rounded-lg border border-tv-border bg-tv-surface p-4">
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="text-[11px] font-extrabold uppercase tracking-[0.14em] text-tv-dim">{metric.label}</p>
          <p className="mt-0.5 text-xs text-tv-dim">Objetivo: {metric.ideal}</p>
        </div>
        <span className={`rounded-full px-2 py-1 text-[11px] font-bold ${statusClass(status)}`}>
          {status === "ok" ? "En rango" : status === "critical" ? "Critico" : "Vigilar"}
        </span>
      </div>
      <div className="mt-3">
        <span className="font-heading text-3xl font-bold text-white">{formatNumber(value, metric.digits)}</span>
        <span className="ml-1 text-sm text-tv-dim">{metric.unit}</span>
      </div>
    </div>
  );
}

function QualityMetricCard({
  lactation,
  metric,
}: {
  lactation?: Lactation;
  metric: (typeof qualityIndicators)[number];
}) {
  const value = getIndicatorValue(metric.key, lactation);
  const status = indicatorStatus(metric, value);
  const improving = metric.key === "produccion" ? status === "ok" : status !== "critical";

  return (
    <div className={`rounded-lg border px-4 py-3.5 ${statusClass(status)}`}>
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="text-[11px] font-extrabold uppercase tracking-[0.14em] text-tv-dim">{metric.label}</p>
          <div className="mt-2 flex items-baseline gap-1">
            <span className="font-heading text-2xl font-bold">{formatNumber(value, metric.digits)}</span>
            <span className="text-xs text-tv-dim">{metric.unit}</span>
          </div>
        </div>
        {improving ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />}
      </div>
      {status !== "ok" && (
        <div className="mt-2 border-t border-current/20 pt-2 text-xs">
          {status === "critical" ? "Requiere atencion inmediata" : "Fuera del rango objetivo"}
        </div>
      )}
    </div>
  );
}

function AnimalQualityCard({ animal, lactation }: { animal: Animal; lactation?: Lactation }) {
  const score = qualityScore(lactation);
  const hasWarning = score > 0 && score < 85;

  return (
    <div className="space-y-4 rounded-lg border border-tv-border bg-tv-surface p-4">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <span className="font-mono text-sm font-bold text-tv-accent">{animal.crotal_oficial}</span>
          {animal.nombre && <span className="ml-2 text-sm text-tv-dim">{animal.nombre}</span>}
          <p className="mt-1 text-xs text-tv-dim">
            {animal.raza} - {lactation ? `${lactation.dias_transcurridos ?? 0} dias en leche` : "sin lactacion activa"}
          </p>
        </div>
        <div className="shrink-0 text-center">
          <div className={`flex h-14 w-14 items-center justify-center rounded-full font-heading text-xl font-bold ${
            score >= 85 ? "bg-state-ok/15 text-state-ok" : "bg-state-atencion/15 text-state-atencion"
          }`}>
            {score || "-"}
          </div>
          <p className="mt-1 text-[10px] font-bold text-tv-dim">Score</p>
        </div>
      </div>
      {hasWarning && (
        <div className="flex items-center gap-2 rounded-lg bg-state-atencion/15 px-3 py-2 text-xs font-semibold text-state-atencion">
          <AlertTriangle className="h-3.5 w-3.5" />
          Revisar parametros de lactacion
        </div>
      )}
    </div>
  );
}

export default function QualityPage() {
  const [showComposition, setShowComposition] = useState(true);
  const [selectedMetric, setSelectedMetric] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const pageSize = DEFAULT_PAGE_SIZE;

  const animalsQuery = useQuery({
    queryKey: ["animals-produccion-quality", page],
    queryFn: () =>
      api.animals({
        estado: "produccion",
        skip: getSkip(page, pageSize),
        limit: pageSize + 1,
      }),
    staleTime: 60_000,
  });

  const allProductionAnimals = useQuery({
    queryKey: ["animals-produccion-quality-all"],
    queryFn: () => api.animals({ estado: "produccion", limit: 500 }),
    staleTime: 60_000,
  });

  const lactationsQuery = useQuery({
    queryKey: ["quality-lactations-active"],
    queryFn: () => api.lactations({ activa: true, limit: 500 }),
    staleTime: 60_000,
  });

  const summaryQuery = useQuery({
    queryKey: ["quality-summary"],
    queryFn: api.qualitySummary,
    staleTime: 60_000,
  });

  const fetched = animalsQuery.data ?? [];
  const hasNext = fetched.length > pageSize;
  const list = fetched.slice(0, pageSize);

  const lactationByAnimal = useMemo(() => {
    const map = new Map<string, Lactation>();
    for (const lactation of lactationsQuery.data ?? []) {
      if (!map.has(lactation.animal_id)) map.set(lactation.animal_id, lactation);
    }
    return map;
  }, [lactationsQuery.data]);

  const activeLactations = lactationsQuery.data ?? [];
  const scores = activeLactations.map((lactation) => qualityScore(lactation)).filter((score) => score > 0);
  const avgQuality = scores.length > 0 ? Math.round(scores.reduce((sum, score) => sum + score, 0) / scores.length) : 0;
  const warningLactations = activeLactations.filter((lactation) => (lactation.rcs_promedio ?? 0) >= 250000);
  const criticalLactations = activeLactations.filter((lactation) => (lactation.rcs_promedio ?? 0) >= 400000);
  const trend = activeLactations
    .filter((lactation) => lactation.produccion_promedio != null)
    .slice(0, 10)
    .reverse()
    .map((lactation, index) => ({
      label: lactation.fecha_inicio?.slice(5, 10) ?? String(index + 1),
      value: Number(lactation.produccion_promedio),
    }));

  return (
    <div className="min-h-full">
      <div className="border-b border-tv-border px-6 py-5 lg:px-8">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
              <Droplets className="h-4 w-4 text-tv-accent" />
              Leche a la carta
            </div>
            <h1 className="mt-1 font-heading text-2xl font-bold text-white">Calidad de leche</h1>
          </div>
          <span className="rounded-full border border-tv-border bg-tv-surface px-3 py-1.5 text-sm font-bold text-white">
            {summaryQuery.data?.animales_en_control ?? activeLactations.length} animales en control
          </span>
        </div>
      </div>

      <div className="space-y-6 px-6 py-6 lg:px-8">
        {!animalsQuery.isLoading && !lactationsQuery.isLoading && (
          <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
            {[
              { label: "Calidad media", value: avgQuality, sub: "puntuacion", color: "text-tv-accent", Icon: Target },
              { label: "RCS vigilancia", value: warningLactations.length, sub: "lactaciones", color: "text-state-atencion", Icon: AlertTriangle },
              { label: "RCS critico", value: criticalLactations.length, sub: "lactaciones", color: "text-state-critica", Icon: AlertTriangle },
              {
                label: "Produccion media",
                value: formatNumber(summaryQuery.data?.produccion_promedio, 1),
                sub: "L/dia",
                color: "text-state-ok",
                Icon: Droplets,
              },
            ].map(({ label, value, sub, color, Icon }) => (
              <div key={label} className="rounded-lg border border-tv-border bg-tv-surface p-4">
                <div className="flex items-center gap-2">
                  <Icon className={`h-4 w-4 ${color}`} />
                  <span className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-tv-dim">{label}</span>
                </div>
                <div className={`mt-2 font-heading text-4xl font-bold ${color}`}>{value}</div>
                <div className="mt-1 text-xs font-semibold text-tv-dim">{sub}</div>
              </div>
            ))}
          </div>
        )}

        {!animalsQuery.isLoading && !lactationsQuery.isLoading && list.length > 0 && (
          <div className="grid gap-4 xl:grid-cols-[1.4fr_280px]">
            <div className="rounded-lg border border-tv-border bg-tv-surface p-5">
              <div className="mb-4 text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
                Evolucion de produccion por lactacion
              </div>
              <div className="h-28">
                {trend.length >= 2 ? (
                  <SparkArea color="#35E479" data={trend} />
                ) : (
                  <div className="grid h-full place-items-center rounded-lg border border-dashed border-tv-border text-sm font-semibold text-tv-dim">
                    Sin datos suficientes
                  </div>
                )}
              </div>
            </div>
            <div className="rounded-lg border border-tv-border bg-tv-surface p-5">
              <DonutStat value={avgQuality} label="calidad" />
            </div>
          </div>
        )}

        <div className="flex flex-wrap items-center gap-3">
          <div className="flex gap-2">
            {[
              { key: "composition", label: "Composicion" },
              { key: "quality", label: "Indicadores" },
            ].map(({ key, label }) => (
              <button
                key={key}
                type="button"
                onClick={() => setShowComposition(key === "composition")}
                className={`rounded-lg px-4 py-2 text-sm font-semibold transition ${
                  (key === "composition" && showComposition) || (key === "quality" && !showComposition)
                    ? "bg-tv-surface2 text-tv-accent"
                    : "bg-tv-surface text-tv-dim hover:bg-tv-surface2"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          {!showComposition && (
            <div className="ml-auto flex flex-wrap gap-2">
              {qualityIndicators.map(({ key, label }) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => setSelectedMetric(selectedMetric === key ? null : key)}
                  className={`rounded-lg px-3 py-2 text-xs font-bold transition ${
                    selectedMetric === key
                      ? "bg-tv-accent/20 text-tv-accent"
                      : "bg-tv-surface text-tv-dim hover:bg-tv-surface2"
                  }`}
                >
                  <Filter className="mr-1 inline h-3 w-3" />
                  {label}
                </button>
              ))}
            </div>
          )}
        </div>

        {animalsQuery.isLoading || lactationsQuery.isLoading ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {Array.from({ length: 6 }).map((_, index) => (
              <div key={index} className="h-64 animate-pulse rounded-lg bg-tv-surface" />
            ))}
          </div>
        ) : (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {list.map((animal) => {
              const lactation = lactationByAnimal.get(animal.id);
              return (
                <div key={animal.id} className="space-y-3">
                  <AnimalQualityCard animal={animal} lactation={lactation} />
                  {showComposition ? (
                    <div className="grid grid-cols-2 gap-2">
                      {compositionMetrics.map((metric) => (
                        <CompositionCard key={metric.key} lactation={lactation} metric={metric} />
                      ))}
                    </div>
                  ) : (
                    <div className="grid grid-cols-2 gap-2">
                      {qualityIndicators
                        .filter((metric) => !selectedMetric || metric.key === selectedMetric)
                        .map((metric) => (
                          <QualityMetricCard key={metric.key} lactation={lactation} metric={metric} />
                        ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {!animalsQuery.isLoading && !lactationsQuery.isLoading && list.length === 0 && (
          <div className="rounded-lg border border-tv-border bg-tv-surface py-16 text-center">
            <Droplets className="mx-auto h-12 w-12 text-tv-dim" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-white">Sin datos de calidad disponibles</p>
            <p className="mt-1 text-sm text-tv-dim">
              Hay {allProductionAnimals.data?.length ?? 0} animales en produccion registrados.
            </p>
          </div>
        )}

        {!animalsQuery.isLoading && list.length > 0 && (
          <Pagination
            page={page}
            pageSize={pageSize}
            currentCount={list.length}
            hasNext={hasNext}
            isLoading={animalsQuery.isFetching}
            onPageChange={setPage}
          />
        )}
      </div>
    </div>
  );
}
