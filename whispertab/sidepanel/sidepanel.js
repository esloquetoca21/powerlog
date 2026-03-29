// ============================================================
// WhisperTab - Side Panel (la interfaz que ve el usuario)
// ============================================================
// Este archivo controla todo lo que pasa en el panel lateral:
// - Botones para iniciar/detener grabación
// - Mostrar la transcripción en tiempo real
// - Enviar a Claude para generar resúmenes
// - Copiar texto y limpiar
// ============================================================

// --- Referencias a elementos del HTML ---
const btnRealtime = document.getElementById("btn-realtime");
const btnDeferred = document.getElementById("btn-deferred");
const btnStop = document.getElementById("btn-stop");
const btnSummarize = document.getElementById("btn-summarize");
const btnCopy = document.getElementById("btn-copy");
const btnClear = document.getElementById("btn-clear");
const statusBadge = document.getElementById("status-badge");
const statusDetail = document.getElementById("status-detail");
const transcriptArea = document.getElementById("transcript-area");
const summarySection = document.getElementById("summary-section");
const summaryContent = document.getElementById("summary-content");
const errorBanner = document.getElementById("error-banner");
const openOptions = document.getElementById("open-options");

// --- Estado local del panel ---
let fullTranscript = "";      // Toda la transcripción acumulada
let interimText = "";          // Texto parcial (modo tiempo real)
let currentMode = null;        // "realtime" o "deferred"

// ============================================================
// EVENTOS DE BOTONES
// ============================================================

// --- Botón "Tiempo Real" ---
btnRealtime.addEventListener("click", async () => {
  currentMode = "realtime";
  highlightActiveMode(btnRealtime);

  // Obtener la pestaña activa
  const tab = await getCurrentTab();
  if (!tab) {
    showError("No se pudo obtener la pestaña activa.");
    return;
  }

  // Enviar mensaje al service worker para que inicie el modo
  chrome.runtime.sendMessage({
    type: "START_REALTIME",
    tabId: tab.id
  });

  // Activar botón de detener
  btnStop.disabled = false;
});

// --- Botón "Diferido" ---
btnDeferred.addEventListener("click", async () => {
  // Verificar que hay API key configurada
  const settings = await chrome.storage.sync.get(["groqApiKey"]);
  if (!settings.groqApiKey) {
    showError("No se encontró la API Key de Groq. Ve a Opciones (⚙️) para configurarla.");
    return;
  }

  currentMode = "deferred";
  highlightActiveMode(btnDeferred);

  const tab = await getCurrentTab();
  if (!tab) {
    showError("No se pudo obtener la pestaña activa.");
    return;
  }

  chrome.runtime.sendMessage({
    type: "START_DEFERRED",
    tabId: tab.id
  });

  btnStop.disabled = false;
});

// --- Botón "Detener" ---
btnStop.addEventListener("click", () => {
  chrome.runtime.sendMessage({ type: "STOP_RECORDING" });
  btnStop.disabled = true;
});

// --- Botón "Resumir con Claude" ---
btnSummarize.addEventListener("click", async () => {
  const text = transcriptArea.value.trim();
  if (!text) {
    showError("No hay transcripción para resumir.");
    return;
  }

  // Verificar API key de Claude
  const settings = await chrome.storage.sync.get(["claudeApiKey"]);
  if (!settings.claudeApiKey) {
    showError("No se encontró la API Key de Claude. Ve a Opciones (⚙️) para configurarla.");
    return;
  }

  await summarizeWithClaude(text, settings.claudeApiKey);
});

// --- Botón "Copiar texto" ---
btnCopy.addEventListener("click", async () => {
  const text = transcriptArea.value;
  if (!text) return;

  try {
    await navigator.clipboard.writeText(text);
    btnCopy.textContent = "✅ Copiado!";
    setTimeout(() => {
      btnCopy.textContent = "📋 Copiar texto";
    }, 2000);
  } catch (e) {
    showError("No se pudo copiar al portapapeles.");
  }
});

// --- Botón "Limpiar" ---
btnClear.addEventListener("click", () => {
  fullTranscript = "";
  interimText = "";
  transcriptArea.value = "";
  summarySection.style.display = "none";
  summaryContent.textContent = "";
  hideError();
  btnSummarize.disabled = true;
  btnCopy.disabled = true;

  // Limpiar también del storage
  chrome.storage.local.remove("transcript");
});

// --- Link a opciones ---
openOptions.addEventListener("click", (e) => {
  e.preventDefault();
  chrome.runtime.openOptionsPage();
});

// ============================================================
// ESCUCHAR MENSAJES DEL SERVICE WORKER
// ============================================================
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.type) {
    case "TRANSCRIPT_UPDATE":
      handleTranscriptUpdate(message);
      break;

    case "STATUS_UPDATE":
      handleStatusUpdate(message);
      break;
  }
});

