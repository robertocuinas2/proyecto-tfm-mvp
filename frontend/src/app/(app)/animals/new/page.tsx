"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import * as z from "zod";
import { api } from "@/lib/api";

const hoy = new Date().toISOString().split("T")[0];
const SEXO = ["hembra", "macho"] as const;
const ESTADO_ANIMAL = ["recria", "produccion", "baja", "crianza"] as const;
const ESTADO_REPRODUCTIVO = [
  "vacia",
  "en_celo",
  "inseminada",
  "confirmada_gestante",
  "parto_reciente",
] as const;

const animalSchema = z
  .object({
    crotal_oficial: z
      .string()
      .min(1, "El crotal es obligatorio")
      .max(20, "El crotal es demasiado grande"),
    nombre: z.string().max(80, "El nombre es demsiado grande"),
    sexo: z.string().min(1, "El sexo es obligatorio"),
    fecha_nacimiento: z.string().min(1, "La fech de nacimiento es obligatoria"),
    raza: z.string().max(80, "El nombre de la raza es demsiado grande"),
    estado: z.enum(ESTADO_ANIMAL, {
      message: "El estado es obligatorio",
    }),
    estado_reproductivo: z.string(),
    madre_id: z.string(),
    fecha_entrada: z.string().min(1, "La fecha de entrada es obligatoria"),
    fecha_baja: z.string(),
    motivo_baja: z.string().max(200, "El motvo de baja es demsiado grande"),
    notas: z.string(),
  })
  .refine(
    (datos) => {
      if (!datos.fecha_baja) return true;
      return datos.fecha_entrada < datos.fecha_baja;
    },
    {
      error: "La fecha de baja debe ser posterior a la de nacimiento",
      path: ["fecha_baja"],
    },
  );

type AnimalFormData = z.infer<typeof animalSchema>;

