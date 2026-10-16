# Tablero Kanban Fase 2

Proyecto: App Móvil de Control de Finanzas Personales  
Responsable: Tomás García, Grupo 7, proyecto individual  
Fecha de corte: 16 de octubre de 2026

Este tablero aplica Kanban personal. Una tarea solo pasa a **Hecho** cuando tiene una evidencia comprobable, como una prueba en emulador o teléfono, un cambio versionado o documentación actualizada.

| Pendiente | En curso | En prueba | Hecho |
| --- | --- | --- | --- |
| Presupuestos mensuales y alertas | Documentar casos de prueba del MVP | — | Configurar Flutter para Android |
| Reportes por categoría y mes | Preparar entrega y demostración de Fase 2 | — | Persistencia local con SQLite |
| Exportar y respaldar datos |  | — | Registro manual de ingresos y gastos |
| Evaluar nuevos formatos de notificaciones |  | — | Crear y seleccionar categorías personalizadas |
| Política de privacidad y consentimiento |  | — | Ver detalle, editar categoría y eliminar movimiento |
|  |  | — | Crear Banco Demo para notificaciones ficticias |
|  |  | — | Registrar automáticamente compras, abonos y transferencias de prueba |
|  |  | — | Probar el flujo en emulador Android y teléfono físico |

## Regla de trabajo

1. Mantener solo una tarea técnica importante en **En curso**.
2. Mover una tarea a **En prueba** cuando esté implementada, pero antes de validar el flujo completo.
3. Mover una tarea a **Hecho** solo después de guardar su evidencia.
4. Revisar el tablero y la carta Gantt una vez por semana o cuando aparezca un bloqueo.

## Alcance comprobado de la automatización

La detección automática actual corresponde exclusivamente a la aplicación **Banco Demo**. Sus notificaciones son ficticias y permiten validar el recorrido notificación → interpretación → registro en SQLite → visualización y corrección del movimiento. La compatibilidad con bancos o billeteras reales queda como trabajo futuro y requerirá validación de formatos, privacidad y consentimiento.
