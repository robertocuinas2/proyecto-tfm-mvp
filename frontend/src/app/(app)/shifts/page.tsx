"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  CalendarClock,
  ChevronDown,
  ChevronUp,
  Monitor,
  Plus,
  UserRound,
  X,
} from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { Pagination } from "@/components/common/Pagination";
import { PageHeader } from "@/components/ui/page-header";
import { api } from "@/lib/api";
import { DEFAULT_PAGE_SIZE, getSkip } from "@/lib/pagination";
import type {
  CreateShiftAssignmentPayload,
  CreateShiftPayload,
  Shift,
  ShiftAssignment,
  ShiftType,
} from "@/lib/types";

// ── Constants ──────────────────────────────────────────────────────────────

const SHIFT_TYPE_LABELS: Record<ShiftType, string> = {
  manana: "Mañana",
  tarde: "Tarde",
};

const SHIFT_TYPE_STYLES: Record<ShiftType, string> = {
  manana: "bg-state-info/15 text-state-info border-state-info/30",
  tarde: "bg-state-atencion/15 text-state-atencion border-state-atencion/30",
};

// ── Helpers ────────────────────────────────────────────────────────────────

function formatTime(time?: string | null) {
  if (!time) return "—";
  return time.slice(0, 5); // HH:MM from HH:MM:SS
}

