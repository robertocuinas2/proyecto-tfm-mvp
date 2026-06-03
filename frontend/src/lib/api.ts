import { API_BASE_URL, API_V1_URL, TOKEN_STORAGE_KEY } from "@/lib/config";
import type {
  Alert,
  AlertsResponse,
  Animal,
  AnimalPrediction,
  AssistantRequest,
  AssistantResponse,
  AuditLogResponse,
  AuthResponse,
  CreateIncidentPayload,
  CreateOrderPayload,
  CreateShiftAssignmentPayload,
  CreateShiftPayload,
  DashboardSummary,
  Employee,
  HealthResponse,
  Incident,
  Lactation,
  LoginPayload,
  Machinery,
  Order,
  OrderStatus,
  OrdersResponse,
  QualitySummary,
  Shift,
  ShiftAssignment,
  ShiftAssignmentsResponse,
  ShiftHandover,
  ShiftHandoversResponse,
  ShiftsResponse,
  Task,
  TaskCatalogItem,
  Treatment,
  WeatherData,
  Zone,
} from "@/lib/types";

type QueryParams = Record<string, string | number | boolean | null | undefined>;

function getToken() {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(TOKEN_STORAGE_KEY);
}

function buildUrl(path: string, params?: QueryParams): string {
  const base = path.startsWith("/api") || path === "/health" ? API_BASE_URL : API_V1_URL;
  const fullPath = `${base}${path}`;
  const entries = Object.entries(params ?? {}).filter(([, value]) => value !== null && value !== undefined && value !== "");
  if (entries.length === 0) return fullPath;
  return `${fullPath}?${new URLSearchParams(entries.map(([key, value]) => [key, String(value)])).toString()}`;
}

async function request<T>(path: string, init: RequestInit = {}, params?: QueryParams): Promise<T> {
  const token = getToken();
  const response = await fetch(buildUrl(path, params), {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
  });

  if (!response.ok) {
    let detail = `${response.status} ${response.statusText}`;
    try {
      const payload = await response.json();
      if (typeof payload.detail === "string") detail = payload.detail;
    } catch {
      // Keep the HTTP fallback message.
    }
    throw new Error(detail);
  }

  if (response.status === 204) return undefined as T;
  return response.json() as Promise<T>;
}

