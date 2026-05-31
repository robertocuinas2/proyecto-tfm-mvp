"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertTriangle,
  CheckCircle2,
  ChevronLeft,
  ClipboardList,
  Clock,
  Monitor,
  Plus,
  Settings2,
  Tablet,
  X,
} from "lucide-react";
import Link from "next/link";
import { use, useEffect, useState } from "react";
import { WeatherPanel } from "@/components/ui/WeatherPanel";
import { api } from "@/lib/api";
import { TV_REFETCH, TV_STALE } from "@/lib/tv-constants";
import type { CreateIncidentPayload, Employee, IncidentPriority, Machinery, Task } from "@/lib/types";

const severityBar: Record<string, string> = {
  critica: "border-l-state-critica",
  alta: "border-l-state-atencion",
  media: "border-l-state-info",
  baja: "border-l-tv-dim",
};

const severityBadge: Record<string, string> = {
  critica: "bg-state-critica/15 text-state-critica",
  alta: "bg-state-atencion/15 text-state-atencion",
  media: "bg-state-info/15 text-state-info",
  baja: "bg-tv-dim/10 text-tv-dim",
};

const taskStateCard: Record<string, string> = {
  retrasada: "border-l-state-critica bg-state-critica/5",
  programada: "border-l-state-info bg-app-bg",
  ejecutada: "border-l-state-ok bg-state-ok/5",
  pausada: "border-l-state-atencion bg-state-atencion/5",
  cancelada: "border-l-app-border bg-app-bg",
};

const taskLabel: Record<string, string> = {
  retrasada: "Retrasada",
  programada: "Programada",
  ejecutada: "Ejecutada",
  pausada: "Pausada",
  cancelada: "Cancelada",
};

const taskTone: Record<string, string> = {
  retrasada: "text-state-critica",
  programada: "text-state-info",
  ejecutada: "text-state-ok",
  pausada: "text-state-atencion",
  cancelada: "text-app-dim",
};