function formatShiftDate(iso?: string | null) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("es-ES", {
    weekday: "short",
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

function isToday(iso?: string | null) {
  if (!iso) return false;
  const today = new Date().toISOString().slice(0, 10);
  return iso === today;
}

// ── Sub-components ─────────────────────────────────────────────────────────

function ShiftTypeBadge({ tipo }: { tipo: ShiftType }) {
  return (
    <span className={`inline-flex rounded-full border px-2.5 py-0.5 text-[11px] font-extrabold uppercase ${SHIFT_TYPE_STYLES[tipo]}`}>
      {SHIFT_TYPE_LABELS[tipo]}
    </span>
  );
}

function KpiCard({ label, value, tone }: { label: string; value: number | string; tone: string }) {
  return (
    <div className="rounded-[10px] border border-app-border bg-white shadow-card p-4">
      <p className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-app-dim">{label}</p>
      <p className={`mt-2 font-heading text-3xl font-bold ${tone}`}>{value}</p>
    </div>
  );
}

// ── Create shift modal ─────────────────────────────────────────────────────

function CreateShiftModal({ onClose }: { onClose: () => void }) {
  const queryClient = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);
  const [fecha, setFecha] = useState(today);
  const [tipoTurno, setTipoTurno] = useState<ShiftType>("manana");
  const [horaInicio, setHoraInicio] = useState("06:00");
  const [horaFin, setHoraFin] = useState("14:00");
  const [notas, setNotas] = useState("");

  const mutation = useMutation({
    mutationFn: (payload: CreateShiftPayload) => api.createShift(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["shifts"] });
      onClose();
    },
  });

  const handleTipoChange = (tipo: ShiftType) => {
    setTipoTurno(tipo);
    if (tipo === "manana") {
      setHoraInicio("06:00");
      setHoraFin("14:00");
    } else {
      setHoraInicio("14:00");
      setHoraFin("22:00");
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 sm:items-center">
      <div className="w-full max-w-md rounded-t-[20px] border border-app-border bg-white shadow-panel sm:rounded-[14px]">
        <div className="flex items-center justify-between border-b border-app-border px-6 py-4">
          <h2 className="font-heading text-lg font-bold text-app-text">Nuevo turno</h2>
          <button type="button" onClick={onClose} className="text-app-dim hover:text-app-text">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 px-6 py-5">
          {/* Fecha */}
          <label className="block">
            <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Fecha *
            </span>
            <input
              type="date"
              value={fecha}
              onChange={(e) => setFecha(e.target.value)}
              className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none focus:border-brand"
            />
          </label>

          {/* Tipo turno */}
          <div>
            <p className="mb-2 text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Tipo de turno *
            </p>
            <div className="grid grid-cols-2 gap-3">
              {(["manana", "tarde"] as ShiftType[]).map((tipo) => (
                <button
                  key={tipo}
                  type="button"
                  onClick={() => handleTipoChange(tipo)}
                  className={`rounded-[10px] border-2 py-3 font-bold text-sm transition ${
                    tipoTurno === tipo
                      ? SHIFT_TYPE_STYLES[tipo].replace("/15", "/20").replace("border-", "border-2 border-")
                      : "border-app-border text-app-dim hover:border-app-dim"
                  }`}
                >
                  {SHIFT_TYPE_LABELS[tipo]}
                </button>
              ))}
            </div>
          </div>

          {/* Horas */}
          <div className="grid grid-cols-2 gap-3">
            <label className="block">
              <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
                Hora inicio *
              </span>
              <input
                type="time"
                value={horaInicio}
                onChange={(e) => setHoraInicio(e.target.value)}
                className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none focus:border-brand"
              />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
                Hora fin *
              </span>
              <input
                type="time"
                value={horaFin}
                onChange={(e) => setHoraFin(e.target.value)}
                className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none focus:border-brand"
              />
            </label>
          </div>

          {/* Notas */}
          <label className="block">
            <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Notas
            </span>
            <textarea
              rows={2}
              value={notas}
              onChange={(e) => setNotas(e.target.value)}
              className="w-full resize-none rounded-[10px] border border-app-border bg-white px-3 py-2.5 text-sm text-app-text outline-none placeholder:text-app-dim focus:border-brand"
            />
          </label>

          {mutation.isError && (
            <p className="rounded-[10px] bg-state-critica/10 px-3 py-2 text-sm text-state-critica">
              {mutation.error.message}
            </p>
          )}

          <button
            type="button"
            disabled={!fecha || !horaInicio || !horaFin || mutation.isPending}
            onClick={() =>
              mutation.mutate({
                fecha,
                tipo_turno: tipoTurno,
                hora_inicio: horaInicio,
                hora_fin: horaFin,
                notas: notas.trim() || null,
              })
            }
            className="w-full rounded-[10px] bg-brand py-3.5 font-heading text-base font-bold text-white shadow-brand transition hover:bg-[#135532] disabled:opacity-50"
          >
            {mutation.isPending ? "Creando..." : "Crear turno"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Assign employee modal ──────────────────────────────────────────────────

function AssignEmployeeModal({
  turnoId,
  zones,
  employees,
  onClose,
}: {
  turnoId: string;
  zones: { id: string; nombre: string }[];
  employees: { id: string; nombre: string; apellidos?: string | null }[];
  onClose: () => void;
}) {
  const queryClient = useQueryClient();
  const [empleadoId, setEmpleadoId] = useState("");
  const [zonaId, setZonaId] = useState("");
  const [rol, setRol] = useState("");

  const mutation = useMutation({
    mutationFn: (payload: CreateShiftAssignmentPayload) => api.createShiftAssignment(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["shift-assignments"] });
      onClose();
    },
  });

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 sm:items-center">
      <div className="w-full max-w-md rounded-t-[20px] border border-app-border bg-white shadow-panel sm:rounded-[14px]">
        <div className="flex items-center justify-between border-b border-app-border px-6 py-4">
          <h2 className="font-heading text-lg font-bold text-app-text">Asignar empleado</h2>
          <button type="button" onClick={onClose} className="text-app-dim hover:text-app-text">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 px-6 py-5">
          <label className="block">
            <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Empleado *
            </span>
            <select
              value={empleadoId}
              onChange={(e) => setEmpleadoId(e.target.value)}
              className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none focus:border-brand"
            >
              <option value="">Seleccionar empleado</option>
              {employees.map((e) => (
                <option key={e.id} value={e.id}>
                  {e.nombre} {e.apellidos ?? ""}
                </option>
              ))}
            </select>
          </label>

          <label className="block">
            <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Zona (opcional)
            </span>
            <select
              value={zonaId}
              onChange={(e) => setZonaId(e.target.value)}
              className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none focus:border-brand"
            >
              <option value="">Sin zona específica</option>
              {zones.map((z) => (
                <option key={z.id} value={z.id}>{z.nombre}</option>
              ))}
            </select>
          </label>

          <label className="block">
            <span className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Rol en el turno (opcional)
            </span>
            <input
              type="text"
              value={rol}
              onChange={(e) => setRol(e.target.value)}
              placeholder="Ej: responsable_ordeno"
              className="h-11 w-full rounded-[10px] border border-app-border bg-white px-3 text-sm text-app-text outline-none placeholder:text-app-dim focus:border-brand"
            />
          </label>

          {mutation.isError && (
            <p className="rounded-[10px] bg-state-critica/10 px-3 py-2 text-sm text-state-critica">
              {mutation.error.message}
            </p>
          )}

          <button
            type="button"
            disabled={!empleadoId || mutation.isPending}
            onClick={() =>
              mutation.mutate({
                turno_id: turnoId,
                empleado_id: empleadoId,
                zona_id: zonaId || null,
                rol: rol.trim() || null,
              })
            }
            className="w-full rounded-[10px] bg-brand py-3.5 font-heading text-base font-bold text-white shadow-brand transition hover:bg-[#135532] disabled:opacity-50"
          >
            {mutation.isPending ? "Asignando..." : "Asignar"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Shift card ─────────────────────────────────────────────────────────────

function ShiftCard({
  shift,
  assignments,
  employeeLookup,
  zoneLookup,
  zones,
  employees,
}: {
  shift: Shift;
  assignments: ShiftAssignment[];
  employeeLookup: Map<string, string>;
  zoneLookup: Map<string, string>;
  zones: { id: string; nombre: string }[];
  employees: { id: string; nombre: string; apellidos?: string | null }[];
}) {
  const [expanded, setExpanded] = useState(false);
  const [showAssign, setShowAssign] = useState(false);
  const today = isToday(shift.fecha);

  return (
    <>
      {showAssign && (
        <AssignEmployeeModal
          turnoId={shift.id}
          zones={zones}
          employees={employees}
          onClose={() => setShowAssign(false)}
        />
      )}

      <div className={`rounded-[10px] border bg-white ${today ? "border-brand/25" : "border-app-border"}`}>
        <button
          type="button"
          className="w-full px-4 py-4 text-left"
          onClick={() => setExpanded((v) => !v)}
        >
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <ShiftTypeBadge tipo={shift.tipo_turno} />
                {today && (
                  <span className="rounded-full bg-brand/10 px-2 py-0.5 text-[11px] font-extrabold uppercase text-brand">
                    Hoy
                  </span>
                )}
                <span className="text-xs text-app-dim">
                  {formatTime(shift.hora_inicio)} – {formatTime(shift.hora_fin)}
                </span>
                {assignments.length > 0 && (
                  <span className="flex items-center gap-1 text-xs text-app-dim">
                    <UserRound className="h-3.5 w-3.5" />
                    {assignments.length}
                  </span>
                )}
              </div>
              <h2 className="mt-2 font-heading text-base font-bold text-app-text">
                {formatShiftDate(shift.fecha)}
              </h2>
              {shift.notas && (
                <p className="mt-1 text-xs text-app-dim">{shift.notas}</p>
              )}
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
            {assignments.length === 0 ? (
              <p className="text-sm text-app-dim">Sin empleados asignados a este turno.</p>
            ) : (
              <div className="space-y-2">
                {assignments.map((a) => (
                  <div key={a.id} className="flex items-center justify-between gap-3 rounded-[10px] bg-app-bg px-3 py-2.5">
                    <div className="flex items-center gap-2">
                      <UserRound className="h-4 w-4 shrink-0 text-app-dim" />
                      <span className="text-sm font-semibold text-app-text">
                        {employeeLookup.get(a.empleado_id) ?? a.empleado_id.slice(0, 8) + "…"}
                      </span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-app-dim">
                      {a.zona_id && <span>{zoneLookup.get(a.zona_id) ?? "Zona"}</span>}
                      {a.rol && <span className="rounded-full bg-app-bg px-2 py-0.5 font-mono text-[11px]">{a.rol}</span>}
                    </div>
                  </div>
                ))}
              </div>
            )}

            <button
              type="button"
              onClick={() => setShowAssign(true)}
              className="inline-flex items-center gap-2 rounded-[10px] border border-app-border bg-app-bg px-3 py-2 text-xs font-bold text-app-dim transition hover:border-brand/25 hover:text-brand"
            >
              <Plus className="h-3.5 w-3.5" />
              Asignar empleado
            </button>
          </div>
        )}
      </div>
    </>
  );
}

// ── Main page ──────────────────────────────────────────────────────────────

type FilterType = ShiftType | "todos";

export default function ShiftsPage() {
  const [typeFilter, setTypeFilter] = useState<FilterType>("todos");
  const [dateFilter, setDateFilter] = useState("");
  const [page, setPage] = useState(1);
  const [showCreate, setShowCreate] = useState(false);
  const pageSize = DEFAULT_PAGE_SIZE;

  const shiftsQuery = useQuery({
    queryKey: ["shifts", typeFilter, dateFilter, page],
    queryFn: () =>
      api.shifts({
        skip: getSkip(page, pageSize),
        limit: pageSize + 1,
        ...(typeFilter !== "todos" ? { tipo_turno: typeFilter } : {}),
        ...(dateFilter ? { fecha: dateFilter } : {}),
      }),
    staleTime: 30_000,
    refetchInterval: 60_000,
  });

  const assignmentsQuery = useQuery({
    queryKey: ["shift-assignments"],
    queryFn: () => api.shiftAssignments({ limit: 200 }),
    staleTime: 30_000,
  });

  const zonesQuery = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: 5 * 60_000,
  });

  const employeesQuery = useQuery({
    queryKey: ["management-employees"],
    queryFn: () => api.employees(),
    staleTime: 5 * 60_000,
  });

  const employeeLookup = useMemo(() => {
    const map = new Map<string, string>();
    for (const e of employeesQuery.data ?? []) {
      map.set(e.id, `${e.nombre}${e.apellidos ? " " + e.apellidos : ""}`);
    }
    return map;
  }, [employeesQuery.data]);

  const zoneLookup = useMemo(() => {
    const map = new Map<string, string>();
    for (const z of zonesQuery.data ?? []) {
      map.set(z.id, z.nombre);
    }
    return map;
  }, [zonesQuery.data]);

  const assignmentsByShift = useMemo(() => {
    const map = new Map<string, ShiftAssignment[]>();
    for (const a of assignmentsQuery.data?.asignaciones ?? []) {
      const arr = map.get(a.turno_id) ?? [];
      arr.push(a);
      map.set(a.turno_id, arr);
    }
    return map;
  }, [assignmentsQuery.data]);

  const pageData = shiftsQuery.data?.turnos ?? [];
  const hasNext = pageData.length > pageSize;
  const pageItems = pageData.slice(0, pageSize);
  const totalShifts = shiftsQuery.data?.total ?? 0;

  const todayStr = new Date().toISOString().slice(0, 10);
  const todayShifts = (shiftsQuery.data?.turnos ?? []).filter((s) => s.fecha === todayStr).length;

  return (
    <div className="min-h-full">
      {showCreate && <CreateShiftModal onClose={() => setShowCreate(false)} />}

      <PageHeader eyebrow="Planificación de equipo" title="Turnos" EyebrowIcon={CalendarClock}>
        <div className="flex items-center gap-3">
          <Link
            href="/tv/shifts"
            className="inline-flex items-center gap-1.5 rounded-[10px] border border-app-border bg-app-bg px-3 py-2 text-sm font-semibold text-app-dim transition hover:border-brand/30 hover:text-brand"
          >
            <Monitor className="h-4 w-4" />
            TV Turnos
          </Link>
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            className="inline-flex items-center gap-2 rounded-[10px] bg-brand px-4 py-2 text-sm font-bold text-white shadow-brand transition hover:bg-[#135532]"
          >
            <Plus className="h-4 w-4" />
            Nuevo turno
          </button>
        </div>
      </PageHeader>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        {/* KPIs */}
        {shiftsQuery.isSuccess && (
          <div className="grid grid-cols-3 gap-3">
            <KpiCard label="Total turnos" value={totalShifts} tone="text-app-text" />
            <KpiCard label="Turnos hoy" value={todayShifts} tone={todayShifts > 0 ? "text-brand" : "text-app-dim"} />
            <KpiCard
              label="Asignaciones"
              value={assignmentsQuery.data?.total ?? 0}
              tone="text-state-info"
            />
          </div>
        )}

        {/* Filters */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex gap-2">
            {(["todos", "manana", "tarde"] as FilterType[]).map((key) => (
              <button
                key={key}
                type="button"
                onClick={() => { setTypeFilter(key); setPage(1); }}
                className={`rounded-[10px] px-3 py-2 text-sm font-semibold transition ${
                  typeFilter === key
                    ? "bg-app-bg text-brand"
                    : "bg-white text-app-dim hover:bg-app-bg"
                }`}
              >
                {key === "todos" ? "Todos" : SHIFT_TYPE_LABELS[key]}
              </button>
            ))}
          </div>

          <input
            type="date"
            value={dateFilter}
            onChange={(e) => { setDateFilter(e.target.value); setPage(1); }}
            className="rounded-[10px] border border-app-border bg-white px-3 py-2 text-sm font-semibold text-app-text outline-none focus:border-brand"
          />

          {dateFilter && (
            <button
              type="button"
              onClick={() => { setDateFilter(""); setPage(1); }}
              className="rounded-[10px] border border-app-border bg-white px-3 py-2 text-sm font-semibold text-app-dim transition hover:text-app-text"
            >
              Limpiar fecha
            </button>
          )}
        </div>

        {/* Loading */}
        {shiftsQuery.isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-24 animate-pulse rounded-[10px] bg-app-bg" />
            ))}
          </div>
        )}

        {/* Error */}
        {shiftsQuery.isError && (
          <div className="rounded-[10px] border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar turnos: {shiftsQuery.error.message}
          </div>
        )}

        {/* Empty */}
        {shiftsQuery.isSuccess && pageItems.length === 0 && (
          <div className="rounded-[10px] border border-app-border bg-white py-16 text-center">
            <CalendarClock className="mx-auto h-12 w-12 text-app-dim" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-app-text">Sin turnos</p>
            <p className="mt-1 text-sm text-app-dim">
              {dateFilter || typeFilter !== "todos" ? "Sin resultados con estos filtros" : "Crea el primer turno"}
            </p>
          </div>
        )}

        {/* List */}
        <div className="space-y-3">
          {pageItems.map((shift) => (
            <ShiftCard
              key={shift.id}
              shift={shift}
              assignments={assignmentsByShift.get(shift.id) ?? []}
              employeeLookup={employeeLookup}
              zoneLookup={zoneLookup}
              zones={zonesQuery.data ?? []}
              employees={employeesQuery.data ?? []}
            />
          ))}
        </div>

        {/* Pagination */}
        {!shiftsQuery.isLoading && pageItems.length > 0 && (
          <Pagination
            page={page}
            pageSize={pageSize}
            currentCount={pageItems.length}
            hasNext={hasNext}
            isLoading={shiftsQuery.isFetching}
            onPageChange={setPage}
          />
        )}
      </div>
    </div>
  );
}
