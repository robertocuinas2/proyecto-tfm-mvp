"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import * as z from "zod";
import { api } from "@/lib/api";

const zonaSchema = z.object({
  nombre: z.string().min(1, "El nombre es obligatorio"),
  codigo: z.string().min(1, "El código es obligatorio"),
  descripcion: z.string().optional(),
  tiene_pantalla_tv: z.boolean(),
  tiene_tablet: z.boolean(),
});

type ZonaFormData = z.infer<typeof zonaSchema>;

export default function ZonaForm() {
  const router = useRouter();
  const queryClient = useQueryClient();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ZonaFormData>({
    resolver: zodResolver(zonaSchema),
    defaultValues: {
      nombre: "",
      codigo: "",
      descripcion: "",
      tiene_pantalla_tv: false,
      tiene_tablet: false,
    },
  });

  // useMutation reemplaza el async/await
  const mutation = useMutation({
    mutationFn: (datos: ZonaFormData) => api.createZone(datos),
    onSuccess: () => {
      // Invalida la caché de zonas para que la lista se refresque
      queryClient.invalidateQueries({ queryKey: ["zones"] });
      router.push("/zones");
    },
  });

  const onSubmit = (datos: ZonaFormData) => {
    mutation.mutate(datos);
  };

  return (
    <div className="mx-auto max-w-lg space-y-6 p-6">
      <div>
        <h2 className="font-heading text-2xl font-bold text-black">
          Nueva zona
        </h2>
        <p className="mt-1 text-sm text-tv-dim">
          Crea una nueva zona de trabajo en la explotación.
        </p>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Nombre
          </label>
          <input
            type="text"
            {...register("nombre")}
            placeholder="Ej: Sala de robots, Becerrero..."
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          />
          {errors.nombre && (
            <p className="mt-1 text-xs text-state-critica">
              {errors.nombre.message}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Código
          </label>
          <input
            type="text"
            {...register("codigo")}
            placeholder="Ej: zona_robots, becerrero..."
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          />
          {errors.codigo && (
            <p className="mt-1 text-xs text-state-critica">
              {errors.codigo.message}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Descripción{" "}
            <span className="text-tv-dim font-normal">(opcional)</span>
          </label>
          <textarea
            {...register("descripcion")}
            rows={3}
            placeholder="Describe la zona..."
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent resize-none"
          />
        </div>

        <div className="space-y-3">
          <label className="block text-sm font-medium text-tv-dim">
            Equipamiento
          </label>
          <label className="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              {...register("tiene_pantalla_tv")}
              className="rounded border-tv-border text-tv-accent w-4 h-4"
            />
            <span className="text-sm text-black">Tiene pantalla TV</span>
          </label>
          <label className="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              {...register("tiene_tablet")}
              className="rounded border-tv-border text-tv-accent w-4 h-4"
            />
            <span className="text-sm text-black">Tiene tablet</span>
          </label>
        </div>

        {/* Error global de la mutación */}
        {mutation.isError && (
          <p className="text-xs text-state-critica">
            {mutation.error instanceof Error
              ? mutation.error.message
              : "Error al crear la zona"}
          </p>
        )}

        <div className="flex gap-3 pt-2">
          <button
            type="button"
            onClick={() => router.back()}
            className="flex-1 rounded-lg border border-tv-border bg-tv-surface px-4 py-2 text-sm font-medium text-tv-dim hover:bg-tv-surface2 transition"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={mutation.isPending}
            className="flex-1 rounded-lg bg-tv-accent px-4 py-2 text-sm font-bold text-tv-bg hover:opacity-90 transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {mutation.isPending ? "Guardando..." : "Crear zona"}
          </button>
        </div>
      </form>
    </div>
  );
}
