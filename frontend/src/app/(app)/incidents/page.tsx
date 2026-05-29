"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertOctagon,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Loader2,
  Plus,
  Siren,
  X,
} from "lucide-react";
import { useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useToast } from "@/components/ui/toast";
import { PageHeader } from "@/components/ui/page-header";
import { api } from "@/lib/api";
import type {
  CreateIncidentPayload,
  Incident,
  IncidentPriority,
  IncidentStatus,
} from "@/lib/types";

// â"€â"€ Constants â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€

const INCIDENT_TYPES = [
  "averia_maquinaria",
  "infraestructura",
  "sanidad_animal",
  "calidad_leche",
  "alimentacion",
  "pedidos",
];

const STATUS_LABELS: Record<IncidentStatus, string> = {
  abierta: "Abierta",
  en_gestion: "En gestion",
  resuelta: "Resuelta",
  cerrada: "Cerrada",
};

const STATUS_STYLES: Record<IncidentStatus, string> = {
  abierta: "bg-state-critica/15 text-state-critica border-state-critica/30",
  en_gestion: "bg-state-atencion/15 text-state-atencion border-state-atencion/30",
  resuelta: "bg-state-ok/15 text-state-ok border-state-ok/30",
  cerrada: "bg-state-neutral/10 text-state-neutral border-state-neutral/20",
};

const PRIORITY_STYLES: Record<IncidentPriority, string> = {
  critica: "bg-state-critica/15 text-state-critica",
  alta: "bg-state-atencion/15 text-state-atencion",
  media: "bg-state-info/15 text-state-info",
  baja: "bg-state-neutral/10 text-state-neutral",
};

const PAGE_SIZE = 15;

// â"€â"€ Helpers â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€

