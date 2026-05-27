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
  Tablet,
  X,
} from "lucide-react";
import Link from "next/link";
import { use, useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { CreateIncidentPayload, IncidentPriority, Task } from "@/lib/types";

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
  programada: "border-l-state-info bg-tv-surface2/60",
  ejecutada: "border-l-state-ok bg-state-ok/5",
  pausada: "border-l-state-atencion bg-state-atencion/5",
  cancelada: "border-l-tv-dim bg-tv-surface2/30",
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
  cancelada: "text-tv-dim",
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
    refetchInterval: 30_000,
  });

  const alertsQuery = useQuery({
    queryKey: ["alerts-pending"],
    queryFn: () => api.alerts({ limit: 50 }),
    refetchInterval: 30_000,
  });

  const tasks = tasksQuery.data ?? [];
  const delayed = tasks.filter((task) => task.estado === "retrasada");
  const urgent = tasks.filter((task) => task.estado === "programada" && task.es_urgente);
  const pending = tasks.filter((task) => task.estado === "programada" && !task.es_urgente);
  const done = tasks.filter((task) => task.estado === "ejecutada");
  const alerts = (alertsQuery.data?.alertas ?? []).filter((alert) => alert.estado === "pendiente");
  const critical = alerts.filter((alert) => alert.severidad === "critica");

  return (
    <div className="space-y-4">
      <div className="grid gap-3 rounded-lg border border-tv-border bg-tv-surface p-4 md:grid-cols-4">
        {[
          { label: "Zona", value: zoneName, color: "text-white" },
          { label: "Alertas criticas", value: critical.length, color: "text-state-critica" },
          { label: "Tareas retrasadas", value: delayed.length, color: "text-state-atencion" },
          { label: "Hora actual", value: <LiveClock />, color: "text-tv-accent" },
        ].map(({ label, value, color }) => (
          <div key={label} className="text-center">
            <div className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-tv-dim">{label}</div>
            <div className={`mt-2 font-heading text-3xl font-bold ${color}`}>{value}</div>
          </div>
        ))}
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
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
              className="w-full resize-none rounded-lg border border-tv-border bg-tv-surface2 px-3 py-2.5 text-sm text-white outline-none placeholder:text-tv-dim focus:border-tv-accent"
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
    refetchInterval: 30_000,
  });

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
          <p className="mb-2 text-[11px] font-extrabold uppercase tracking-[0.14em] text-tv-dim">
            Acciones rapidas
          </p>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { label: "Completar tarea", Icon: CheckCircle2, color: "text-tv-accent", action: undefined },
              { label: "Nueva incidencia", Icon: Plus, color: "text-state-critica", action: () => setShowIncident(true) },
              { label: "Ver alertas", Icon: AlertTriangle, color: "text-state-atencion", action: undefined },
              { label: "Tareas urgentes", Icon: Clock, color: "text-state-info", action: undefined },
            ].map(({ label, Icon, color, action }) => (
              <button
                key={label}
                type="button"
                onClick={action}
                className="flex min-h-[78px] flex-col items-center justify-center gap-2 rounded-lg border border-tv-border bg-tv-surface px-3 py-4 text-center transition hover:border-tv-accent/40 hover:bg-tv-surface2"
              >
                <Icon className={`h-6 w-6 ${color}`} />
                <span className="text-xs font-semibold text-white">{label}</span>
              </button>
            ))}
          </div>
        </div>

        {successId && (
          <div className="flex items-center gap-2 rounded-lg bg-state-ok/15 px-4 py-3 text-sm font-bold text-state-ok">
            <CheckCircle2 className="h-4 w-4" />
            Tarea completada y registrada
          </div>
        )}

        <div className="grid gap-4 lg:grid-cols-2">
          <section>
            <p className="mb-2 text-[11px] font-extrabold uppercase tracking-[0.14em] text-tv-dim">
              Trabajo pendiente · {pending.length} tareas
            </p>
            {tasksQuery.isLoading ? (
              Array.from({ length: 3 }).map((_, index) => (
                <div key={index} className="mb-2 h-20 animate-pulse rounded-lg bg-tv-surface" />
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
                        active ? "border-tv-accent ring-2 ring-tv-accent/30" : "hover:border-tv-accent/40"
                      }`}
                    >
                      <span className={`text-[10px] font-extrabold uppercase tracking-[0.14em] ${taskTone[task.estado]}`}>
                        {taskLabel[task.estado]}
                        {task.es_urgente && " · URGENTE"}
                      </span>
                      <p className="mt-0.5 font-heading text-sm font-bold text-white">
                        {task.tarea_catalogo?.nombre ?? "Tarea"}
                      </p>
                      <p className="mt-0.5 text-xs text-tv-dim">
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
            <p className="mb-2 text-[11px] font-extrabold uppercase tracking-[0.14em] text-tv-dim">
              Detalle de tarea
            </p>
            {!selectedTask ? (
              <div className="rounded-lg border border-dashed border-tv-border bg-tv-surface px-4 py-10 text-center text-sm text-tv-dim">
                Selecciona una tarea para ver el detalle
              </div>
            ) : (
              <div className="space-y-4 rounded-lg border border-tv-border bg-tv-surface p-5">
                <div>
                  <span className={`text-[10px] font-extrabold uppercase tracking-[0.14em] ${taskTone[selectedTask.estado]}`}>
                    {taskLabel[selectedTask.estado]}
                  </span>
                  <h3 className="mt-1 font-heading text-base font-bold text-white">
                    {selectedTask.tarea_catalogo?.nombre ?? "Tarea"}
                  </h3>
                  <p className="mt-0.5 text-xs text-tv-dim">
                    Programada:{" "}
                    {new Date(selectedTask.fecha_programada).toLocaleString("es-ES", {
                      dateStyle: "medium",
                      timeStyle: "short",
                    })}
                  </p>
                </div>

                <div>
                  <label className="mb-1.5 block text-xs font-extrabold uppercase tracking-[0.14em] text-tv-dim">
                    Observaciones
                  </label>
                  <textarea
                    rows={3}
                    value={observaciones}
                    onChange={(event) => setObservaciones(event.target.value)}
                    placeholder="Incidencias encontradas, notas"
                    className="w-full resize-none rounded-lg border border-tv-border bg-tv-surface2 px-3 py-2.5 text-sm text-white outline-none placeholder:text-tv-dim focus:border-tv-accent"
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
      </div>
    </>
  );
}

export default function ZoneDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [viewMode, setViewMode] = useState<"tv" | "tablet">("tv");

  const zonesQuery = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: 60_000,
  });

  const zone = zonesQuery.data?.find((item) => item.id === id);

  return (
    <div className="min-h-full">
      <div className="border-b border-tv-border px-6 py-4 lg:px-8">
        <div className="flex flex-wrap items-center gap-4">
          <Link href="/zones" className="flex items-center gap-1 text-sm text-tv-dim hover:text-white">
            <ChevronLeft className="h-4 w-4" />
            Zonas
          </Link>
          <div className="h-4 w-px bg-tv-border" />
          <div>
            <h1 className="font-heading text-xl font-bold text-white">{zone?.nombre ?? id}</h1>
            <span className="font-mono text-xs text-tv-dim">{zone?.codigo ?? "ZONA"}</span>
          </div>

          <div className="ml-auto flex overflow-hidden rounded-lg border border-tv-border bg-tv-surface">
            {[
              { key: "tv", label: "TV", Icon: Monitor },
              { key: "tablet", label: "Tablet", Icon: Tablet },
            ].map(({ key, label, Icon }) => (
              <button
                key={key}
                type="button"
                onClick={() => setViewMode(key as "tv" | "tablet")}
                className={`inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold transition ${
                  viewMode === key ? "bg-tv-surface2 text-tv-accent" : "text-tv-dim hover:text-white"
                }`}
              >
                <Icon className="h-4 w-4" />
                {label}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="px-6 py-6 lg:px-8">
        {viewMode === "tv" ? (
          <TVMode zoneId={id} zoneName={zone?.nombre ?? "Zona"} />
        ) : (
          <TabletMode zoneId={id} />
        )}
      </div>
    </div>
  );
}
