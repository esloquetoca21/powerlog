# PowerLog — Guía para Claude

App móvil de registro de entrenamiento para powerlifting. Primera app del sector en español con IA integrada y gestión profesional entrenador-atleta.

Referencia completa: `docs/PRD.md`

---

## Stack tecnológico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| App móvil | Flutter + Dart | SDK ≥ 3.0.0 |
| Base de datos | Firebase Firestore | cloud_firestore ^5.2.1 |
| Autenticación | Firebase Auth + Google Sign-In | firebase_auth ^5.1.4, google_sign_in ^6.2.1 |
| IA generativa | Anthropic API | claude-sonnet-4-6 |
| Estado | Provider | ^6.1.2 |
| HTTP | http (para Anthropic) | ^1.2.2 |
| UI | google_fonts, intl | — |
| IDs únicos | uuid | ^4.4.2 |

### Colecciones Firestore
```
users        → perfil de usuario y rol (athlete / coach)
sessions     → sesiones de entrenamiento completadas
sets         → series individuales (subcolección de sessions)
plans        → planes de entrenamiento (manual, IA o del entrenador)
messages     → mensajes del chat entrenador-atleta
```

Regla fija: **siempre incluir campo `timestamp`** en cualquier documento escrito en Firestore.

---

## Estructura de carpetas

```
lib/
  main.dart                          # Entry point. MultiProvider con AuthService y SessionService.
  firebase_options.dart              # Generado por flutterfire configure. No editar a mano.

  models/
    user_model.dart                  # UserModel — rol, peso corporal, federación, fecha de competición
    session_model.dart               # SessionModel — sesión completa con ejercicios y métricas
    set_model.dart                   # SetModel — serie individual con 1RM (Epley, Brzycki)
    exercise_model.dart              # ExerciseModel — ejercicio con lista de SetModel
    calculators.dart                 # Epley, Brzycki, Lombardi, Wilks 2020, DOTS IPF, intentos meet

  services/
    auth_service.dart                # ChangeNotifier — Firebase Auth: signUp, signIn, signOut
    session_service.dart             # ChangeNotifier — CRUD de sesiones en Firestore
    ai_service.dart                  # Anthropic API — analyzeSession, getCoachAdvice, generatePlan

  screens/
    splash_screen.dart               # ✅ Animación de entrada + redirect según auth state

    auth/
      login_screen.dart              # ✅ Login con email/contraseña
      register_screen.dart           # ✅ Registro de nueva cuenta

    home/
      home_screen.dart               # ✅ Lista de sesiones recientes + FAB nueva sesión

    workout/
      new_session_screen.dart        # ✅ Nombre de sesión + plantillas rápidas
      active_session_screen.dart     # ✅ Registro en tiempo real: ejercicios, series, temporizador

  widgets/
    primary_button.dart              # Botón primario rojo con estado de carga
    custom_text_field.dart           # TextField con estilo oscuro y validación
    session_card.dart                # Tarjeta de sesión en el historial
    exercise_card.dart               # Tarjeta de ejercicio con series inline editables
    add_exercise_sheet.dart          # Bottom sheet: búsqueda y selección de ejercicio

docs/
  PRD.md                             # Product Requirements Document completo
```

---

## Convenciones de código

### Idioma
- **UI (strings visibles al usuario):** español
- **Código (variables, funciones, clases, comentarios técnicos):** inglés

### Modelos
- Todos los modelos tienen `fromMap` / `toMap` para Firestore.
- Todo documento en Firestore incluye `timestamp: DateTime.toIso8601String()`.
- `copyWith` en todos los modelos mutables.
- Sin `equatable` ni dependencias externas en modelos; igualdad manual si se necesita.

### Estado
- Un `ChangeNotifier` por dominio: `AuthService`, `SessionService`.
- Los servicios se proveen en `main.dart` con `MultiProvider`.
- Las pantallas consumen el estado con `context.watch<T>()` y disparan acciones con `context.read<T>()`.

### Firestore
- Colecciones en minúsculas y plural: `users`, `sessions`, `sets`, `plans`, `messages`.
- Siempre incluir `timestamp` en cada escritura.
- Ordenar por `timestamp` descendente al leer listas.

### IA (Anthropic)
- Modelo fijo: `claude-sonnet-4-6`.
- La clave API vive en `ai_service.dart` como constante `_apiKey`.
  **Antes de producción**, moverla a variables de entorno o Firebase Remote Config.
- Las llamadas a IA solo se realizan al finalizar una sesión (plan Pro) para controlar costes.
- Prompts siempre en español; respuestas máximo 512 tokens.

