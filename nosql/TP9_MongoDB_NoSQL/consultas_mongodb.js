// ============================================================================
// TP9 — Parte 2 Consigna 4: Consultas de Verificación en MongoDB
// Asignatura: Base de Datos II (UTN FRM)
// Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
// Docente: Sergio Neira
// Base de datos: foodstore_nosql | Colección: pedidos
// ============================================================================

use('foodstore_nosql');

print("\n====================================================================");
print("CONSULTA 4.a: Mostrar todos los pedidos (identificador y estado)");
print("====================================================================");
db.pedidos.find(
  {},
  {
    id_pedido: 1,
    estado: 1,
    fecha_pedido: 1,
    "cliente.nombre": 1,
    total: 1,
    _id: 0
  }
).sort({ id_pedido: 1 }).forEach(printjson);


print("\n====================================================================");
print("CONSULTA 4.b: Filtrar pedidos por un estado existente ('ENTREGADO')");
print("====================================================================");
db.pedidos.find(
  { estado: "ENTREGADO" },
  {
    id_pedido: 1,
    estado: 1,
    fecha_pedido: 1,
    "cliente.nombre": 1,
    forma_pago: 1,
    total: 1,
    _id: 0
  }
).sort({ id_pedido: 1 }).forEach(printjson);


print("\n====================================================================");
print("CONSULTA 4.c: Buscar pedidos con producto específico en el arreglo (id_producto = 1)");
print("====================================================================");
// Variante Estándar: Recupera el pedido completo con todas sus líneas mediante Multikey Index
db.pedidos.find(
  { "lineas.id_producto": 1 },
  {
    id_pedido: 1,
    estado: 1,
    "cliente.nombre": 1,
    "lineas.id_producto": 1,
    "lineas.nombre": 1,
    "lineas.cantidad": 1,
    total: 1,
    _id: 0
  }
).sort({ id_pedido: 1 }).forEach(printjson);

// Variante Avanzada con Aggregate y $filter (Proyecta únicamente el ítem buscado)
print("\n--- Variante 4.c (Aggregate con $filter para proyectar solo la línea coincidente) ---");
db.pedidos.aggregate([
  { $match: { "lineas.id_producto": 1 } },
  {
    $project: {
      id_pedido: 1,
      estado: 1,
      "cliente.nombre": 1,
      lineas: {
        $filter: {
          input: "$lineas",
          as: "l",
          cond: { $eq: ["$$l.id_producto", 1] }
        }
      },
      total: 1,
      _id: 0
    }
  },
  { $sort: { id_pedido: 1 } }
]).forEach(printjson);


print("\n====================================================================");
print("CONSULTA 4.d: Buscar pedidos con total superior a un umbral (total > $10.000,00)");
print("====================================================================");
// Umbral elegido: $10.000,00 ARS.
// Justificación: Segmenta compras de mayor volumen o pedidos familiares/grupales frente
// a compras unitarias básicas (ticket promedio habitual en Food Store ~ $6.000 - $8.000).
db.pedidos.find(
  { total: { $gt: 10000.00 } },
  {
    id_pedido: 1,
    estado: 1,
    "cliente.nombre": 1,
    total: 1,
    _id: 0
  }
).sort({ total: -1 }).forEach(printjson);
