"use client";

import { useState, useMemo } from "react";
import { Plus } from "lucide-react";
import type { Task, Zone, Employee } from "@/lib/types";
import { TaskCard } from "./TaskCard";
import { TaskAssignmentModal } from "./TaskAssignmentModal";

interface ZonePlanViewProps {
  tasks: Task[];
  zones: Zone[];
  employees: Employee[];
  onTaskUpdate: (taskId: string, updates: Partial<Task>) => void;
}

const COLUMNS = [
  { key: "unassigned", label: "Sin asignar", color: "bg-app-bg" },
  { key: "assigned", label: "Asignadas", color: "bg-state-info/5" },
  { key: "in_progress", label: "En curso", color: "bg-brand/5" },
  { key: "completed", label: "Finalizadas", color: "bg-state-ok/5" },
];

export function ZonePlanView({
  tasks,
  zones,
  employees,
  onTaskUpdate,
}: ZonePlanViewProps) {
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [selectedZone, setSelectedZone] = useState<string | "all">("all");

  // Filter tasks by zone
  const filteredTasks = useMemo(() => {
    if (selectedZone === "all") return tasks;
    return tasks.filter((t) => t.zona_id === selectedZone);
  }, [tasks, selectedZone]);

  // Organize tasks by assignment status
  const tasksByColumn = useMemo(() => {
    const columns: {
      unassigned: Task[];
      assigned: Task[];
      in_progress: Task[];
      completed: Task[];
    } = {
      unassigned: [],
      assigned: [],
      in_progress: [],
      completed: [],
    };

    filteredTasks.forEach((task) => {
      if (task.estado === "ejecutada") {
        columns.completed.push(task);
      } else if (task.estado === "pausada") {
        columns.in_progress.push(task);
      } else if (task.empleado_id) {
        columns.assigned.push(task);
      } else {
        columns.unassigned.push(task);
      }
    });

    // Sort by date
    Object.values(columns).forEach((col) => {
      col.sort(
        (a, b) =>
          new Date(b.fecha_programada || 0).getTime() -
          new Date(a.fecha_programada || 0).getTime()
      );
    });

    return columns;
  }, [filteredTasks]);

  const getEmployeeById = (id?: string) => employees.find((e) => e.id === id);

  return (
    <div className="space-y-6">
      {/* Zone filter */}
      <div>
        <label className="text-xs font-semibold uppercase text-app-dim mb-2 block">
          Filtrar por zona
        </label>
        <select
          value={selectedZone}
          onChange={(e) => setSelectedZone(e.target.value)}
          className="rounded-[10px] border border-app-border px-3 py-2 text-sm bg-white"
        >
          <option value="all">Todas las zonas</option>
          {zones.map((zone) => (
            <option key={zone.id} value={zone.id}>
              {zone.nombre}
            </option>
          ))}
        </select>
      </div>

      {/* Kanban board */}
      <div className="grid gap-4 grid-cols-1 lg:grid-cols-4">
        {COLUMNS.map(({ key, label, color }) => {
          const tasksInColumn = tasksByColumn[key as keyof typeof tasksByColumn];

          return (
            <div
              key={key}
              className={`rounded-[10px] border border-app-border ${color} p-4 min-h-[600px]`}
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-bold text-sm text-app-text">
                  {label}
                  <span className="text-xs font-normal text-app-dim ml-2">
                    ({tasksInColumn.length})
                  </span>
                </h3>
              </div>

              <div className="space-y-2">
                {tasksInColumn.map((task) => (
                  <TaskCard
                    key={task.id}
                    task={task}
                    assignedEmployee={
                      task.empleado_id ? getEmployeeById(task.empleado_id) : undefined
                    }
                    onClick={() => {
                      if (key === "unassigned" || key === "assigned") {
                        setSelectedTask(task);
                      }
                    }}
                    showAssigned
                    variant="compact"
                  />
                ))}

                {tasksInColumn.length === 0 && (
                  <div className="text-xs text-app-dim text-center py-8">
                    Sin tareas
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Assignment modal */}
      {selectedTask && (
        <TaskAssignmentModal
          task={selectedTask}
          employees={employees}
          zones={zones}
          onAssign={(employeeId) => {
            onTaskUpdate(selectedTask.id, { empleado_id: employeeId });
            setSelectedTask(null);
          }}
          onClose={() => setSelectedTask(null)}
        />
      )}
    </div>
  );
}
