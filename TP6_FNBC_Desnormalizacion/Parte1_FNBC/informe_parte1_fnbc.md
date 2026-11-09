# TP6 — Parte 1: Normalización en Forma Normal de Boyce-Codd (FNBC)

**Materia:** Base de Datos II  
**Trabajo Práctico:** TP6 — FNBC y Desnormalización Controlada  
**Proyecto:** Food Store (UTN FRM)  
**Alumno:** Máximo Juan Cruz Quiroga  
**Email:** `maximoj.quiroga@alumnos.frm.utn.edu.ar`  
**Docente:** Sergio Neira  
**Motor:** PostgreSQL 17  

---

## 1. Análisis Teórico de Dependencias Funcionales

Se analizó la relación de control de almacenes y depósitos:
$$R(\text{id\_lote}, \text{id\_deposito}, \text{id\_responsable\_control})$$
Abreviada como $R(L, D, C)$.

### Dependencias Funcionales de Dominio:
1. $LD \to C$: En un lote y depósito específico interviene un único responsable de control de calidad.
2. $C \to D$: Cada responsable de control pertenece a un único depósito físico (no trabaja en depósitos simultáneos).

### Cálculo de Claves Candidatas:
- Atributos que no aparecen a la derecha de ninguna DF: $L$. Todo determinante o clave candidata debe contener obligatoriamente a $L$.
- Clausura de $LD$:
  $$\{L, D\}^+ = \{L, D, C\}$$ (Determina todos los atributos $\Rightarrow LD$ es clave candidata).
- Clausura de $LC$:
  $$\{L, C\}^+ = \{L, C, D\}$$ (Dado que $C \to D \Rightarrow LC$ determina todos los atributos $\Rightarrow LC$ es clave candidata).
- **Claves Candidatas Oficiales:** $LD$ y $LC$.
- **Atributos Primos:** Todos los atributos ($L$, $D$, $C$) son primos porque forman parte de al menos una clave candidata.

---

## 2. Diagnóstico de Formas Normales (3FN vs FNBC)

### ¿Cumple 3FN?
**SÍ.** Una relación está en 3FN si para cada dependencia funcional no trivial $X \to Y$, o bien $X$ es superclave, o bien $Y$ es un atributo primo.
- En $LD \to C$: $LD$ es clave candidata (superclave). Cumple 3FN.
- En $C \to D$: $C$ no es superclave, pero **$D$ es un atributo primo** (pertenece a la clave candidata $LD$). Por ende, **cumple formalmente 3FN**.

### ¿Cumple FNBC?
**NO.** Una relación está en Forma Normal de Boyce-Codd si y solo si para **toda** dependencia funcional no trivial $X \to Y$, el determinante $X$ es una superclave.
- En la dependencia $C \to D$, el determinante $C$ (responsable de control) **no es superclave**.
- Por lo tanto, **viola la FNBC**.

### Anomalías Operativas Derivadas:
1. **Redundancia:** Cada vez que el responsable $801$ inspecciona un nuevo lote en el depósito $30$, se repite innecesariamente la tupla $(801, 30)$.
2. **Anomalía de Inserción:** No se puede registrar la asignación de un nuevo responsable al depósito $30$ hasta que no inspeccione su primer lote.
3. **Anomalía de Borrado:** Si se purga el único lote inspeccionado por un responsable, se pierde la información de a qué depósito pertenece.
4. **Anomalía de Modificación:** Si un responsable es trasladado de depósito, se deben actualizar múltiples filas; de lo contrario, la base cae en inconsistencia.

---

## 3. Descomposición en FNBC

Se aplica el algoritmo formal de descomposición en FNBC particionando sobre la dependencia transgresora $C \to D$:

1. **$R_1(\text{id\_responsable\_control}, \text{id\_deposito})$** $\to$ `responsable_deposito`:
   - Clave primaria: `id_responsable_control`.
   - DF: $C \to D$. Al ser $C$ la clave primaria, **está en FNBC**.
2. **$R_2(\text{id\_lote}, \text{id\_responsable\_control})$** $\to$ `control_lote`:
   - Clave primaria compuesta: `(id_lote, id_responsable_control)`.
   - Única DF no trivial: la combinación completa determina la tupla. **Está en FNBC**.

---

## 4. Evaluación de Propiedades Formales

### 1. Reunión sin Pérdida (Lossless Join): **PRESERVADA**
La intersección de atributos entre $R_1$ y $R_2$ es $\text{id\_responsable\_control}$ ($C$).
Dado que $C$ es la clave primaria de $R_1$ ($C \to CD$), el teorema de descomposiciones garantiza que la reunión natural $R_1 \bowtie R_2$ es **estrictamente sin pérdida**.
Esto fue comprobado formalmente en el motor mediante la vista `v_control_lote_almacen` con un `EXCEPT` bidireccional arrojando **0 filas de discrepancia**.

### 2. Preservación de Dependencias: **NO PRESERVADA LOCALMENTE**
- La dependencia $C \to D$ queda preservada localmente en $R_1$ gracias a su clave primaria.
- Sin embargo, la dependencia original **$LD \to C$ no queda cubierta por ninguna de las restricciones locales de clave primaria o foránea**.
- Si se insertaran los responsables $801$ y $803$ (ambos asignados al depósito $30$ en $R_1$), y luego en $R_2$ se asignaran ambos al lote $501$, la reunión natural asignaría dos responsables distintos al mismo lote en el depósito $30$, violando $LD \to C$ sin que ninguna restricción local de PostgreSQL lo impida.
- **Conclusión Técnica:** Se demuestra en la práctica el principio teórico que establece que *toda relación puede descomponerse en 3FN preservando dependencias y sin pérdida, pero no siempre es posible alcanzar FNBC preservando todas las dependencias funcionales*. Para controlar $LD \to C$ en producción se requeriría un trigger o aserción entre tablas.

