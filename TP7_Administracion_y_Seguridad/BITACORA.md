# TP7 — Bitácora de Interacciones con Inteligencia Artificial

**Proyecto:** Food Store — Base de Datos II (UTN FRM)  
**Institución:** Universidad Tecnológica Nacional – Facultad Regional Mendoza  
**Docente:** Sergio Neira  
**Alumno:** Máximo Juan Cruz Quiroga (`maximoj.quiroga@alumnos.frm.utn.edu.ar`)  
**Ciclo Lectivo:** 2026  
**Ubicación Curricular:** Unidad 5 — Administración y Seguridad (Roles, Auditoría, Incidentes y Protección de Datos Personales)  

---

## 📋 Resumen del Proceso y Cumplimiento de la Parte E

Conforme a la consigna de la **Parte E** del Trabajo Práctico:
1. Se consolidan en la tabla obligatoria de **tres columnas** todas las interacciones realizadas con asistentes de IA para las **Partes A a D**.
2. Se documenta explícitamente el **caso más significativo de error o propuesta insegura** sugerida por la IA (ver sección §2 abajo), explicando cómo se detectó y el criterio humano aplicado para resolverlo.
3. Se verifica la trazabilidad en Git y la correspondencia con las etapas del TP.

---

## 1. Tabla Obligatoria de Interacciones (3 Columnas)

| Prompt enviado a la IA | Respuesta relevante recibida | Validación o corrección humana aplicada |
|---|---|---|
| **Punto de partida (Clases 1 y 2):** Revisar si existen scripts de tabla usuarios, vistas, materializada y funciones `fn_autenticar` / `fn_resetear_password`; proponer su reconstrucción con pgcrypto y `SECURITY DEFINER`. | La IA detectó que las tablas y vistas existen en el repositorio canónico de Food Store, pero las funciones no estaban versionadas. Propuso reconstruir una tabla con columnas dispares (`password_hash`, `email`, `fecha_alta`). | **Corregido por el alumno.** Se rechazó la estructura divergente para preservar la compatibilidad con el modelo canónico de Food Store (`public.usuarios`: `id_usuario`, `correo_electronico`, `contrasena`, `activo`, `fecha_creacion`). Se crearon `sql/fn_autenticar.sql` y `sql/fn_resetear_password.sql` con `pgcrypto`, `SECURITY DEFINER`, `search_path` seguro (`pg_catalog, pg_temp`) y `REVOKE ALL FROM PUBLIC`. |
| **Parte A.4 (Auditoría de Roles):** Auditar `sql/roles.sql` según mínimo privilegio y proponer una modificación con permiso amplio tipo `GRANT ALL ON ALL TABLES IN SCHEMA public TO rol_app_escritura` o `GRANT ALL ON ALL TABLES TO app_web`. | La IA sugirió aplicar `GRANT ALL ON ALL TABLES IN SCHEMA public TO rol_app_escritura` y `GRANT ALL PRIVILEGES ON ALL TABLES TO app_web`, argumentando que *"simplifica el mantenimiento y previene errores imprevistos de permisos (`permission denied`) durante la evolución de la aplicación"*. | **Rechazado enérgicamente por el alumno (Caso más significativo de error/inseguridad).** Se descartó la propuesta: otorgar `ALL` vulnera el principio de mínimo privilegio (PoLP), permitiendo `DELETE` y `TRUNCATE` en tablas transaccionales (violando la regla de negocio R7 de baja lógica y preservación del historial) y exponiendo la tabla `usuarios` completa (incluyendo hashes de contraseña). En su lugar, se conservaron únicamente los privilegios estrictos: `SELECT` para lectura, `INSERT, UPDATE` para escritura, y acceso restringido por columnas sin `contrasena` para soporte. |
| **Parte A.4 (Acceso de Soporte):** Proponer darle lectura completa a `rol_soporte` (`GRANT SELECT ON usuarios TO rol_soporte`) para evitar errores en columnas no otorgadas. | La IA sugirió conceder `GRANT SELECT ON usuarios TO rol_soporte` bajo el supuesto de facilitar la atención de tickets y reclamos de clientes. | **Rechazado por el alumno.** Viola el requerimiento RF-03: `rol_soporte` nunca debe poder leer la columna `contrasena` (hash bcrypt), ya que facilitaría ataques de fuerza bruta offline o robo de credenciales. Se mantuvieron permisos exclusivamente granulares sobre columnas no sensibles (`id_usuario`, `nombre`, `apellido`, `correo_electronico`, `telefono`, `rol`, `activo`, `fecha_creacion`) más `UPDATE (activo)` y `EXECUTE` en `fn_resetear_password`. |
| **Parte B.1 y B.2 (Configuración de Auditoría):** Activar parámetros de auditoría (`log_connections`, `log_disconnections`, `log_statement`, `log_line_prefix`), ejecutar secuencia de prueba y capturar el log. | La IA recomendó configurar `log_statement = 'mod'` para capturar sentencias de modificación (`INSERT`, `UPDATE`, `DELETE`). | **Ajustado por el alumno.** Si bien `'mod'` es suficiente para cambios de datos, la consigna exige verificar también una operación de lectura (`SELECT`). Por lo tanto, se fijó deliberadamente `log_statement = 'all'` para la prueba de laboratorio. Asimismo, se observó que la contraseña errónea pasada a `fn_autenticar` queda en texto plano en el log, documentando este hallazgo de seguridad en `informe_auditoria.md`. |
| **Parte C.4 (Reconstrucción del Simulacro de Incidente):** A partir exclusivamente del fragmento de log anonimizado (sin contexto adicional), reconstruir qué ocurrió y sugerir acciones de contención. | La IA reconstruyó correctamente la secuencia: 3 intentos fallidos de autenticación (posible fuerza bruta), 1 autenticación exitosa, lectura masiva de usuarios y un intento fallido de escalamiento de privilegios (`GRANT admin_datos`). Sugirió como hipótesis de contención: *"Bloquear la dirección IP de origen y rotar credenciales de forma inmediata"*. | **Validado críticamente con decisión humana.** La IA acertó en la cronología técnica de los eventos, pero su propuesta de bloqueo automático de IP fue desestimada como acción automática: en un entorno real o corporativo con proxies/NAT, un bloqueo reactivo sin validación previa puede generar una denegación de servicio (DoS) a usuarios legítimos. La decisión final adoptada fue: aislar la sesión sospechosa, forzar el reseteo de la credencial comprometida mediante `fn_resetear_password`, auditar trazas previas y verificar que ningún rol haya obtenido membresías indebidas. |
| **Parte D.2 (Anonimización y Equivalencia):** Generar consulta analítica por rol y mes de alta sobre `usuarios_anon` y formular la consulta equivalente sobre la tabla real `usuarios`. | La IA formuló ambas consultas agrupando por `rol` y `date_trunc('month', fecha_creacion)::date`. Inicialmente propuso una comparación visual de resultados. | **Corregido y reforzado por el alumno.** Una inspección visual es insuficiente para garantizar equivalencia matemática rigurosa en bases de datos. Se implementó una verificación formal utilizando el operador de teoría de conjuntos `EXCEPT ALL` en ambas direcciones (`anon EXCEPT ALL real` y `real EXCEPT ALL anon`), asegurando igualdad exacta de cardinalidades y conteos sin margen de error humano. |