### Tema visual
- Fondo: `#0D0D0D` / superficies: `#1A1A1A`
- Accent: `#E53935` (rojo powerlifting)
- Texto principal: blanco / secundario: `Colors.white.withOpacity(0.4–0.5)`
- Bordes sutiles: `Colors.white.withOpacity(0.06–0.07)`
- Material 3 habilitado con `useMaterial3: true`

### Nomenclatura de archivos
- `snake_case` para archivos: `session_model.dart`, `auth_service.dart`
- `PascalCase` para clases: `SessionModel`, `AuthService`
- Sufijos obligatorios: `_screen.dart`, `_service.dart`, `_model.dart`, `_widget.dart` (solo si es widget genérico)

---

## Pantallas — estado actual

### Flujo de entrada
| Pantalla | Archivo | Estado |
|----------|---------|--------|
| Splash | `screens/splash_screen.dart` | ✅ Hecha |
| Login | `screens/auth/login_screen.dart` | ✅ Hecha (email+pass, Google, olvidé contraseña) |
| Registro | `screens/auth/register_screen.dart` | ✅ Hecha (email+pass, confirmar, Google) |
| Perfil inicial (onboarding) | `screens/auth/onboarding_screen.dart` | ✅ Hecha |
| Selección de rol | `screens/auth/role_selection_screen.dart` | ✅ Hecha |

### Flujo del atleta
| Pantalla | Archivo | Estado |
|----------|---------|--------|
| Home / lista de sesiones | `screens/home/home_screen.dart` | ✅ Hecha |
| Nueva sesión | `screens/workout/new_session_screen.dart` | ✅ Hecha |
| Sesión activa | `screens/workout/active_session_screen.dart` | ✅ Hecha |
| Dashboard (próx. sesión, racha, semana) | `screens/home/dashboard_screen.dart` | ⬜ Pendiente |
| Análisis post-sesión + IA | `screens/workout/session_detail_screen.dart` | ⬜ Pendiente |
| Progreso (gráficas, récords, Wilks, DOTS) | `screens/progress/progress_screen.dart` | ⬜ Pendiente |
| Mi plan / Calendario (semanal + macrociclo) | `screens/plan/calendar_screen.dart` | ⬜ Pendiente |
| Crear / editar plan (manual, IA, entrenador) | `screens/plan/plan_builder_screen.dart` | ⬜ Pendiente |
| Perfil y configuración | `screens/profile/profile_screen.dart` | ⬜ Pendiente |

### Flujo del entrenador
| Pantalla | Archivo | Estado |
|----------|---------|--------|
| Panel de atletas | `screens/coach/coach_dashboard_screen.dart` | ⬜ Pendiente |
| Ficha de atleta | `screens/coach/athlete_detail_screen.dart` | ⬜ Pendiente |
| Constructor de macrociclos | `screens/coach/plan_builder_screen.dart` | ⬜ Pendiente |
| Chat entrenador-atleta | `screens/coach/chat_screen.dart` | ⬜ Pendiente |

### Módulos transversales
| Pantalla | Archivo | Estado |
|----------|---------|--------|
| Herramientas (1RM, Wilks, DOTS, intentos) | `screens/tools/calculators_screen.dart` | ⬜ Pendiente |
| Día de meet (planificación de intentos) | `screens/tools/meet_day_screen.dart` | ⬜ Pendiente |
| Ajustes (cuenta, notificaciones, kg/lb) | `screens/settings/settings_screen.dart` | ⬜ Pendiente |

---

## Roadmap de desarrollo (PRD sección 8)

| Fase | Entregables clave |
|------|------------------|
| **MVP** (sem. 1–2) | Autenticación, registro de sesiones, perfil, cálculos 1RM/Wilks/DOTS |
| **Planificación** (sem. 3–4) | Plan manual + IA, calendario semanal, sincronización iCal |
| **Entrenador** (sem. 5–6) | Panel de atletas, chat, análisis post-sesión con IA |
| **Pulido** (sem. 7–8) | Tests, correcciones, App Store + Google Play |
| **Crecimiento** (mes 4–6) | Wearables, más federaciones, modelo de suscripción |

---

## Configuración Firebase (pasos pendientes)

```bash
# 1. Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Configurar con tu proyecto Firebase
flutterfire configure

# 3. Habilitar en Firebase Console:
#    - Authentication → Email/contraseña (+ Google, Apple)
#    - Firestore Database → modo producción
#    - Cloud Messaging (fase entrenador)
```

El archivo `lib/firebase_options.dart` contiene valores placeholder. Ejecutar `flutterfire configure` para reemplazarlos con las credenciales reales del proyecto.
