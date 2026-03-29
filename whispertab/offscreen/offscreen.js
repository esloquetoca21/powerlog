// ============================================================
// WhisperTab - Offscreen Document
// ============================================================
// Este archivo maneja la grabación de audio real porque el
// service worker de MV3 no puede usar MediaRecorder.
// Recibe órdenes del service worker y devuelve los chunks.
// ============================================================

let mediaRecorder = null;
let audioChunks = [];
let mediaStream = null;

// Escuchar mensajes del service worker
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "OFFSCREEN_START_RECORDING") {
    startRecording(message.streamId, message.tabId);
    sendResponse({ ok: true });
    return true;
  }

  if (message.type === "OFFSCREEN_STOP_RECORDING") {
    stopRecording();
    sendResponse({ ok: true });
    return true;
  }
});

// ============================================================
// Iniciar la grabación de audio
// ============================================================
async function startRecording(streamId, tabId) {
  try {
    // Obtener el stream de audio usando el ID que nos dio tabCapture
    mediaStream = await navigator.mediaDevices.getUserMedia({
      audio: {
        mandatory: {
          chromeMediaSource: "tab",
          chromeMediaSourceId: streamId
        }
      }
    });

    audioChunks = [];

    // Crear el MediaRecorder con formato WebM/Opus
    mediaRecorder = new MediaRecorder(mediaStream, {
      mimeType: "audio/webm;codecs=opus"
    });

    // Cada 30 segundos, guardar un fragmento de audio
    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) {
        audioChunks.push(event.data);
      }
    };

    // Cuando se detiene la grabación, enviar los chunks al service worker
    mediaRecorder.onstop = async () => {
      // Convertir cada Blob a un array de bytes para poder enviarlo
      // (Los mensajes de Chrome no pueden enviar Blobs directamente)
      const chunksAsArrays = [];

      for (const chunk of audioChunks) {
        const buffer = await chunk.arrayBuffer();
        chunksAsArrays.push(Array.from(new Uint8Array(buffer)));
      }

      // Enviar los chunks al service worker
      chrome.runtime.sendMessage({
        type: "AUDIO_CHUNKS_READY",
        chunks: chunksAsArrays
      });

      // Limpiar
      cleanup();
    };

    mediaRecorder.onerror = (event) => {
      console.error("Error en MediaRecorder:", event.error);
      chrome.runtime.sendMessage({
        type: "OFFSCREEN_RECORDING_ERROR",
        error: "Error durante la grabación: " + event.error.message
      });
      cleanup();
    };

    // Iniciar grabación con fragmentos cada 30 segundos
    mediaRecorder.start(30000);

  } catch (error) {
    console.error("Error al iniciar grabación offscreen:", error);
    chrome.runtime.sendMessage({
      type: "OFFSCREEN_RECORDING_ERROR",
      error: "No se pudo acceder al audio de la pestaña: " + error.message
    });
  }
}

// ============================================================
// Detener la grabación
// ============================================================
function stopRecording() {
  if (mediaRecorder && mediaRecorder.state !== "inactive") {
    mediaRecorder.stop();
  }
}

// ============================================================
// Limpiar recursos
// ============================================================
function cleanup() {
  if (mediaStream) {
    mediaStream.getTracks().forEach(track => track.stop());
    mediaStream = null;
  }
  mediaRecorder = null;
  audioChunks = [];
}
