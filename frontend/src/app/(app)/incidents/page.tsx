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
import { api, normalizeAlert, normalizeIncident } from "@/lib/api";
import type {
  AlertState,
  CreateIncidentPayload,
  IncidentPriority,
  IncidentStatus,
  UnifiedEstado,
  UnifiedIncident,
  UnifiedIncidentOrigen,
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

const SEVERITY_STYLES: Record<string, string> = {
  critica: "bg-state-critica/15 text-state-critica",
  alta: "bg-state-atencion/15 text-state-atencion",
  media: "bg-state-info/15 text-state-info",
  baja: "bg-state-neutral/10 text-state-neutral",
};

const INCIDENT_ZONE_OPTIONS = [
  { label: "Boxes de terneros", codes: ["boxes_terneros", "becerrero"] },
  { label: "Zona de recria", codes: ["zona_recria", "recria"] },
  { label: "Patio de alimentacion", codes: ["patio_alimentacion", "silos", "almacen"] },
  { label: "Enfermeria", codes: ["enfermeria"] },
  { label: "Maquinaria", codes: ["maquinaria", "robots", "sala_ordeno", "oficina", "general"] },
];

function displayZoneName(codigo?: string | null, fallback?: string | null) {
  if (!codigo) return fallback ?? null;
  const option = INCIDENT_ZONE_OPTIONS.find((item) => item.codes.includes(codigo));
  return option?.label ?? fallback ?? codigo;
}

function incidentZoneOptions(zones: { id: string; nombre: string; codigo: string }[]) {
  return INCIDENT_ZONE_OPTIONS.map((option) => {
    const zone = zones.find((z) => option.codes.includes(z.codigo));
    return zone ? { id: zone.id, nombre: option.label } : null;
  }).filter((zone): zone is { id: string; nombre: string } => Boolean(zone));
}

function OrigenBadge({ origen }: { origen: UnifiedIncidentOrigen }) {
  void origen;
  return null;
}

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

function getNextStatuses(item: UnifiedIncident): UnifiedEstado[] {
  if (item.origen === "alerta") {
    if (item.estado === "abierta") return ["en_gestion", "resuelta"];
    if (item.estado === "en_gestion") return ["resuelta", "cerrada"];
    return [];
  }
  const machine: Partial<Record<UnifiedEstado, UnifiedEstado[]>> = {
    abierta: ["en_gestion", "resuelta"],
    en_gestion: ["resuelta"],
    resuelta: ["cerrada"],
  };
  return machine[item.estado] ?? [];
}

function UnifiedCard({
  item,
  onStatusChange,
  updatingId,
  animalLookup,
  zoneLookup,
}: {
  item: UnifiedIncident;
  onStatusChange: (item: UnifiedIncident, estado: UnifiedEstado) => void;
  updatingId: string | null;
  animalLookup: Map<string, string>;
  zoneLookup: Map<string, string>;
}) {
  const [expanded, setExpanded] = useState(false);
  const isUpdating = updatingId === item.id;
  const available = getNextStatuses(item);

  const statusBtnStyle: Record<UnifiedEstado, string> = {
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
              <StatusBadge estado={item.estado} />
              <span className={`rounded-full px-2 py-0.5 text-[11px] font-bold uppercase ${SEVERITY_STYLES[item.severidad]}`}>
                {item.severidad}
              </span>
              <OrigenBadge origen={item.origen} />
              <span className="text-xs text-app-dim">{formatDate(item.fecha_creacion)}</span>
            </div>
            <p className="mt-2 text-sm font-semibold leading-snug text-app-text">
              {item.titulo}
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
          <p className="text-sm text-app-text">{item.descripcion}</p>

          <div className="flex flex-wrap gap-4 text-xs text-app-dim">
            {item.zona_id && (
              <span>
                Zona:{" "}
                <span className="font-semibold text-app-text">
                  {zoneLookup.get(item.zona_id) ?? item.zona_id.slice(0, 8) + "\u2026"}
                </span>
              </span>
            )}
            {item.animal_id && (
              <span>
                Animal:{" "}
                <span className="font-mono font-bold text-brand">
                  {animalLookup.get(item.animal_id) ?? item.animal_id.slice(0, 8) + "\u2026"}
                </span>
              </span>
            )}
            {item.reportado_por && (
              <span>
                Reportado por:{" "}
                <span className="font-semibold text-app-text">{item.reportado_por.slice(0, 8)}\u2026</span>
              </span>
            )}
            {item.fecha_resolucion && (
              <span>
                Resuelto: <span className="text-app-text">{formatDate(item.fecha_resolucion)}</span>
              </span>
            )}
          </div>

          {item.recomendacion && (
            <div className="rounded-[10px] bg-brand/5 px-3 py-2 text-xs text-app-text">
              <span className="font-semibold">Recomendaci\u00f3n:</span> {item.recomendacion}
            </div>
          )}

          {available.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {available.map((next) => (
                <button
                  key={next}
                  type="button"
                  disabled={isUpdating}
                  onClick={() => onStatusChange(item, next)}
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

          {item.estado === "cerrada" && (
            <div className="rounded-[10px] bg-state-neutral/10 px-3 py-2 text-xs font-bold text-state-neutral">
              Registro cerrado
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// â"€â"€ Main page â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€

type FilterEstado = UnifiedEstado | "todas";
type FilterPrioridad = "baja" | "media" | "alta" | "critica" | "todas";

export default function IncidentsPage() {
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const toast = useToast();
  const [estadoFilter, setEstadoFilter] = useState<FilterEstado>("todas");
  const [prioridadFilter, setPrioridadFilter] = useState<FilterPrioridad>("todas");
  const [page, setPage] = useState(1);
  const [showCreate, setShowCreate] = useState(() => searchParams.get("new") === "1");
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const incidentsQuery = useQuery({
    queryKey: ["incidents", estadoFilter],
    queryFn: () => api.incidents({
      limit: 200,
      ...(estadoFilter !== "todas" ? { estado: estadoFilter } : {}),
    }),
    staleTime: 30_000,
    refetchInterval: 60_000,
  });

  const alertsQuery = useQuery({
    queryKey: ["alerts-unified"],
    queryFn: () => api.alerts({ limit: 200 }),
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
      map.set(z.id, displayZoneName(z.codigo, z.nombre) ?? z.nombre);
    }
    return map;
  }, [zonesQuery.data]);

  const createIncidentZones = useMemo(
    () => incidentZoneOptions(zonesQuery.data ?? []),
    [zonesQuery.data],
  );

  const updateMutation = useMutation({
    mutationFn: async ({ item, estado }: { item: UnifiedIncident; estado: UnifiedEstado }) => {
      if (item.origen === "alerta") {
        const alertEstado: AlertState =
          estado === "abierta" ? "pendiente"
          : estado === "en_gestion" ? "revisada"
          : estado === "resuelta" ? "resuelta"
          : "falsa_alarma";
        return api.reviewAlert(item.rawId, { estado: alertEstado });
      }
      return api.updateIncident(item.rawId, { estado });
    },
    onMutate: ({ item }) => setUpdatingId(item.id),
    onError: (err: Error) => {
      toast.error(err.message || "Error al actualizar");
    },
    onSettled: () => {
      setUpdatingId(null);
      queryClient.invalidateQueries({ queryKey: ["incidents"] });
      queryClient.invalidateQueries({ queryKey: ["alerts-unified"] });
    },
  });

  const all = useMemo<UnifiedIncident[]>(() => {
    const items = [
      ...(incidentsQuery.data ?? []).map(normalizeIncident),
      ...(alertsQuery.data?.alertas ?? []).map(normalizeAlert),
    ];
    return items.sort((a, b) =>
      new Date(b.fecha_creacion).getTime() - new Date(a.fecha_creacion).getTime()
    );
  }, [incidentsQuery.data, alertsQuery.data]);

  const isLoading = incidentsQuery.isLoading || alertsQuery.isLoading;
  const isError = incidentsQuery.isError || alertsQuery.isError;

  const filtered = useMemo(() => {
    return all.filter((i) => {
      if (estadoFilter !== "todas" && i.estado !== estadoFilter) return false;
      if (prioridadFilter !== "todas" && i.severidad !== prioridadFilter) return false;
      return true;
    });
  }, [all, estadoFilter, prioridadFilter]);

  const stats = useMemo(() => ({
    total: all.length,
    abiertas: all.filter((i) => i.estado === "abierta").length,
    en_gestion: all.filter((i) => i.estado === "en_gestion").length,
    resueltas: all.filter((i) => i.estado === "resuelta" || i.estado === "cerrada").length,
    criticas: all.filter((i) => i.severidad === "critica").length,
    altas: all.filter((i) => i.severidad === "alta").length,
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
          zones={createIncidentZones}
          onClose={() => setShowCreate(false)}
        />
      )}

      <PageHeader eyebrow="Seguimiento operativo" title="Incidencias" EyebrowIcon={AlertOctagon}>
        <div className="flex items-center gap-3">
          {incidentsQuery.isSuccess && alertsQuery.isSuccess && (
            <span className="rounded-full border border-app-border bg-white px-3 py-1.5 text-sm font-bold text-app-text">
              {filtered.length} registros
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
        {isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-20 animate-pulse rounded-[10px] bg-app-bg" />
            ))}
          </div>
        )}

        {/* Error */}
        {isError && (
          <div className="rounded-[10px] border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar: {incidentsQuery.error?.message || alertsQuery.error?.message || "Error desconocido"}
          </div>
        )}

        {/* Empty */}
        {!isLoading && !isError && filtered.length === 0 && (
          <div className="rounded-[10px] border border-app-border bg-white py-16 text-center">
            <Siren className="mx-auto h-12 w-12 text-app-dim" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-app-text">Sin registros</p>
            <p className="mt-1 text-sm text-app-dim">
              {estadoFilter !== "todas" || prioridadFilter !== "todas"
                ? "Prueba a cambiar los filtros"
                : "No hay incidencias registradas"}
            </p>
          </div>
        )}

        {/* List */}
        <div className="space-y-3">
          {pageItems.map((item) => (
            <UnifiedCard
              key={item.id}
              item={item}
              onStatusChange={(item, estado) => updateMutation.mutate({ item, estado })}
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
