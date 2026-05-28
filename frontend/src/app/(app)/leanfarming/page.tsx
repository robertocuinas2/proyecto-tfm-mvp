"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertOctagon,
  CheckCircle2,
  Clock,
  LayoutGrid,
  ListChecks,
  ListTodo,
  RefreshCw,
} from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { api } from "@/lib/api";
import type { Task, Zone } from "@/lib/types";

type ViewMode = "zonas" | "lista";
type ZoneStatus = "critica" | "atencion" | "operativa" | "inactiva";

type ZoneTaskSummary = {
  zone: Zone;
  programadas: Task[];
  retrasadas: Task[];
  ejecutadas: Task[];
  urgentes: Task[];
};

const statusStyles: Record<ZoneStatus, string> = {
  critica: "border-state-critica/40 bg-state-critica/10 text-state-critica",
  atencion: "border-state-atencion/40 bg-state-atencion/10 text-state-atencion",
  operativa: "border-tv-accent/30 bg-tv-accent/10 text-tv-accent",
  inactiva: "border-tv-border bg-tv-surface2 text-tv-dim",
};

const statusDot: Record<ZoneStatus, string> = {
  critica: "bg-state-critica",
  atencion: "bg-state-atencion",
  operativa: "bg-tv-accent",
  inactiva: "bg-tv-dim",
};

function getZoneStatus(summary: ZoneTaskSummary): ZoneStatus {
  if (summary.retrasadas.some((task) => task.es_urgente)) return "critica";
  if (summary.retrasadas.length > 0 || summary.urgentes.length > 0) return "atencion";
  if (summary.programadas.length === 0 && summary.ejecutadas.length === 0) return "inactiva";
  return "operativa";
}

function TaskRow({
  task,
  onComplete,
  completing,
}: {
  task: Task;
  onComplete: (taskId: string) => void;
  completing: boolean;
}) {
  const canComplete = task.estado === "programada" || task.estado === "retrasada";

  return (
    <div className="flex items-center justify-between gap-3 rounded-lg border border-tv-border bg-tv-surface2 px-3 py-2.5">
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          {task.estado === "retrasada" && (
            <AlertOctagon className="h-3.5 w-3.5 shrink-0 text-state-critica" />
          )}
          {task.es_urgente && task.estado !== "retrasada" && (
            <Clock className="h-3.5 w-3.5 shrink-0 text-state-atencion" />
          )}
          <p className="truncate text-sm font-semibold text-white">
            {task.tarea_catalogo?.nombre ?? "Tarea"}
          </p>
        </div>
        <p className="mt-0.5 text-xs text-tv-dim">
          {new Date(task.fecha_programada).toLocaleString("es-ES", {
            day: "2-digit",
            month: "short",
            hour: "2-digit",
            minute: "2-digit",
          })}
        </p>
      </div>

      {canComplete ? (
        <button
          type="button"
          disabled={completing}
          onClick={() => onComplete(task.id)}
          className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-tv-accent/15 text-tv-accent transition hover:bg-tv-accent/25 disabled:opacity-50"
          title="Completar tarea"
        >
          <CheckCircle2 className="h-4 w-4" />
        </button>
      ) : (
        <CheckCircle2 className="h-5 w-5 shrink-0 text-state-ok" />
      )}
    </div>
  );
}

