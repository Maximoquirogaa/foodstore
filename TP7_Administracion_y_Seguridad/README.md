# TP7 — Administración y Seguridad: Food Store

**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza (UTN FRM)  
**Cátedra:** Base de Datos II  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Proyecto:** Food Store (PostgreSQL 17)  
**Ubicación curricular:** Unidad 5 — Administración y Seguridad (Roles, Auditoría, Incidentes y Protección de Datos Personales)  

---

## 📌 Guía de Lectura y Matriz de Entregables

La siguiente matriz orienta la lectura del trabajo práctico conforme a la [consigna oficial de la cátedra](Trabajo%20Practico%20Unidad%205.pdf). Cada sección cuenta con su especificación, scripts ejecutables, evidencias y análisis crítico:

| Punto | Qué pide | Entregable | Evidencia o validación documentada |
|---|---|---|---|
| **A.1** | Especificar roles con Kiro | [Requisitos](docs/kiro_roles_spec/requirements.md) y [diseño](docs/kiro_roles_spec/design.md) | RF-01 a RF-07 y matriz de mínimo privilegio |
| **A.2** | Implementar roles y privilegios | [roles.sql](sql/roles.sql) | [Roles vigentes verificados](docs/evidencias/roles_vigentes_20261109.md) |
| **A.3** | Verificar permisos efectivos | [Verificación de permisos](docs/kiro_roles_spec/verificacion_permisos.md) | [Salida cruda de roles y grants](docs/evidencias/salida_roles_vigentes_20261109.txt) |
| **A.4** | Revisar críticamente permisos amplios | [Bitácora consolidada](BITACORA.md) | Propuestas de `GRANT ALL` solicitadas a la IA y rechazadas por el alumno |
| **B.1** | Configurar parámetros de auditoría | [Informe B](docs/informe_auditoria.md) | Parámetros activados (`log_connections`, `log_disconnections`, `log_statement=all`) |
| **B.2** | Registrar operaciones y login fallido | [Secuencia B](sql/auditoria_test.sql) | [Log capturado (UTF-8)](docs/log_auditoria_prueba.utf8.txt) |
| **B.3** | Analizar información y límites del log | [Informe B](docs/informe_auditoria.md) | Quién, qué, cuándo, desde dónde; límites nativos vs `pgaudit` / triggers |
| **B.4** | Evaluar sensibilidad y acceso al log | [Informe B](docs/informe_auditoria.md) | ACLs de sistema operativo (NTFS/POSIX) y motor de base de datos |
| **C.1** | Ejecutar secuencia del simulacro | [Guion C](sql/simulacro_incidente.sql) | [Ejecución documentada](docs/evidencias/ejecucion_20261109_1211.md) |
| **C.2** | Comprobar rechazo del escalamiento | [Informe C](docs/informe_incidente.md) | Captura de excepción `SQLSTATE 42501` (permisos insuficientes) |
| **C.3** | Anonimizar el fragmento de log | [Log anonimizado](docs/log_simulacro_anonimizado.utf8.txt) | Eliminación de IPs, mails y credenciales antes de procesar con IA |
| **C.4** | Reconstruir incidente con asistente IA | [Respuesta íntegra de IA](docs/respuesta_ia_incidente.md) | [Bitácora de interacciones](BITACORA.md) |
| **C.5** | Contrastar críticamente la respuesta | [Informe C](docs/informe_incidente.md) | Aciertos, omisiones e inferencias no sustentadas por el log |
| **C.6** | Decidir medidas de contención humanas | [Informe C](docs/informe_incidente.md) | Plan de respuesta a incidentes: distinción entre entorno de prueba y producción |
| **D.1** | Transformar y anonimizar datos | [usuario_anon.sql](sql/usuario_anon.sql) | [Informe D](docs/verificacion_equivalencia.md): generación sintética determinista |
| **D.2** | Formular consultas equivalentes | [usuario_anon.sql](sql/usuario_anon.sql) | Distribución de usuarios por rol y mes de alta |
| **D.3** | Comparar resultados analíticos | [Informe D](docs/verificacion_equivalencia.md) | Verificación matemática exacta con `EXCEPT ALL` bidireccional |
| **D.4** | Criterios de protección ante la IA | [Informe D](docs/verificacion_equivalencia.md) | Políticas de frontera de datos personales y sensibles |
| **E.1** | Consolidar bitácora de IA en 3 columnas | [Bitácora](BITACORA.md) | Formato obligatorio: Prompt, Respuesta y Validación/Corrección Humana |
| **E.2** | Documentar error significativo de la IA | [Bitácora](BITACORA.md) | Detección de propuestas inseguras (`GRANT ALL`) y resolución con criterio propio |
| **E.3** | Registro y trazabilidad en Git | [Bitácora](BITACORA.md) | Historial estructurado por partes |

---

## 🏗️ Estructura del Repositorio TP7

```text
TP7_Administracion_y_Seguridad/
├── README.md                                  <- Guía de navegación y matriz de entrega
├── BITACORA.md                                <- Bitácora consolidada de interacción con IA (3 columnas)
├── Informe_TP7_Administracion_y_Seguridad.pdf <- Informe técnico compilado en PDF
├── Trabajo Practico Unidad 5.pdf              <- Consigna oficial de la cátedra
├── sql/
│   ├── roles.sql                              <- Implementación canónica de roles y permisos (Parte A)
│   ├── fn_autenticar.sql                      <- Autenticación bcrypt contra public.usuarios (Clase 2 / TP7)
│   ├── fn_resetear_password.sql               <- Restablecimiento de contraseñas bcrypt con longitud mínima
│   ├── auditoria_test.sql                     <- Secuencia de prueba auditable (Parte B)
│   ├── simulacro_incidente.sql                <- Escenario de ataque y escalamiento rechazado (Parte C)
│   ├── usuario_anon.sql                       <- Anonimización y prueba de equivalencia analítica (Parte D)
│   ├── usuario_anon_cobertura.sql             <- Ensayo ampliado con fixtures para cobertura total
│   └── activar_auditoria_local.sql            <- Parámetros de auditoría a nivel motor
└── docs/
    ├── kiro_roles_spec/                       <- Especificación formal Kiro (Parte A.1 y A.3)
    │   ├── requirements.md                    <- Requisitos funcionales de roles y privilegios
    │   ├── design.md                          <- Decisiones de diseño y arquitectura de seguridad
    │   └── verificacion_permisos.md           <- Evidencia psql de permisos efectivos
    ├── informe_auditoria.md                   <- Informe técnico de configuración y análisis de log (Parte B)
    ├── log_auditoria_prueba.utf8.txt          <- Fragmento de log capturado durante la prueba B
    ├── informe_incidente.md                   <- Análisis y contención del incidente simulado (Parte C)
    ├── log_simulacro_anonimizado.utf8.txt     <- Log anonimizado entregado al asistente de IA
    ├── respuesta_ia_incidente.md              <- Salida íntegra recibida de la IA para el incidente
    ├── verificacion_equivalencia.md           <- Demostración analítica y matemática de equivalencia (Parte D)
    └── evidencias/                            <- Registros de ejecución fechados y salidas de soporte
```