// ============================================================
// Manejar actualizaciones de transcripción
// ============================================================
function handleTranscriptUpdate(message) {
  hideError();

  if (message.isFinal) {
    // Texto final confirmado: agregarlo a la transcripción completa
    fullTranscript += (fullTranscript ? "\n" : "") + message.text;
    interimText = "";
  } else {
    // Texto parcial (aún puede cambiar)
    if (currentMode === "realtime") {
      interimText = message.text;
    } else {
      // En modo diferido, Groq envía actualizaciones parciales completas
      fullTranscript = message.text;
    }
  }

  // Mostrar en el textarea
  if (currentMode === "realtime" && interimText) {
    transcriptArea.value = fullTranscript + (fullTranscript ? "\n" : "") + "[..." + interimText + "...]";
  } else {
    transcriptArea.value = fullTranscript;
  }

  // Hacer scroll hacia abajo automáticamente
  transcriptArea.scrollTop = transcriptArea.scrollHeight;

  // Activar botones si hay texto
  if (fullTranscript.trim()) {
    btnSummarize.disabled = false;
    btnCopy.disabled = false;
  }
}

// ============================================================
// Manejar cambios de estado
// ============================================================
function handleStatusUpdate(message) {
  const { status, error, progress } = message;

  // Actualizar el badge de estado
  statusBadge.className = "badge";

  switch (status) {
    case "recording":
      statusBadge.classList.add("badge--recording");
      statusBadge.textContent = "Grabando...";
      statusDetail.textContent = currentMode === "realtime" ? "Modo tiempo real" : "Modo diferido";
      hideError();
      break;

    case "stopped":
      statusBadge.classList.add("badge--stopped");
      statusBadge.textContent = "Completado";
      statusDetail.textContent = "";
      btnStop.disabled = true;
      break;

    case "transcribing":
      statusBadge.classList.add("badge--transcribing");
      statusBadge.textContent = "Transcribiendo...";
      statusDetail.textContent = progress || "Enviando audio a Groq...";
      break;

    case "error":
      statusBadge.classList.add("badge--error");
      statusBadge.textContent = "Error";
      statusDetail.textContent = "";
      if (error) showError(error);
      btnStop.disabled = true;
      break;

    default:
      statusBadge.classList.add("badge--idle");
      statusBadge.textContent = "Listo";
      statusDetail.textContent = "";
  }
}

// ============================================================
// Resumir con Claude API
// ============================================================
async function summarizeWithClaude(transcript, apiKey) {
  // Mostrar sección de resumen con estado de carga
  summarySection.style.display = "block";
  summaryContent.textContent = "Generando resumen...";
  btnSummarize.disabled = true;

  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "anthropic-dangerous-direct-browser-access": "true"
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        system: "Eres un asistente que genera resúmenes concisos y estructurados de transcripciones de videos y cursos online en español.",
        messages: [
          {
            role: "user",
            content: `Resume esta transcripción en puntos clave:\n\n${transcript}`
          }
        ]
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new Error(`Claude API error (${response.status}): ${errorData}`);
    }

    const data = await response.json();

    // Extraer el texto de la respuesta de Claude
    const summaryText = data.content
      .filter(block => block.type === "text")
      .map(block => block.text)
      .join("\n");

    summaryContent.textContent = summaryText;

  } catch (error) {
    console.error("Error al resumir con Claude:", error);
    summaryContent.textContent = "Error al generar el resumen: " + error.message;
    showError("Error al conectar con Claude API: " + error.message);
  } finally {
    btnSummarize.disabled = false;
  }
}

// ============================================================
// UTILIDADES
// ============================================================

// Obtener la pestaña activa actual
async function getCurrentTab() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  return tab;
}

// Resaltar el botón de modo activo
function highlightActiveMode(activeBtn) {
  btnRealtime.classList.remove("mode-btn--active");
  btnDeferred.classList.remove("mode-btn--active");
  activeBtn.classList.add("mode-btn--active");
}

// Mostrar error
function showError(message) {
  errorBanner.textContent = message;
  errorBanner.style.display = "block";
}

// Ocultar error
function hideError() {
  errorBanner.style.display = "none";
  errorBanner.textContent = "";
}

// ============================================================
// AL CARGAR: recuperar transcripción guardada (si existe)
// ============================================================
(async function init() {
  const data = await chrome.storage.local.get(["transcript"]);
  if (data.transcript) {
    fullTranscript = data.transcript;
    transcriptArea.value = fullTranscript;
    btnSummarize.disabled = false;
    btnCopy.disabled = false;
  }
})();
