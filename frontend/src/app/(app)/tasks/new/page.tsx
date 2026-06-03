"use client";

import { useMemo } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, ClipboardList } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/page-header";
import { api } from "@/lib/api";
import type { Task, Zone, Employee, TaskCatalogItem } from "@/lib/types";
import * as z from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

const tareaFormSchema = z.object({
  tarea_catalogo_id: z.string().optional(),
  zona_id: z.string().optional(),
  empleado_id: z.string().optional(),
  fecha_programada: z.string().min(1, "La fecha planificada es obligatoria"),
  observaciones: z.string().optional(),
});

type TareaFormData = z.infer<typeof tareaFormSchema>;

function getLocalDateTimeValue() {
  const date = new Date();
  date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
  return date.toISOString().slice(0, 16);
}

export default function TareaForm() {
  const router = useRouter();
  const queryClient = useQueryClient();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<TareaFormData>({
    resolver: zodResolver(tareaFormSchema),
    defaultValues: {
      tarea_catalogo_id: "",
      zona_id: "",
      empleado_id: "",
      fecha_programada: getLocalDateTimeValue(),
      observaciones: "",
    },
  });

  const zonesQuery = useQuery<Zone[]>({
    queryKey: ["zones"],
    queryFn: () => api.zones(),
    staleTime: 5 * 60_000,
  });

  const employeesQuery = useQuery<Employee[]>({
    queryKey: ["employees"],
    queryFn: () => api.employees(),
    staleTime: 5 * 60_000,
  });

  const taskCatalogQuery = useQuery<TaskCatalogItem[]>({
    queryKey: ["task-catalog-options"],
    queryFn: () => api.taskCatalog(),
    staleTime: 5 * 60_000,
  });

  const catalogOptions = useMemo(
    () =>
      (taskCatalogQuery.data ?? []).map((item) => ({
        id: item.id,
        nombre: item.nombre,
      })),
    [taskCatalogQuery.data],
  );

  const mutation = useMutation({
    mutationFn: (data: Partial<Task>) => api.createTask(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
      router.push("/tasks");
    },
  });

  const onSubmit = (data: TareaFormData) => {
    const payload: Partial<Task> = {
      fecha_programada: new Date(data.fecha_programada).toISOString(),
      ...(data.tarea_catalogo_id
        ? { tarea_catalogo_id: data.tarea_catalogo_id }
        : {}),
      ...(data.zona_id ? { zona_id: data.zona_id } : {}),
      ...(data.empleado_id ? { empleado_id: data.empleado_id } : {}),
      ...(data.observaciones ? { observaciones: data.observaciones } : {}),
    };

    mutation.mutate(payload);
  };

  return (
    <div className="min-h-full">
      <PageHeader
        eyebrow="Plan diario"
        title="Nueva Tarea"
        EyebrowIcon={ClipboardList}
      >
        <Link
          href="/tasks"
          className="flex items-center gap-2 rounded-full border border-app-border bg-white px-4 py-1.5 text-sm font-bold text-app-text transition hover:bg-app-bg"
        >
          <ArrowLeft className="h-4 w-4" />
          Volver
        </Link>
      </PageHeader>

      <div className="mx-auto max-w-2xl px-6 py-8">
        <div className="rounded-[10px] border border-app-border bg-white p-6 shadow-card">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            <div>
              <label className="mb-1 block text-sm font-semibold text-app-text">
                Tipo de tarea
              </label>
              <select
                {...register("tarea_catalogo_id")}
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm font-medium outline-none focus:border-brand"
              >
                <option value="">Selecciona una tarea del catálogo</option>
                {catalogOptions.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.nombre}
                  </option>
                ))}
              </select>
              {!taskCatalogQuery.isLoading && catalogOptions.length === 0 && (
                <p className="mt-2 text-xs text-app-dim">
                  No hay tareas de catálogo en los datos actuales. Se creará una
                  tarea con la primera entrada activa del catálogo en el
                  backend.
                </p>
              )}
            </div>

            <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
              <div>
                <label className="mb-1 block text-sm font-semibold text-app-text">
                  Zona
                </label>
                <select
                  {...register("zona_id")}
                  className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm font-medium outline-none focus:border-brand"
                >
                  <option value="">Sin especificar</option>
                  {zonesQuery.data?.map((zone) => (
                    <option key={zone.id} value={zone.id}>
                      {zone.nombre}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-1 block text-sm font-semibold text-app-text">
                  Asignar a
                </label>
                <select
                  {...register("empleado_id")}
                  className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm font-medium outline-none focus:border-brand"
                >
                  <option value="">Sin asignar</option>
                  {employeesQuery.data?.map((employee) => (
                    <option key={employee.id} value={employee.id}>
                      {employee.nombre}
                      {employee.apellidos ? ` ${employee.apellidos}` : ""}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label className="mb-1 block text-sm font-semibold text-app-text">
                Fecha y hora planificada *
              </label>
              <input
                type="datetime-local"
                {...register("fecha_programada")}
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm font-medium outline-none focus:border-brand"
              />
              {errors.fecha_programada && (
                <p className="mt-2 text-xs text-state-critica">
                  {errors.fecha_programada.message}
                </p>
              )}
            </div>

            <div>
              <label className="mb-1 block text-sm font-semibold text-app-text">
                Notas / Observaciones
              </label>
              <textarea
                rows={4}
                {...register("observaciones")}
                placeholder="Instrucciones adicionales para el operario..."
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm font-medium outline-none focus:border-brand resize-none"
              />
            </div>

            {mutation.isError && (
              <p className="text-xs text-state-critica">
                {mutation.error instanceof Error
                  ? mutation.error.message
                  : "Error al crear la tarea."}
              </p>
            )}

            <div className="pt-4">
              <button
                type="submit"
                disabled={mutation.isPending}
                className="w-full rounded-[10px] bg-brand px-5 py-3 font-bold text-white transition hover:bg-brand/90 disabled:opacity-50"
              >
                {mutation.isPending ? "Guardando..." : "Crear Tarea"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
