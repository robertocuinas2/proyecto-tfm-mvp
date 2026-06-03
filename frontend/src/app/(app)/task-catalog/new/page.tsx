"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, ClipboardList } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/page-header";
import { api } from "@/lib/api";
import type { TaskCatalogItem } from "@/lib/types";
import * as z from "zod";
import { useForm, type Resolver } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

const taskCatalogSchema = z.object({
  codigo: z.string().min(1, "El código es obligatorio"),
  nombre: z.string().min(1, "El nombre es obligatorio"),
  descripcion: z.string().optional(),
  cualificacion_requerida: z.string().optional(),
  duracion_estimada_min: z.preprocess((value) => {
    if (value === "" || value === null || value === undefined) {
      return undefined;
    }
    return Number(value);
  }, z.number().int().nonnegative().optional()),
  activa: z.boolean(),
});

type TaskCatalogFormData = z.infer<typeof taskCatalogSchema>;

export default function TaskCatalogNewPage() {
  const router = useRouter();
  const queryClient = useQueryClient();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<TaskCatalogFormData>({
    resolver: zodResolver(taskCatalogSchema) as Resolver<TaskCatalogFormData>,
    defaultValues: {
      codigo: "",
      nombre: "",
      descripcion: "",
      cualificacion_requerida: "",
      duracion_estimada_min: undefined,
      activa: true,
    },
  });

  const mutation = useMutation({
    mutationFn: (data: Partial<TaskCatalogItem>) => api.createTaskCatalog(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["task-catalog-options"] });
      router.push("/tasks");
    },
  });

  return (
    <div className="min-h-full">
      <PageHeader
        eyebrow="Catálogo"
        title="Nueva tarea de catálogo"
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
          <form
            onSubmit={handleSubmit((data) => mutation.mutate(data))}
            className="space-y-5"
          >
            <div>
              <label className="mb-1 block text-sm font-semibold text-app-text">
                Código
              </label>
              <input
                type="text"
                {...register("codigo")}
                placeholder="Ej: lavado_robot"
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm text-app-text outline-none focus:border-brand"
              />
              {errors.codigo && (
                <p className="mt-2 text-xs text-state-critica">
                  {errors.codigo.message}
                </p>
              )}
            </div>

            <div>
              <label className="mb-1 block text-sm font-semibold text-app-text">
                Nombre
              </label>
              <input
                type="text"
                {...register("nombre")}
                placeholder="Ej: Lavado de robot de ordeño"
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm text-app-text outline-none focus:border-brand"
              />
              {errors.nombre && (
                <p className="mt-2 text-xs text-state-critica">
                  {errors.nombre.message}
                </p>
              )}
            </div>

            <div>
              <label className="mb-1 block text-sm font-semibold text-app-text">
                Descripción
              </label>
              <textarea
                rows={3}
                {...register("descripcion")}
                placeholder="Descripción breve de la tarea"
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm text-app-text outline-none focus:border-brand resize-none"
              />
            </div>

            <div>
              <label className="mb-1 block text-sm font-semibold text-app-text">
                Cualificación requerida
              </label>
              <textarea
                rows={3}
                {...register("cualificacion_requerida")}
                placeholder="Ej: operario, alimentacion, mecanico"
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm text-app-text outline-none focus:border-brand resize-none"
              />
            </div>

            <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
              <div>
                <label className="mb-1 block text-sm font-semibold text-app-text">
                  Duración estimada (min)
                </label>
                <input
                  type="number"
                  min={0}
                  {...register("duracion_estimada_min")}
                  className="w-full rounded-[10px] border border-app-border bg-app-bg px-4 py-2.5 text-sm text-app-text outline-none focus:border-brand"
                />
              </div>

              <div className="flex items-center gap-3 rounded-[10px] border border-app-border bg-app-bg px-4 py-3">
                <input
                  type="checkbox"
                  {...register("activa")}
                  className="rounded border-app-border text-brand w-4 h-4"
                />
                <span className="text-sm text-app-text">Activa</span>
              </div>
            </div>

            {mutation.isError && (
              <p className="text-xs text-state-critica">
                {mutation.error instanceof Error
                  ? mutation.error.message
                  : "Error al crear la tarea de catálogo."}
              </p>
            )}

            <div className="pt-4">
              <button
                type="submit"
                disabled={mutation.isPending}
                className="w-full rounded-[10px] bg-brand px-5 py-3 font-bold text-white transition hover:bg-brand/90 disabled:opacity-50"
              >
                {mutation.isPending
                  ? "Guardando..."
                  : "Crear tarea de catálogo"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
