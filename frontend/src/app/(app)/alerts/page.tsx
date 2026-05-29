"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertTriangle,
  CheckCircle2,
  Eye,
  ShieldCheck,
  Siren,
  XCircle,
} from "lucide-react";
import { useMemo, useState } from "react";
import { useToast } from "@/components/ui/toast";
import { Pagination } from "@/components/common/Pagination";
import { PageHeader } from "@/components/ui/page-header";
import { api } from "@/lib/api";
import { DEFAULT_PAGE_SIZE, getSkip } from "@/lib/pagination";
import type { Alert, AlertSeverity, AlertState, Animal } from "@/lib/types";

type FilterSeverity = AlertSeverity | "todas";

const severityLabels: Record<AlertSeverity, string> = {
  critica: "Critica",
  alta: "Alta",
  media: "Media",
  baja: "Baja",
};

const severityStyles: Record<AlertSeverity, string> = {
  critica: "border-state-critica/35 bg-state-critica/15 text-state-critica",
  alta: "border-state-atencion/35 bg-state-atencion/15 text-state-atencion",
  media: "border-state-info/35 bg-state-info/15 text-state-info",
  baja: "border-state-neutral/30 bg-state-neutral/10 text-state-neutral",
};

const severityBar: Record<AlertSeverity, string> = {
  critica: "border-l-state-critica",
  alta: "border-l-state-atencion",
  media: "border-l-state-info",
  baja: "border-l-state-neutral",
};

function SeverityBadge({ severity }: { severity: AlertSeverity }) {
  return (
    <span className={`inline-flex rounded-full border px-2.5 py-0.5 text-[11px] font-extrabold uppercase ${severityStyles[severity]}`}>
      {severityLabels[severity]}
    </span>
  );
}

function StatCard({
  label,
  value,
  tone,
  Icon,
}: {
  label: string;
  value: number;
  tone: string;
  Icon: typeof AlertTriangle;
}) {
  return (
    <div className="rounded-[10px] border border-app-border bg-white p-4 shadow-card">
      <div className="flex items-center gap-2">
        <Icon className={`h-4 w-4 ${tone}`} />
        <span className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-app-dim">
          {label}
        </span>
      </div>
      <div className={`mt-2 font-heading text-4xl font-bold ${tone}`}>{value}</div>
    </div>
  );
}

type AnimalLookup = Map<string, Pick<Animal, "crotal_oficial" | "nombre">>;

function AnimalRef({ animalId, lookup }: { animalId: string; lookup: AnimalLookup }) {
  const animal = lookup.get(animalId);
  if (!animal) {
    return <span className="font-mono text-app-text" title={animalId}>Animal ({animalId.slice(0, 8)}…)</span>;
  }
  return (
    <span>
      <span className="font-mono font-bold text-brand">{animal.crotal_oficial}</span>
      {animal.nombre && <span className="ml-1 text-app-dim">{animal.nombre}</span>}
    </span>
  );
}

