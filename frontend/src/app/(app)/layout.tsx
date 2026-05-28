"use client";

import {
  Activity,
  AlertOctagon,
  AlertTriangle,
  ArrowLeftRight,
  Beef,
  BrainCircuit,
  CalendarClock,
  ClipboardList,
  Droplets,
  LayoutDashboard,
  ListTodo,
  LogOut,
  MapPin,
  Milk,
  Package,
  Settings2,
  ShieldCheck,
  SlidersHorizontal,
  UserRound,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { OperationalAssistant } from "@/features/assistant/operational-assistant";
import { useAppStore } from "@/store/app-store";

type NavItem = { href: string; label: string; Icon: typeof LayoutDashboard };

const navGroups: { label: string; items: NavItem[] }[] = [
  {
    label: "",
    items: [
      { href: "/dashboard", label: "Control", Icon: LayoutDashboard },
    ],
  },
  {
    label: "Operativa",
    items: [
      { href: "/leanfarming", label: "LeanFarming", Icon: ListTodo },
      { href: "/tasks", label: "Tareas", Icon: ClipboardList },
      { href: "/alerts", label: "Alertas", Icon: AlertTriangle },
      { href: "/incidents", label: "Incidencias", Icon: AlertOctagon },
      { href: "/handover", label: "Relevos", Icon: ArrowLeftRight },
    ],
  },
  {
    label: "Ganadería",
    items: [
      { href: "/animals", label: "Animales", Icon: Beef },
      { href: "/quality", label: "Calidad", Icon: Droplets },
      { href: "/predictions", label: "Predicciones", Icon: BrainCircuit },
    ],
  },
  {
    label: "Recursos",
    items: [
      { href: "/shifts", label: "Turnos", Icon: CalendarClock },
      { href: "/orders", label: "Pedidos", Icon: Package },
    ],
  },
  {
    label: "Sistema",
    items: [
      { href: "/profile", label: "Perfil", Icon: UserRound },
      { href: "/settings", label: "Configuración", Icon: SlidersHorizontal },
      { href: "/zones", label: "Zonas", Icon: MapPin },
      { href: "/management", label: "Gestión", Icon: Settings2 },
      { href: "/integration", label: "Integración", Icon: Activity },
      { href: "/audit-log", label: "Audit Log", Icon: ShieldCheck },
    ],
  },
];

function LogoMark() {
  return (
    <div className="t4m-logo grid h-9 w-9 shrink-0 place-items-center rounded-[10px] text-white shadow-brand">
      <Milk className="h-4.5 w-4.5" strokeWidth={2.4} />
    </div>
  );
}

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const hydrate = useAppStore((state) => state.hydrate);
  const isHydrated = useAppStore((state) => state.isHydrated);
  const token = useAppStore((state) => state.token);
  const user = useAppStore((state) => state.user);
  const logout = useAppStore((state) => state.logout);

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  useEffect(() => {
    if (isHydrated && !token) router.replace("/");
  }, [isHydrated, token, router]);

  if (!isHydrated || !token) {
    return (
      <div className="grid min-h-screen place-items-center bg-app-bg">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-brand border-t-transparent" />
      </div>
    );
  }

  function handleLogout() {
    logout();
    router.replace("/");
  }

  return (
    <div className="flex min-h-screen bg-app-bg font-body text-app-text">
      {/* ── Sidebar ── */}
      <aside className="flex w-56 shrink-0 flex-col border-r border-[#1e3a26] bg-[#0d1a10]">
        {/* Logo */}
        <div className="flex items-center gap-3 border-b border-[#1e3a26] px-4 py-4">
          <LogoMark />
          <div className="min-w-0">
            <div className="font-heading text-[15px] font-bold leading-none text-white">
              Tools4 Milk
            </div>
            <div className="mt-0.5 text-[11px] font-semibold text-[#7fa18d]">
              Centro de control
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto px-2 py-3">
          {navGroups.map((group) => (
            <div key={group.label} className="mb-4">
              {group.label && (
                <p className="mb-1 px-3 text-[10px] font-extrabold uppercase tracking-[0.14em] text-[#4a7058]">
                  {group.label}
                </p>
              )}
              {group.items.map(({ href, label, Icon }) => {
                const active = pathname === href || pathname.startsWith(`${href}/`);
                return (
                  <Link
                    key={href}
                    href={href}
                    className={`flex items-center gap-2.5 rounded-[10px] px-3 py-2.5 text-sm font-semibold transition-colors ${
                      active
                        ? "bg-[#1e3a26] text-[#35e479]"
                        : "text-[#7fa18d] hover:bg-[#1a2e1f] hover:text-white"
                    }`}
                  >
                    <Icon
                      className={`h-4 w-4 shrink-0 ${active ? "text-[#35e479]" : "text-[#4a7058]"}`}
                      strokeWidth={2}
                    />
                    {label}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>

        {/* User footer */}
        <div className="space-y-1.5 border-t border-[#1e3a26] px-2 py-3">
          <div className="rounded-[10px] bg-[#132219] px-3 py-2.5">
            <div className="truncate text-xs font-bold text-white">
              {user?.username ?? "Usuario"}
            </div>
            <div className="mt-0.5 text-[11px] capitalize text-[#7fa18d]">
              {user?.role ?? "operario"}
            </div>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className="flex w-full items-center gap-2 rounded-[10px] px-3 py-2 text-sm font-semibold text-[#7fa18d] transition hover:bg-[#3d1010]/40 hover:text-state-critica"
          >
            <LogOut className="h-4 w-4" />
            Cerrar sesión
          </button>
        </div>
      </aside>

      {/* ── Main content ── */}
      <main className="min-w-0 flex-1 overflow-auto">
        {children}
      </main>

      <OperationalAssistant />
    </div>
  );
}
