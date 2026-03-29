// ============================================================
// WhisperTab - Service Worker (el "cerebro" de la extensión)
// ============================================================
// Este archivo se ejecuta en segundo plano y coordina todo:
// - Captura el audio de la pestaña activa
// - Graba el audio en modo diferido
// - Envía los fragmentos de audio a Groq para transcripción
// - Comunica el estado al Side Panel
// ============================================================

// --- Estado global ---
let mediaStream = null;       // El stream de audio capturado
let mediaRecorder = null;     // El grabador de audio (modo diferido)
let audioChunks = [];         // Los fragmentos de audio grabados
let currentMode = null;       // "realtime" o "deferred"
let isRecording = false;      // ¿Está grabando ahora mismo?

// --- Al hacer clic en el icono de la extensión, abrir el Side Panel ---
chrome.action.onClicked.addListener((tab) => {
  chrome.sidePanel.open({ tabId: tab.id });
});

// --- Escuchar mensajes del Side Panel y del Content Script ---
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.type) {
    case "START_REALTIME":
      startRealtimeMode(message.tabId);
      sendResponse({ ok: true });
      break;

    case "START_DEFERRED":
      startDeferredMode(message.tabId);
      sendResponse({ ok: true });
      break;

    case "STOP_RECORDING":
      stopRecording();
      sendResponse({ ok: true });
      break;

    default:
      break;
  }
  // Devolver true permite respuestas asíncronas
  return true;
});

// ============================================================
// MODO TIEMPO REAL
// ============================================================
// Captura el audio de la pestaña y lo envía al content script
// para que use Web Speech API (SpeechRecognition).
// ============================================================
async function startRealtimeMode(tabId) {
  try {
    currentMode = "realtime";
    isRecording = true;

    // Informar al side panel que estamos grabando
    broadcastMessage({ type: "STATUS_UPDATE", status: "recording" });

    // Inyectar la orden al content script para que active SpeechRecognition
    chrome.tabs.sendMessage(tabId, { type: "ACTIVATE_SPEECH_RECOGNITION" });

  } catch (error) {
    console.error("Error en modo tiempo real:", error);
    broadcastMessage({
      type: "STATUS_UPDATE",
      status: "error",
      error: "No se pudo iniciar el modo tiempo real: " + error.message
    });
  }
}

// ============================================================
// MODO DIFERIDO (Groq Whisper)
// ============================================================
// 1. Captura el audio de la pestaña con tabCapture
// 2. Graba con MediaRecorder en fragmentos de 30 segundos
// 3. Al detener, envía cada fragmento a Groq para transcribir
// ============================================================
async function startDeferredMode(tabId) {
  try {
    currentMode = "deferred";
    isRecording = true;
    audioChunks = [];

    // Informar al side panel
    broadcastMessage({ type: "STATUS_UPDATE", status: "recording" });

    // Capturar el audio de la pestaña activa
    // chrome.tabCapture.getMediaStreamId nos da un ID que podemos usar
    const streamId = await new Promise((resolve, reject) => {
      chrome.tabCapture.getMediaStreamId({ targetTabId: tabId }, (id) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
        } else {
          resolve(id);
        }
      });
    });

    // Crear un offscreen document para manejar el MediaRecorder
    // (Los service workers de MV3 no pueden usar MediaRecorder directamente)
    await setupOffscreenRecording(streamId, tabId);

  } catch (error) {
    console.error("Error en modo diferido:", error);
    isRecording = false;
    broadcastMessage({
      type: "STATUS_UPDATE",
      status: "error",
      error: "No se pudo iniciar la grabación: " + error.message
    });
  }
}

// ============================================================
// Offscreen Document para grabación
// ============================================================
// Los service workers de Manifest V3 NO pueden usar MediaRecorder
// ni getUserMedia. Necesitamos un "offscreen document" que sí puede.
// ============================================================
async function setupOffscreenRecording(streamId, tabId) {
  // Verificar si ya existe un offscreen document
  const existingContexts = await chrome.runtime.getContexts({
    contextTypes: ["OFFSCREEN_DOCUMENT"]
  });

  if (existingContexts.length === 0) {
    // Crear el offscreen document
    await chrome.offscreen.createDocument({
      url: "offscreen/offscreen.html",
      reasons: ["USER_MEDIA"],
      justification: "Grabar audio de la pestaña para transcripción"
    });
  }

  // Enviar mensaje al offscreen document para que empiece a grabar
  chrome.runtime.sendMessage({
    type: "OFFSCREEN_START_RECORDING",
    streamId: streamId,
    tabId: tabId
  });
}