function LiveClock() {
  const [time, setTime] = useState(() =>
    new Date().toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" }),
  );

  useEffect(() => {
    const timer = window.setInterval(() => {
      setTime(new Date().toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" }));
    }, 60_000);
    return () => window.clearInterval(timer);
  }, []);

  return <>{time}</>;
}

function TVMode({ zoneId, zoneName }: { zoneId: string; zoneName: string }) {
  const tasksQuery = useQuery({
    queryKey: ["tasks-zone", zoneId],
    queryFn: () => api.tasks({ zona_id: zoneId, limit: 100 }),
    refetchInterval: TV_REFETCH.NORMAL,
    staleTime: TV_STALE.NORMAL,
  });

  const alertsQuery = useQuery({
    queryKey: ["alerts-pending"],
    queryFn: () => api.alerts({ limit: 50 }),
    refetchInterval: TV_REFETCH.FAST,
    staleTime: TV_STALE.FAST,
  });

  // Incidents filtered client-side by zona_id (endpoint has no filter param for zona_id)
  const incidentsQuery = useQuery({
    queryKey: ["tv-incidents"],
    queryFn: () => api.incidents({ limit: 100 }),
    refetchInterval: TV_REFETCH.NORMAL,
    staleTime: TV_STALE.NORMAL,
  });

  const tasks = tasksQuery.data ?? [];
  const delayed = tasks.filter((task) => task.estado === "retrasada");
  const urgent = tasks.filter((task) => task.estado === "programada" && task.es_urgente);
  const pending = tasks.filter((task) => task.estado === "programada" && !task.es_urgente);
  const done = tasks.filter((task) => task.estado === "ejecutada");
  const alerts = (alertsQuery.data?.alertas ?? []).filter((alert) => alert.estado === "pendiente");
  const critical = alerts.filter((alert) => alert.severidad === "critica");
  // Filter incidents for this zone client-side
  const zoneIncidents = (incidentsQuery.data ?? []).filter(
    (i: { zona_id?: string | null; estado: string }) =>
      i.zona_id === zoneId && (i.estado === "abierta" || i.estado === "en_gestion"),
  );

  return (
    <div className="space-y-4">
      <div className="grid gap-3 rounded-lg border border-tv-border bg-tv-surface p-4 sm:grid-cols-2 md:grid-cols-5">
        {[
          { label: "Zona", value: zoneName, color: "text-white" },
          { label: "Alertas criticas", value: critical.length, color: critical.length > 0 ? "text-state-critica" : "text-state-ok" },
          { label: "Incidencias", value: zoneIncidents.length, color: zoneIncidents.length > 0 ? "text-state-atencion" : "text-state-ok" },
          { label: "Tareas retrasadas", value: delayed.length, color: delayed.length > 0 ? "text-state-atencion" : "text-state-ok" },
          { label: "Hora actual", value: <LiveClock />, color: "text-tv-accent" },
        ].map(({ label, value, color }) => (
          <div key={label} className="text-center">
            <div className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-tv-dim">{label}</div>
            <div className={`mt-2 font-heading text-3xl font-bold ${color}`}>{value}</div>
          </div>
        ))}
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        {/* Incidents for this zone */}
        {zoneIncidents.length > 0 && (
          <section className="space-y-3 xl:col-span-3">
            <HeaderLabel Icon={AlertTriangle} label="Incidencias de zona" count={zoneIncidents.length} tone="text-state-atencion" />
            <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
              {zoneIncidents.map((inc: { id: string; tipo: string; descripcion: string; prioridad: string; estado: string }) => (
                <div key={inc.id} className="rounded-lg border border-tv-border bg-tv-surface px-4 py-3">
                  <div className="flex items-center gap-2">
                    <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase ${
                      inc.prioridad === "critica" ? "bg-state-critica/15 text-state-critica"
                      : inc.prioridad === "alta" ? "bg-state-atencion/15 text-state-atencion"
                      : "bg-state-info/15 text-state-info"
                    }`}>
                      {inc.prioridad}
                    </span>
                    <span className="text-xs capitalize text-tv-dim">{inc.tipo.replace(/_/g, " ")}</span>
                  </div>
                  <p className="mt-1 text-sm font-semibold text-app-text">{inc.descripcion}</p>
                </div>
              ))}
            </div>
          </section>
        )}

        <section className="space-y-3">
          <HeaderLabel Icon={AlertTriangle} label="Alertas activas" count={alerts.length} tone="text-state-critica" />
          {alerts.length === 0 ? (
            <EmptyPanel text="Sin alertas pendientes" />
          ) : (
            alerts.slice(0, 6).map((alert) => (
              <div
                key={alert.id}
                className={`rounded-lg border border-l-4 border-tv-border bg-tv-surface px-4 py-3 ${severityBar[alert.severidad]}`}
              >
                <div className="flex items-center gap-2">
                  <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase ${severityBadge[alert.severidad]}`}>
                    {alert.severidad}
                  </span>
                  <span className="text-xs capitalize text-tv-dim">{alert.tipo_alerta}</span>
                </div>
                <p className="mt-1.5 text-sm font-semibold leading-snug text-white">{alert.descripcion}</p>
              </div>
            ))
          )}
        </section>

        <section className="space-y-3">
          <HeaderLabel Icon={ClipboardList} label="Tareas de zona" count={tasks.length} tone="text-tv-accent" />
          {tasksQuery.isLoading ? (
            Array.from({ length: 4 }).map((_, index) => (
              <div key={index} className="h-16 animate-pulse rounded-lg bg-tv-surface" />
            ))
          ) : tasks.length === 0 ? (
            <EmptyPanel text="Sin tareas registradas" />
          ) : (
            [...delayed, ...urgent, ...pending].slice(0, 8).map((task) => <TaskMiniCard key={task.id} task={task} />)
          )}
        </section>

        <section className="space-y-3">
          <HeaderLabel Icon={CheckCircle2} label="Completadas" count={done.length} tone="text-state-ok" />
          {done.length === 0 ? (
            <EmptyPanel text="Sin tareas completadas" />
          ) : (
            done.slice(0, 6).map((task) => (
              <div key={task.id} className="flex items-center gap-3 rounded-lg border border-tv-border bg-tv-surface px-4 py-3">
                <CheckCircle2 className="h-4 w-4 shrink-0 text-state-ok" />
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-white">{task.tarea_catalogo?.nombre ?? "Tarea"}</p>
                  {task.ejecutado_por && <p className="text-xs text-tv-dim">{task.ejecutado_por}</p>}
                </div>
              </div>
            ))
          )}
        </section>
      </div>
    </div>
  );
}

function HeaderLabel({
  Icon,
  label,
  count,
  tone,
}: {
  Icon: typeof AlertTriangle;
  label: string;
  count: number;
  tone: string;
}) {
  return (
    <div className="flex items-center gap-2">
      <Icon className={`h-4 w-4 ${tone}`} />
      <span className="text-xs font-extrabold uppercase tracking-[0.14em] text-tv-dim">{label}</span>
      <span className={`rounded-full bg-tv-surface px-2 py-0.5 text-[11px] font-bold ${tone}`}>{count}</span>
    </div>
  );
}

function EmptyPanel({ text }: { text: string }) {
  return (
    <div className="rounded-lg border border-tv-border bg-tv-surface px-4 py-8 text-center text-sm font-semibold text-tv-dim">
      {text}
    </div>
  );
}

function TaskMiniCard({ task }: { task: Task }) {
  return (
    <div className={`rounded-lg border border-l-4 border-tv-border px-4 py-3 ${taskStateCard[task.estado]}`}>
      <span className={`text-[10px] font-extrabold uppercase tracking-[0.14em] ${taskTone[task.estado]}`}>
        {taskLabel[task.estado]}
        {task.es_urgente && " · URGENTE"}
      </span>
      <p className="mt-0.5 text-sm font-semibold leading-snug text-white">{task.tarea_catalogo?.nombre ?? "Tarea"}</p>
      <p className="mt-0.5 text-xs text-tv-dim">
        {new Date(task.fecha_programada).toLocaleString("es-ES", {
          day: "2-digit",
          month: "short",
          hour: "2-digit",
          minute: "2-digit",
        })}
      </p>
    </div>
  );
}

function CreateIncidentModal({ zoneId, onClose }: { zoneId: string; onClose: () => void }) {
  const queryClient = useQueryClient();
  const [tipo, setTipo] = useState("");
  const [descripcion, setDescripcion] = useState("");
  const [prioridad, setPrioridad] = useState<IncidentPriority>("media");

  const mutation = useMutation({
    mutationFn: (payload: CreateIncidentPayload) => api.createIncident(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["incidents"] });
      onClose();
    },
  });

  const tipos = [
    "Sanitaria - animal enfermo",
    "Sanitaria - lesion",
    "Operativa - tarea no ejecutada",
    "Calidad - leche fuera de parametro",
    "Maquinaria - averia",
    "Alimentacion - error en racion",
    "Otra",
  ];

  const priorities: { value: IncidentPriority; label: string; cls: string }[] = [
    { value: "critica", label: "Critica", cls: "border-state-critica text-state-critica bg-state-critica/10" },
    { value: "alta", label: "Alta", cls: "border-state-atencion text-state-atencion bg-state-atencion/10" },
    { value: "media", label: "Media", cls: "border-state-info text-state-info bg-state-info/10" },
    { value: "baja", label: "Baja", cls: "border-tv-dim text-tv-dim bg-tv-surface2" },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 sm:items-center">
      <div className="w-full max-w-lg rounded-t-[20px] bg-tv-surface sm:rounded-lg">
        <div className="flex items-center justify-between border-b border-tv-border px-6 py-4">
          <h2 className="font-heading text-lg font-bold">Nueva incidencia</h2>
          <button type="button" onClick={onClose} className="text-tv-dim hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 px-6 py-5">
          <div>
            <label className="mb-2 block text-xs font-extrabold uppercase tracking-[0.14em] text-tv-dim">
              Prioridad
            </label>
            <div className="grid grid-cols-4 gap-2">
              {priorities.map(({ value, label, cls }) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setPrioridad(value)}
                  className={`rounded-lg border-2 py-2 text-xs font-bold transition ${
                    prioridad === value ? cls : "border-tv-border text-tv-dim hover:border-tv-dim"
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="mb-2 block text-xs font-extrabold uppercase tracking-[0.14em] text-tv-dim">
              Tipo
            </label>
            <select
              value={tipo}
              onChange={(event) => setTipo(event.target.value)}
              className="h-12 w-full rounded-lg border border-tv-border bg-tv-surface2 px-3 text-sm text-white outline-none focus:border-tv-accent"
            >
              <option value="">Seleccionar tipo</option>
              {tipos.map((item) => (
                <option key={item} value={item}>
                  {item}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-2 block text-xs font-extrabold uppercase tracking-[0.14em] text-tv-dim">
              Descripcion
            </label>
            <textarea
              rows={3}
              value={descripcion}
              onChange={(event) => setDescripcion(event.target.value)}
              placeholder="Describe la incidencia con detalle"
              className="w-full resize-none rounded-[10px] border border-app-border bg-white px-3 py-2.5 text-sm text-app-text outline-none placeholder:text-app-dim focus:border-brand"
            />
          </div>

          {mutation.isError && (
            <p className="rounded-lg bg-state-critica/10 px-3 py-2 text-sm text-state-critica">
              {mutation.error.message}
            </p>
          )}

          <button
            type="button"
            disabled={!tipo || !descripcion || mutation.isPending}
            onClick={() => mutation.mutate({ tipo, zona_id: zoneId, descripcion, prioridad })}
            className="w-full rounded-lg bg-brand py-3.5 font-heading text-base font-bold text-white shadow-brand transition hover:bg-[#135532] disabled:opacity-50"
          >
            {mutation.isPending ? "Registrando..." : "Registrar incidencia"}
          </button>
        </div>
      </div>
    </div>
  );
}

function TabletMode({ zoneId }: { zoneId: string }) {
  const queryClient = useQueryClient();
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [showIncident, setShowIncident] = useState(false);
  const [observaciones, setObservaciones] = useState("");
  const [successId, setSuccessId] = useState<string | null>(null);

  useEffect(() => {
    if (!successId) return;
    const timer = window.setTimeout(() => setSuccessId(null), 3000);
    return () => window.clearTimeout(timer);
  }, [successId]);

  const tasksQuery = useQuery({
    queryKey: ["tasks-zone", zoneId],
    queryFn: () => api.tasks({ zona_id: zoneId, limit: 100 }),
    refetchInterval: TV_REFETCH.NORMAL,
    staleTime: TV_STALE.NORMAL,
  });

  // Incidents for this zone (client-side filter)
  const incidentsTabletQuery = useQuery({
    queryKey: ["tv-incidents"],
    queryFn: () => api.incidents({ limit: 100 }),
    staleTime: TV_STALE.NORMAL,
    refetchInterval: TV_REFETCH.NORMAL,
  });
  const tabletZoneIncidents = (incidentsTabletQuery.data ?? []).filter(
    (i: { zona_id?: string | null; estado: string }) =>
      i.zona_id === zoneId && (i.estado === "abierta" || i.estado === "en_gestion"),
  );

  // Employees for current shift assignments in this zone
  const assignmentsTabletQ = useQuery({
    queryKey: ["tv-shift-assignments"],
    queryFn: () => api.shiftAssignments({ limit: 50 }),
    staleTime: TV_STALE.SLOW,
  });
  const employeesTabletQ = useQuery({
    queryKey: ["employees-lookup"],
    queryFn: () => api.employees(),
    staleTime: TV_STALE.CATALOG,
  });
  const employeeById = new Map<string, Employee>(
    (employeesTabletQ.data ?? []).map((e) => [e.id, e] as [string, Employee]),
  );

  const completeMutation = useMutation({
    mutationFn: ({ id, body }: { id: string; body?: Partial<Task> }) => api.completeTask(id, body),
    onSuccess: (_, { id }) => {
      setSuccessId(id);
      setSelectedTask(null);
      setObservaciones("");
      queryClient.invalidateQueries({ queryKey: ["tasks-zone", zoneId] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-summary"] });
    },
  });

  const tasks = tasksQuery.data ?? [];
  const pending = [
    ...tasks.filter((task) => task.estado === "retrasada"),
    ...tasks.filter((task) => task.estado === "programada" && task.es_urgente),
    ...tasks.filter((task) => task.estado === "programada" && !task.es_urgente),
  ];

  return (
    <>
      {showIncident && <CreateIncidentModal zoneId={zoneId} onClose={() => setShowIncident(false)} />}

      <div className="space-y-4">
        <div>
          <p className="mb-2 text-[11px] font-extrabold uppercase tracking-[0.14em] text-app-dim">
            Acciones rapidas
          </p>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { label: "Completar tarea", Icon: CheckCircle2, color: "text-brand", action: undefined },
              { label: "Nueva incidencia", Icon: Plus, color: "text-state-critica", action: () => setShowIncident(true) },
              { label: "Ver alertas", Icon: AlertTriangle, color: "text-state-atencion", action: undefined },
              { label: "Tareas urgentes", Icon: Clock, color: "text-state-info", action: undefined },
            ].map(({ label, Icon, color, action }) => (
              <button
                key={label}
                type="button"
                onClick={action}
                className="flex min-h-[96px] flex-col items-center justify-center gap-2.5 rounded-[14px] border border-app-border bg-white px-3 py-5 text-center shadow-card transition hover:border-brand/25 hover:bg-app-bg active:scale-95"
              >
                <Icon className={`h-8 w-8 ${color}`} />
                <span className="text-xs font-semibold text-app-text">{label}</span>
              </button>
            ))}
          </div>
        </div>

        {successId && (
          <div className="flex items-center gap-2 rounded-[10px] bg-state-ok/10 px-4 py-3 text-sm font-bold text-state-ok">
            <CheckCircle2 className="h-4 w-4" />
            Tarea completada y registrada
          </div>
        )}

        <div className="grid gap-4 lg:grid-cols-2">
          <section>
            <p className="mb-2 text-[11px] font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Trabajo pendiente · {pending.length} tareas
            </p>
            {tasksQuery.isLoading ? (
              Array.from({ length: 3 }).map((_, index) => (
                <div key={index} className="mb-2 h-20 animate-pulse rounded-[10px] bg-app-surface2" />
              ))
            ) : pending.length === 0 ? (
              <EmptyPanel text="Sin tareas pendientes" />
            ) : (
              <div className="space-y-2">
                {pending.map((task) => {
                  const active = selectedTask?.id === task.id;
                  return (
                    <button
                      key={task.id}
                      type="button"
                      onClick={() => setSelectedTask(active ? null : task)}
                      className={`w-full rounded-lg border border-l-4 px-4 py-3 text-left transition ${taskStateCard[task.estado]} ${
                        active ? "border-brand/40 ring-2 ring-brand/20" : "hover:border-brand/25"
                      }`}
                    >
                      <span className={`text-[10px] font-extrabold uppercase tracking-[0.14em] ${taskTone[task.estado]}`}>
                        {taskLabel[task.estado]}
                        {task.es_urgente && " · URGENTE"}
                      </span>
                      <p className="mt-0.5 font-heading text-sm font-bold text-app-text">
                        {task.tarea_catalogo?.nombre ?? "Tarea"}
                      </p>
                      <p className="mt-0.5 text-xs text-app-dim">
                        {new Date(task.fecha_programada).toLocaleString("es-ES", {
                          day: "2-digit",
                          month: "short",
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </p>
                    </button>
                  );
                })}
              </div>
            )}
          </section>

          <section>
            <p className="mb-2 text-[11px] font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Detalle de tarea
            </p>
            {!selectedTask ? (
              <div className="rounded-[10px] border border-dashed border-app-border bg-white px-4 py-10 text-center text-sm text-app-dim">
                Selecciona una tarea para ver el detalle
              </div>
            ) : (
              <div className="space-y-4 rounded-[10px] border border-app-border bg-white p-5">
                <div>
                  <span className={`text-[10px] font-extrabold uppercase tracking-[0.14em] ${taskTone[selectedTask.estado]}`}>
                    {taskLabel[selectedTask.estado]}
                  </span>
                  <h3 className="mt-1 font-heading text-base font-bold text-app-text">
                    {selectedTask.tarea_catalogo?.nombre ?? "Tarea"}
                  </h3>
                  <p className="mt-0.5 text-xs text-app-dim">
                    Programada:{" "}
                    {new Date(selectedTask.fecha_programada).toLocaleString("es-ES", {
                      dateStyle: "medium",
                      timeStyle: "short",
                    })}
                  </p>
                </div>

                <div>
                  <label className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-app-dim">
                    Observaciones
                  </label>
                  <textarea
                    rows={3}
                    value={observaciones}
                    onChange={(event) => setObservaciones(event.target.value)}
                    placeholder="Incidencias encontradas, notas"
                    className="w-full resize-none rounded-[10px] border border-app-border bg-white px-3 py-2.5 text-sm text-app-text outline-none placeholder:text-app-dim focus:border-brand"
                  />
                </div>

                <div className="flex gap-3">
                  <button
                    type="button"
                    disabled={completeMutation.isPending}
                    onClick={() =>
                      completeMutation.mutate({
                        id: selectedTask.id,
                        body: { observaciones },
                      })
                    }
                    className="flex-1 rounded-lg bg-state-ok/20 py-3 text-sm font-bold text-state-ok transition hover:bg-state-ok/30 disabled:opacity-50"
                  >
                    {completeMutation.isPending ? "Guardando..." : "Completar"}
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowIncident(true)}
                    className="flex-1 rounded-lg bg-state-critica/10 py-3 text-sm font-bold text-state-critica transition hover:bg-state-critica/20"
                  >
                    Problema
                  </button>
                </div>
              </div>
            )}
          </section>
        </div>

        {/* Incidents for this zone */}
        {tabletZoneIncidents.length > 0 && (
          <div className="rounded-[14px] border border-app-border bg-white p-4 shadow-card">
            <p className="mb-3 text-[11px] font-extrabold uppercase tracking-[0.14em] text-state-atencion">
              Incidencias en esta zona · {tabletZoneIncidents.length}
            </p>
            <div className="space-y-2">
              {tabletZoneIncidents.map((inc: { id: string; tipo: string; descripcion: string; prioridad: string }) => (
                <div key={inc.id} className="rounded-[10px] border border-app-border bg-app-bg px-4 py-3">
                  <div className="flex items-center gap-2">
                    <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${
                      inc.prioridad === "critica" ? "bg-state-critica/15 text-state-critica"
                      : "bg-state-atencion/15 text-state-atencion"
                    }`}>
                      {inc.prioridad}
                    </span>
                    <span className="text-xs capitalize text-app-dim">{inc.tipo.replace(/_/g, " ")}</span>
                  </div>
                  <p className="mt-1 text-sm font-semibold text-app-text">{inc.descripcion}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Current shift assignments for this zone */}
        {(assignmentsTabletQ.data?.asignaciones ?? []).filter((a) => a.zona_id === zoneId).length > 0 && (
          <div className="rounded-[14px] border border-app-border bg-white p-4 shadow-card">
            <p className="mb-3 text-[11px] font-extrabold uppercase tracking-[0.14em] text-app-dim">
              Personal asignado a esta zona
            </p>
            <div className="space-y-2">
              {(assignmentsTabletQ.data?.asignaciones ?? [])
                .filter((a) => a.zona_id === zoneId)
                .map((a) => {
                  const emp = employeeById.get(a.empleado_id);
                  const name = emp
                    ? [emp.nombre, emp.apellidos].filter(Boolean).join(" ")
                    : a.empleado_id.slice(0, 8) + "…";
                  return (
                    <div key={a.id} className="flex items-center gap-3 rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5">
                      <span className="text-sm font-semibold text-app-text">{name}</span>
                      {emp?.role && (
                        <span className="rounded-full bg-app-bg px-2 py-0.5 text-xs capitalize text-app-dim">
                          {emp.role}
                        </span>
                      )}
                      {a.rol && (
                        <span className="ml-auto rounded font-mono text-[10px] text-app-dim">{a.rol}</span>
                      )}
                    </div>
                  );
                })}
            </div>
          </div>
        )}
      </div>
    </>
  );
}