---

## 2. Caso más significativo de error o propuesta insegura detectado (Parte E.2)

### El problema: Sugerencia de permisos amplios (`GRANT ALL PRIVILEGES`)
Durante la auditoría asistida de la **Parte A.4**, el asistente de inteligencia artificial propuso en reiteradas oportunidades otorgar permisos indiscriminados como `GRANT ALL ON ALL TABLES IN SCHEMA public TO app_web` y `GRANT ALL ON ALL TABLES IN SCHEMA public TO rol_app_escritura`, argumentando que era una *"práctica recomendada para agilizar el desarrollo y evitar excepciones imprevistas de tipo permission denied"*.

### Análisis crítico y detección
El alumno detectó de inmediato que este consejo viola flagrantemente el **Principio de Mínimo Privilegio (PoLP)** y la especificación de diseño de Food Store:
1. **Pérdida de integridad histórica:** Otorgar `ALL` incluye privilegios destructivos como `DELETE` y `TRUNCATE`. En Food Store, la regla de negocio **R7** prohíbe la eliminación física de registros históricos, exigiendo baja lógica mediante el atributo booleano `activo = FALSE`.
2. **Exposición masiva de secretos:** `GRANT ALL` sobre todas las tablas otorgaría al usuario web o a soporte acceso directo a la tabla `usuarios` completa, exponiendo los hashes de contraseñas (`contrasena`), facilitando ataques de escalamiento y comprometiendo los datos personales de clientes y empleados.
3. **Resolución aplicada:** Se rechazó categóricamente la sugerencia y se mantuvieron las concesiones estrictas por tabla, columna (`GRANT SELECT (...) ON usuarios`), vista y función (`GRANT EXECUTE`), preservando la robustez del sistema ante accesos no autorizados.

---

## 3. Verificación del Control de Versiones en Git (Parte E.3)

El trabajo se estructuró de manera secuencial y trazable en el repositorio Git, reflejando el avance progresivo en las distintas partes de la Unidad 5:
- **Parte A:** Especificación Kiro, diseño de roles, modelo canónico en `sql/roles.sql` y verificación de permisos.
- **Parte B:** Configuración de parámetros en PostgreSQL (`postgresql.conf`/`ALTER SYSTEM`), script `sql/auditoria_test.sql` y análisis técnico del log.
- **Parte C:** Diseño y ejecución controlada del simulacro de incidente (`sql/simulacro_incidente.sql`), anonimización de evidencias y contraste crítico de la reconstrucción con IA.
- **Parte D:** Implementación de la anonimización de datos (`sql/usuario_anon.sql`), consultas analíticas y demostración matemática de equivalencia con `EXCEPT ALL`.
- **Parte E:** Consolidación final de la bitácora, documentación técnica y cierre de la entrega.
