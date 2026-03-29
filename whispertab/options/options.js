// ============================================================
// WhisperTab - Página de Opciones
// ============================================================
// Aquí el usuario configura sus API Keys y preferencias.
// Los datos se guardan con chrome.storage.sync (se sincroniza
// entre dispositivos si el usuario tiene Chrome con cuenta).
// ============================================================

// --- Referencias a los elementos del formulario ---
const form = document.getElementById("options-form");
const groqKeyInput = document.getElementById("groq-key");
const claudeKeyInput = document.getElementById("claude-key");
const languageSelect = document.getElementById("language");
const statusMessage = document.getElementById("status-message");

// ============================================================
// AL CARGAR LA PÁGINA: rellenar los campos con valores guardados
// ============================================================
document.addEventListener("DOMContentLoaded", async () => {
  // Leer los valores guardados del almacenamiento de Chrome
  const settings = await chrome.storage.sync.get([
    "groqApiKey",
    "claudeApiKey",
    "transcriptionLanguage"
  ]);

  // Si hay valores guardados, ponerlos en los campos
  if (settings.groqApiKey) {
    groqKeyInput.value = settings.groqApiKey;
  }

  if (settings.claudeApiKey) {
    claudeKeyInput.value = settings.claudeApiKey;
  }

  if (settings.transcriptionLanguage) {
    languageSelect.value = settings.transcriptionLanguage;
  }
});

// ============================================================
// AL ENVIAR EL FORMULARIO: guardar los valores
// ============================================================
form.addEventListener("submit", async (event) => {
  // Evitar que el formulario recargue la página
  event.preventDefault();

  // Obtener los valores de los campos
  const groqKey = groqKeyInput.value.trim();
  const claudeKey = claudeKeyInput.value.trim();
  const language = languageSelect.value;

  // Guardar en chrome.storage.sync
  try {
    await chrome.storage.sync.set({
      groqApiKey: groqKey,
      claudeApiKey: claudeKey,
      transcriptionLanguage: language
    });

    // Mostrar mensaje de éxito
    showMessage("✅ Configuración guardada correctamente.", "success");

  } catch (error) {
    // Mostrar mensaje de error
    showMessage("❌ Error al guardar: " + error.message, "error");
  }
});

// ============================================================
// Mostrar mensaje de estado
// ============================================================
function showMessage(text, type) {
  statusMessage.textContent = text;
  statusMessage.className = "message";

  if (type === "success") {
    statusMessage.classList.add("message--success");
  } else {
    statusMessage.classList.add("message--error");
  }

  // Ocultar el mensaje después de 3 segundos
  setTimeout(() => {
    statusMessage.style.display = "none";
    statusMessage.className = "message";
  }, 3000);
}
