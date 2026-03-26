[PRD.md](https://github.com/user-attachments/files/26287812/PRD.md)
[PRD.md](https://github.com/user-attachments/files/26287812/PRD.md)
# PowerLog — Product Requirements Document

**Versión:** 1.0  
**Fecha:** Marzo 2026  
**Estado:** En definición  
**Plataformas:** iOS y Android (Flutter)  
**Backend:** Firebase + Anthropic API  

---

## 1. Resumen ejecutivo

PowerLog es una aplicación móvil nativa para iOS y Android orientada al registro inteligente de entrenamientos de powerlifting. A diferencia de las apps genéricas de fitness, PowerLog está construida desde cero para las necesidades específicas de este deporte: los tres levantamientos fundamentales (sentadilla, press banca y peso muerto), los cálculos de rendimiento propios del powerlifting (1RM, Wilks, DOTS), la planificación periodizada por bloques y la relación entrenador-atleta.

El mercado de apps de powerlifting en España y Latinoamérica está desatendido. Las soluciones existentes (StrengthLog, Juggernaut AI, Strong) son en inglés, no contemplan federaciones locales y carecen de herramientas para entrenadores. PowerLog cubre este hueco con una propuesta de valor clara: la primera app de powerlifting en español con IA integrada y gestión profesional de atletas.

---

## 2. Problema que resuelve

### Para el atleta
- Las apps genéricas de fitness no entienden la lógica del powerlifting (bloques, RPE, peaking)
- No existen cálculos automáticos de métricas clave como Wilks o DOTS en apps en español
- Es difícil visualizar el progreso en los tres levantamientos y planificar hacia una competición
- No hay herramientas que integren el calendario de entrenamiento con el calendario del móvil

### Para el entrenador
- Gestionar múltiples atletas requiere hojas de cálculo y chats de WhatsApp mezclados
- No existe una herramienta profesional para asignar planes, hacer seguimiento y dar feedback centralizado
- La comunicación con atletas es dispersa y sin contexto del entrenamiento

---

## 3. Solución propuesta

| Módulo | Descripción |
|--------|-------------|
| Registro | Registro de sesiones con series, kg, reps y RPE. Cálculo automático de 1RM, Wilks y DOTS en tiempo real. |
| Planificación | Tres modos: manual, asignado por entrenador o generado por IA (Sheiko, 5/3/1, GZCLP). Bloques de acumulación, intensificación, peaking y descarga. |
| Calendario | Vista semanal y de macrociclo. Reprogramación por arrastre. Sincronización con Google Calendar, Apple Calendar y Outlook vía iCal. |
| Análisis IA | Análisis post-sesión: tonelaje, RPE medio, comparativa con sesión anterior e intensidad respecto al 1RM. Resumen inteligente generado por IA. |
| Entrenador | Panel de gestión de múltiples atletas, asignación de planes, chat integrado y visualización del progreso individual. |

---

## 4. Usuarios objetivo

| Perfil | Necesidad principal | Funcionalidad clave |
|--------|--------------------|--------------------|
| Principiante | Aprender a registrar y progresar con estructura | Plan IA + cálculo automático de cargas |
| Atleta intermedio | Seguimiento riguroso del progreso y planificación | Calendario, gráficas, análisis post-sesión |
| Competidor federado | Peaking hacia competición y métricas oficiales | Wilks/DOTS, planificación de intentos, federaciones ES |
| Entrenador | Gestionar atletas de forma profesional y centralizada | Panel de atletas, asignación de planes, chat |

---

## 5. Funcionalidades detalladas

### 5.1 Registro de sesiones
- Registro de series con kg, repeticiones y RPE (escala 1–10, paso 0.5)
- Cálculo en tiempo real de 1RM estimado (fórmula de Epley)
- Temporizador de descanso configurable entre series
- Historial completo de sesiones por ejercicio y por fecha
- Notas libres por serie o por sesión

### 5.2 Planificación
- **Modo libre:** el atleta construye su programa manualmente
- **Modo entrenador:** el entrenador diseña y publica el plan en el calendario del atleta
- **Modo IA:** generación automática basada en Sheiko, 5/3/1, Texas Method o GZCLP
- Bloques estructurados: acumulación → intensificación → peaking → descarga
- Ajuste automático de carga según RPE real reportado (autorregulación)
- Semanas de descarga automáticas cada N semanas
- Planificación orientada a fecha de competición objetivo

### 5.3 Calendario
- Vista semanal y vista completa del macrociclo
- Reprogramación por arrastre con historial de cambios
- Alerta si dos sesiones intensas quedan en días consecutivos
- Sincronización vía URL iCal con Google Calendar, Apple Calendar y Outlook
- Cada evento incluye: nombre, duración estimada, ejercicios del día y enlace a la app

### 5.4 Análisis post-sesión
- Tonelaje total (kg × reps)
- RPE medio ponderado de todos los levantamientos
- Comparativa porcentual con la sesión equivalente anterior
- Intensidad media respecto al 1RM actual (% de carga)
- Resumen inteligente con recomendaciones para la próxima sesión (Anthropic API)

### 5.5 Herramientas y calculadoras
- Calculadora de 1RM (Epley, Brzycki, Lombardi)
- Calculadora Wilks y DOTS con coeficientes vigentes
- Calculadora de intentos para competición (apertura, segundo y tercero)
- Gestor del peso corporal y categoría de la federación
- Soporte para federaciones españolas (FEPE, IPF España) y categorías oficiales

### 5.6 Módulo de entrenador
- Panel con vista de todos los atletas y estado de su entrenamiento
- Alertas de fatiga acumulada o sesiones saltadas
- Ficha individual: progreso, plan activo, historial
- Constructor de macrociclos para asignar a uno o varios atletas
- Chat integrado con contexto del entrenamiento (adjuntar análisis de sesión)

---

## 6. Mapa de pantallas

### Flujo de entrada
1. Splash y bienvenida
2. Registro / login (email, Google, Apple)
3. Perfil inicial: nombre, peso, categoría, federación, nivel, fecha de competición
4. Selección de rol: atleta o entrenador

### Navegación del atleta
- **Dashboard:** próxima sesión, racha semanal, resumen de la semana
- **Mi plan / Calendario:** vista semanal y macrociclo, reprogramación
- **Sesión activa:** registro en tiempo real con temporizador
- **Análisis post-sesión:** métricas y resumen IA
- **Progreso:** gráficas por levantamiento, récords, 1RM, Wilks, DOTS
- **Crear / editar plan:** manual, IA o recibido del entrenador
- **Perfil y configuración:** datos, historial de competiciones, ajustes

### Navegación del entrenador
- **Panel de atletas:** lista con estado, alertas y acceso rápido
- **Ficha de atleta:** progreso, plan, sesiones, notas
- **Crear plan:** constructor de macrociclos
- **Mensajes:** chat con contexto del entrenamiento

### Módulos transversales
- **Herramientas:** calculadoras de 1RM, Wilks, DOTS y % de carga
- **Día de meet:** planificación de intentos y totales en tiempo real
- **Ajustes:** cuenta, notificaciones, sincronización, unidades (kg/lb)

---

## 7. Stack tecnológico

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| App móvil | Flutter (Dart) | Una base de código para iOS y Android. Rendimiento nativo. |
| Base de datos | Firebase Firestore | Sincronización en tiempo real. Escalable sin infraestructura propia. |
| Autenticación | Firebase Auth | Login con email, Google y Apple ID. |
| IA generativa | Anthropic API (Claude Sonnet 4.6) | Generación de planes, análisis de sesiones y feedback. |
| Notificaciones | Firebase Cloud Messaging | Recordatorios y alertas del entrenador. |
| Calendario | iCal / Google Calendar API | Exportación de sesiones al calendario nativo del móvil. |

### Estructura de carpetas
```
lib/
  screens/       → pantallas de la app
  widgets/       → componentes reutilizables
  services/      → lógica de Firebase y Anthropic API
  models/        → modelos de datos
docs/
  PRD.md         → este documento
```

### Convenciones de código
- Español en la UI, inglés en el código
- Provider para gestión de estado
- Guardar siempre `timestamp` en Firestore
- Nombres de colecciones en Firestore: `users`, `sessions`, `sets`, `plans`, `messages`

---

## 8. Roadmap de desarrollo

| Fase | Período | Entregables |
|------|---------|-------------|
| MVP | Semana 1–2 | Registro de sesiones, perfil, cálculos 1RM/Wilks/DOTS, autenticación |
| Planificación | Semana 3–4 | Planes manual + IA, calendario, sincronización iCal |
| Entrenador | Semana 5–6 | Panel de entrenador, chat, análisis post-sesión con IA |
| Pulido | Semana 7–8 | Tests, correcciones, publicación App Store y Google Play |
| Crecimiento | Mes 4–6 | Wearables, federaciones adicionales, modelo de suscripción |

---

## 9. Modelo de negocio

### Planes

| | Plan gratuito | Plan atleta Pro | Plan entrenador |
|-|--------------|----------------|----------------|
| Precio | Gratis | 7,99 €/mes | 19,99 €/mes |
| Registro de sesiones | Básico | Ilimitado | Ilimitado |
| Historial | 4 semanas | Completo | Completo |
| Planificación IA | — | Ilimitada | Ilimitada |
| Análisis post-sesión IA | — | Sí | Sí |
| Sincronización calendario | — | Sí | Sí |
| Gestión de atletas | — | — | Hasta 20 atletas |
| Chat entrenador-atleta | — | — | Sí |

### Proyección de ingresos
- **Año 1:** 500 usuarios activos → 15.000–25.000 €/año
- **Año 2:** 2.000 usuarios con expansión a LATAM → 80.000–120.000 €/año
- **Año 3:** 5.000+ usuarios, modelo B2B para boxes y clubs

---

## 10. Análisis competitivo

| Funcionalidad | PowerLog | StrengthLog | Juggernaut AI | Strong |
|--------------|----------|-------------|---------------|--------|
| En español | ✓ | — | — | — |
| Wilks / DOTS | ✓ | Básico | ✓ | — |
| Planificación IA | ✓ | — | ✓ | — |
| Gestión entrenador | ✓ | — | — | — |
| Chat entrenador-atleta | ✓ | — | — | — |
| Peaking competición | ✓ | Básico | ✓ | — |
| Federaciones españolas | ✓ | — | — | — |
| Sincronización calendario | ✓ | — | — | — |
| Precio base | Gratis / 7,99€ | Gratis / 5,99€ | 22€/mes | Gratis / 3,99€ |

---

## 11. Métricas de éxito

- Retención a 30 días superior al 40%
- Sesiones registradas por usuario activo: mínimo 3 por semana
- Tasa de conversión gratuito a Pro superior al 8%
- NPS superior a 45
- CAC inferior a 5 €
- MRR de 2.000 € al final del primer año
- Churn mensual inferior al 5%

---

## 12. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|-----------|
| Mercado nicho pequeño en España | Medio | Expansión temprana a LATAM |
| Competidor grande copia funcionalidades | Alto | Velocidad de lanzamiento y comunidad fidelizada |
| Coste de API de IA escala con usuarios | Medio | Limitar llamadas a IA al plan Pro |
| Baja adopción por entrenadores | Alto | Prueba gratuita de 60 días para entrenadores |

---

## 13. Próximos pasos

1. Validación con 10 atletas y 5 entrenadores reales
2. Diseño de wireframes en Figma para pantallas críticas
3. Configuración del entorno: Flutter + Firebase + Anthropic API
4. Desarrollo del MVP en 4 semanas
5. Beta cerrada con 20 atletas de la comunidad española de powerlifting

---

*PowerLog PRD v1.0 — Marzo 2026*