// ── Management view (light theme) ────────────────────────────────────────────

function ManagementMode({ zoneId }: { zoneId: string }) {
  const machineryQ = useQuery({
    queryKey: ["machinery-zone", zoneId],
    queryFn: () => api.machinery({ zona_id: zoneId, limit: 50 }),
    staleTime: TV_STALE.CATALOG,
  });

  const tasksQ = useQuery({
    queryKey: ["tasks-zone", zoneId],
    queryFn: () => api.tasks({ zona_id: zoneId, limit: 100 }),
    staleTime: TV_STALE.NORMAL,
    refetchInterval: TV_REFETCH.NORMAL,
  });

  const incidentsQ = useQuery({
    queryKey: ["tv-incidents"],
    queryFn: () => api.incidents({ limit: 100 }),
    staleTime: TV_STALE.NORMAL,
  });

  const assignmentsQ = useQuery({
    queryKey: ["tv-shift-assignments"],
    queryFn: () => api.shiftAssignments({ limit: 50 }),
    staleTime: TV_STALE.SLOW,
  });

  const employeesQ = useQuery({
    queryKey: ["employees-lookup"],
    queryFn: () => api.employees(),
    staleTime: TV_STALE.CATALOG,
  });

  const machinery = (machineryQ.data ?? []) as Machinery[];
  const allTasks = tasksQ.data ?? [];
  const zoneIncidents = (incidentsQ.data ?? []).filter((i: { zona_id?: string | null; estado: string }) => i.zona_id === zoneId && (i.estado === "abierta" || i.estado === "en_gestion"));

  const pendingTasks = allTasks.filter((t: Task) => t.estado === "programada" || t.estado === "retrasada");
  const delayedTasks = allTasks.filter((t: Task) => t.estado === "retrasada");
  const doneTasks = allTasks.filter((t: Task) => t.estado === "ejecutada");

  const empById = new Map<string, Employee>((employeesQ.data ?? []).map((e) => [e.id, e] as [string, Employee]));
  const zoneAssignments = (assignmentsQ.data?.asignaciones ?? []).filter((a: { zona_id?: string | null }) => a.zona_id === zoneId);

  const machineryStateStyles: Record<string, string> = {
    operativa: "bg-state-ok/10 text-state-ok",
    revision: "bg-state-atencion/10 text-state-atencion",
    baja: "bg-state-neutral/10 text-state-neutral",
  };

  return (
    <div className="space-y-5 bg-app-bg px-6 py-6 lg:px-8">
      {/* Zone summary KPIs */}
      <div className="grid grid-cols-2 gap-4 xl:grid-cols-4">
        {[
          { label: "Tareas pendientes", value: pendingTasks.length, color: delayedTasks.length > 0 ? "text-state-critica" : "text-app-text" },
          { label: "Retrasadas", value: delayedTasks.length, color: delayedTasks.length > 0 ? "text-state-critica" : "text-state-ok" },
          { label: "Incidencias", value: zoneIncidents.length, color: zoneIncidents.length > 0 ? "text-state-atencion" : "text-app-text" },
          { label: "Maquinaria", value: machinery.length, color: "text-app-text" },
        ].map(({ label, value, color }) => (
          <div key={label} className="rounded-[14px] border border-app-border bg-white p-4 shadow-card">
            <p className="text-[11px] font-extrabold uppercase tracking-[0.14em] text-app-dim">{label}</p>
            <p className={`mt-2 font-heading text-4xl font-bold ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        {/* Machinery */}
        <div className="rounded-[14px] border border-app-border bg-white p-5 shadow-card">
          <h3 className="mb-4 font-heading text-base font-bold text-app-text">
            Maquinaria de zona ({machinery.length})
          </h3>
          {machineryQ.isError ? (
            <p className="text-sm text-state-critica">Error al cargar maquinaria.</p>
          ) : machineryQ.isLoading ? (
            <div className="h-20 animate-pulse rounded-[10px] bg-app-surface2" />
          ) : machinery.length === 0 ? (
            <p className="text-sm text-app-dim">Sin maquinaria asignada a esta zona.</p>
          ) : (
            <div className="space-y-2">
              {machinery.map((m: Machinery) => (
                <div key={m.id} className="flex items-center justify-between gap-3 rounded-[10px] border border-app-border bg-app-bg px-4 py-3">
                  <div>
                    <p className="text-sm font-semibold text-app-text">{m.nombre}</p>
                    <p className="text-xs capitalize text-app-dim">{m.tipo.replace(/_/g, " ")}</p>
                    {m.observaciones && <p className="mt-0.5 text-xs text-app-dim">{m.observaciones}</p>}
                  </div>
                  <span className={`shrink-0 rounded-full px-2.5 py-0.5 text-[11px] font-bold capitalize ${machineryStateStyles[m.estado] ?? "bg-app-bg text-app-dim"}`}>
                    {m.estado}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Weather */}
        <div className="space-y-5">
          <WeatherPanel />

          {/* Zone personnel */}
          {zoneAssignments.length > 0 && (
            <div className="rounded-[14px] border border-app-border bg-white p-5 shadow-card">
              <h3 className="mb-3 font-heading text-base font-bold text-app-text">
                Personal asignado
              </h3>
              <div className="space-y-2">
                {zoneAssignments.map((a: { id: string; empleado_id: string; rol?: string | null }) => {
                  const emp = empById.get(a.empleado_id);
                  const name = emp ? [emp.nombre, emp.apellidos].filter(Boolean).join(" ") : a.empleado_id.slice(0, 8) + "…";
                  return (
                    <div key={a.id} className="flex items-center gap-3 rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5">
                      <span className="text-sm font-semibold text-app-text">{name}</span>
                      {emp?.role && <span className="text-xs capitalize text-app-dim">{emp.role}</span>}
                      {a.rol && <span className="ml-auto rounded bg-white px-2 py-0.5 font-mono text-[10px] text-app-dim">{a.rol}</span>}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Tasks summary */}
      {allTasks.length > 0 && (
        <div className="rounded-[14px] border border-app-border bg-white p-5 shadow-card">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-heading text-base font-bold text-app-text">
              Tareas de zona ({allTasks.length})
            </h3>
            <div className="flex gap-2 text-xs">
              <span className="rounded-full bg-state-ok/10 px-2.5 py-1 font-semibold text-state-ok">{doneTasks.length} hechas</span>
              <span className={`rounded-full px-2.5 py-1 font-semibold ${delayedTasks.length > 0 ? "bg-state-critica/10 text-state-critica" : "bg-app-bg text-app-dim"}`}>{delayedTasks.length} retrasadas</span>
            </div>
          </div>
          <div className="space-y-2">
            {[...delayedTasks, ...pendingTasks.filter((t: Task) => t.estado !== "retrasada")].slice(0, 8).map((task: Task) => (
              <div key={task.id} className={`rounded-[10px] border px-4 py-3 ${task.estado === "retrasada" ? "border-state-critica/20 bg-state-critica/5" : "border-app-border bg-app-bg"}`}>
                <div className="flex items-center justify-between gap-3">
                  <p className="text-sm font-semibold text-app-text">
                    {task.tarea_catalogo?.nombre ?? "Tarea"}
                  </p>
                  <span className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-bold ${task.estado === "retrasada" ? "bg-state-critica/10 text-state-critica" : "bg-state-info/10 text-state-info"}`}>
                    {task.estado}
                  </span>
                </div>
                <p className="mt-0.5 text-xs text-app-dim">
                  {new Date(task.fecha_programada).toLocaleString("es-ES", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" })}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Incidents */}
      {zoneIncidents.length > 0 && (
        <div className="rounded-[14px] border border-state-atencion/20 bg-state-atencion/5 p-5">
          <h3 className="mb-3 font-heading text-base font-bold text-state-atencion">
            Incidencias de zona ({zoneIncidents.length})
          </h3>
          <div className="space-y-2">
            {zoneIncidents.map((inc: { id: string; tipo: string; descripcion: string; prioridad: string; estado: string }) => (
              <div key={inc.id} className="rounded-[10px] border border-app-border bg-white px-4 py-3">
                <div className="flex items-center gap-2">
                  <span className="text-xs capitalize text-app-dim">{inc.tipo.replace(/_/g, " ")}</span>
                  <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${inc.prioridad === "critica" ? "bg-state-critica/10 text-state-critica" : "bg-state-atencion/10 text-state-atencion"}`}>
                    {inc.prioridad}
                  </span>
                </div>
                <p className="mt-1 text-sm font-semibold text-app-text">{inc.descripcion}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default function ZoneDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [viewMode, setViewMode] = useState<"management" | "tv" | "tablet">("management");

  const zonesQuery = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: 60_000,
  });

  const zone = zonesQuery.data?.find((item) => item.id === id);

  const isTvMode = viewMode === "tv";

  return (
    <div className={`min-h-full ${isTvMode ? "bg-tv-bg text-white" : "bg-app-bg"}`}>
      {/* Header adapts to theme: dark only for TV mode */}
      <div className={`border-b px-6 py-4 lg:px-8 ${isTvMode ? "border-tv-border" : "border-app-border bg-white"}`}>
        <div className="flex flex-wrap items-center gap-4">
          <Link
            href="/zones"
            className={`flex items-center gap-1 text-sm transition ${isTvMode ? "text-tv-dim hover:text-white" : "text-app-dim hover:text-app-text"}`}
          >
            <ChevronLeft className="h-4 w-4" />
            Zonas
          </Link>
          <div className={`h-4 w-px ${isTvMode ? "bg-tv-border" : "bg-app-border"}`} />
          <div>
            <h1 className={`font-heading text-xl font-bold ${isTvMode ? "text-white" : "text-app-text"}`}>
              {zone?.nombre ?? id}
            </h1>
            <span className={`font-mono text-xs ${isTvMode ? "text-tv-dim" : "text-app-dim"}`}>
              {zone?.codigo ?? "ZONA"}
            </span>
          </div>

          <div className="ml-auto flex flex-wrap items-center gap-2">
            <Link
              href="/tv"
              className={`inline-flex items-center gap-1.5 rounded-[10px] border px-3 py-2 text-xs font-semibold transition ${
                isTvMode
                  ? "border-tv-border bg-tv-surface2 text-tv-accent hover:bg-tv-surface"
                  : "border-app-border bg-app-bg text-app-dim hover:border-brand/30 hover:text-brand"
              }`}
            >
              <Monitor className="h-3.5 w-3.5" />
              TV Global
            </Link>

            {/* Mode toggle: Management | TV | Tablet */}
            <div className={`flex overflow-hidden rounded-[10px] border ${isTvMode ? "border-tv-border bg-tv-surface" : "border-app-border bg-white"}`}>
              {[
                { key: "management", label: "Gestión", Icon: Settings2 },
                { key: "tv", label: "TV", Icon: Monitor },
                { key: "tablet", label: "Tablet", Icon: Tablet },
              ].map(({ key, label, Icon }) => {
                const active = viewMode === key;
                return (
                  <button
                    key={key}
                    type="button"
                    onClick={() => setViewMode(key as "management" | "tv" | "tablet")}
                    className={`inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold transition ${
                      active
                        ? isTvMode
                          ? "bg-tv-surface2 text-tv-accent"
                          : "bg-brand/10 text-brand"
                        : isTvMode
                          ? "text-tv-dim hover:text-white"
                          : "text-app-dim hover:text-app-text"
                    }`}
                  >
                    <Icon className="h-3.5 w-3.5" />
                    {label}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      {viewMode === "management" ? (
        <ManagementMode zoneId={id} />
      ) : viewMode === "tv" ? (
        <div className="px-6 py-6 lg:px-8">
          <TVMode zoneId={id} zoneName={zone?.nombre ?? "Zona"} />
        </div>
      ) : (
        <div className="px-6 py-6 lg:px-8">
          <TabletMode zoneId={id} />
        </div>
      )}
    </div>
  );
}
