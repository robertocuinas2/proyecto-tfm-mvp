"use client";

import { useQuery } from "@tanstack/react-query";
import {
  Activity,
  BrainCircuit,
  CheckCircle2,
  LogOut,
  Monitor,
  Settings2,
  ShieldCheck,
  UserRound,
} from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/page-header";
import { PanelCard } from "@/components/ui/panel-card";
import { api } from "@/lib/api";
import { useAppStore } from "@/store/app-store";

const roleLabels: Record<string, { label: string; description: string; color: string }> = {
  admin: { label: "Administrador", description: "Acceso completo al sistema.", color: "bg-brand/10 text-brand border-brand/20" },
  veterinario: { label: "Veterinario", description: "Gestión sanitaria, tratamientos y alertas.", color: "bg-state-info/10 text-state-info border-state-info/20" },
  operario: { label: "Operario", description: "Tareas operativas por zona.", color: "bg-state-atencion/10 text-state-atencion border-state-atencion/20" },
  alimentacion: { label: "Nutrición", description: "Alimentación, calidad y pedidos.", color: "bg-state-ok/10 text-state-ok border-state-ok/20" },
};

function InfoRow({ label, value, mono = false }: { label: string; value: React.ReactNode; mono?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-app-border py-3 text-sm last:border-0">
      <span className="font-semibold text-app-dim">{label}</span>
      <span className={`text-app-text ${mono ? "font-mono" : ""}`}>{value ?? <span className="text-app-dim">—</span>}</span>
    </div>
  );
}

export default function ProfilePage() {
  const router = useRouter();
  const user = useAppStore((s) => s.user);
  const logout = useAppStore((s) => s.logout);
  const isAdmin = user?.role === "admin";

  // Refresh user data from API
  const meQ = useQuery({
    queryKey: ["me"],
    queryFn: api.me,
    staleTime: 5 * 60_000,
    retry: 0,
  });

  // Use API data if available, fall back to store
  const profile = meQ.data ?? user;
  const roleInfo = roleLabels[profile?.role ?? ""] ?? {
    label: profile?.role ?? "Desconocido",
    description: "Rol no reconocido.",
    color: "bg-state-neutral/10 text-state-neutral border-state-neutral/20",
  };

  function handleLogout() {
    logout();
    router.replace("/");
  }

  return (
    <div className="min-h-full">
      <PageHeader eyebrow="Mi cuenta" title="Perfil" EyebrowIcon={UserRound}>
        <button
          type="button"
          onClick={handleLogout}
          className="inline-flex items-center gap-2 rounded-[10px] border border-state-critica/20 bg-state-critica/5 px-3 py-2 text-sm font-semibold text-state-critica transition hover:bg-state-critica/10"
        >
          <LogOut className="h-4 w-4" />
          Cerrar sesión
        </button>
      </PageHeader>

      <div className="space-y-5 px-6 py-6 lg:px-8">
        {/* User card */}
        <div className="rounded-[14px] border border-app-border bg-white p-6 shadow-card">
          <div className="flex flex-wrap items-start gap-5">
            {/* Avatar */}
            <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-full bg-brand/10">
              <UserRound className="h-10 w-10 text-brand" strokeWidth={1.5} />
            </div>

            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-3">
                <h2 className="font-heading text-2xl font-bold text-app-text">
                  {profile?.username ?? "—"}
                </h2>
                <span className={`rounded-full border px-3 py-0.5 text-[11px] font-extrabold uppercase ${roleInfo.color}`}>
                  {roleInfo.label}
                </span>
                {profile?.activo !== false ? (
                  <span className="flex items-center gap-1 rounded-full bg-state-ok/10 px-2.5 py-0.5 text-[11px] font-bold text-state-ok">
                    <CheckCircle2 className="h-3 w-3" />
                    Activo
                  </span>
                ) : (
                  <span className="rounded-full bg-state-neutral/10 px-2.5 py-0.5 text-[11px] font-bold text-state-neutral">
                    Inactivo
                  </span>
                )}
              </div>
              <p className="mt-1 text-sm text-app-dim">{profile?.email ?? "—"}</p>
              <p className="mt-2 max-w-xs text-sm text-app-dim">{roleInfo.description}</p>
            </div>
          </div>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          {/* Account data */}
          <PanelCard>
            <h3 className="mb-1 font-heading text-base font-bold text-app-text">Datos de la cuenta</h3>
            <div className="mt-3">
              <InfoRow label="Usuario" value={profile?.username} mono />
              <InfoRow label="Email" value={profile?.email} />
              <InfoRow label="Rol del sistema" value={roleInfo.label} />
              <InfoRow label="Estado" value={
                profile?.activo !== false
                  ? <span className="font-semibold text-state-ok">Activo</span>
                  : <span className="font-semibold text-state-neutral">Inactivo</span>
              } />
              <InfoRow label="ID de usuario" value={
                <span className="font-mono text-xs text-app-dim">{profile?.id?.slice(0, 16)}…</span>
              } />
            </div>

            {/* TODO: Aviso si debe_cambiar_contrasena=true — el campo existe en el backend
                (Usuario.debe_cambiar_contrasena) pero no se expone en el endpoint /auth/me.
                Cuando el backend lo incluya en UserResponse, mostrar aviso aquí. */}
          </PanelCard>

          {/* Session & access */}
          <PanelCard>
            <h3 className="mb-3 font-heading text-base font-bold text-app-text">Sesión y accesos</h3>

            <div className="space-y-2">
              {[
                { href: "/dashboard", label: "Centro de control", Icon: Activity, always: true },
                { href: "/tv", label: "TV Global", Icon: Monitor, always: true },
                { href: "/settings", label: "Configuración", Icon: Settings2, always: true },
                { href: "/audit-log", label: "Audit Log", Icon: ShieldCheck, always: false, adminOnly: true },
                { href: "/integration", label: "Integración API", Icon: BrainCircuit, always: false, adminOnly: true },
              ]
                .filter((item) => item.always || (item.adminOnly && isAdmin))
                .map(({ href, label, Icon }) => (
                  <Link
                    key={href}
                    href={href}
                    className="flex items-center justify-between gap-3 rounded-[10px] border border-app-border bg-app-bg px-4 py-3 text-sm font-semibold text-app-text transition hover:border-brand/30 hover:bg-white"
                  >
                    <span className="flex items-center gap-2">
                      <Icon className="h-4 w-4 text-brand" />
                      {label}
                    </span>
                    <span className="text-app-dim">→</span>
                  </Link>
                ))}
            </div>

            <div className="mt-5 border-t border-app-border pt-4">
              {/* TODO: Trabajador asociado — pendiente de backend
                  La idea futura es: usuario → cuenta ganadería → selección de trabajador/empleado → permisos detallados.
                  Por ahora, el rol del sistema (admin/veterinario/operario/alimentacion) determina el acceso. */}
              <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-app-dim">
                Trabajador asociado
              </p>
              <p className="mt-2 text-sm text-app-dim">
                {profile?.empleado_id
                  ? <span className="font-mono text-xs">{profile.empleado_id}</span>
                  : "Sin empleado vinculado a este usuario."}
              </p>
              <p className="mt-1 text-xs text-app-dim opacity-70">
                La vinculación usuario–empleado está pendiente de implementación backend.
              </p>
            </div>
          </PanelCard>
        </div>
      </div>
    </div>
  );
}
