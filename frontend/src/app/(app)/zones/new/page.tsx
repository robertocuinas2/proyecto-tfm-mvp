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

  const mutation = useMutation({
    mutationFn: (datos: ZonaFormData) => api.createZone(datos),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["zones"] });
      router.push("/zones");
    },
  });

  return (
    <div className="min-h-full bg-app-bg">
      <div className="border-b border-app-border bg-white px-6 py-5 lg:px-8">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs font-extrabold uppercase tracking-[0.18em] text-app-dim">
              Sistema
            </p>
            <h1 className="mt-1 font-heading text-2xl font-bold text-app-text">
              Nueva zona
            </h1>
          </div>
          <button
            type="button"
            onClick={() => router.back()}
            className="rounded-[10px] border border-app-border bg-white px-4 py-2 text-sm font-semibold text-app-dim hover:bg-app-bg transition"
          >
            Cancelar
          </button>
        </div>
      </div>

      <div className="mx-auto max-w-lg px-6 py-8 lg:px-8">
        <div className="rounded-[10px] border border-app-border bg-white p-6 shadow-card">
          <form
            onSubmit={handleSubmit((datos) => mutation.mutate(datos))}
            className="space-y-5"
          >
            <div>
              <label className="block text-sm font-semibold text-app-text mb-1">
                Nombre
              </label>
              <input
                type="text"
                {...register("nombre")}
                placeholder="Ej: Sala de robots, Becerrero..."
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-3 py-2 text-sm text-app-text placeholder:text-app-dim focus:outline-none focus:ring-2 focus:ring-brand/40"
              />
              {errors.nombre && (
                <p className="mt-1 text-xs text-state-critica">
                  {errors.nombre.message}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-semibold text-app-text mb-1">
                Código
              </label>
              <input
                type="text"
                {...register("codigo")}
                placeholder="Ej: zona_robots, becerrero..."
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-3 py-2 text-sm text-app-text placeholder:text-app-dim focus:outline-none focus:ring-2 focus:ring-brand/40"
              />
              <p className="mt-1 text-xs text-app-dim">
                Solo minúsculas y guiones bajos.
              </p>
              {errors.codigo && (
                <p className="mt-1 text-xs text-state-critica">
                  {errors.codigo.message}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-semibold text-app-text mb-1">
                Descripción{" "}
                <span className="font-normal text-app-dim">(opcional)</span>
              </label>
              <textarea
                {...register("descripcion")}
                rows={3}
                placeholder="Describe la zona..."
                className="w-full rounded-[10px] border border-app-border bg-app-bg px-3 py-2 text-sm text-app-text placeholder:text-app-dim focus:outline-none focus:ring-2 focus:ring-brand/40 resize-none"
              />
            </div>

            <div className="space-y-3">
              <label className="block text-sm font-semibold text-app-text">
                Equipamiento
              </label>
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  {...register("tiene_pantalla_tv")}
                  className="rounded border-app-border text-brand w-4 h-4"
                />
                <span className="text-sm text-app-text">Tiene pantalla TV</span>
              </label>
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  {...register("tiene_tablet")}
                  className="rounded border-app-border text-brand w-4 h-4"
                />
                <span className="text-sm text-app-text">Tiene tablet</span>
              </label>
            </div>

            {mutation.isError && (
              <p className="text-xs text-state-critica">
                {mutation.error instanceof Error
                  ? mutation.error.message
                  : "Error al crear la zona"}
              </p>
            )}

            <button
              type="submit"
              disabled={mutation.isPending}
              className="w-full rounded-[10px] bg-brand px-4 py-2.5 text-sm font-bold text-white hover:opacity-90 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {mutation.isPending ? "Guardando..." : "Crear zona"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