export default function AnimalForm() {
  const router = useRouter();
  const queryClient = useQueryClient();

  const { data: animales = [], isLoading: cargandoAnimales } = useQuery({
    queryKey: ["animals"],
    queryFn: () => api.animals(),
  });

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<AnimalFormData>({
    resolver: zodResolver(animalSchema),
    defaultValues: {
      crotal_oficial: "",
      nombre: "",
      sexo: "hembra",
      fecha_nacimiento: "",
      raza: "",
      estado: "recria",
      estado_reproductivo: "",
      madre_id: "",
      fecha_entrada: hoy,
      fecha_baja: "",
      motivo_baja: "",
      notas: "",
    },
  });

  // useMutation reemplaza el async/await
  const mutation = useMutation({
    mutationFn: (datos: AnimalFormData) => api.createAnimal(datos),
    onSuccess: () => {
      // Invalida la caché de zonas para que la lista se refresque
      queryClient.invalidateQueries({ queryKey: ["animals"] });
      router.push("/animals");
    },
  });

  const onSubmit = (datos: AnimalFormData) => {
    mutation.mutate(datos);
  };

  return (
    <div className="mx-auto max-w-lg space-y-6 p-6">
      <div>
        <h2 className="font-heading text-2xl font-bold text-black">
          Nuevo animal
        </h2>
        <p className="mt-1 text-sm text-tv-dim">
          Crea un nuevo animal de la granja
        </p>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Crotal Oficial
          </label>
          <input
            type="text"
            {...register("crotal_oficial")}
            placeholder="Ej: V-15, ES25000..."
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          />
          {errors.crotal_oficial && (
            <p className="mt-1 text-xs text-state-critica">
              {errors.crotal_oficial.message}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Nombre <span className="text-gray-400 font-normal">(opcional)</span>
          </label>
          <input
            type="text"
            {...register("nombre")}
            placeholder="Ej: Lola, Pepa..."
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
            Sexo
          </label>
          <select
            {...register("sexo")}
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          >
            {SEXO.map((sex) => (
              <option key={sex} value={sex}>
                {sex}
              </option>
            ))}
          </select>
          {errors.sexo && (
            <p className="text-red-500 text-xs mt-1">{errors.sexo.message}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Fecha de Nacimiento
          </label>
          <input
            type="date"
            {...register("fecha_nacimiento")}
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          />
          {errors.fecha_nacimiento && (
            <p className="text-red-500 text-xs mt-1">
              {errors.fecha_nacimiento.message}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Raza <span className="text-gray-400 font-normal">(opcional)</span>
          </label>
          <input
            type="text"
            placeholder="Ej: Holstein, Hereford..."
            {...register("raza")}
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          />
          {errors.raza && (
            <p className="text-red-500 text-xs mt-1">{errors.raza.message}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Estado
          </label>
          <select
            {...register("estado")}
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          >
            {ESTADO_ANIMAL.map((est) => (
              <option key={est} value={est}>
                {est}
              </option>
            ))}
          </select>
          {errors.estado && (
            <p className="text-red-500 text-xs mt-1">{errors.estado.message}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Estado Reproductivo{" "}
            <span className="text-gray-400 font-normal">(opcional)</span>
          </label>
          <select
            {...register("estado_reproductivo")}
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          >
            <option value="vacia">Selecciona una opción</option>
            {ESTADO_REPRODUCTIVO.map((est) => (
              <option key={est} value={est}>
                {est}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Madre del animal{" "}
            <span className="text-gray-400 font-normal">(opcional)</span>
          </label>
          <select
            {...register("madre_id")}
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          >
            <option value="">Selecciona una opción</option>

            {/* mostrar cargando mientras carga */}
            {cargandoAnimales ? (
              <option value="" disabled>
                Cargando madres...
              </option>
            ) : (
              /* filtro por hembras */
              animales
                .filter((animal) => animal.sexo === "hembra")
                .map((animal) => (
                  <option key={animal.id} value={animal.id}>
                    {animal.crotal_oficial}{" "}
                    {animal.nombre ? `- ${animal.nombre}` : ""}
                  </option>
                ))
            )}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          {/* Fecha de Entrada */}
          <div>
            <label className="block text-sm font-medium text-tv-dim mb-1">
              Fecha de Entrada
            </label>
            <input
              type="date"
              {...register("fecha_entrada")}
              className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
            />
            {errors.fecha_entrada && (
              <p className="text-red-500 text-xs mt-1">
                {errors.fecha_entrada.message}
              </p>
            )}
          </div>

          {/* Fecha de Baja */}
          <div>
            <label className="block text-sm font-medium text-tv-dim mb-1">
              Fecha de Baja{" "}
              <span className="text-gray-400 font-normal">(opcional)</span>
            </label>
            <input
              type="date"
              {...register("fecha_baja")}
              className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
            />
            {errors.fecha_baja && (
              <p className="text-red-500 text-xs mt-1">
                {errors.fecha_baja.message}
              </p>
            )}
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Motivo de la Baja{" "}
            <span className="text-gray-400 font-normal">(opcional)</span>
          </label>
          <input
            type="text"
            placeholder="Ej: Enfermedad, Análisis..."
            {...register("motivo_baja")}
            className="w-full rounded-lg border border-tv-border bg-tv-surface px-3 py-2 text-sm text-white placeholder:text-tv-dim focus:outline-none focus:ring-2 focus:ring-tv-accent"
          />
          {errors.motivo_baja && (
            <p className="text-red-500 text-xs mt-1">
              {errors.motivo_baja.message}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-tv-dim mb-1">
            Notas sobre el animal{" "}
            <span className="text-gray-400 font-normal">(opcional)</span>
          </label>
          <textarea
            rows={3}
            placeholder="Descripción sobre el animal..."
            {...register("notas")}
            className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
          />
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
            {mutation.isPending ? "Guardando..." : "Crear animal"}
          </button>
        </div>
      </form>
    </div>
  );
}