function ZoneCard({
  summary,
  onComplete,
  completing,
}: {
  summary: ZoneTaskSummary;
  onComplete: (taskId: string) => void;
  completing: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const status = getZoneStatus(summary);
  const total = summary.programadas.length + summary.retrasadas.length + summary.ejecutadas.length;
  const pct = total > 0 ? Math.round((summary.ejecutadas.length / total) * 100) : 0;
  const priorityTasks = [
    ...summary.retrasadas,
    ...summary.urgentes.filter((task) => task.estado === "programada"),
    ...summary.programadas.filter((task) => !task.es_urgente),
  ];

  return (
    <div className="rounded-lg border border-tv-border bg-tv-surface">
      <button
        type="button"
        className="w-full px-4 py-4 text-left"
        onClick={() => setExpanded((value) => !value)}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className={`h-2.5 w-2.5 shrink-0 rounded-full ${statusDot[status]}`} />
              <span className="font-mono text-[11px] font-bold uppercase tracking-widest text-tv-dim">
                {summary.zone.codigo}
              </span>
            </div>
            <h2 className="mt-1 truncate font-heading text-lg font-bold text-white">
              {summary.zone.nombre}
            </h2>
          </div>
          <span className={`shrink-0 rounded-full border px-2.5 py-1 text-[10px] font-extrabold uppercase ${statusStyles[status]}`}>
            {status}
          </span>
        </div>

        <div className="mt-4">
          <div className="mb-1 flex justify-between text-xs font-semibold text-tv-dim">
            <span>{summary.ejecutadas.length} / {total || 0} completadas</span>
            <span>{pct}%</span>
          </div>
          <div className="h-1.5 rounded-full bg-tv-surface2">
            <div className="h-full rounded-full bg-tv-accent" style={{ width: `${pct}%` }} />
          </div>
        </div>

        <div className="mt-4 grid grid-cols-4 gap-2">
          {[
            { label: "Prog.", value: summary.programadas.length, color: "text-state-info" },
            { label: "Retras.", value: summary.retrasadas.length, color: "text-state-critica" },
            { label: "Hechas", value: summary.ejecutadas.length, color: "text-state-ok" },
            { label: "Urg.", value: summary.urgentes.length, color: "text-state-atencion" },
          ].map(({ label, value, color }) => (
            <div key={label} className="rounded-lg bg-tv-surface2 px-2 py-2 text-center">
              <div className={`font-heading text-lg font-bold ${color}`}>{value}</div>
              <div className="text-[10px] font-bold uppercase text-tv-dim">{label}</div>
            </div>
          ))}
        </div>
      </button>

      {expanded && (
        <div className="space-y-2 border-t border-tv-border px-4 pb-4 pt-3">
          {priorityTasks.map((task) => (
            <TaskRow
              key={task.id}
              task={task}
              onComplete={onComplete}
              completing={completing}
            />
          ))}
          {priorityTasks.length === 0 && (
            <div className="rounded-lg bg-tv-surface2 px-3 py-6 text-center text-sm font-semibold text-tv-dim">
              Sin tareas pendientes en esta zona.
            </div>
          )}
          <Link
            href={`/zones/${summary.zone.id}`}
            className="block pt-1 text-center text-xs font-semibold text-tv-accent hover:underline"
          >
            Abrir vista de zona completa →
          </Link>
        </div>
      )}
    </div>
  );
}

function GlobalTaskList({
  tasks,
  onComplete,
  completing,
}: {
  tasks: Task[];
  onComplete: (id: string) => void;
  completing: boolean;
}) {
  const [tab, setTab] = useState<Task["estado"]>("retrasada");
  const filtered = tasks.filter((task) => task.estado === tab);

  const tabs = [
    { key: "retrasada", label: "Retrasadas", color: "text-state-critica" },
    { key: "programada", label: "Programadas", color: "text-state-info" },
    { key: "ejecutada", label: "Ejecutadas", color: "text-state-ok" },
  ] as const;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        {tabs.map(({ key, label, color }) => {
          const count = tasks.filter((task) => task.estado === key).length;
          return (
            <button
              key={key}
              type="button"
              onClick={() => setTab(key)}
              className={`inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold transition ${
                tab === key
                  ? "bg-tv-surface2 text-white"
                  : "bg-tv-surface text-tv-dim hover:bg-tv-surface2"
              }`}
            >
              {label}
              <span className={`rounded-full px-1.5 text-[11px] font-bold ${tab === key ? color : "text-tv-dim"}`}>
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {filtered.length === 0 ? (
        <div className="rounded-lg border border-tv-border bg-tv-surface px-4 py-12 text-center">
          <CheckCircle2 className="mx-auto h-8 w-8 text-state-ok" strokeWidth={1.6} />
          <p className="mt-2 text-sm font-semibold text-white">No hay tareas en esta vista.</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.slice(0, 30).map((task) => (
            <TaskRow key={task.id} task={task} onComplete={onComplete} completing={completing} />
          ))}
        </div>
      )}
    </div>
  );
}

export default function LeanFarmingPage() {
  const queryClient = useQueryClient();
  const [view, setView] = useState<ViewMode>("zonas");

  const zones = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: 60_000,
  });

  const tasksQuery = useQuery({
    queryKey: ["tasks-all-lean"],
    queryFn: () => api.tasks({ limit: 500 }),
    staleTime: 30_000,
    refetchInterval: 60_000,
  });

  const completeMutation = useMutation({
    mutationFn: (id: string) => api.completeTask(id),
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks-all-lean"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-summary"] });
    },
  });

  const tasks = tasksQuery.data ?? [];
  const zoneSummaries: ZoneTaskSummary[] = (zones.data ?? []).map((zone) => {
    const zoneTasks = tasks.filter((task) => task.zona_id === zone.id);
    return {
      zone,
      programadas: zoneTasks.filter((task) => task.estado === "programada"),
      retrasadas: zoneTasks.filter((task) => task.estado === "retrasada"),
      ejecutadas: zoneTasks.filter((task) => task.estado === "ejecutada"),
      urgentes: zoneTasks.filter((task) => task.es_urgente && task.estado !== "ejecutada"),
    };
  });

  const totals = {
    programadas: tasks.filter((task) => task.estado === "programada").length,
    retrasadas: tasks.filter((task) => task.estado === "retrasada").length,
    ejecutadas: tasks.filter((task) => task.estado === "ejecutada").length,
    urgentes: tasks.filter((task) => task.es_urgente && task.estado !== "ejecutada").length,
  };

  return (
    <div className="min-h-full bg-tv-bg text-white">
      <div className="border-b border-tv-border px-6 py-5 lg:px-8">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
              <ListTodo className="h-4 w-4 text-tv-accent" />
              LeanFarming
            </div>
            <h1 className="mt-1 font-heading text-2xl font-bold text-white">
              Gestion visual de tareas por zona
            </h1>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <div className="flex overflow-hidden rounded-lg border border-tv-border bg-tv-surface">
              {[
                { key: "zonas", label: "Por zona", Icon: LayoutGrid },
                { key: "lista", label: "Lista", Icon: ListChecks },
              ].map(({ key, label, Icon }) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => setView(key as ViewMode)}
                  className={`inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold transition ${
                    view === key ? "bg-tv-surface2 text-tv-accent" : "text-tv-dim hover:text-white"
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  {label}
                </button>
              ))}
            </div>
            <button
              type="button"
              onClick={() => tasksQuery.refetch()}
              className="inline-flex items-center gap-2 rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm font-semibold text-tv-dim transition hover:text-white"
            >
              <RefreshCw className="h-4 w-4" />
              Actualizar
            </button>
          </div>
        </div>
      </div>

      <div className="space-y-6 px-6 py-6 lg:px-8">
        <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
          {[
            { label: "Programadas", value: totals.programadas, Icon: Clock, color: "text-state-info" },
            { label: "Retrasadas", value: totals.retrasadas, Icon: AlertOctagon, color: "text-state-critica" },
            { label: "Ejecutadas", value: totals.ejecutadas, Icon: CheckCircle2, color: "text-state-ok" },
            { label: "Urgentes", value: totals.urgentes, Icon: ListTodo, color: "text-state-atencion" },
          ].map(({ label, value, Icon, color }) => (
            <div key={label} className="rounded-lg border border-tv-border bg-tv-surface p-4">
              <div className="flex items-center gap-2">
                <Icon className={`h-4 w-4 ${color}`} />
                <span className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-tv-dim">
                  {label}
                </span>
              </div>
              <div className={`mt-2 font-heading text-4xl font-bold ${color}`}>{value}</div>
            </div>
          ))}
        </div>

        {tasksQuery.isLoading || zones.isLoading ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {Array.from({ length: 6 }).map((_, index) => (
              <div key={index} className="h-52 animate-pulse rounded-lg bg-tv-surface" />
            ))}
          </div>
        ) : view === "zonas" ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {zoneSummaries.map((summary) => (
              <ZoneCard
                key={summary.zone.id}
                summary={summary}
                onComplete={(id) => completeMutation.mutate(id)}
                completing={completeMutation.isPending}
              />
            ))}
          </div>
        ) : (
          <GlobalTaskList
            tasks={tasks}
            onComplete={(id) => completeMutation.mutate(id)}
            completing={completeMutation.isPending}
          />
        )}
      </div>
    </div>
  );
}
