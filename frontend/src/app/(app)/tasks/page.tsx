"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertOctagon,
  CheckCircle2,
  ClipboardList,
  Clock,
  MapPin,
  TimerReset,
} from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { Pagination } from "@/components/common/Pagination";
import { PageHeader } from "@/components/ui/page-header";
import { api } from "@/lib/api";
import { DEFAULT_PAGE_SIZE, getSkip } from "@/lib/pagination";
import type { Task, TaskStatus } from "@/lib/types";

type FilterTab = "programada" | "retrasada" | "ejecutada";

const tabConfig: Record<
  FilterTab,
  { label: string; color: string; Icon: typeof Clock }
> = {
  programada: { label: "Programadas", color: "text-state-info", Icon: Clock },
  retrasada: {
    label: "Retrasadas",
    color: "text-state-critica",
    Icon: AlertOctagon,
  },
  ejecutada: {
    label: "Ejecutadas",
    color: "text-state-ok",
    Icon: CheckCircle2,
  },
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
    <span
      className={`rounded-full px-2.5 py-0.5 text-[11px] font-extrabold uppercase ${statusStyles[estado]}`}
    >
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
  const canComplete =
    task.estado === "programada" || task.estado === "retrasada";

  return (
    <div className="rounded-[10px] border border-app-border bg-white px-4 py-4 shadow-card transition hover:border-brand/20 hover:bg-app-bg">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge estado={task.estado} />
            {task.es_urgente && (
              <span className="rounded-full bg-state-critica/15 px-2 py-0.5 text-[11px] font-bold uppercase text-state-critica">
                Urgente
              </span>
            )}
            {categoria && (
              <span className="text-xs font-semibold capitalize text-app-dim">
                {categoria}
              </span>
            )}
          </div>
          <h2 className="mt-2 font-heading text-base font-bold text-app-text">
            {nombre}
          </h2>
          <div className="mt-1 flex flex-wrap gap-3 text-xs text-app-dim">
            <span>
              {fecha.toLocaleDateString("es-ES", {
                day: "2-digit",
                month: "short",
              })}{" "}
              {fecha.toLocaleTimeString("es-ES", {
                hour: "2-digit",
                minute: "2-digit",
              })}
            </span>
            {zona && <span className="capitalize">Zona: {zona}</span>}
            {task.ejecutado_por && <span>Por: {task.ejecutado_por}</span>}
          </div>
          {task.observaciones && (
            <p className="mt-2 text-xs text-app-dim">{task.observaciones}</p>
          )}
        </div>

        {canComplete ? (
          <button
            type="button"
            disabled={loading}
            onClick={() => onComplete(task.id)}
            className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-[10px] bg-brand/10 text-brand transition hover:bg-brand/15 disabled:opacity-50"
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
  const [zoneFilter, setZoneFilter] = useState<string>("");
  const pageSize = DEFAULT_PAGE_SIZE;

  const zonesQuery = useQuery({
    queryKey: ["zones"],
    queryFn: api.zones,
    staleTime: 5 * 60_000,
  });

  const tasksQuery = useQuery({
    queryKey: ["tasks", tab, page, zoneFilter],
    queryFn: () =>
      api.tasks({
        estado: tab,
        skip: getSkip(page, pageSize),
        limit: pageSize + 1,
        ...(zoneFilter ? { zona_id: zoneFilter } : {}),
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
      <PageHeader
        eyebrow="Plan diario"
        title="Tareas"
        EyebrowIcon={ClipboardList}
      >
        <div className="flex flex-wrap items-center gap-3">
          <span className="rounded-full border border-app-border bg-white px-3 py-1.5 text-sm font-bold text-app-text">
            {list.length} en pagina
          </span>
          <Link
            href="/tasks/new"
            className="rounded-[10px] border border-app-border bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand/90"
          >
            Añadir tarea
          </Link>
          <Link
            href="/task-catalog/new"
            className="rounded-[10px] border border-app-border bg-white px-4 py-2 text-sm font-bold text-app-text transition hover:bg-app-bg"
          >
            Nuevo catálogo
          </Link>
        </div>
      </PageHeader>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        <div className="flex flex-wrap items-end gap-3">
          <div className="grid min-w-0 flex-1 grid-cols-3 gap-3">
            {(
              Object.entries(tabConfig) as [
                FilterTab,
                (typeof tabConfig)[FilterTab],
              ][]
            ).map(([key, { label, color, Icon }]) => (
              <button
                key={key}
                type="button"
                onClick={() => {
                  setTab(key);
                  setPage(1);
                }}
                className={`rounded-[10px] border px-4 py-3 text-left transition ${
                  tab === key
                    ? "border-brand/25 bg-brand/10"
                    : "border-app-border bg-white hover:bg-app-bg"
                }`}
              >
                <div className="flex items-center gap-2">
                  <Icon
                    className={`h-4 w-4 ${tab === key ? color : "text-app-dim"}`}
                  />
                  <span
                    className={`text-sm font-bold ${tab === key ? "text-brand" : "text-app-dim"}`}
                  >
                    {label}
                  </span>
                </div>
              </button>
            ))}
          </div>

          {/* Filtro por zona */}
          <div className="flex items-center gap-2 rounded-[10px] border border-app-border bg-white px-3 py-2.5">
            <MapPin className="h-4 w-4 shrink-0 text-app-dim" />
            <select
              value={zoneFilter}
              onChange={(e) => {
                setZoneFilter(e.target.value);
                setPage(1);
              }}
              className="bg-transparent text-sm font-semibold text-app-text outline-none"
              aria-label="Filtrar por zona"
            >
              <option value="">Todas las zonas</option>
              {(zonesQuery.data ?? []).map((z) => (
                <option key={z.id} value={z.id}>
                  {z.nombre}
                </option>
              ))}
            </select>
          </div>
        </div>

        {tasksQuery.isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, index) => (
              <div
                key={index}
                className="h-24 animate-pulse rounded-[10px] bg-app-surface2"
              />
            ))}
          </div>
        )}

        {tasksQuery.isError && (
          <div className="rounded-[10px] border border-state-critica/30 bg-state-critica/10 px-4 py-3 text-sm font-semibold text-state-critica">
            Error al cargar tareas.
          </div>
        )}

        {!tasksQuery.isLoading && list.length === 0 && (
          <div className="rounded-[10px] border border-app-border bg-white py-16 text-center shadow-card">
            <TimerReset
              className="mx-auto h-12 w-12 text-app-dim"
              strokeWidth={1.5}
            />
            <p className="mt-3 font-heading text-lg font-bold text-app-text">
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
