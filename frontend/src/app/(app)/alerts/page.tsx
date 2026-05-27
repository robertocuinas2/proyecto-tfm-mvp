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
import { useState } from "react";
import { Pagination } from "@/components/common/Pagination";
import { api } from "@/lib/api";
import { DEFAULT_PAGE_SIZE, getSkip } from "@/lib/pagination";
import type { Alert, AlertSeverity, AlertState } from "@/lib/types";

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
    <div className="rounded-lg border border-tv-border bg-tv-surface p-4">
      <div className="flex items-center gap-2">
        <Icon className={`h-4 w-4 ${tone}`} />
        <span className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-tv-dim">
          {label}
        </span>
      </div>
      <div className={`mt-2 font-heading text-4xl font-bold ${tone}`}>{value}</div>
    </div>
  );
}

function AlertCard({
  alert,
  onAction,
  loading,
}: {
  alert: Alert;
  onAction: (id: string, estado: AlertState) => void;
  loading: boolean;
}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className={`rounded-lg border border-l-4 border-tv-border bg-tv-surface ${severityBar[alert.severidad]}`}>
      <button
        type="button"
        className="w-full px-4 py-4 text-left"
        onClick={() => setExpanded((value) => !value)}
      >
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <SeverityBadge severity={alert.severidad} />
              <span className="text-xs font-semibold capitalize text-tv-dim">
                {alert.tipo_alerta}
              </span>
              {alert.fecha_creacion && (
                <span className="text-xs text-tv-dim">
                  {new Date(alert.fecha_creacion).toLocaleString("es-ES", {
                    day: "2-digit",
                    month: "short",
                    hour: "2-digit",
                    minute: "2-digit",
                  })}
                </span>
              )}
            </div>
            <p className="mt-2 text-sm font-semibold leading-snug text-white">
              {alert.descripcion}
            </p>
          </div>
          <Eye className="mt-1 h-4 w-4 shrink-0 text-tv-dim" />
        </div>
      </button>

      {expanded && (
        <div className="space-y-3 border-t border-tv-border px-4 py-4">
          {alert.recomendacion && (
            <div className="rounded-lg bg-tv-surface2 px-4 py-3">
              <div className="text-[11px] font-extrabold uppercase tracking-[0.14em] text-tv-dim">
                Recomendacion
              </div>
              <p className="mt-1 text-sm text-white">{alert.recomendacion}</p>
            </div>
          )}

          <div className="flex flex-wrap gap-3 text-xs text-tv-dim">
            <span>
              Animal: <span className="font-mono text-white">{alert.animal_id}</span>
            </span>
            {alert.confianza_prediccion != null && (
              <span>
                Confianza:{" "}
                <span className="font-bold text-white">
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
                className="inline-flex items-center gap-1.5 rounded-lg bg-state-info/15 px-3 py-2 text-xs font-bold text-state-info transition hover:bg-state-info/25 disabled:opacity-50"
              >
                <Eye className="h-3.5 w-3.5" />
                Revisada
              </button>
              <button
                type="button"
                disabled={loading}
                onClick={() => onAction(alert.id, "resuelta")}
                className="inline-flex items-center gap-1.5 rounded-lg bg-state-ok/15 px-3 py-2 text-xs font-bold text-state-ok transition hover:bg-state-ok/25 disabled:opacity-50"
              >
                <CheckCircle2 className="h-3.5 w-3.5" />
                Resolver
              </button>
              <button
                type="button"
                disabled={loading}
                onClick={() => onAction(alert.id, "falsa_alarma")}
                className="inline-flex items-center gap-1.5 rounded-lg bg-state-neutral/10 px-3 py-2 text-xs font-bold text-state-neutral transition hover:bg-state-neutral/20 disabled:opacity-50"
              >
                <XCircle className="h-3.5 w-3.5" />
                Falsa alarma
              </button>
            </div>
          ) : (
            <div className="rounded-lg bg-state-ok/10 px-3 py-2 text-xs font-bold capitalize text-state-ok">
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
  const [filter, setFilter] = useState<FilterSeverity>("todas");
  const [page, setPage] = useState(1);
  const pageSize = DEFAULT_PAGE_SIZE;

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
      <div className="border-b border-tv-border px-6 py-5 lg:px-8">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
              <Siren className="h-4 w-4 text-state-critica" />
              Monitor sanitario y operativo
            </div>
            <h1 className="mt-1 font-heading text-2xl font-bold text-white">Alertas</h1>
          </div>
          {alertsQuery.data && (
            <span className="rounded-full border border-state-critica/30 bg-state-critica/10 px-3 py-1.5 text-sm font-bold text-state-critica">
              {counts.todas} alertas registradas
            </span>
          )}
        </div>
      </div>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        <div className="grid gap-3 md:grid-cols-3">
          <StatCard Icon={AlertTriangle} label="Criticas" value={counts.critica} tone="text-state-critica" />
          <StatCard Icon={ShieldCheck} label="Altas" value={counts.alta} tone="text-state-atencion" />
          <StatCard Icon={CheckCircle2} label="Total" value={counts.todas} tone="text-tv-accent" />
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
              className={`inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold transition ${
                filter === key
                  ? "bg-tv-surface2 text-tv-accent"
                  : "bg-tv-surface text-tv-dim hover:bg-tv-surface2 hover:text-white"
              }`}
            >
              {label}
              <span className="rounded-full bg-tv-bg/60 px-1.5 text-[11px] font-bold">
                {counts[key]}
              </span>
            </button>
          ))}
        </div>

        {alertsQuery.isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, index) => (
              <div key={index} className="h-24 animate-pulse rounded-lg bg-tv-surface" />
            ))}
          </div>
        )}

        {alertsQuery.isError && (
          <div className="rounded-lg border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar alertas.
          </div>
        )}

        {!alertsQuery.isLoading && allAlerts.length === 0 && (
          <div className="rounded-lg border border-tv-border bg-tv-surface py-16 text-center">
            <CheckCircle2 className="mx-auto h-12 w-12 text-tv-accent" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-white">Sin alertas pendientes</p>
            <p className="mt-1 text-sm text-tv-dim">La explotacion esta bajo control.</p>
          </div>
        )}

        <div className="space-y-3">
          {allAlerts.map((alert) => (
            <AlertCard
              key={alert.id}
              alert={alert}
              onAction={(id, estado) => updateMutation.mutate({ id, estado })}
              loading={updateMutation.isPending}
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
