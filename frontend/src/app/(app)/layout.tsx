"use client";

import {
  AlertTriangle,
  Beef,
  BrainCircuit,
  ClipboardList,
  Droplets,
  LayoutDashboard,
  ListTodo,
  LogOut,
  MapPin,
  Milk,
  Settings2,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { OperationalAssistant } from "@/features/assistant/operational-assistant";
import { useAppStore } from "@/store/app-store";

const navItems = [
  { href: "/dashboard", label: "Control", Icon: LayoutDashboard },
  { href: "/zones", label: "Zonas", Icon: MapPin },
  { href: "/alerts", label: "Alertas", Icon: AlertTriangle },
  { href: "/tasks", label: "Tareas", Icon: ClipboardList },
  { href: "/leanfarming", label: "LeanFarming", Icon: ListTodo },
  { href: "/animals", label: "Animales", Icon: Beef },
  { href: "/quality", label: "Calidad", Icon: Droplets },
  { href: "/predictions", label: "Predicciones", Icon: BrainCircuit },
  { href: "/management", label: "Gestion", Icon: Settings2 },
];

function LogoMark() {
  return (
    <div className="t4m-logo grid h-10 w-10 shrink-0 place-items-center rounded-[11px] text-white shadow-brand">
      <Milk className="h-5 w-5" strokeWidth={2.4} />
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
      <div className="grid min-h-screen place-items-center bg-tv-bg">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-tv-accent border-t-transparent" />
      </div>
    );
  }

  function handleLogout() {
    logout();
    router.replace("/");
  }

  return (
    <div className="flex min-h-screen bg-tv-bg font-body text-white">
      <aside className="flex w-56 shrink-0 flex-col border-r border-tv-border bg-tv-surface">
        <div className="flex items-center gap-3 border-b border-tv-border px-4 py-4">
          <LogoMark />
          <div className="min-w-0">
            <div className="font-heading text-[15px] font-bold leading-none">Tools4 Milk</div>
            <div className="mt-0.5 text-[11px] font-semibold text-tv-dim">Centro de control</div>
          </div>
        </div>

        <nav className="flex-1 space-y-0.5 px-2 py-3">
          {navItems.map(({ href, label, Icon }) => {
            const active = pathname === href || pathname.startsWith(`${href}/`);
            return (
              <Link
                key={href}
                href={href}
                className={`flex items-center gap-2.5 rounded-[10px] px-3 py-2.5 text-sm font-semibold transition ${
                  active
                    ? "bg-tv-surface2 text-tv-accent"
                    : "text-tv-dim hover:bg-tv-surface2/60 hover:text-white"
                }`}
              >
                <Icon className="h-4 w-4 shrink-0" strokeWidth={2} />
                {label}
              </Link>
            );
          })}
        </nav>

        <div className="space-y-2 border-t border-tv-border px-2 py-3">
          <div className="rounded-[10px] bg-tv-surface2 px-3 py-2.5">
            <div className="truncate text-xs font-bold text-white">{user?.username ?? "Usuario"}</div>
            <div className="text-[11px] capitalize text-tv-dim">{user?.role ?? "operario"}</div>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className="flex w-full items-center gap-2 rounded-[10px] px-3 py-2 text-sm font-semibold text-tv-dim transition hover:bg-state-critica/10 hover:text-state-critica"
          >
            <LogOut className="h-4 w-4" />
            Cerrar sesion
          </button>
        </div>
      </aside>

      <main className="min-w-0 flex-1 overflow-auto">{children}</main>
      <OperationalAssistant />
    </div>
  );
}
