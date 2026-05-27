"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import {
  AlertTriangle,
  BarChart3,
  CheckCircle2,
  ChevronRight,
  ClipboardCheck,
  HeartPulse,
  Loader2,
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
  { value: "alimentacion", label: "Responsable alimentacion", short: "Nutricion", Icon: Sprout },
];

const demoUsers = [
  { username: "admin", role: "admin" as const, label: "Admin" },
  { username: "roberto.castro", role: "admin" as const, label: "Gestor" },
  { username: "operario.zona", role: "operario" as const, label: "Sala ordeno" },
  { username: "laura.fernandez", role: "alimentacion" as const, label: "Alimentacion" },
  { username: "dr.mendez", role: "veterinario" as const, label: "Sanidad" },
];

const kpis = [
  { label: "Produccion hoy", value: "1842 L", tone: "text-[#E87500]", bar: "bg-[#E87500]" },
  { label: "RCS medio", value: "198k", tone: "text-state-ok", bar: "bg-state-ok" },
  { label: "Grasa", value: "3.92 %", tone: "text-state-ok", bar: "bg-state-ok" },
  { label: "Alertas", value: "5", tone: "text-state-critica", bar: "bg-state-critica" },
];

const zones = [
  { name: "Sala de Ordeno", alerts: 3, status: "OPERATIVA", active: true },
  { name: "Recria", alerts: 2, status: "OPERATIVA", active: false },
  { name: "Paridera", alerts: 4, status: "CRITICA", active: false },
  { name: "Alimentacion", alerts: 1, status: "OPERATIVA", active: false },
];

function LogoMark({ size = "md" }: { size?: "sm" | "md" | "lg" }) {
  const classes = {
    sm: "h-11 w-11 rounded-[13px] text-[24px]",
    md: "h-14 w-14 rounded-[16px] text-[30px]",
    lg: "h-20 w-20 rounded-[22px] text-[44px]",
  };

  return (
    <div
      className={`t4m-logo grid place-items-center font-heading font-extrabold text-white shadow-brand ${classes[size]}`}
    >
      T
    </div>
  );
}

