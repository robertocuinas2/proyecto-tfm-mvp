"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Bot, Check, Mic, MicOff, Send, X } from "lucide-react";
import { usePathname } from "next/navigation";
import { useMemo, useState } from "react";
import { api } from "@/lib/api";
import { ASSISTANT_ENABLED } from "@/lib/config";
import type { AssistantResponse } from "@/lib/types";

type SpeechRecognitionLike = {
  lang: string;
  interimResults: boolean;
  start: () => void;
  stop: () => void;
  onresult: ((event: SpeechRecognitionEventLike) => void) | null;
  onend: (() => void) | null;
  onerror: (() => void) | null;
};

type SpeechRecognitionConstructor = new () => SpeechRecognitionLike;

type SpeechRecognitionEventLike = {
  results: ArrayLike<{ 0: { transcript: string } }>;
};

type AssistantMessage = {
  id: string;
  role: "user" | "assistant";
  text: string;
  response?: AssistantResponse;
};

function getSpeechRecognition(): SpeechRecognitionConstructor | null {
  if (typeof window === "undefined") return null;
  const speechWindow = window as Window & {
    SpeechRecognition?: SpeechRecognitionConstructor;
    webkitSpeechRecognition?: SpeechRecognitionConstructor;
  };
  return speechWindow.SpeechRecognition ?? speechWindow.webkitSpeechRecognition ?? null;
}

function isTvRoute(pathname: string) {
  return /^\/zones\/[^/]+$/.test(pathname);
}

export function OperationalAssistant() {
  const pathname = usePathname();
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [input, setInput] = useState("");
  const [listening, setListening] = useState(false);
  const [messages, setMessages] = useState<AssistantMessage[]>([
    {
      id: "welcome",
      role: "assistant",
      text: "Puedo crear lactaciones, tratamientos, tareas e incidencias; tambien revisar alertas y consultar estado.",
    },
  ]);

  const SpeechRecognition = useMemo(() => getSpeechRecognition(), []);
  const hidden = !ASSISTANT_ENABLED || isTvRoute(pathname);

  const mutation = useMutation({
    mutationFn: api.assistantMessage,
    onSuccess: (response) => {
      setMessages((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          text: response.reply,
          response,
        },
      ]);
      if (response.result) {
        queryClient.invalidateQueries();
      }
    },
    onError: (error) => {
      setMessages((current) => [
        ...current,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          text: error instanceof Error ? error.message : "No he podido completar la accion.",
        },
      ]);
    },
  });

  if (hidden) return null;

  function send(text: string) {
    const clean = text.trim();
    if (!clean || mutation.isPending) return;
    setInput("");
    setMessages((current) => [
      ...current,
      { id: crypto.randomUUID(), role: "user", text: clean },
    ]);
    mutation.mutate({ message: clean });
  }

  function confirm(response: AssistantResponse) {
    if (!response.draft || mutation.isPending) return;
    setMessages((current) => [
      ...current,
      { id: crypto.randomUUID(), role: "user", text: "Confirmado" },
    ]);
    mutation.mutate({ message: "confirmo", confirmed: true, draft: response.draft });
  }

  function startVoice() {
    if (!SpeechRecognition || listening) return;
    const recognition = new SpeechRecognition();
    recognition.lang = "es-ES";
    recognition.interimResults = false;
    recognition.onresult = (event) => {
      const transcript = event.results[0]?.[0]?.transcript;
      if (transcript) setInput(transcript);
    };
    recognition.onerror = () => setListening(false);
    recognition.onend = () => setListening(false);
    setListening(true);
    recognition.start();
  }

  return (
    <div className="fixed bottom-5 right-5 z-50 hidden w-[360px] max-w-[calc(100vw-2rem)] md:block">
      {open ? (
        <section className="overflow-hidden rounded-lg border border-tv-border bg-tv-surface shadow-2xl">
          <div className="flex items-center justify-between border-b border-tv-border px-4 py-3">
            <div className="flex items-center gap-2">
              <span className="grid h-9 w-9 place-items-center rounded-lg bg-tv-accent/15 text-tv-accent">
                <Bot className="h-5 w-5" />
              </span>
              <div>
                <div className="font-heading text-sm font-bold text-white">Asistente operativo</div>
                <div className="text-[11px] font-semibold text-tv-dim">Texto y voz con confirmacion</div>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setOpen(false)}
              className="grid h-8 w-8 place-items-center rounded-lg text-tv-dim transition hover:bg-tv-surface2 hover:text-tv-text"
              aria-label="Cerrar asistente"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          <div className="max-h-[360px] space-y-3 overflow-y-auto px-4 py-4">
            {messages.map((message) => (
              <div
                key={message.id}
                className={`rounded-lg px-3 py-2 text-sm ${
                  message.role === "user"
                    ? "ml-8 bg-tv-accent/15 text-white"
                    : "mr-8 bg-tv-surface2 text-tv-dim"
                }`}
              >
                <p>{message.text}</p>
                {message.response?.requires_confirmation && (
                  <div className="mt-3 flex gap-2">
                    <button
                      type="button"
                      onClick={() => confirm(message.response as AssistantResponse)}
                      disabled={mutation.isPending}
                      className="inline-flex items-center gap-1.5 rounded-lg bg-state-ok/15 px-3 py-1.5 text-xs font-bold text-state-ok transition hover:bg-state-ok/25 disabled:opacity-50"
                    >
                      <Check className="h-3.5 w-3.5" />
                      Confirmar
                    </button>
                  </div>
                )}
              </div>
            ))}
            {mutation.isPending && (
              <div className="mr-8 rounded-lg bg-tv-surface2 px-3 py-2 text-sm font-semibold text-tv-dim">
                Pensando...
              </div>
            )}
          </div>

          <form
            className="border-t border-tv-border p-3"
            onSubmit={(event) => {
              event.preventDefault();
              send(input);
            }}
          >
            <div className="flex gap-2">
              <input
                value={input}
                onChange={(event) => setInput(event.target.value)}
                placeholder="Dicta o escribe una accion"
                className="h-10 min-w-0 flex-1 rounded-lg border border-tv-border bg-tv-bg px-3 text-sm text-white outline-none placeholder:text-tv-dim focus:border-tv-accent"
              />
              <button
                type="button"
                onClick={startVoice}
                disabled={!SpeechRecognition || listening}
                className="grid h-10 w-10 place-items-center rounded-lg bg-tv-surface2 text-tv-dim transition hover:text-tv-accent disabled:opacity-40"
                aria-label="Dictar por voz"
                title={SpeechRecognition ? "Dictar por voz" : "Voz no soportada por este navegador"}
              >
                {listening ? <MicOff className="h-4 w-4" /> : <Mic className="h-4 w-4" />}
              </button>
              <button
                type="submit"
                disabled={!input.trim() || mutation.isPending}
                className="grid h-10 w-10 place-items-center rounded-lg bg-tv-accent text-tv-bg transition hover:bg-tv-accent2 disabled:opacity-40"
                aria-label="Enviar"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
          </form>
        </section>
      ) : (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="ml-auto flex h-12 items-center gap-2 rounded-full border border-tv-accent/35 bg-tv-surface px-4 text-sm font-bold text-white shadow-2xl transition hover:bg-tv-surface2"
        >
          <Bot className="h-5 w-5 text-tv-accent" />
          Asistente
        </button>
      )}
    </div>
  );
}
