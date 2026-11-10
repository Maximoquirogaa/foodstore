// ============================================================================
// TP9 — NoSQL y Nuevas Formas de Almacenamiento: Script de Migración a MongoDB
// Asignatura: Base de Datos II (UTN FRM)
// Alumno: Máximo Juan Cruz Quiroga (maximoj.quiroga@alumnos.frm.utn.edu.ar)
// Docente: Sergio Neira
// Motor: MongoDB 6+ / 7+ / 8+ / 9+ (ejecutable vía mongosh o Compass)
// ============================================================================
// Consigna 1 y 2:
//   Crear la base de datos 'foodstore_nosql' y la colección 'pedidos'.
//   Migrar un mínimo de 5 pedidos con sus líneas de detalle embebidas y datos
//   esenciales del cliente, preservando identificadores de origen, importes,
//   cantidades y estados existentes.
// ============================================================================

// 1. Selección y cambio a la base de datos
use('foodstore_nosql');

// 2. Limpieza preventiva de la colección para asegurar reproducibilidad idempotente
db.pedidos.drop();

// 3. Creación de la colección con reglas de validación de esquema (JSON Schema)
// Garantiza que ningún documento se inserte sin cumplir las reglas de integridad R4/R5
db.createCollection("pedidos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_pedido", "fecha_pedido", "forma_pago", "estado", "cliente", "lineas", "total"],
      properties: {
        id_pedido: {
          bsonType: "int",
          description: "Identificador numérico original de PostgreSQL"
        },
        fecha_pedido: {
          bsonType: "date",
          description: "Fecha y hora de emisión del pedido"
        },
        forma_pago: {
          enum: ["EFECTIVO", "TARJETA", "TRANSFERENCIA"],
          description: "Dominio cerrado de formas de pago"
        },
        estado: {
          enum: ["PENDIENTE", "EN_PREPARACION", "ENTREGADO", "CANCELADO"],
          description: "Estado operativo del pedido"
        },
        cliente: {
          bsonType: "object",
          required: ["id_cliente", "nombre", "correo_electronico"],
          properties: {
            id_cliente: { bsonType: "int" },
            nombre: { bsonType: "string" },
            correo_electronico: { bsonType: "string" }
          }
        },
        lineas: {
          bsonType: "array",
          minItems: 1,
          description: "Arreglo de renglones de pedido (embebidos)",
          items: {
            bsonType: "object",
            required: ["id_producto", "nombre", "cantidad", "precio_unitario", "subtotal"],
            properties: {
              id_producto: { bsonType: "int" },
              nombre: { bsonType: "string" },
              cantidad: {
                bsonType: "int",
                minimum: 1,
                description: "Cantidad estrictamente mayor a 0 (Regla R5)"
              },
              precio_unitario: {
                bsonType: "number",
                minimum: 0,
                description: "Precio unitario no negativo al momento de compra (Regla R4/R5)"
              },
              subtotal: {
                bsonType: "number",
                minimum: 0
              }
            }
          }
        },
        total: {
          bsonType: "number",
          minimum: 0,
          description: "Total general del pedido en pesos argentinos"
        }
      }
    }
  }
});

