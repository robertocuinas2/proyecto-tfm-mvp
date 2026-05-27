"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertOctagon, CheckCircle2, ClipboardList, Clock, TimerReset } from "lucide-react";
import { useState } from "react";
import { Pagination } from "@/components/common/Pagination";
import { api } from "@/lib/api";
import { DEFAULT_PAGE_SIZE, getSkip } from "@/lib/pagination";
import type { Task, TaskStatus } from "@/lib/types";

type FilterTab = "programada" | "retrasada" | "ejecutada";

const tabConfig: Record<FilterTab, { label: string; color: string; Icon: typeof Clock }> = {
  programada: { label: "Programadas", color: "text-state-info", Icon: Clock },
  retrasada: { label: "Retrasadas", color: "text-state-critica", Icon: AlertOctagon },
  ejecutada: { label: "Ejecutadas", color: "text-state-ok", Icon: CheckCircle2 },
};

const statusStyles: Record<TaskStatus, string> = {
  programada: "bg-state-info/15 text-state-info",
  ejecutada: "bg-state-ok/15 text-state-ok",
  retrasada: "bg-state-critica/15 text-state-critica",
  cancelada: "bg-state-neutral/10 text-state-neutral",
  pausada: "bg-state-atencion/15 text-state-atencion",
};

function StatusBadge({ estado }: { estado: TaskStatus }) {
  return (
    <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-extrabold uppercase ${statusStyles[estado]}`}>
      {estado}
    </span>
  );
}

function TaskCard({
  task,
  onComplete,
  loading,
}: {
  task: Task;
  onComplete: (id: string) => void;
  loading: boolean;
}) {
  const nombre = task.tarea_catalogo?.nombre ?? "Tarea sin nombre";
  const categoria = task.tarea_catalogo?.categoria;
  const zona = task.tarea_catalogo?.zona_aplicable;
  const fecha = new Date(task.fecha_programada);
  const canComplete = task.estado === "programada" || task.estado === "retrasada";

  return (
    <div className="rounded-lg border border-tv-border bg-tv-surface px-4 py-4 transition hover:border-tv-accent/35 hover:bg-tv-surface2">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge estado={task.estado} />
            {task.es_urgente && (
              <span className="rounded-full bg-state-critica/15 px-2 py-0.5 text-[11px] font-bold uppercase text-state-critica">
                Urgente
              </span>
            )}
            {categoria && <span className="text-xs font-semibold capitalize text-tv-dim">{categoria}</span>}
          </div>
          <h2 className="mt-2 font-heading text-base font-bold text-white">{nombre}</h2>
          <div className="mt-1 flex flex-wrap gap-3 text-xs text-tv-dim">
            <span>
              {fecha.toLocaleDateString("es-ES", { day: "2-digit", month: "short" })}{" "}
              {fecha.toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" })}
            </span>
            {zona && <span className="capitalize">Zona: {zona}</span>}
            {task.ejecutado_por && <span>Por: {task.ejecutado_por}</span>}
          </div>
          {task.observaciones && <p className="mt-2 text-xs text-tv-dim">{task.observaciones}</p>}
        </div>

        {canComplete ? (
          <button
            type="button"
            disabled={loading}
            onClick={() => onComplete(task.id)}
            className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-tv-accent/15 text-tv-accent transition hover:bg-tv-accent/25 disabled:opacity-50"
            title="Completar tarea"
          >
            <CheckCircle2 className="h-4 w-4" />
          </button>
        ) : (
          <CheckCircle2 className="h-5 w-5 shrink-0 text-state-ok" />
        )}
      </div>
    </div>
  );
}

export default function TasksPage() {
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<FilterTab>("programada");
  const [page, setPage] = useState(1);
  const pageSize = DEFAULT_PAGE_SIZE;

  const tasksQuery = useQuery({
    queryKey: ["tasks", tab, page],
    queryFn: () =>
      api.tasks({
        estado: tab,
        skip: getSkip(page, pageSize),
        limit: pageSize + 1,
      }),
    refetchInterval: 30_000,
  });

  const completeMutation = useMutation({
    mutationFn: (id: string) => api.completeTask(id),
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-summary"] });
    },
  });

  const fetched = tasksQuery.data ?? [];
  const hasNext = fetched.length > pageSize;
  const list = fetched.slice(0, pageSize);

  return (
    <div className="min-h-full">
      <div className="border-b border-tv-border px-6 py-5 lg:px-8">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.18em] text-tv-dim">
              <ClipboardList className="h-4 w-4 text-tv-accent" />
              Plan diario
            </div>
            <h1 className="mt-1 font-heading text-2xl font-bold text-white">Tareas</h1>
          </div>
          <span className="rounded-full border border-tv-border bg-tv-surface px-3 py-1.5 text-sm font-bold text-white">
            {list.length} en pagina
          </span>
        </div>
      </div>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        <div className="grid grid-cols-3 gap-3">
          {(Object.entries(tabConfig) as [FilterTab, (typeof tabConfig)[FilterTab]][]).map(
            ([key, { label, color, Icon }]) => (
              <button
                key={key}
                type="button"
                onClick={() => {
                  setTab(key);
                  setPage(1);
                }}
                className={`rounded-lg border px-4 py-3 text-left transition ${
                  tab === key
                    ? "border-tv-accent/40 bg-tv-surface2"
                    : "border-tv-border bg-tv-surface hover:bg-tv-surface2"
                }`}
              >
                <div className="flex items-center gap-2">
                  <Icon className={`h-4 w-4 ${tab === key ? color : "text-tv-dim"}`} />
                  <span className="text-sm font-bold text-white">{label}</span>
                </div>
              </button>
            ),
          )}
        </div>

        {tasksQuery.isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, index) => (
              <div key={index} className="h-24 animate-pulse rounded-lg bg-tv-surface" />
            ))}
          </div>
        )}

        {tasksQuery.isError && (
          <div className="rounded-lg border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar tareas.
          </div>
        )}

        {!tasksQuery.isLoading && list.length === 0 && (
          <div className="rounded-lg border border-tv-border bg-tv-surface py-16 text-center">
            <TimerReset className="mx-auto h-12 w-12 text-tv-dim" strokeWidth={1.5} />
            <p className="mt-3 font-heading text-lg font-bold text-white">
              No hay tareas {tabConfig[tab].label.toLowerCase()}
            </p>
          </div>
        )}

        <div className="space-y-3">
          {list.map((task) => (
            <TaskCard
              key={task.id}
              task={task}
              onComplete={(id) => completeMutation.mutate(id)}
              loading={completeMutation.isPending}
            />
          ))}
        </div>

        {!tasksQuery.isLoading && list.length > 0 && (
          <Pagination
            page={page}
            pageSize={pageSize}
            currentCount={list.length}
            hasNext={hasNext}
            isLoading={tasksQuery.isFetching}
            onPageChange={setPage}
          />
        )}
      </div>
    </div>
  );
}
