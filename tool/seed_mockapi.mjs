// Carga tareas de ejemplo en MockAPI para una cuenta de prueba.
//
// Uso (Node 18+):
//   node tool/seed_mockapi.mjs <URL de MockAPI> <uid de Firebase>
//
// El uid se copia de Firebase Console → Authentication → Usuarios. Las fechas
// se calculan desde "ahora", así siempre hay tareas que vencen hoy (para el
// banner y el filtro "Hoy") y tareas completadas (historial para Gemini).

const baseUrl = (process.argv[2] ?? '').replace(/\/+$/, '');
const userId = process.argv[3];
if (!baseUrl || !userId) {
  console.error('Uso: node tool/seed_mockapi.mjs https://<id>.mockapi.io <uid>');
  process.exit(1);
}

const HOUR = 60 * 60 * 1000;
const now = Date.now();

/** Tarea que vence en `dueInHours` y empieza con margen suficiente. */
function task(title, category, priority, estimatedPomodoros, dueInHours, completedPomodoros = 0) {
  const dueAt = new Date(now + dueInHours * HOUR);
  const startAt = new Date(dueAt.getTime() - estimatedPomodoros * 30 * 60 * 1000);
  return {
    userId,
    title,
    category,
    priority,
    estimatedPomodoros,
    completedPomodoros,
    startAt: startAt.toISOString(),
    dueAt: dueAt.toISOString(),
    isCompleted: completedPomodoros >= estimatedPomodoros,
    createdAt: new Date(now - (100 - dueInHours) * HOUR).toISOString(),
  };
}

const tasks = [
  // Completadas: historial para que Gemini compare.
  task('Lab 1 de Dart', 'study', 'med', 3, -48, 3),
  task('Resumen de la clase de Provider', 'study', 'low', 2, -24, 2),
  task('Diseñar pantallas en Figma', 'deepWork', 'high', 4, -20, 4),
  task('Responder correo del profesor', 'quickWin', 'low', 1, -5, 1),
  // Pendientes (dos vencen hoy).
  task('Repasar para el parcial de cálculo', 'study', 'high', 4, 6),
  task('Terminar la tarea de ciberseguridad', 'deepWork', 'high', 3, 3, 1),
  task('Reunión de equipo del proyecto móvil', 'meeting', 'med', 1, 26),
  task('Leer capítulo 5 de arquitectura', 'study', 'med', 2, 30),
  task('Salir a correr', 'personal', 'low', 1, 50),
];

for (const body of tasks) {
  const response = await fetch(`${baseUrl}/tasks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  console.log(`${response.status} ${body.title}`);
  if (!response.ok) process.exitCode = 1;
}