// 4. Inserción masiva de los 5 pedidos de Food Store mediante insertMany()
const pedidosFoodStore = [
  {
    id_pedido: NumberInt(1),
    fecha_pedido: new Date("2026-10-15T12:30:00Z"),
    forma_pago: "TARJETA",
    estado: "ENTREGADO",
    cliente: {
      id_cliente: NumberInt(1),
      nombre: "Juan Pérez",
      correo_electronico: "juan.perez@email.com"
    },
    lineas: [
      {
        id_producto: NumberInt(1),
        nombre: "Hamburguesa Clásica",
        cantidad: NumberInt(2),
        precio_unitario: 4500.00,
        subtotal: 9000.00
      },
      {
        id_producto: NumberInt(3),
        nombre: "Papas Fritas Medianas",
        cantidad: NumberInt(1),
        precio_unitario: 2200.00,
        subtotal: 2200.00
      },
      {
        id_producto: NumberInt(4),
        nombre: "Gaseosa Cola 500ml",
        cantidad: NumberInt(2),
        precio_unitario: 1500.00,
        subtotal: 3000.00
      }
    ],
    total: 14200.00
  },
  {
    id_pedido: NumberInt(2),
    fecha_pedido: new Date("2026-10-16T13:15:00Z"),
    forma_pago: "EFECTIVO",
    estado: "PENDIENTE",
    cliente: {
      id_cliente: NumberInt(2),
      nombre: "María Gómez",
      correo_electronico: "maria.gomez@email.com"
    },
    lineas: [
      {
        id_producto: NumberInt(1),
        nombre: "Hamburguesa Clásica",
        cantidad: NumberInt(1),
        precio_unitario: 4500.00,
        subtotal: 4500.00
      },
      {
        id_producto: NumberInt(4),
        nombre: "Gaseosa Cola 500ml",
        cantidad: NumberInt(1),
        precio_unitario: 1500.00,
        subtotal: 1500.00
      }
    ],
    total: 6000.00
  },
  {
    id_pedido: NumberInt(3),
    fecha_pedido: new Date("2026-10-16T20:45:00Z"),
    forma_pago: "TRANSFERENCIA",
    estado: "ENTREGADO",
    cliente: {
      id_cliente: NumberInt(3),
      nombre: "Carlos López",
      correo_electronico: "carlos.lopez@email.com"
    },
    lineas: [
      {
        id_producto: NumberInt(2),
        nombre: "Hamburguesa Doble Queso",
        cantidad: NumberInt(2),
        precio_unitario: 6200.00,
        subtotal: 12400.00
      },
      {
        id_producto: NumberInt(5),
        nombre: "Cerveza Artesanal 500ml",
        cantidad: NumberInt(2),
        precio_unitario: 2800.00,
        subtotal: 5600.00
      }
    ],
    total: 18000.00
  },
  {
    id_pedido: NumberInt(4),
    fecha_pedido: new Date("2026-10-17T21:10:00Z"),
    forma_pago: "TARJETA",
    estado: "CANCELADO",
    cliente: {
      id_cliente: NumberInt(1),
      nombre: "Juan Pérez",
      correo_electronico: "juan.perez@email.com"
    },
    lineas: [
      {
        id_producto: NumberInt(1),
        nombre: "Hamburguesa Clásica",
        cantidad: NumberInt(1),
        precio_unitario: 4500.00,
        subtotal: 4500.00
      },
      {
        id_producto: NumberInt(2),
        nombre: "Hamburguesa Doble Queso",
        cantidad: NumberInt(1),
        precio_unitario: 6200.00,
        subtotal: 6200.00
      }
    ],
    total: 10700.00
  },
  {
    id_pedido: NumberInt(5),
    fecha_pedido: new Date("2026-10-18T14:00:00Z"),
    forma_pago: "TRANSFERENCIA",
    estado: "ENTREGADO",
    cliente: {
      id_cliente: NumberInt(2),
      nombre: "María Gómez",
      correo_electronico: "maria.gomez@email.com"
    },
    lineas: [
      {
        id_producto: NumberInt(3),
        nombre: "Papas Fritas Medianas",
        cantidad: NumberInt(2),
        precio_unitario: 2200.00,
        subtotal: 4400.00
      },
      {
        id_producto: NumberInt(4),
        nombre: "Gaseosa Cola 500ml",
        cantidad: NumberInt(2),
        precio_unitario: 1500.00,
        subtotal: 3000.00
      }
    ],
    total: 7400.00
  }
];

const resultado = db.pedidos.insertMany(pedidosFoodStore);
print(`✓ Migración exitosa: ${resultado.insertedIds ? Object.keys(resultado.insertedIds).length : 5} pedidos insertados en la colección 'pedidos'.`);

// 5. Creación de índices multikey y compuestos para optimizar consultas de la Parte 2
db.pedidos.createIndex({ id_pedido: 1 }, { unique: true });
db.pedidos.createIndex({ estado: 1 });
db.pedidos.createIndex({ "lineas.id_producto": 1 });
db.pedidos.createIndex({ total: 1 });
print("✓ Índices creados satisfactoriamente.");
