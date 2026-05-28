"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import {
  ChevronRight,
  ClipboardCheck,
  HeartPulse,
  Loader2,
  Milk,
  ShieldCheck,
  Sprout,
  UserRound,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { API_BASE_URL } from "@/lib/config";
import type { UserRole } from "@/lib/types";
import { useAppStore } from "@/store/app-store";

const roles: {
  value: UserRole;
  label: string;
  short: string;
  Icon: typeof ShieldCheck;
}[] = [
  { value: "admin", label: "Gestor / Administrador", short: "Control", Icon: ShieldCheck },
  { value: "veterinario", label: "Veterinario", short: "Sanidad", Icon: HeartPulse },
  { value: "operario", label: "Operario de zona", short: "Zona", Icon: UserRound },
  { value: "alimentacion", label: "Responsable alimentación", short: "Nutrición", Icon: Sprout },
];

const demoUsers = [
  { username: "admin", role: "admin" as const, label: "Administrador", password: "testpass123" },
  { username: "roberto.castro", role: "admin" as const, label: "Gestor", password: "testpass123" },
  { username: "operario.zona", role: "operario" as const, label: "Sala ordeño", password: "testpass123" },
  { username: "laura.fernandez", role: "alimentacion" as const, label: "Alimentación", password: "testpass123" },
  { username: "dr.mendez", role: "veterinario" as const, label: "Veterinario", password: "testpass123" },
];