// ============================================================
// Detener grabación
// ============================================================
async function stopRecording() {
  if (!isRecording) return;

  isRecording = false;

  if (currentMode === "realtime") {
    // En modo tiempo real, detener el SpeechRecognition
    // Enviamos mensaje a todas las pestañas
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tabs[0]) {
      chrome.tabs.sendMessage(tabs[0].id, { type: "STOP_SPEECH_RECOGNITION" });
    }
    broadcastMessage({ type: "STATUS_UPDATE", status: "stopped" });

  } else if (currentMode === "deferred") {
    // Enviar mensaje al offscreen document para que detenga la grabación
    chrome.runtime.sendMessage({ type: "OFFSCREEN_STOP_RECORDING" });
    // El offscreen document enviará los chunks de vuelta
  }

  currentMode = null;
}

// ============================================================
// Recibir chunks de audio del offscreen document y transcribir
// ============================================================
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "AUDIO_CHUNKS_READY") {
    // Los chunks llegan como arrays de bytes
    transcribeWithGroq(message.chunks);
    sendResponse({ ok: true });
    return true;
  }

  if (message.type === "TRANSCRIPT_FROM_CONTENT") {
    // Transcripción del modo tiempo real (desde el content script)
    broadcastMessage({
      type: "TRANSCRIPT_UPDATE",
      text: message.text,
      isFinal: message.isFinal
    });
    sendResponse({ ok: true });
    return true;
  }

  if (message.type === "OFFSCREEN_RECORDING_ERROR") {
    broadcastMessage({
      type: "STATUS_UPDATE",
      status: "error",
      error: message.error
    });
    sendResponse({ ok: true });
    return true;
  }
});

// ============================================================
// Transcribir audio con Groq API (Whisper)
// ============================================================
async function transcribeWithGroq(chunksData) {
  // Cambiar estado a "transcribiendo"
  broadcastMessage({ type: "STATUS_UPDATE", status: "transcribing" });

  // Obtener la API key de las opciones guardadas
  const settings = await chrome.storage.sync.get(["groqApiKey", "transcriptionLanguage"]);

  if (!settings.groqApiKey) {
    broadcastMessage({
      type: "STATUS_UPDATE",
      status: "error",
      error: "No se encontró la API Key de Groq. Ve a Opciones para configurarla."
    });
    return;
  }

  let fullTranscript = "";

  // Procesar cada fragmento de audio
  for (let i = 0; i < chunksData.length; i++) {
    try {
      broadcastMessage({
        type: "STATUS_UPDATE",
        status: "transcribing",
        progress: `Transcribiendo fragmento ${i + 1} de ${chunksData.length}...`
      });

      // Convertir el array de bytes de vuelta a un Blob
      const audioBlob = new Blob(
        [new Uint8Array(chunksData[i])],
        { type: "audio/webm;codecs=opus" }
      );

      // Crear un File a partir del Blob (Groq necesita un File, no un Blob)
      const audioFile = new File([audioBlob], `audio_chunk_${i}.webm`, {
        type: "audio/webm;codecs=opus"
      });

      // Preparar el FormData para enviar a Groq
      const formData = new FormData();
      formData.append("file", audioFile);
      formData.append("model", "whisper-large-v3");

      // Agregar idioma si no es "auto"
      if (settings.transcriptionLanguage && settings.transcriptionLanguage !== "auto") {
        formData.append("language", settings.transcriptionLanguage);
      }

      // Enviar a Groq API
      const response = await fetch(
        "https://api.groq.com/openai/v1/audio/transcriptions",
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${settings.groqApiKey}`
          },
          body: formData
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Groq API error (${response.status}): ${errorText}`);
      }

      const result = await response.json();
      fullTranscript += result.text + " ";

      // Enviar actualización parcial al side panel
      broadcastMessage({
        type: "TRANSCRIPT_UPDATE",
        text: fullTranscript.trim(),
        isFinal: false
      });

    } catch (error) {
      console.error(`Error transcribiendo fragmento ${i}:`, error);
      broadcastMessage({
        type: "STATUS_UPDATE",
        status: "error",
        error: `Error en fragmento ${i + 1}: ${error.message}`
      });
    }
  }

  // Guardar la transcripción completa en storage
  await chrome.storage.local.set({ transcript: fullTranscript.trim() });

  // Enviar la transcripción final
  broadcastMessage({
    type: "TRANSCRIPT_UPDATE",
    text: fullTranscript.trim(),
    isFinal: true
  });

  broadcastMessage({ type: "STATUS_UPDATE", status: "stopped" });

  // Cerrar el offscreen document
  try {
    await chrome.offscreen.closeDocument();
  } catch (e) {
    // Puede que ya esté cerrado
  }
}

// ============================================================
// Utilidad: enviar mensaje a todas las partes de la extensión
// ============================================================
function broadcastMessage(message) {
  chrome.runtime.sendMessage(message).catch(() => {
    // Es normal que falle si el side panel no está abierto
  });
}