function StatusDot({ online }: { online: boolean }) {
  return (
    <span
      className={`h-2.5 w-2.5 rounded-full ${online ? "bg-tv-accent" : "bg-state-critica"}`}
    />
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

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  useEffect(() => {
    if (isHydrated && token) {
      router.replace("/dashboard");
    }
  }, [isHydrated, token, router]);

  const health = useQuery({
    queryKey: ["health"],
    queryFn: api.health,
    retry: 0,
  });

  const activeRole = useMemo(
    () => roles.find((role) => role.value === selectedRole) ?? roles[2],
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
    if (!username.trim() || password.length < 8 || isLoading) return;
    loginMutation.mutate({ username: username.trim(), password });
  }

  if (redirecting) {
    return (
      <main className="grid min-h-screen place-items-center bg-tv-bg px-6 font-heading text-white">
        <section className="text-center">
          <LogoMark size="lg" />
          <CheckCircle2 className="mx-auto mb-5 mt-8 h-14 w-14 text-tv-accent" strokeWidth={1.8} />
          <h1 className="mb-2 text-[34px] font-bold leading-tight">Bienvenido/a, {username}</h1>
          <p className="text-base font-semibold text-tv-dim">
            Abriendo panel de {activeRole.label.toLowerCase()}...
          </p>
        </section>
      </main>
    );
  }

  return (
    <main className="min-h-screen overflow-hidden bg-[radial-gradient(circle_at_68%_22%,rgba(27,94,59,0.42),transparent_34%),linear-gradient(145deg,#020704_0%,#06140B_48%,#0B2515_100%)] font-body text-white">
      <div className="mx-auto grid min-h-screen w-full max-w-[1680px] grid-cols-1 gap-8 px-5 py-6 lg:grid-cols-[minmax(0,1.15fr)_560px] lg:px-10 lg:py-10 xl:gap-12">
        <section className="relative flex min-h-[620px] flex-col justify-between rounded-[28px] border border-white/5 bg-tv-bg/55 p-7 shadow-deck backdrop-blur sm:p-9 lg:min-h-[calc(100vh-80px)]">
          <header className="flex flex-wrap items-center justify-between gap-5">
            <div className="flex items-center gap-4">
              <LogoMark />
              <div>
                <div className="font-heading text-[28px] font-bold leading-none">Tools4 Milk</div>
                <div className="mt-1 text-sm font-semibold text-tv-dim">Centro de control</div>
              </div>
            </div>

            <div className="flex items-center gap-6">
              <div className="rounded-full border border-tv-accent/70 bg-tv-accent/10 px-6 py-3 text-sm font-extrabold uppercase tracking-[0.15em] text-tv-accent">
                Operativa
              </div>
              <div className="text-right">
                <div className="font-heading text-[46px] font-bold leading-none">14:41</div>
                <div className="mt-1 text-xs font-bold uppercase tracking-[0.12em] text-tv-dim">
                  Hora actual
                </div>
              </div>
            </div>
          </header>

          <div className="grid gap-6 py-10 xl:grid-cols-[1fr_340px]">
            <div className="space-y-6">
              <div>
                <div className="text-xs font-extrabold uppercase tracking-[0.28em] text-tv-dim">
                  Estado de zonas
                </div>
                <h1 className="mt-2 max-w-[780px] font-heading text-[46px] font-bold leading-[0.98] tracking-[-0.02em] sm:text-[62px]">
                  Vision global de la explotacion
                </h1>
              </div>

              <div className="grid gap-3 sm:grid-cols-2">
                {zones.map((zone) => (
                  <div
                    key={zone.name}
                    className={`rounded-[18px] border p-5 transition ${
                      zone.active
                        ? "border-tv-accent bg-tv-surface2"
                        : "border-tv-border bg-tv-surface/82"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="font-heading text-xl font-bold">{zone.name}</div>
                        <div className="mt-5 flex items-end gap-5">
                          <div>
                            <div className="text-3xl font-extrabold text-state-critica">
                              {zone.alerts}
                            </div>
                            <div className="text-xs font-semibold text-tv-dim">alertas</div>
                          </div>
                          <div>
                            <div className="text-3xl font-extrabold text-white">
                              {zone.active ? 68 : zone.name === "Paridera" ? 6 : 34}
                            </div>
                            <div className="text-xs font-semibold text-tv-dim">animales</div>
                          </div>
                        </div>
                      </div>
                      <div
                        className={`rounded-full px-4 py-2 text-[11px] font-extrabold uppercase tracking-[0.13em] ${
                          zone.status === "CRITICA"
                            ? "bg-state-critica/12 text-state-critica"
                            : "bg-tv-accent/10 text-tv-accent"
                        }`}
                      >
                        {zone.status}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="rounded-[18px] border border-tv-border bg-tv-surface/82 p-5">
                <div className="mb-4 flex items-center justify-between border-b border-tv-border pb-4">
                  <div>
                    <div className="text-xs font-extrabold uppercase tracking-[0.22em] text-tv-dim">
                      En curso
                    </div>
                    <div className="mt-1 font-heading text-2xl font-bold">Ordeno lote 1 - Robot A</div>
                  </div>
                  <span className="text-xl font-bold text-state-info">07:30</span>
                </div>
                <div className="grid gap-3 sm:grid-cols-3">
                  <div className="rounded-xl bg-white/[0.04] p-4">
                    <div className="text-xs font-bold uppercase tracking-[0.16em] text-tv-dim">
                      Produccion
                    </div>
                    <div className="mt-2 font-heading text-3xl font-bold">1.842 L</div>
                  </div>
                  <div className="rounded-xl bg-white/[0.04] p-4">
                    <div className="text-xs font-bold uppercase tracking-[0.16em] text-tv-dim">
                      Media animal
                    </div>
                    <div className="mt-2 font-heading text-3xl font-bold">28,7 L</div>
                  </div>
                  <div className="rounded-xl bg-white/[0.04] p-4">
                    <div className="text-xs font-bold uppercase tracking-[0.16em] text-tv-dim">
                      Tareas hoy
                    </div>
                    <div className="mt-2 font-heading text-3xl font-bold">14/28</div>
                  </div>
                </div>
              </div>
            </div>

            <aside className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                {kpis.map((kpi) => (
                  <div key={kpi.label} className="rounded-[16px] bg-white p-4 text-app-text">
                    <div className="text-[11px] font-extrabold uppercase tracking-[0.16em] text-app-dim">
                      {kpi.label}
                    </div>
                    <div className={`mt-1 font-heading text-[26px] font-bold ${kpi.tone}`}>
                      {kpi.value}
                    </div>
                    <div className="mt-3 h-1.5 rounded-full bg-app-border">
                      <div className={`h-full w-[82%] rounded-full ${kpi.bar}`} />
                    </div>
                  </div>
                ))}
              </div>

              <div className="rounded-[18px] border border-tv-border bg-tv-surface/88 p-5">
                <div className="mb-4 flex items-center justify-between">
                  <div className="text-xs font-extrabold uppercase tracking-[0.22em] text-tv-dim">
                    Alertas activas
                  </div>
                  <span className="rounded-full bg-state-critica/12 px-3 py-1 text-xs font-bold text-state-critica">
                    10 pendientes
                  </span>
                </div>
                <div className="space-y-3">
                  {["Celulas somaticas", "Retirada de leche", "Parto inminente"].map((item, index) => (
                    <div
                      key={item}
                      className="rounded-xl border-l-4 border-state-critica bg-white px-4 py-3 text-app-text"
                    >
                      <div className="flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.14em] text-state-critica">
                        <AlertTriangle className="h-3.5 w-3.5" />
                        Critica
                      </div>
                      <div className="mt-1 font-heading text-lg font-bold">{item}</div>
                      <div className="text-xs font-semibold text-app-dim">ES-{index === 0 ? "1423" : index === 1 ? "0892" : "3102"}</div>
                    </div>
                  ))}
                </div>
              </div>
            </aside>
          </div>

          <footer className="flex flex-wrap items-center justify-between gap-3 border-t border-tv-border pt-5 text-sm font-semibold text-tv-dim">
            <span className="flex items-center gap-2">
              <StatusDot online />
              Tools4 Milk - Sala de Ordeno
            </span>
            <span>Ultima actualizacion: hace 3 min</span>
          </footer>
        </section>

        <section className="flex min-h-[calc(100vh-80px)] items-center justify-center">
          <div className="w-full max-w-[520px] overflow-hidden rounded-[26px] border border-white/10 bg-app-bg shadow-deck">
            <div className="bg-brand px-6 py-5 text-white sm:px-7">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <div className="text-xs font-extrabold uppercase tracking-[0.18em] text-white/55">
                    Acceso seguro
                  </div>
                  <h2 className="mt-1 font-heading text-[30px] font-bold leading-tight">
                    Tools4 Milk
                  </h2>
                </div>
                <div className="flex items-center gap-3 rounded-full border border-white/15 bg-white/10 px-3 py-2">
                  <StatusDot online={backendOnline} />
                  <span className="text-xs font-bold">
                    {backendOnline ? "API online" : health.isLoading ? "Conectando" : "API offline"}
                  </span>
                </div>
              </div>
            </div>

            <div className="px-5 py-5 sm:px-7 sm:py-6">
              <div className="mb-5 grid grid-cols-2 gap-3">
                {roles.map(({ value, short, Icon }) => {
                  const active = selectedRole === value;
                  return (
                    <button
                      key={value}
                      type="button"
                      onClick={() => setSelectedRole(value)}
                      className={`flex min-h-[80px] items-center gap-3 rounded-[14px] border px-4 text-left transition ${
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

              <form
                className="grid gap-4"
                onSubmit={(event) => {
                  event.preventDefault();
                  submitLogin();
                }}
              >
                <div>
                  <label className="mb-2 block text-xs font-extrabold uppercase tracking-[0.18em] text-app-dim">
                    Usuario
                  </label>
                  <input
                    value={username}
                    onChange={(event) => setUsername(event.target.value)}
                    placeholder="nombre.apellido"
                    className="h-[58px] w-full rounded-[14px] border border-app-border bg-white px-5 text-[18px] font-semibold text-app-text outline-none transition placeholder:text-app-dim/50 focus:border-brand focus:ring-4 focus:ring-brand/10"
                  />
                </div>

                <div>
                  <label className="mb-2 block text-xs font-extrabold uppercase tracking-[0.18em] text-app-dim">
                    Contrasena
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    placeholder="Minimo 8 caracteres"
                    className="h-[58px] w-full rounded-[14px] border border-app-border bg-white px-5 text-[18px] font-semibold text-app-text outline-none transition placeholder:text-app-dim/50 focus:border-brand focus:ring-4 focus:ring-brand/10"
                  />
                </div>

                {loginMutation.isError && (
                  <div className="rounded-[14px] border border-[#fecaca] bg-[#fff1f2] px-4 py-3 text-sm font-bold text-state-critica">
                    {loginMutation.error.message}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={isLoading || !username.trim() || password.length < 8}
                  className="mt-1 flex min-h-[80px] w-full items-center justify-center gap-3 rounded-[16px] bg-brand font-heading text-[22px] font-bold text-white shadow-brand transition hover:bg-[#135532] disabled:cursor-not-allowed disabled:bg-brand/55"
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="h-6 w-6 animate-spin" />
                      Autenticando
                    </>
                  ) : (
                    <>
                      Entrar
                      <ChevronRight className="h-6 w-6" />
                    </>
                  )}
                </button>
              </form>

              <div className="mt-5 rounded-[16px] border border-app-border bg-white p-4">
                <div className="mb-3 flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.18em] text-app-dim">
                  <ClipboardCheck className="h-4 w-4" />
                  Accesos de prueba
                </div>
                <div className="grid gap-2">
                  {demoUsers.map((demo) => (
                    <button
                      key={demo.username}
                      type="button"
                      onClick={() => {
                        setUsername(demo.username);
                        setPassword("testpass123");
                        setSelectedRole(demo.role);
                      }}
                      className="flex min-h-[44px] items-center justify-between rounded-[10px] px-2 text-left text-sm font-semibold text-app-dim transition hover:bg-app-bg"
                    >
                      <span className="font-mono">{demo.username}</span>
                      <span>{demo.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              <div className="mt-4 flex items-center gap-2 rounded-[14px] border border-app-border bg-white px-4 py-3 text-xs font-semibold text-app-dim">
                <BarChart3 className="h-4 w-4" />
                <span className="truncate">
                  API: <span className="font-mono text-app-text">{API_BASE_URL}</span>
                </span>
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
