# Protocolo de Seguridad — TP2

**Materia:** Base de Datos II — UTN
**Motor:** PostgreSQL 13+ (Windows)
**Ámbito:** Toda operación del TP se ejecuta sobre la **copia de trabajo**, nunca sobre la base original.

---

## Paso 1: Copia de trabajo

Antes de ejecutar cualquier script SQL, se crea una copia exacta de la base original.
Reemplazar `<usuario>` y `<bd_original>` por los valores reales del entorno.

### Opción A: `pg_dump` + `createdb` + `psql` (recomendada en Windows)

```powershell
# 1) Volcar la base original a un archivo
pg_dump -U <usuario> -h localhost -p 5432 -d <bd_original> -f "backups\copia_trabajo_20260923.sql"

# 2) Crear la base copia
createdb -U <usuario> -h localhost <bd_copia>

# 3) Restaurar el volcado en la copia
psql -U <usuario> -h localhost -d <bd_copia> -f "backups\copia_trabajo_20260923.sql"
```

Ejemplo con valores concretos:

```powershell
pg_dump -U postgres -h localhost -d proyecto_integrador -f "backups\copia_trabajo_20260923.sql"
createdb -U postgres -h localhost proyecto_integrador_copia
psql -U postgres -h localhost -d proyecto_integrador_copia -f "backups\copia_trabajo_20260923.sql"
```

Para no editar la fecha a mano, se puede usar una variable de PowerShell:

```powershell
$fecha = Get-Date -Format "yyyyMMdd"
pg_dump -U postgres -h localhost -d proyecto_integrador -f "backups\copia_trabajo_$fecha.sql"
createdb -U postgres -h localhost proyecto_integrador_copia
psql -U postgres -h localhost -d proyecto_integrador_copia -f "backups\copia_trabajo_$fecha.sql"
```

### Opción B: `createdb -T` (sin volcado intermedio)

```powershell
createdb -U <usuario> -h localhost -T <bd_original> <bd_copia>
```

Requiere que **no haya conexiones activas** a `bd_original` (si las hay, PostgreSQL responde
`ERROR 55006: source database ... is being accessed by other users`).

> Regla: todo el TP opera sobre `<bd_copia>` (BD_Copia). `<bd_original>` queda intacta.
> Esta regla se verifica antes de ejecutar cualquier script con:
> `SELECT current_database();` debe devolver `<bd_copia>`.

---

## Paso 2: Transacción explícita

Todo cambio estructural (DDL) o de datos (DML) se envuelve en una transacción explícita.
Nada se ejecuta en modo autocommit durante el TP.

```sql
BEGIN;

  -- sentencias DDL o DML aquí, p. ej.:
  -- ALTER TABLE pedido ADD CONSTRAINT ...;
  -- UPDATE funcion SET activa = FALSE WHERE fecha_fin < CURRENT_DATE;

  -- SELECT de verificación OBLIGATORIO antes de decidir:
  SELECT current_database(); -- confirma que se trabaja sobre la copia
  SELECT COUNT(*) FROM ...  -- confirma el efecto esperado

COMMIT;   -- si el resultado es correcto
-- ROLLBACK;  -- si el resultado NO es correcto (cambios descartados)
```

Reglas asociadas:

- Si las filas afectadas o los valores retornados no coinciden con lo esperado
  → ejecutar `ROLLBACK` antes de reintentar.
- Para pruebas que **no deben persistir** (positiva/negativa, lectura crítica),
  se usa el bloque `BEGIN ... ROLLBACK` y la base queda idéntica antes y después:

```sql
BEGIN;
INSERT INTO pedido(monto_total) VALUES (-5);  -- debe fallar con SQLSTATE 23xxx
ROLLBACK;
```

---

## Paso 3: Respaldo versionado (Git)

Cada entregable se confirma en Git con la convención obligatoria:

```
<tipo>: <descripción> — Parte <N>
```

- `<tipo>` ∈ {`feat`, `fix`, `docs`}
- `<descripción>`: entre 1 y 72 caracteres, verbo en presente
- separador: ` — ` (espacio, guion em —, espacio)
- `<N>` ∈ {0, 1, 2, 3}

```powershell
git add protocolo_seguridad.md
git commit -m "feat: agrega protocolo de seguridad con pg_dump — Parte 0"
```

Verificación de que el commit contiene únicamente ese archivo:

```powershell
git show --stat HEAD
```

Ejemplos por parte:

```powershell
git commit -m "feat: protocolo de seguridad con copia de trabajo — Parte 0"
git commit -m "feat: restricción chk_monto_positivo en pedido — Parte 1"
git commit -m "fix: corrijo restricción chk_monto_positivo — Parte 1"
git commit -m "docs: informe concurrencia - lectura no repetible — Parte 2"
git commit -m "docs: lectura crítica scripts peligrosos — Parte 3"
```

Reglas:
- El mensaje describe **qué** se hizo y para **qué parte**, no cómo lo generó la IA.
- Nunca se versionan credenciales, cadenas de conexión con clave ni datos sensibles del entorno.