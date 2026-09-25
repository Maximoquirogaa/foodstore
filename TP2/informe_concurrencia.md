# Informe de Concurrencia - Parte 2

## Escenario 1: Lectura no repetible

**Cómo se reprodujo:**
- **Sesión A:** `BEGIN; SELECT precio_actual FROM productos WHERE id_producto = 1;`
- **Sesión B:** `BEGIN; UPDATE productos SET precio_actual = 1200 WHERE id_producto = 1; COMMIT;`
- **Sesión A:** `SELECT precio_actual FROM productos WHERE id_producto = 1;`

**Qué se observó:**
En la Sesión A, la primera consulta devolvió un precio inicial. Luego de que la Sesión B hiciera COMMIT, la segunda consulta en la Sesión A devolvió el nuevo precio modificado (1200), a pesar de seguir dentro de la misma transacción abierta.

**Explicación de la IA:**
El nivel de aislamiento por defecto en PostgreSQL es `READ COMMITTED`. Este nivel asegura que leas datos confirmados, pero si otra transacción modifica una fila y hace commit en el medio, tu próxima consulta verá el valor actualizado. Esto se llama anomalía de "Lectura no repetible". Se resuelve subiendo el nivel de aislamiento a `REPEATABLE READ`.

**Verificación en el motor:**
Se repitió el experimento iniciando la Sesión A con `BEGIN ISOLATION LEVEL REPEATABLE READ;`. Al ejecutar el segundo `SELECT` en la Sesión A, el motor devolvió el valor original, ignorando el commit realizado por la Sesión B.

**Conclusión:**
La explicación se confirmó. El nivel `REPEATABLE READ` evita la anomalía tomando un "snapshot" (captura) de la base de datos al inicio de la transacción gracias al MVCC de PostgreSQL.

---

## Escenario 2: Espera por bloqueo (Lock Wait)

**Cómo se reprodujo:**
- **Sesión A:** `BEGIN; SELECT * FROM productos WHERE id_producto = 1 FOR UPDATE;`
- **Sesión B:** `BEGIN; SELECT * FROM productos WHERE id_producto = 1 FOR UPDATE;`

**Qué se observó:**
La consulta en la Sesión A se ejecutó inmediatamente. Sin embargo, al enviar la consulta en la Sesión B, la consola se quedó esperando sin devolver resultados. Al hacer `COMMIT` en la Sesión A, la Sesión B inmediatamente avanzó y devolvió la fila.

**Explicación de la IA:**
La instrucción `FOR UPDATE` coloca un bloqueo exclusivo sobre las filas leídas (`RowShareLock`). Al pedir el mismo bloqueo en la Sesión B, PostgreSQL suspende la ejecución de esta transacción y la pone a la espera hasta que la Sesión A libere el recurso mediante un COMMIT o ROLLBACK.

**Verificación en el motor:**
Consultando la vista `pg_locks` durante el experimento, se comprobó que la Sesión B tenía su solicitud de bloqueo de tupla en estado `granted = f` (falso), esperando la resolución de la Sesión A.

**Conclusión:**
La explicación se confirmó. El mecanismo de bloqueos (locks) resuelve las colisiones al indicar explícitamente la intención de actualizar, encolando las transacciones para mantener la integridad.

---

## Escenario 3: Interbloqueo real (Deadlock)

**Cómo se reprodujo:**
- **Sesión A:** `BEGIN; UPDATE productos SET stock = stock - 1 WHERE id_producto = 1;`
- **Sesión B:** `BEGIN; UPDATE productos SET stock = stock - 1 WHERE id_producto = 2;`
- **Sesión A:** `UPDATE productos SET stock = stock - 1 WHERE id_producto = 2;` *(Queda esperando)*.
- **Sesión B:** `UPDATE productos SET stock = stock - 1 WHERE id_producto = 1;`

**Qué se observó:**
Al enviar el último update en la Sesión B, PostgreSQL abortó automáticamente una de las transacciones (la A o la B) lanzando el error: `ERROR: deadlock detected (SQLSTATE 40P01)`.

**Explicación de la IA:**
Ha ocurrido un "Abrazo Mortal" (Deadlock). La Sesión A bloqueó el producto 1 y necesita el producto 2; la Sesión B bloqueó el producto 2 y necesita el producto 1. Es una espera cíclica infinita. PostgreSQL cuenta con un proceso de detección de deadlocks que, al pasar un breve instante (`deadlock_timeout`), sacrifica (aborta) una transacción para que la otra pueda completarse.

**Verificación en el motor:**
El motor resolvió el conflicto matando un proceso exactamente como se predijo, desbloqueando así el sistema.

**Conclusión:**
La explicación se confirmó. El mecanismo de prevención de PostgreSQL (Deadlock Detector) detiene la anomalía. Para evitarlo desde el diseño de software, la regla de oro es adquirir los bloqueos (o procesar las filas) siempre en un orden consistente, por ejemplo, ordenando primero por `id_producto`.

