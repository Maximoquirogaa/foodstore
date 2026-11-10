// ============================================================================
// TP9 — Experimento de Laboratorio: Validación de Dependencias Cruzadas ($expr)
// Asignatura: Base de Datos II (UTN FRM)
// Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
// Docente: Sergio Neira
// Motor: MongoDB 6+ / 7+ / 8+ / 9+ (ejecutable vía mongosh o Compass)
// ============================================================================
// Objetivo del Experimento:
//   Evaluar si MongoDB es capaz de validar de forma nativa dependencias matemáticas
//   cruzadas entre campos internos (subtotal = cantidad * precio y total = SUM(subtotales))
//   mediante el operador de consulta $expr, contrastando las afirmaciones habituales
//   de la IA que sostienen que esto solo puede validarse en la capa de aplicación.
// ============================================================================

use('foodstore_nosql');

// Limpieza de la colección de ensayo
db.pedidos_validacion_expr.drop();

// Creación de la colección con validador de expresión ($expr)
db.createCollection("pedidos_validacion_expr", {
  validator: {
    $expr: {
      $and: [
        // Regla 1: El total del pedido debe ser igual a la suma de los subtotales de las líneas
        {
          $eq: [
            "$total",
            { $sum: "$lineas.subtotal" }
          ]
        },
        // Regla 2: Cada subtotal debe ser estrictamente igual a (cantidad * precio_unitario)
        {
          $eq: [
            "$lineas.subtotal",
            {
              $map: {
                input: "$lineas",
                as: "l",
                in: { $multiply: ["$$l.cantidad", "$$l.precio_unitario"] }
              }
            }
          ]
        }
      ]
    }
  },
  validationAction: "error",
  validationLevel: "strict"
});

print("=== COLECCIÓN 'pedidos_validacion_expr' CREADA CON REGLAS $expr ===");

// ----------------------------------------------------------------------------
// Caso A: Pedido con cálculos matemáticos EXACTOS (Debe ser ACEPTADO)
// ----------------------------------------------------------------------------
try {
  db.pedidos_validacion_expr.insertOne({
    id_pedido: 101,
    cliente: { id_cliente: 1, alias: "Juan P." },
    lineas: [
      { id_producto: 1, cantidad: 2, precio_unitario: 4500, subtotal: 9000 },
      { id_producto: 3, cantidad: 1, precio_unitario: 2200, subtotal: 2200 }
    ],
    total: 11200 // 9000 + 2200 = 11200
  });
  print("[OK] Caso A (Matemática correcta): Documento ACEPTADO con éxito.");
} catch (e) {
  print("[ERROR] Caso A falló inesperadamente: " + e.message);
}

// ----------------------------------------------------------------------------
// Caso B: Pedido con TOTAL INCOHERENTE (Debe ser RECHAZADO por código 121)
// ----------------------------------------------------------------------------
try {
  db.pedidos_validacion_expr.insertOne({
    id_pedido: 102,
    cliente: { id_cliente: 2, alias: "María G." },
    lineas: [
      { id_producto: 1, cantidad: 1, precio_unitario: 4500, subtotal: 4500 }
    ],
    total: 99999 // Total deliberadamente alterado (debería ser 4500)
  });
  print("[ALERTA] Caso B NO fue rechazado (Comportamiento incorrecto).");
} catch (e) {
  print("[OK] Caso B (Total incoherente): RECHAZADO correctamente por MongoDB (Código 121 - Document failed validation).");
}

// ----------------------------------------------------------------------------
// Caso C: Pedido con SUBTOTAL ALTERADO EN UNA LÍNEA (Debe ser RECHAZADO)
// ----------------------------------------------------------------------------
try {
  db.pedidos_validacion_expr.insertOne({
    id_pedido: 103,
    cliente: { id_cliente: 3, alias: "Carlos L." },
    lineas: [
      // 2 * 4500 = 9000, pero colocamos subtotal adulterado de 7000
      { id_producto: 1, cantidad: 2, precio_unitario: 4500, subtotal: 7000 }
    ],
    total: 7000 // El total cuadra con la suma de subtotales, pero el subtotal no cuadra con cant * precio
  });
  print("[ALERTA] Caso C NO fue rechazado (Comportamiento incorrecto).");
} catch (e) {
  print("[OK] Caso C (Subtotal incoherente con cant*precio): RECHAZADO correctamente por MongoDB.");
}

print("\nConteo final en colección de ensayo (debe ser exactamente 1): " + db.pedidos_validacion_expr.countDocuments());
