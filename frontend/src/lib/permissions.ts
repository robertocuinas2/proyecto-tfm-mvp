import type { UserRole } from "@/lib/types";

export type Permission =
  | "manageAnimals"
  | "manageZones"
  | "manageTasks"
  | "manageClinical"
  | "manageQuality"
  | "manageOperations"
  | "manageEmployees";

const permissionMatrix: Record<Permission, UserRole[]> = {
  manageAnimals: ["admin", "veterinario"],
  manageZones: ["admin"],
  manageTasks: ["admin", "operario", "alimentacion"],
  manageClinical: ["admin", "veterinario"],
  manageQuality: ["admin", "veterinario", "alimentacion"],
  manageOperations: ["admin", "operario", "alimentacion"],
  manageEmployees: ["admin"],
};

export function hasPermission(role: UserRole | undefined, permission: Permission): boolean {
  return Boolean(role && permissionMatrix[permission].includes(role));
}

export function roleLabel(role: UserRole | undefined): string {
  if (role === "admin") return "Administrador";
  if (role === "veterinario") return "Veterinario";
  if (role === "alimentacion") return "Alimentacion";
  return "Operario";
}