function formatDate(iso?: string | null) {
  if (!iso) return "\u2014";
  return new Date(iso).toLocaleString("es-ES", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

// â"€â"€ Sub-components â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€

function StatusBadge({ estado }: { estado: IncidentStatus }) {
  return (
    <span className={`inline-flex rounded-full border px-2.5 py-0.5 text-[11px] font-extrabold uppercase ${STATUS_STYLES[estado]}`}>
      {STATUS_LABELS[estado]}
    </span>
  );
}

function PriorityBadge({ prioridad }: { prioridad: IncidentPriority }) {
  return (
    <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold uppercase ${PRIORITY_STYLES[prioridad]}`}>
      {prioridad}
    </span>
  );
}

function KpiCard({
  label,
  value,
  tone,
}: {
  label: string;
  value: number;
  tone: string;
}) {
  return (
    <div className="rounded-[10px] border border-app-border bg-white shadow-card p-4">
      <p className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-app-dim">{label}</p>
      <p className={`mt-2 font-heading text-4xl font-bold ${tone}`}>{value}</p>
    </div>
  );
}

// â"€â"€ Create incident modal â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€

function CreateIncidentModal({
  zones,
  onClose,
}: {
  zones: { id: string; nombre: string }[];
  onClose: () => void;
}) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const [tipo, setTipo] = useState(INCIDENT_TYPES[0]);
  const [descripcion, setDescripcion] = useState("");
  const [prioridad, setPrioridad] = useState<IncidentPriority>("media");
  const [zonaId, setZonaId] = useState("");

  const mutation = useMutation({
    mutationFn: (payload: CreateIncidentPayload) => api.createIncident(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["incidents"] });
      toast.success("Incidencia registrada");
      onClose();
    },
  });

  const priorities: { value: IncidentPriority; label: string; cls: string }[] = [
    { value: "critica", label: "Critica", cls: "border-state-critica text-state-critica bg-state-critica/10" },
    { value: "alta", label: "Alta", cls: "border-state-atencion text-state-atencion bg-state-atencion/10" },
    { value: "media", label: "Media", cls: "border-state-info text-state-info bg-state-info/10" },
    { value: "baja", label: "Baja", cls: "border-app-dim text-app-dim bg-app-bg" },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 sm:items-center">
      <div className="w-full max-w-lg rounded-t-[20px] border border-app-border bg-white shadow-panel sm:rounded-[14px]">
        <div className="flex items-center justify-between border-b border-app-border px-6 py-4">
          <h2 className="font-heading text-lg font-bold text-app-text">Nueva incidencia</h2>
          <button type="button" onClick={onClose} className="text-app-dim hover:text-app-text">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 px-6 py-5">
          {/* Prioridad */}
          <div>
            <p className="mb-2 text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">Prioridad</p>
            <div className="grid grid-cols-4 gap-2">
              {priorities.map(({ value, label, cls }) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setPrioridad(value)}
                  className={`rounded-[10px] border-2 py-2 text-xs font-bold transition ${prioridad === value ? cls : "border-app-border text-app-dim hover:border-app-dim"}`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Tipo */}
          <div>
            <label className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Tipo
            </label>
            <select
              value={tipo}
              onChange={(e) => setTipo(e.target.value)}
              className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none focus:border-brand"
            >
              {INCIDENT_TYPES.map((t) => (
                <option key={t} value={t}>{t.replace(/_/g, " ")}</option>
              ))}
            </select>
          </div>

          {/* Zona (opcional) */}
          <div>
            <label className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Zona (opcional)
            </label>
            <select
              value={zonaId}
              onChange={(e) => setZonaId(e.target.value)}
              className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none focus:border-brand"
            >
              <option value="">Sin zona asignada</option>
              {zones.map((z) => (
                <option key={z.id} value={z.id}>{z.nombre}</option>
              ))}
            </select>
          </div>

          {/* DescripciÃ³n */}
          <div>
            <label className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Descripcion *
            </label>
            <textarea
              rows={3}
              value={descripcion}
              onChange={(e) => setDescripcion(e.target.value)}
              placeholder="Describe la incidencia con detalle"
              className="w-full resize-none rounded-[10px] border border-app-border bg-white px-3 py-2.5 text-sm text-app-text outline-none placeholder:text-app-dim focus:border-brand"
            />
          </div>

          {mutation.isError && (
            <p className="rounded-[10px] bg-state-critica/10 px-3 py-2 text-sm text-state-critica">
              {mutation.error.message}
            </p>
          )}

          <button
            type="button"
            disabled={!tipo || !descripcion.trim() || mutation.isPending}
            onClick={() =>
              mutation.mutate({
                tipo,
                descripcion,
                prioridad,
                zona_id: zonaId || null,
              })
            }
            className="w-full rounded-[10px] bg-brand py-3.5 font-heading text-base font-bold text-white shadow-brand transition hover:bg-[#135532] disabled:opacity-50"
          >
            {mutation.isPending ? "Registrando..." : "Registrar incidencia"}
          </button>
        </div>
      </div>
    </div>
  );
}

// â"€â"€ Incident card â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€

function IncidentCard({
  incident,
  onStatusChange,
  updatingId,
  animalLookup,
  zoneLookup,
}: {
  incident: Incident;
  onStatusChange: (id: string, estado: IncidentStatus) => void;
  updatingId: string | null;
  animalLookup: Map<string, string>;
  zoneLookup: Map<string, string>;
}) {
  const [expanded, setExpanded] = useState(false);
  const isUpdating = updatingId === incident.id;

  const nextStatuses: Partial<Record<IncidentStatus, IncidentStatus[]>> = {
    abierta: ["en_gestion", "resuelta"],
    en_gestion: ["resuelta"],
    resuelta: ["cerrada"],
  };
  const available = nextStatuses[incident.estado] ?? [];

  const statusBtnStyle: Record<IncidentStatus, string> = {
    en_gestion: "bg-state-atencion/15 text-state-atencion hover:bg-state-atencion/25",
    resuelta: "bg-state-ok/15 text-state-ok hover:bg-state-ok/25",
    cerrada: "bg-state-neutral/10 text-state-neutral hover:bg-state-neutral/20",
    abierta: "",
  };

  return (
    <div className="rounded-[10px] border border-app-border bg-white">
      <button
        type="button"
        className="w-full px-4 py-4 text-left"
        onClick={() => setExpanded((v) => !v)}
      >
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <StatusBadge estado={incident.estado} />
              <PriorityBadge prioridad={incident.prioridad} />
              <span className="text-xs text-app-dim capitalize">{incident.tipo.replace(/_/g, " ")}</span>
              <span className="text-xs text-app-dim">{formatDate(incident.fecha_creacion)}</span>
            </div>
            <p className="mt-2 text-sm font-semibold leading-snug text-app-text">
              {incident.descripcion}
            </p>
          </div>
          {expanded ? (
            <ChevronUp className="mt-1 h-4 w-4 shrink-0 text-app-dim" />
          ) : (
            <ChevronDown className="mt-1 h-4 w-4 shrink-0 text-app-dim" />
          )}
        </div>
      </button>

      {expanded && (
        <div className="space-y-3 border-t border-app-border px-4 py-4">
          <div className="flex flex-wrap gap-4 text-xs text-app-dim">
            {incident.zona_id && (
              <span>
                Zona:{" "}
                <span className="font-semibold text-app-text">
                  {zoneLookup.get(incident.zona_id) ?? incident.zona_id.slice(0, 8) + "\u2026"}
                </span>
              </span>
            )}
            {incident.animal_id && (
              <span>
                Animal:{" "}
                <span className="font-mono font-bold text-brand">
                  {animalLookup.get(incident.animal_id) ?? incident.animal_id.slice(0, 8) + "\u2026"}
                </span>
              </span>
            )}
            {incident.reportado_por && (
              <span>
                Reportado por:{" "}
                <span className="font-semibold text-app-text">{incident.reportado_por.slice(0, 8)}\u2026</span>
              </span>
            )}
            {incident.fecha_resolucion && (
              <span>
                Resuelto: <span className="text-app-text">{formatDate(incident.fecha_resolucion)}</span>
              </span>
            )}
          </div>

          {available.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {available.map((next) => (
                <button
                  key={next}
                  type="button"
                  disabled={isUpdating}
                  onClick={() => onStatusChange(incident.id, next)}
                  className={`inline-flex items-center gap-1.5 rounded-[10px] px-3 py-2 text-xs font-bold transition disabled:opacity-50 ${statusBtnStyle[next]}`}
                >
                  {isUpdating ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  ) : (
                    <CheckCircle2 className="h-3.5 w-3.5" />
                  )}
                  Marcar como {STATUS_LABELS[next].toLowerCase()}
                </button>
              ))}
            </div>
          )}

          {incident.estado === "cerrada" && (
            <div className="rounded-[10px] bg-state-neutral/10 px-3 py-2 text-xs font-bold text-state-neutral">
              Incidencia cerrada
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// â"€â"€ Main page â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€

type FilterEstado = IncidentStatus | "todas";
type FilterPrioridad = IncidentPriority | "todas";

export default function IncidentsPage() {
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const toast = useToast();
  const [estadoFilter, setEstadoFilter] = useState<FilterEstado>("todas");
  const [prioridadFilter, setPrioridadFilter] = useState<FilterPrioridad>("todas");
  const [page, setPage] = useState(1);
  // Auto-open creation modal when ?new=1 is in the URL
  const [showCreate, setShowCreate] = useState(() => searchParams.get("new") === "1");
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  // Load all incidents for client-side filtering (endpoint has no server-side filter support)
  const incidentsQuery = useQuery({
    queryKey: ["incidents"],
    queryFn: () => api.incidents({ limit: 200 }),
    staleTime: 30_000,
    refetchInterval: 60_000,
  });

  const zonesQuery = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: 5 * 60_000,
  });

  const animalsLookupQuery = useQuery({
    queryKey: ["animals-lookup"],
    queryFn: () => api.animals({ limit: 500 }),
    staleTime: 5 * 60_000,
  });

  const animalLookup = useMemo(() => {
    const map = new Map<string, string>();
    for (const a of animalsLookupQuery.data ?? []) {
      map.set(a.id, a.crotal_oficial + (a.nombre ? ` Â· ${a.nombre}` : ""));
    }
    return map;
  }, [animalsLookupQuery.data]);

  const zoneLookup = useMemo(() => {
    const map = new Map<string, string>();
    for (const z of zonesQuery.data ?? []) {
      map.set(z.id, z.nombre);
    }
    return map;
  }, [zonesQuery.data]);

  const updateMutation = useMutation({
    mutationFn: ({ id, estado }: { id: string; estado: IncidentStatus }) =>
      api.updateIncident(id, { estado }),
    onMutate: ({ id }) => setUpdatingId(id),
    onSettled: () => {
      setUpdatingId(null);
      queryClient.invalidateQueries({ queryKey: ["incidents"] });
    },
  });

  const all = incidentsQuery.data ?? [];

  // Client-side filtering
  const filtered = useMemo(() => {
    return all.filter((i) => {
      if (estadoFilter !== "todas" && i.estado !== estadoFilter) return false;
      if (prioridadFilter !== "todas" && i.prioridad !== prioridadFilter) return false;
      return true;
    });
  }, [all, estadoFilter, prioridadFilter]);

  // KPIs from all incidents (regardless of filter)
  const stats = useMemo(() => ({
    total: all.length,
    abiertas: all.filter((i) => i.estado === "abierta").length,
    en_gestion: all.filter((i) => i.estado === "en_gestion").length,
    resueltas: all.filter((i) => i.estado === "resuelta" || i.estado === "cerrada").length,
    criticas: all.filter((i) => i.prioridad === "critica").length,
    altas: all.filter((i) => i.prioridad === "alta").length,
  }), [all]);

  // Client-side pagination
  const pageItems = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const totalPages = Math.ceil(filtered.length / PAGE_SIZE);

  function resetFilters() {
    setEstadoFilter("todas");
    setPrioridadFilter("todas");
    setPage(1);
  }

  const estadoTabs: { key: FilterEstado; label: string }[] = [
    { key: "todas", label: "Todas" },
    { key: "abierta", label: "Abiertas" },
    { key: "en_gestion", label: "En gestion" },
    { key: "resuelta", label: "Resueltas" },
    { key: "cerrada", label: "Cerradas" },
  ];

  return (
    <div className="min-h-full">
      {showCreate && (
        <CreateIncidentModal
          zones={zonesQuery.data ?? []}
          onClose={() => setShowCreate(false)}
        />
      )}

      <PageHeader eyebrow="Seguimiento operativo" title="Incidencias" EyebrowIcon={AlertOctagon}>
        <div className="flex items-center gap-3">
          {incidentsQuery.data && (
            <span className="rounded-full border border-app-border bg-white px-3 py-1.5 text-sm font-bold text-app-text">
              {filtered.length} incidencias
            </span>
          )}
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            className="inline-flex items-center gap-2 rounded-[10px] bg-brand px-4 py-2 text-sm font-bold text-white shadow-brand transition hover:bg-[#135532]"
          >
            <Plus className="h-4 w-4" />
            Nueva
          </button>
        </div>
      </PageHeader>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        {/* KPIs */}
        {incidentsQuery.isSuccess && (
          <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
            <KpiCard label="Total" value={stats.total} tone="text-app-text" />
            <KpiCard label="Abiertas" value={stats.abiertas} tone="text-state-critica" />
            <KpiCard label="En gestion" value={stats.en_gestion} tone="text-state-atencion" />
            <KpiCard label="Resueltas" value={stats.resueltas} tone="text-state-ok" />
            <KpiCard label="Criticas" value={stats.criticas} tone="text-state-critica" />
            <KpiCard label="Altas" value={stats.altas} tone="text-state-atencion" />
          </div>
        )}

        {/* Filters */}
        <div className="flex flex-wrap gap-2">
          <div className="flex flex-wrap gap-1">
            {estadoTabs.map(({ key, label }) => {
              const count = key === "todas" ? filtered.length : all.filter((i) => i.estado === key).length;
              return (
                <button
                  key={key}
                  type="button"
                  onClick={() => { setEstadoFilter(key); setPage(1); }}
                  className={`inline-flex items-center gap-1.5 rounded-[10px] px-3 py-2 text-sm font-semibold transition ${
                    estadoFilter === key
                      ? "bg-app-bg text-brand"
                      : "bg-white text-app-dim hover:bg-app-bg"
                  }`}
                >
                  {label}
                  <span className="rounded-full bg-app-bg/60 px-1.5 text-[11px] font-bold">{count}</span>
                </button>
              );
            })}
          </div>

          <select
            value={prioridadFilter}
            onChange={(e) => { setPrioridadFilter(e.target.value as FilterPrioridad); setPage(1); }}
            className="rounded-[10px] border border-app-border bg-white px-3 py-2 text-sm font-semibold text-app-text outline-none"
          >
            <option value="todas">Todas las prioridades</option>
            <option value="critica">Critica</option>
            <option value="alta">Alta</option>
            <option value="media">Media</option>
            <option value="baja">Baja</option>
          </select>

          {(estadoFilter !== "todas" || prioridadFilter !== "todas") && (
            <button
              type="button"
              onClick={resetFilters}
              className="rounded-[10px] border border-app-border bg-white px-3 py-2 text-sm font-semibold text-app-dim transition hover:text-app-text"
            >
              Limpiar filtros
            </button>
          )}
        </div>

        {/* Loading */}
        {incidentsQuery.isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-20 animate-pulse rounded-[10px] bg-app-bg" />
            ))}
          </div>
        )}

        {/* Error */}
        {incidentsQuery.isError && (
          <div className="rounded-[10px] border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar incidencias: {incidentsQuery.error.message}
          </div>
        )}

        {/* Empty */}
        {incidentsQuery.isSuccess && filtered.length === 0 && (
          <div className="rounded-[10px] border border-app-border bg-white py-16 text-center">
            <Siren className="mx-auto h-12 w-12 text-app-dim" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-app-text">Sin incidencias</p>
            <p className="mt-1 text-sm text-app-dim">
              {estadoFilter !== "todas" || prioridadFilter !== "todas"
                ? "Prueba a cambiar los filtros"
                : "No hay incidencias registradas"}
            </p>
          </div>
        )}

        {/* List */}
        <div className="space-y-3">
          {pageItems.map((incident) => (
            <IncidentCard
              key={incident.id}
              incident={incident}
              onStatusChange={(id, estado) => updateMutation.mutate({ id, estado })}
              updatingId={updatingId}
              animalLookup={animalLookup}
              zoneLookup={zoneLookup}
            />
          ))}
        </div>

        {/* Pagination */}
        {filtered.length > PAGE_SIZE && (
          <nav className="flex items-center justify-between rounded-[10px] border border-app-border bg-white px-4 py-3 text-sm text-app-dim">
            <span>
              Mostrando <strong className="text-app-text">{(page - 1) * PAGE_SIZE + 1}</strong>-
              <strong className="text-app-text">{Math.min(page * PAGE_SIZE, filtered.length)}</strong> de{" "}
              <strong className="text-app-text">{filtered.length}</strong>
            </span>
            <div className="flex items-center gap-2">
              <button
                type="button"
                disabled={page === 1}
                onClick={() => setPage((p) => p - 1)}
                className="rounded-[10px] border border-app-border bg-app-bg px-3 py-2 font-bold text-app-text transition hover:border-brand/60 disabled:opacity-40"
              >
                Anterior
              </button>
              <span className="rounded-[10px] bg-app-bg px-3 py-2 font-heading font-bold text-app-text">{page} / {totalPages}</span>
              <button
                type="button"
                disabled={page >= totalPages}
                onClick={() => setPage((p) => p + 1)}
                className="rounded-[10px] border border-app-border bg-app-bg px-3 py-2 font-bold text-app-text transition hover:border-brand/60 disabled:opacity-40"
              >
                Siguiente
              </button>
            </div>
          </nav>
        )}
      </div>
    </div>
  );
}