export const api = {
  health() {
    return request<HealthResponse>("/health");
  },

  login(payload: LoginPayload) {
    return request<AuthResponse>("/auth/login", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  me() {
    return request<AuthResponse["user"]>("/auth/me");
  },

  assistantMessage(payload: AssistantRequest) {
    return request<AssistantResponse>("/assistant/message", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  dashboardSummary() {
    return request<DashboardSummary>("/dashboard/summary");
  },

  zones() {
    return request<Zone[]>("/zones");
  },

  zone(zoneId: string) {
    return request<Zone>(`/zones/${zoneId}`);
  },

  createZone(body: Partial<Zone>) {
    return request<Zone>("/zones", { method: "POST", body: JSON.stringify(body) });
  },

  updateZone(zoneId: string, body: Partial<Zone>) {
    return request<Zone>(`/zones/${zoneId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  alerts(params?: QueryParams) {
    return request<AlertsResponse>("/alerts", {}, params);
  },

  animalAlerts(animalId: string, params?: QueryParams) {
    return request<AlertsResponse>(`/alerts/${animalId}`, {}, params);
  },

  alertDetail(alertId: string) {
    return request<Alert>(`/alerts/detail/${alertId}`);
  },

  createAlert(body: Partial<Alert>) {
    return request<Alert>("/alerts", { method: "POST", body: JSON.stringify(body) });
  },

  reviewAlert(alertId: string, body: Partial<Alert>) {
    return request<Alert>(`/alerts/${alertId}`, { method: "PATCH", body: JSON.stringify(body) });
  },

  generateAlerts(animalId: string) {
    return request<{ generated: number; alertas: Alert[] }>(`/alerts/generate/${animalId}`, { method: "POST" });
  },

  tasks(params?: QueryParams) {
    return request<Task[]>("/tasks", {}, params);
  },

  task(taskId: string) {
    return request<Task>(`/tasks/${taskId}`);
  },

  createTask(body: Partial<Task>) {
    return request<Task>("/tasks", { method: "POST", body: JSON.stringify(body) });
  },

  taskCatalog(params?: QueryParams) {
    return request<TaskCatalogItem[]>("/tasks/catalog", {}, params);
  },

  createTaskCatalog(body: Partial<TaskCatalogItem>) {
    return request<TaskCatalogItem>("/tasks/catalog", { method: "POST", body: JSON.stringify(body) });
  },

  completeTask(taskId: string, body?: Partial<Task>) {
    return request<Task>(`/tasks/${taskId}`, {
      method: "PUT",
      body: JSON.stringify({
        estado: "ejecutada",
        fecha_ejecucion: new Date().toISOString(),
        resultado: "completada",
        ...body,
      }),
    });
  },

  updateTask(taskId: string, body: Partial<Task>) {
    return request<Task>(`/tasks/${taskId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  animals(params?: QueryParams) {
    return request<Animal[]>("/animals", {}, params);
  },

  animal(animalId: string) {
    return request<Animal>(`/animals/${animalId}`);
  },

  createAnimal(body: Partial<Animal>) {
    return request<Animal>("/animals", { method: "POST", body: JSON.stringify(body) });
  },

  updateAnimal(animalId: string, body: Partial<Animal>) {
    return request<Animal>(`/animals/${animalId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  animalByCretal(crotal: string) {
    return request<Animal>(`/animals/search/by-crotal/${crotal}`);
  },

  incidents(params?: QueryParams) {
    return request<Incident[]>("/incidents", {}, params);
  },

  incident(incidentId: string) {
    return request<Incident>(`/incidents/${incidentId}`);
  },

  createIncident(body: CreateIncidentPayload) {
    return request<Incident>("/incidents", { method: "POST", body: JSON.stringify(body) });
  },

  updateIncident(incidentId: string, body: Partial<Incident>) {
    return request<Incident>(`/incidents/${incidentId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  treatments(params?: QueryParams) {
    return request<Treatment[]>("/treatments", {}, params);
  },

  treatment(treatmentId: string) {
    return request<Treatment>(`/treatments/${treatmentId}`);
  },

  createTreatment(body: Partial<Treatment>) {
    return request<Treatment>("/treatments", { method: "POST", body: JSON.stringify(body) });
  },

  updateTreatment(treatmentId: string, body: Partial<Treatment>) {
    return request<Treatment>(`/treatments/${treatmentId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  employees(params?: QueryParams) {
    return request<Employee[]>("/employees", {}, params);
  },

  createEmployee(body: Partial<Employee>) {
    return request<Employee>("/employees", { method: "POST", body: JSON.stringify(body) });
  },

  updateEmployee(employeeId: string, body: Partial<Employee>) {
    return request<Employee>(`/employees/${employeeId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  lactations(params?: QueryParams) {
    return request<Lactation[]>("/lactations", {}, params);
  },

  createLactation(body: Partial<Lactation>) {
    return request<Lactation>("/lactations", { method: "POST", body: JSON.stringify(body) });
  },

  updateLactation(lactationId: string, body: Partial<Lactation>) {
    return request<Lactation>(`/lactations/${lactationId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  qualitySummary() {
    return request<QualitySummary>("/lactations/quality/summary");
  },

  predictions(animalId: string, params?: QueryParams) {
    return request<AnimalPrediction>(`/predictions/${animalId}`, {}, params);
  },

  productionPrediction(animalId: string, params?: QueryParams) {
    return request<AnimalPrediction["produccion"]>(`/predictions/production/${animalId}`, {}, params);
  },

  compositionPrediction(animalId: string) {
    return request<AnimalPrediction["composicion"]>(`/predictions/composition/${animalId}`);
  },

  healthRiskPrediction(animalId: string, params?: QueryParams) {
    return request<AnimalPrediction["riesgo_sanitario"]>(`/predictions/health-risk/${animalId}`, {}, params);
  },

  weather() {
    return request<WeatherData>("/weather/current");
  },

  machinery(params?: QueryParams) {
    return request<Machinery[]>("/machinery", {}, params);
  },

  createMachinery(body: Partial<Machinery>) {
    return request<Machinery>("/machinery", { method: "POST", body: JSON.stringify(body) });
  },

  updateMachinery(machineryId: string, body: Partial<Machinery>) {
    return request<Machinery>(`/machinery/${machineryId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  // ── Orders (Pedidos) ──────────────────────────────────────────────────────

  orders(params?: QueryParams) {
    return request<OrdersResponse>("/pedidos", {}, params);
  },

  order(orderId: string) {
    return request<Order>(`/pedidos/${orderId}`);
  },

  createOrder(body: CreateOrderPayload) {
    return request<Order>("/pedidos", { method: "POST", body: JSON.stringify(body) });
  },

  updateOrder(orderId: string, body: Partial<Order>) {
    return request<Order>(`/pedidos/${orderId}`, { method: "PUT", body: JSON.stringify(body) });
  },

  updateOrderStatus(orderId: string, estado: OrderStatus) {
    return request<Order>(`/pedidos/${orderId}/estado`, {
      method: "PATCH",
      body: JSON.stringify({ estado }),
    });
  },

  // ── Shifts (Turnos) ───────────────────────────────────────────────────────

  shifts(params?: QueryParams) {
    return request<ShiftsResponse>("/turnos", {}, params);
  },

  createShift(body: CreateShiftPayload) {
    return request<Shift>("/turnos", { method: "POST", body: JSON.stringify(body) });
  },

  shiftAssignments(params?: QueryParams) {
    return request<ShiftAssignmentsResponse>("/asignaciones-turno", {}, params);
  },

  createShiftAssignment(body: CreateShiftAssignmentPayload) {
    return request<ShiftAssignment>("/asignaciones-turno", {
      method: "POST",
      body: JSON.stringify(body),
    });
  },

  // ── Handovers (Resúmenes de relevo) ───────────────────────────────────────

  shiftHandovers(params?: QueryParams) {
    return request<ShiftHandoversResponse>("/resumenes-relevo", {}, params);
  },

  createShiftHandover(body: { turno_saliente_id: string; turno_entrante_id: string; notas_saliente?: string }) {
    return request<ShiftHandover>("/resumenes-relevo", { method: "POST", body: JSON.stringify(body) });
  },

  // ── Weather (extended) ────────────────────────────────────────────────────

  weatherForecast() {
    return request<unknown>("/weather/forecast");
  },

  // ── Audit Log ─────────────────────────────────────────────────────────────

  auditLog(params?: QueryParams) {
    return request<AuditLogResponse>("/audit-log", {}, params);
  },
};