function AlertCard({
  alert,
  onAction,
  loading,
  animalLookup,
}: {
  alert: Alert;
  onAction: (id: string, estado: AlertState) => void;
  loading: boolean;
  animalLookup: AnimalLookup;
}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className={`rounded-[10px] border border-l-4 border-app-border bg-white shadow-card ${severityBar[alert.severidad]}`}>
      <button
        type="button"
        className="w-full px-4 py-4 text-left"
        onClick={() => setExpanded((value) => !value)}
      >
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <SeverityBadge severity={alert.severidad} />
              <span className="text-xs font-semibold capitalize text-app-dim">
                {alert.tipo_alerta}
              </span>
              {alert.fecha_creacion && (
                <span className="text-xs text-app-dim">
                  {new Date(alert.fecha_creacion).toLocaleString("es-ES", {
                    day: "2-digit",
                    month: "short",
                    hour: "2-digit",
                    minute: "2-digit",
                  })}
                </span>
              )}
            </div>
            <p className="mt-2 text-sm font-semibold leading-snug text-app-text">
              {alert.descripcion}
            </p>
          </div>
          <Eye className="mt-1 h-4 w-4 shrink-0 text-app-dim" />
        </div>
      </button>

      {expanded && (
        <div className="space-y-3 border-t border-app-border px-4 py-4">
          {alert.recomendacion && (
            <div className="rounded-[10px] bg-app-bg px-4 py-3">
              <div className="text-[11px] font-extrabold uppercase tracking-[0.14em] text-app-dim">
                Recomendacion
              </div>
              <p className="mt-1 text-sm text-app-text">{alert.recomendacion}</p>
            </div>
          )}

          <div className="flex flex-wrap gap-3 text-xs text-app-dim">
            <span>
              Animal: <AnimalRef animalId={alert.animal_id} lookup={animalLookup} />
            </span>
            {alert.confianza_prediccion != null && (
              <span>
                Confianza:{" "}
                <span className="font-bold text-app-text">
                  {Math.round(alert.confianza_prediccion * 100)}%
                </span>
              </span>
            )}
          </div>

          {alert.estado === "pendiente" ? (
            <div className="flex flex-wrap gap-2 pt-1">
              <button
                type="button"
                disabled={loading}
                onClick={() => onAction(alert.id, "revisada")}
                className="inline-flex items-center gap-1.5 rounded-[10px] bg-state-info/15 px-3 py-2 text-xs font-bold text-state-info transition hover:bg-state-info/25 disabled:opacity-50"
              >
                <Eye className="h-3.5 w-3.5" />
                Revisada
              </button>
              <button
                type="button"
                disabled={loading}
                onClick={() => onAction(alert.id, "resuelta")}
                className="inline-flex items-center gap-1.5 rounded-[10px] bg-state-ok/15 px-3 py-2 text-xs font-bold text-state-ok transition hover:bg-state-ok/25 disabled:opacity-50"
              >
                <CheckCircle2 className="h-3.5 w-3.5" />
                Resolver
              </button>
              <button
                type="button"
                disabled={loading}
                onClick={() => onAction(alert.id, "falsa_alarma")}
                className="inline-flex items-center gap-1.5 rounded-[10px] bg-state-neutral/10 px-3 py-2 text-xs font-bold text-state-neutral transition hover:bg-state-neutral/20 disabled:opacity-50"
              >
                <XCircle className="h-3.5 w-3.5" />
                Falsa alarma
              </button>
            </div>
          ) : (
            <div className="rounded-[10px] bg-state-ok/10 px-3 py-2 text-xs font-bold capitalize text-state-ok">
              Estado: {alert.estado.replace("_", " ")}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default function AlertsPage() {
  const queryClient = useQueryClient();
  const toast = useToast();
  const [filter, setFilter] = useState<FilterSeverity>("todas");
  const [page, setPage] = useState(1);
  const pageSize = DEFAULT_PAGE_SIZE;

  // Carga animales en segundo plano para resolver animal_id → crotal/nombre en las alertas.
  // staleTime largo para no saturar el backend; se comparte con otras páginas que usen la misma queryKey.
  const animalsLookupQuery = useQuery({
    queryKey: ["animals-lookup"],
    queryFn: () => api.animals({ limit: 500 }),
    staleTime: 5 * 60_000,
    gcTime: 30 * 60_000,
  });

  const animalLookup = useMemo<AnimalLookup>(() => {
    const map: AnimalLookup = new Map();
    for (const a of animalsLookupQuery.data ?? []) {
      map.set(a.id, { crotal_oficial: a.crotal_oficial, nombre: a.nombre ?? null });
    }
    return map;
  }, [animalsLookupQuery.data]);

  const alertsQuery = useQuery({
    queryKey: ["alerts", filter, page],
    queryFn: () =>
      api.alerts({
        skip: getSkip(page, pageSize),
        limit: pageSize,
        ...(filter !== "todas" ? { severidad: filter } : {}),
      }),
    refetchInterval: 30_000,
  });

  const alertsStatsQuery = useQuery({
    queryKey: ["alerts-all"],
    queryFn: () => api.alerts({ limit: 500 }),
    refetchInterval: 30_000,
    staleTime: 10_000,
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, estado }: { id: string; estado: AlertState }) =>
      api.reviewAlert(id, { estado }),
    onSuccess: (_, { estado }) => {
      const label = estado === "resuelta" ? "Alerta resuelta" : estado === "revisada" ? "Alerta revisada" : "Alerta actualizada";
      toast.success(label);
    },
    onError: (err: Error) => {
      toast.error(err.message || "Error al actualizar la alerta");
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["alerts"] });
      queryClient.invalidateQueries({ queryKey: ["alerts-all"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-summary"] });
    },
  });

  const allAlerts = alertsQuery.data?.alertas ?? [];
  const globalAlerts = alertsStatsQuery.data?.alertas ?? allAlerts;
  const counts = {
    todas: alertsStatsQuery.data?.total ?? alertsQuery.data?.total ?? allAlerts.length,
    critica: globalAlerts.filter((alert) => alert.severidad === "critica").length,
    alta: globalAlerts.filter((alert) => alert.severidad === "alta").length,
    media: globalAlerts.filter((alert) => alert.severidad === "media").length,
    baja: globalAlerts.filter((alert) => alert.severidad === "baja").length,
  };

  const tabs: { key: FilterSeverity; label: string }[] = [
    { key: "todas", label: "Todas" },
    { key: "critica", label: "Criticas" },
    { key: "alta", label: "Altas" },
    { key: "media", label: "Medias" },
  ];

  return (
    <div className="min-h-full">
      <PageHeader eyebrow="Monitor sanitario y operativo" title="Alertas" EyebrowIcon={Siren}>
        {alertsQuery.data && (
          <span className="rounded-full border border-state-critica/30 bg-state-critica/10 px-3 py-1.5 text-sm font-bold text-state-critica">
            {counts.todas} alertas registradas
          </span>
        )}
      </PageHeader>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        <div className="grid gap-3 md:grid-cols-3">
          <StatCard Icon={AlertTriangle} label="Criticas" value={counts.critica} tone="text-state-critica" />
          <StatCard Icon={ShieldCheck} label="Altas" value={counts.alta} tone="text-state-atencion" />
          <StatCard Icon={CheckCircle2} label="Total" value={counts.todas} tone="text-brand" />
        </div>

        <div className="flex flex-wrap gap-2">
          {tabs.map(({ key, label }) => (
            <button
              key={key}
              type="button"
              onClick={() => {
                setFilter(key);
                setPage(1);
              }}
              className={`inline-flex items-center gap-2 rounded-[10px] px-4 py-2 text-sm font-semibold transition ${
                filter === key
                  ? "bg-brand/10 text-brand"
                  : "border border-app-border bg-white text-app-dim hover:bg-app-bg"
              }`}
            >
              {label}
              <span className="rounded-full bg-app-bg/60 px-1.5 text-[11px] font-bold">
                {counts[key]}
              </span>
            </button>
          ))}
        </div>

        {alertsQuery.isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, index) => (
              <div key={index} className="h-24 animate-pulse rounded-[10px] bg-app-surface2" />
            ))}
          </div>
        )}

        {alertsQuery.isError && (
          <div className="rounded-[10px] border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar alertas.
          </div>
        )}

        {!alertsQuery.isLoading && allAlerts.length === 0 && (
          <div className="rounded-[10px] border border-app-border bg-white py-16 text-center shadow-card">
            <CheckCircle2 className="mx-auto h-12 w-12 text-brand" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-app-text">Sin alertas pendientes</p>
            <p className="mt-1 text-sm text-app-dim">La explotacion esta bajo control.</p>
          </div>
        )}

        <div className="space-y-3">
          {allAlerts.map((alert) => (
            <AlertCard
              key={alert.id}
              alert={alert}
              onAction={(id, estado) => updateMutation.mutate({ id, estado })}
              loading={updateMutation.isPending}
              animalLookup={animalLookup}
            />
          ))}
        </div>

        {!alertsQuery.isLoading && allAlerts.length > 0 && (
          <Pagination
            page={page}
            pageSize={pageSize}
            currentCount={allAlerts.length}
            totalItems={alertsQuery.data?.total}
            isLoading={alertsQuery.isFetching}
            onPageChange={setPage}
          />
        )}
      </div>
    </div>
  );
}
