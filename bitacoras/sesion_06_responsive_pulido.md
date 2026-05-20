# Bitácora IA — Sesión 06
## Responsive, Pulido Visual y Firebase Auth

**Fechas:** 11 al 13 de mayo de 2026  
**Commits:** `75e4e0eb` → `241e2c05` — *puliendo la app, responsive, ajustes finales, app casi completa*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Ajustar el diseño responsive para que la aplicación se vea correctamente en celulares de gama baja (pantallas de 5"), tablets de 8" y 10", y en modo vertical/horizontal. Integrar Firebase Auth con soporte de email/contraseña y Google Sign-In. Pulir detalles visuales según los mockups de Crosmedia.

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | ¿Cómo hacer responsive un layout sin usar `MediaQuery` en cada widget? | `LayoutBuilder` en el widget raíz de cada pantalla; pasar `constraints` hacia abajo en vez de llamar `MediaQuery` repetidamente |
| 2 | ¿Cómo integrar Firebase Auth con email/contraseña y Google en Flutter? | `FirebaseAuthService` con `signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `signInWithGoogle` usando `google_sign_in` |
| 3 | ¿Cómo migrar una cuenta legacy (sin Firebase) a una cuenta Firebase? | `buscarPorEmail()` en SQLite; si existe, hacer `vincularFirebaseUid()` para asociar el UID de Firebase al registro local |
| 4 | ¿Cómo forzar el idioma español en los correos de Firebase? | `await FirebaseAuth.instance.setLanguageCode('es')` antes de enviar el correo de verificación |
| 5 | ¿Cómo subir el perfil del estudiante a Firestore al hacer login? | `FirestoreSyncService.subirPerfil()` se llama desde `SincronizarUseCase.ejecutar()` cuando hay internet |

---

## Mejoras de responsive implementadas

| Pantalla | Problema | Solución |
|----------|----------|----------|
| Menú principal | Tarjetas de materia se solapaban en 5" | `GridView` de 2 columnas con `childAspectRatio` dinámico |
| Actividades de Ciencias | Imágenes de tarjetas desbordaban en landscape | `Flexible` + `FittedBox` con `BoxFit.contain` |
| Pantalla de Racha | Personaje se salía del área visible en tablets | `clamp()` en el cálculo del margen base para limitar al 40% del alto disponible |
| Selección de Grado | Botones muy pequeños en celulares de 4.5" | `SizedBox` mínimo de 48px para área de tap (guideline Material) |
| Detective de Objetos | Grid deformado en tablets landscape | Breakpoint en 600px: 3 columnas en tablet, 2 en celular |

---

## Código generado con IA

- `FirebaseAuthService`: email/contraseña + Google Sign-In + reload() para verificar estado del correo
- `LoginView` y `RegistroView` con validación de formularios y feedback de error en español
- `ConfiguracionView`: cambio de grado con `RadioListTile`, actualización en SQLite + navegación al menú correcto
- `PerfilViewModel`: carga y actualización del perfil desde Firebase + SQLite
- Ajustes responsive en 18 pantallas con `LayoutBuilder` y `MediaQuery`

---

## Complicaciones encontradas

| Problema | Causa | Solución IA |
|----------|-------|-------------|
| Caché de Firebase Auth mostraba usuario logueado aunque se cerró sesión | `currentUser` usa caché local sin verificar el servidor | `reload()` fuerza una consulta a Firebase; el caché local puede estar desactualizado |
| El correo de verificación llegaba en inglés | Firebase usa el idioma del sistema operativo por defecto | `setLanguageCode('es')` fuerza español antes de enviar el correo |
| Google Sign-In fallaba en Android sin `google-services.json` configurado | SHA-1 no registrado en Firebase Console | Documentado en guía de despliegue; no es un bug del código |
| La pantalla de registro no validaba emails duplicados | `createUserWithEmailAndPassword` lanza `email-already-in-use` | Captura del código de error específico con mensaje amigable en español |

---

## Resultado

Aplicación visualmente consistente en celulares de 5" a tablets de 10". Firebase Auth operativo. 18 pantallas con responsive ajustado. Perfil del estudiante sincronizable con Firestore.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*
