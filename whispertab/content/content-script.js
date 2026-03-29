// ============================================================
// WhisperTab - Content Script
// ============================================================
// Este archivo se inyecta en cada página web que visitas.
// Su trabajo es activar el reconocimiento de voz (Web Speech API)
// cuando el service worker se lo pide (modo tiempo real).
// ============================================================

let recognition = null;
let isListening = false;

// Escuchar mensajes del service worker
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "ACTIVATE_SPEECH_RECOGNITION") {
    startSpeechRecognition();
    sendResponse({ ok: true });
    return true;
  }

  if (message.type === "STOP_SPEECH_RECOGNITION") {
    stopSpeechRecognition();
    sendResponse({ ok: true });
    return true;
  }
});

// ============================================================
// Iniciar reconocimiento de voz con Web Speech API
// ============================================================
function startSpeechRecognition() {
  // Verificar si el navegador soporta Web Speech API
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

  if (!SpeechRecognition) {
    chrome.runtime.sendMessage({
      type: "TRANSCRIPT_FROM_CONTENT",
      text: "[Error: Tu navegador no soporta Web Speech API]",
      isFinal: true
    });
    return;
  }

  // Si ya estamos escuchando, no hacer nada
  if (isListening && recognition) {
    return;
  }

  // Crear una nueva instancia de SpeechRecognition
  recognition = new SpeechRecognition();

  // Configuración:
  // - continuous: true = no para de escuchar después de una frase
  // - interimResults: true = muestra texto mientras hablas (no solo al final)
  // - lang: idioma de reconocimiento
  recognition.continuous = true;
  recognition.interimResults = true;

  // Obtener el idioma configurado
  chrome.storage.sync.get(["transcriptionLanguage"], (settings) => {
    const lang = settings.transcriptionLanguage || "es";
    if (lang === "auto") {
      // Si es auto, no establecer idioma y dejar que el navegador decida
      recognition.lang = "";
    } else if (lang === "es") {
      recognition.lang = "es-ES";
    } else if (lang === "en") {
      recognition.lang = "en-US";
    } else {
      recognition.lang = lang;
    }
  });

  // Cuando llegan resultados de reconocimiento
  recognition.onresult = (event) => {
    let interimTranscript = "";
    let finalTranscript = "";

    // Recorrer todos los resultados
    for (let i = event.resultIndex; i < event.results.length; i++) {
      const transcript = event.results[i][0].transcript;

      if (event.results[i].isFinal) {
        finalTranscript += transcript + " ";
      } else {
        interimTranscript += transcript;
      }
    }

    // Enviar al service worker (y de ahí al side panel)
    if (finalTranscript) {
      chrome.runtime.sendMessage({
        type: "TRANSCRIPT_FROM_CONTENT",
        text: finalTranscript.trim(),
        isFinal: true
      });
    }

    if (interimTranscript) {
      chrome.runtime.sendMessage({
        type: "TRANSCRIPT_FROM_CONTENT",
        text: interimTranscript,
        isFinal: false
      });
    }
  };

  // Si el reconocimiento se detiene solo, reiniciarlo (modo continuo)
  recognition.onend = () => {
    if (isListening) {
      // Reiniciar automáticamente si seguimos en modo escucha
      try {
        recognition.start();
      } catch (e) {
        console.log("WhisperTab: No se pudo reiniciar el reconocimiento:", e);
      }
    }
  };

  recognition.onerror = (event) => {
    console.error("WhisperTab Speech Recognition error:", event.error);

    // No reportar errores de "aborted" porque son normales al detener
    if (event.error !== "aborted") {
      chrome.runtime.sendMessage({
        type: "TRANSCRIPT_FROM_CONTENT",
        text: `[Error de reconocimiento: ${event.error}]`,
        isFinal: true
      });
    }
  };

  // ¡Empezar a escuchar!
  try {
    recognition.start();
    isListening = true;
  } catch (e) {
    console.error("WhisperTab: Error al iniciar reconocimiento:", e);
  }
}

// ============================================================
// Detener reconocimiento de voz
// ============================================================
function stopSpeechRecognition() {
  isListening = false;
  if (recognition) {
    try {
      recognition.stop();
    } catch (e) {
      // Puede que ya esté detenido
    }
    recognition = null;
  }
}