// ── Live clock (client-only to avoid SSR mismatch) ────────────────────────────
function LiveClock() {
  const [time, setTime] = useState<string | null>(null);
  useEffect(() => {
    function tick() {
      setTime(new Date().toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" }));
    }
    tick();
    const t = setInterval(tick, 15_000);
    return () => clearInterval(t);
  }, []);
  return <span>{time ?? "--:--"}</span>;
}

function StatusDot({ online, loading = false }: { online: boolean; loading?: boolean }) {
  return (
    <span className={`h-2.5 w-2.5 rounded-full ${
      loading ? "animate-pulse bg-state-atencion"
      : online ? "bg-tv-accent"
      : "bg-state-critica"
    }`} />
  );
}

export function LoginScreen() {
  const router = useRouter();
  const hydrate = useAppStore((state) => state.hydrate);
  const token = useAppStore((state) => state.token);
  const isHydrated = useAppStore((state) => state.isHydrated);
  const selectedRole = useAppStore((state) => state.selectedRole);
  const setSelectedRole = useAppStore((state) => state.setSelectedRole);
  const setSession = useAppStore((state) => state.setSession);

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [redirecting, setRedirecting] = useState(false);

  useEffect(() => { hydrate(); }, [hydrate]);
  useEffect(() => {
    if (isHydrated && token) router.replace("/dashboard");
  }, [isHydrated, token, router]);

  const health = useQuery({
    queryKey: ["health"],
    queryFn: api.health,
    retry: 1,
    refetchInterval: 30_000,
  });

  const activeRole = useMemo(
    () => roles.find((r) => r.value === selectedRole) ?? roles[2],
    [selectedRole],
  );

  const loginMutation = useMutation({
    mutationFn: api.login,
    onSuccess: (data) => {
      const realRole = data.user.role ?? selectedRole;
      setSelectedRole(realRole);
      setSession(data.token.access_token, data.user);
      setRedirecting(true);
      router.push("/dashboard");
    },
  });

  const backendOnline = health.isSuccess && health.data.status === "ok";
  const isLoading = loginMutation.isPending || redirecting;

  function submitLogin() {
    if (!username.trim() || password.length < 3 || isLoading) return;
    loginMutation.mutate({ username: username.trim(), password });
  }

  if (redirecting) {
    return (
      <main className="grid min-h-screen place-items-center bg-tv-bg px-6 font-body text-white">
        <section className="text-center">
          <div className="t4m-logo mx-auto grid h-20 w-20 place-items-center rounded-[22px] font-heading font-extrabold text-white shadow-brand">
            <Milk className="h-9 w-9" strokeWidth={2.4} />
          </div>
          <div className="mx-auto mt-8 flex h-14 w-14 items-center justify-center rounded-full bg-tv-accent/20">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-tv-accent border-t-transparent" />
          </div>
          <h1 className="mt-6 font-heading text-3xl font-bold">Bienvenido/a, {username}</h1>
          <p className="mt-2 text-sm text-tv-dim">
            Abriendo panel de {activeRole.label.toLowerCase()}…
          </p>
        </section>
      </main>
    );
  }

  return (
    <main className="min-h-screen overflow-hidden bg-[radial-gradient(circle_at_68%_22%,rgba(27,94,59,0.42),transparent_34%),linear-gradient(145deg,#020704_0%,#06140B_48%,#0B2515_100%)] font-body text-white">
      <div className="mx-auto grid min-h-screen w-full max-w-[1680px] grid-cols-1 gap-8 px-5 py-6 lg:grid-cols-[minmax(0,1.15fr)_560px] lg:px-10 lg:py-10 xl:gap-12">

        {/* ── Left panel — Application showcase ────────────────────────── */}
        <section className="relative flex min-h-[540px] flex-col justify-between rounded-[28px] border border-white/5 bg-tv-bg/55 p-7 shadow-deck backdrop-blur sm:p-9 lg:min-h-[calc(100vh-80px)]">
          <header className="flex flex-wrap items-center justify-between gap-5">
            <div className="flex items-center gap-4">
              <div className="t4m-logo grid h-14 w-14 shrink-0 place-items-center rounded-[16px] font-heading font-extrabold text-white shadow-brand">
                <Milk className="h-7 w-7" strokeWidth={2.4} />
              </div>
              <div>
                <div className="font-heading text-[26px] font-bold leading-none">Tools4 Milk</div>
                <div className="mt-1 text-sm font-semibold text-tv-dim">Centro de control ganadero</div>
              </div>
            </div>
            <div className="text-right">
              <div className="font-heading text-[42px] font-bold leading-none">
                <LiveClock />
              </div>
              <div className="mt-1 text-[11px] font-bold uppercase tracking-[0.12em] text-tv-dim">
                Hora actual
              </div>
            </div>
          </header>

          <div className="space-y-8 py-8">
            <div>
              <div className="text-xs font-extrabold uppercase tracking-[0.28em] text-tv-dim">
                Sistema de gestión
              </div>
              <h1 className="mt-2 max-w-[780px] font-heading text-[42px] font-bold leading-[0.98] tracking-[-0.02em] sm:text-[56px]">
                Gestión integral de explotación lechera
              </h1>
            </div>

            {/* Feature highlights */}
            <div className="grid gap-3 sm:grid-cols-2">
              {[
                { title: "Producción en tiempo real", desc: "Seguimiento de lactaciones, calidad y rendimiento por animal." },
                { title: "Gestión operativa", desc: "Tareas, turnos, incidencias y pedidos gestionados por zona." },
                { title: "Alertas y predicciones", desc: "Alertas sanitarias, análisis de composición y predicción de producción." },
                { title: "Vistas TV y tablet", desc: "Pantallas operativas por zona para TV y dispositivos táctiles." },
              ].map((f) => (
                <div key={f.title} className="rounded-[18px] border border-tv-border bg-tv-surface/70 p-5">
                  <div className="font-heading text-base font-bold text-white">{f.title}</div>
                  <div className="mt-2 text-sm text-tv-dim">{f.desc}</div>
                </div>
              ))}
            </div>
          </div>

          <footer className="flex flex-wrap items-center justify-between gap-3 border-t border-tv-border pt-5 text-sm font-semibold text-tv-dim">
            <span className="flex items-center gap-2">
              <StatusDot online={backendOnline} loading={health.isLoading} />
              {health.isLoading ? "Verificando conexión…"
                : backendOnline ? "Backend conectado"
                : "Backend no disponible"}
            </span>
            <span className="font-mono text-xs">{API_BASE_URL}</span>
          </footer>
        </section>

        {/* ── Right panel — Login form ─────────────────────────────────── */}
        <section className="flex min-h-[calc(100vh-80px)] items-center justify-center">
          <div className="w-full max-w-[520px] overflow-hidden rounded-[26px] border border-white/10 bg-app-bg shadow-deck">

            {/* Form header */}
            <div className="bg-brand px-6 py-5 text-white sm:px-7">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <div className="text-xs font-extrabold uppercase tracking-[0.18em] text-white/60">
                    Acceso seguro
                  </div>
                  <h2 className="mt-1 font-heading text-[28px] font-bold leading-tight">
                    Tools4 Milk
                  </h2>
                </div>
                <div className="flex items-center gap-2.5 rounded-full border border-white/15 bg-white/10 px-3 py-2">
                  <StatusDot online={backendOnline} loading={health.isLoading} />
                  <span className="text-xs font-bold">
                    {health.isLoading ? "Conectando…"
                      : backendOnline ? "API online"
                      : "API offline"}
                  </span>
                </div>
              </div>
            </div>

            <div className="px-5 py-5 sm:px-7 sm:py-6">
              {/* Role selector */}
              <div className="mb-5 grid grid-cols-2 gap-3">
                {roles.map(({ value, short, Icon }) => {
                  const active = selectedRole === value;
                  return (
                    <button
                      key={value}
                      type="button"
                      onClick={() => setSelectedRole(value)}
                      className={`flex min-h-[72px] items-center gap-3 rounded-[14px] border px-4 text-left transition ${
                        active
                          ? "border-brand bg-white text-brand shadow-panel"
                          : "border-app-border bg-white/70 text-app-dim hover:border-brand/50"
                      }`}
                    >
                      <Icon className="h-5 w-5 shrink-0" strokeWidth={2.2} />
                      <span className="font-heading text-[15px] font-bold">{short}</span>
                    </button>
                  );
                })}
              </div>

              {/* Login form */}
              <form
                className="grid gap-4"
                onSubmit={(e) => { e.preventDefault(); submitLogin(); }}
              >
                <div>
                  <label className="mb-2 block text-xs font-extrabold uppercase tracking-[0.18em] text-app-dim">
                    Usuario
                  </label>
                  <input
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="nombre.apellido"
                    autoComplete="username"
                    className="h-[56px] w-full rounded-[14px] border border-app-border bg-white px-5 text-[17px] font-semibold text-app-text outline-none transition placeholder:text-app-dim/50 focus:border-brand focus:ring-4 focus:ring-brand/10"
                  />
                </div>

                <div>
                  <label className="mb-2 block text-xs font-extrabold uppercase tracking-[0.18em] text-app-dim">
                    Contraseña
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Contraseña"
                    autoComplete="current-password"
                    className="h-[56px] w-full rounded-[14px] border border-app-border bg-white px-5 text-[17px] font-semibold text-app-text outline-none transition placeholder:text-app-dim/50 focus:border-brand focus:ring-4 focus:ring-brand/10"
                  />
                </div>

                {loginMutation.isError && (
                  <div className="rounded-[14px] border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-state-critica">
                    {loginMutation.error.message}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={isLoading || !username.trim() || password.length < 3}
                  className="mt-1 flex min-h-[72px] w-full items-center justify-center gap-3 rounded-[16px] bg-brand font-heading text-[20px] font-bold text-white shadow-brand transition hover:bg-[#135532] disabled:cursor-not-allowed disabled:opacity-55"
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="h-5 w-5 animate-spin" />
                      Autenticando…
                    </>
                  ) : (
                    <>
                      Entrar
                      <ChevronRight className="h-5 w-5" />
                    </>
                  )}
                </button>
              </form>

              {/* Demo access — clearly labeled for development */}
              <div className="mt-5 rounded-[16px] border border-app-border bg-white p-4">
                <div className="mb-2 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.16em] text-app-dim">
                    <ClipboardCheck className="h-4 w-4" />
                    Acceso de demostración
                  </div>
                  <span className="rounded-full bg-state-atencion/10 px-2 py-0.5 text-[10px] font-bold uppercase text-state-atencion">
                    Solo desarrollo
                  </span>
                </div>
                <p className="mb-3 text-[11px] text-app-dim">
                  Selecciona un usuario para rellenar las credenciales automáticamente.
                </p>
                <div className="grid gap-1.5">
                  {demoUsers.map((demo) => (
                    <button
                      key={demo.username}
                      type="button"
                      onClick={() => {
                        setUsername(demo.username);
                        setPassword(demo.password);
                        setSelectedRole(demo.role);
                      }}
                      className="flex min-h-[40px] items-center justify-between rounded-[10px] px-2.5 text-left transition hover:bg-app-bg"
                    >
                      <span className="font-mono text-sm text-app-text">{demo.username}</span>
                      <span className="text-xs font-semibold text-app-dim">{demo.label}</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
