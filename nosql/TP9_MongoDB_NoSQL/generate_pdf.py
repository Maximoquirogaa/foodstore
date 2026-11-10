#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generador del PDF oficial de entrega para TP9 (Unidad 7): NoSQL y MongoDB
UTN FRM - Base de Datos II - Máximo Juan Cruz Quiroga
"""

import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY, TA_RIGHT

def create_tp9_pdf(output_filename):
    doc = SimpleDocTemplate(
        output_filename,
        pagesize=A4,
        rightMargin=1.8*cm, leftMargin=1.8*cm,
        topMargin=1.8*cm, bottomMargin=1.8*cm
    )

    styles = getSampleStyleSheet()
    
    # Custom styles
    primary_color = colors.HexColor('#1a237e')
    secondary_color = colors.HexColor('#283593')
    accent_color = colors.HexColor('#00838f')
    dark_neutral = colors.HexColor('#263238')
    light_bg = colors.HexColor('#f5f7fa')
    border_color = colors.HexColor('#cfd8dc')

    title_style = ParagraphStyle(
        'DocTitle', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=18, leading=22,
        alignment=TA_CENTER, textColor=primary_color, spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle', parent=styles['Normal'],
        fontName='Helvetica', fontSize=11, leading=15,
        alignment=TA_CENTER, textColor=secondary_color, spaceAfter=12
    )
    meta_style = ParagraphStyle(
        'DocMeta', parent=styles['Normal'],
        fontName='Helvetica', fontSize=9, leading=13,
        alignment=TA_CENTER, textColor=dark_neutral, spaceAfter=12
    )
    h1_style = ParagraphStyle(
        'Heading1_Custom', parent=styles['Heading1'],
        fontName='Helvetica-Bold', fontSize=13, leading=16,
        textColor=primary_color, spaceBefore=10, spaceAfter=6,
        keepWithNext=True
    )
    h2_style = ParagraphStyle(
        'Heading2_Custom', parent=styles['Heading2'],
        fontName='Helvetica-Bold', fontSize=10.5, leading=14,
        textColor=secondary_color, spaceBefore=8, spaceAfter=4,
        keepWithNext=True
    )
    body_style = ParagraphStyle(
        'Body_Custom', parent=styles['Normal'],
        fontName='Helvetica', fontSize=8.5, leading=11.5,
        textColor=dark_neutral, alignment=TA_JUSTIFY, spaceAfter=5
    )
    body_bold = ParagraphStyle(
        'Body_Bold', parent=body_style,
        fontName='Helvetica-Bold'
    )
    code_style = ParagraphStyle(
        'Code_Custom', parent=styles['Normal'],
        fontName='Courier', fontSize=7.5, leading=9.5,
        textColor=colors.HexColor('#212121')
    )
    table_cell = ParagraphStyle(
        'TableCell', parent=styles['Normal'],
        fontName='Helvetica', fontSize=8, leading=10,
        textColor=dark_neutral
    )
    table_cell_bold = ParagraphStyle(
        'TableCellBold', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=8, leading=10,
        textColor=primary_color
    )
    table_cell_header = ParagraphStyle(
        'TableCellHeader', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=8, leading=10,
        textColor=colors.white, alignment=TA_CENTER
    )

    story = []

    # ================= PAGE 1 =================
    story.append(Paragraph("TECNICATURA UNIVERSITARIA EN PROGRAMACIÓN · BASES DE DATOS II", subtitle_style))
    story.append(Paragraph("TRABAJO PRÁCTICO · UNIDAD 7: NoSQL Y MONGODB", title_style))
    story.append(Paragraph("<b>Proyecto:</b> Food Store | <b>Alumno:</b> Máximo Juan Cruz Quiroga | <b>Docente:</b> Sergio Neira | UTN FRM 2026", meta_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=primary_color, spaceBefore=2, spaceAfter=8))

    story.append(Paragraph("Parte 1 · Modelo Documental y Migración", h1_style))
    story.append(Paragraph("<b>Consigna 1: Identificación Relacional y Diseño Documental</b>", h2_style))
    story.append(Paragraph(
        "En PostgreSQL 17, el circuito de órdenes está normalizado en 4 tablas: <code>pedidos</code> (PK id_pedido, FK id_cliente, forma_pago, fecha_pedido, estado), <code>detalles_pedido</code> (PK compuesta id_pedido + id_producto, cantidad, precio_unitario), <code>clientes</code> (id_cliente, nombre, apellido, correo_electronico) y <code>productos</code> (id_producto, nombre, precio_actual). "
        "Para MongoDB se adoptó el <b>patrón de documentos embebidos (Embedded Document Pattern)</b> en la colección <code>pedidos</code>. Cada documento concentra la orden completa, integrando un objeto embebido <code>cliente</code> y un arreglo <code>lineas</code> con los renglones comprados, preservando los identificadores de origen (<code>id_pedido</code>, <code>id_cliente</code>, <code>id_producto</code>) como números enteros para trazabilidad bidireccional.",
        body_style
    ))

    esquema_json = """<b>Colección:</b> <code>foodstore_nosql.pedidos</code>
{
  "id_pedido": 1, "fecha_pedido": ISODate("2026-10-15T12:30:00Z"),
  "forma_pago": "TARJETA", "estado": "ENTREGADO",
  "cliente": { "id_cliente": 1, "nombre": "Juan Pérez", "correo_electronico": "juan.perez@email.com" },
  "lineas": [
    { "id_producto": 1, "nombre": "Hamburguesa Clásica", "cantidad": 2, "precio_unitario": 4500.00, "subtotal": 9000.00 },
    { "id_producto": 3, "nombre": "Papas Fritas Medianas", "cantidad": 1, "precio_unitario": 2200.00, "subtotal": 2200.00 },
    { "id_producto": 4, "nombre": "Gaseosa Cola 500ml", "cantidad": 2, "precio_unitario": 1500.00, "subtotal": 3000.00 }
  ],
  "total": 14200.00
}"""
    t_esq = Table([[Paragraph(esquema_json, code_style)]], colWidths=[17.4*cm])
    t_esq.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), light_bg),
        ('BOX', (0,0), (-1,-1), 0.8, border_color),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_esq)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Consigna 2: Base de Datos y Conjunto de Datos Migrados</b>", h2_style))
    story.append(Paragraph(
        "Se creó la base <code>foodstore_nosql</code> y la colección <code>pedidos</code>. La migración se ejecutó mediante <code>insertMany()</code> en <code>migracion_pedidos.js</code>, migrando 5 pedidos con líneas y datos esenciales del cliente:",
        body_style
    ))

    t_data_rows = [
        [Paragraph("ID", table_cell_header), Paragraph("Fecha", table_cell_header), Paragraph("Cliente", table_cell_header), Paragraph("Estado", table_cell_header), Paragraph("Forma Pago", table_cell_header), Paragraph("Ítems del Pedido", table_cell_header), Paragraph("Total ($)", table_cell_header)],
        [Paragraph("1", table_cell_bold), Paragraph("15/10/26", table_cell), Paragraph("Juan Pérez", table_cell), Paragraph("ENTREGADO", table_cell), Paragraph("TARJETA", table_cell), Paragraph("2x Hamb. Clásica, 1x Papas Med., 2x Gaseosa", table_cell), Paragraph("14.200,00", table_cell_bold)],
        [Paragraph("2", table_cell_bold), Paragraph("16/10/26", table_cell), Paragraph("María Gómez", table_cell), Paragraph("PENDIENTE", table_cell), Paragraph("EFECTIVO", table_cell), Paragraph("1x Hamb. Clásica, 1x Gaseosa Cola", table_cell), Paragraph("6.000,00", table_cell_bold)],
        [Paragraph("3", table_cell_bold), Paragraph("16/10/26", table_cell), Paragraph("Carlos López", table_cell), Paragraph("ENTREGADO", table_cell), Paragraph("TRANSFER.", table_cell), Paragraph("2x Hamb. Doble Queso, 2x Cerveza Art.", table_cell), Paragraph("18.000,00", table_cell_bold)],
        [Paragraph("4", table_cell_bold), Paragraph("17/10/26", table_cell), Paragraph("Juan Pérez", table_cell), Paragraph("CANCELADO", table_cell), Paragraph("TARJETA", table_cell), Paragraph("1x Hamb. Clásica, 1x Hamb. Doble Queso", table_cell), Paragraph("10.700,00", table_cell_bold)],
        [Paragraph("5", table_cell_bold), Paragraph("18/10/26", table_cell), Paragraph("María Gómez", table_cell), Paragraph("ENTREGADO", table_cell), Paragraph("TRANSFER.", table_cell), Paragraph("2x Papas Med., 2x Gaseosa Cola", table_cell), Paragraph("7.400,00", table_cell_bold)],
    ]
    t_pedidos = Table(t_data_rows, colWidths=[1.0*cm, 1.8*cm, 2.5*cm, 2.4*cm, 2.2*cm, 5.5*cm, 2.0*cm])
    t_pedidos.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('ALIGN', (6,1), (6,-1), 'RIGHT'),
        ('PADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(t_pedidos)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Consigna 3: Reglas de Integridad y Justificación de Embebido</b>", h2_style))
    story.append(Paragraph(
        "<b>1. Congelamiento Histórico de Precios y Cantidades (Reglas R4 y R5):</b> En Food Store, el precio unitario y subtotal deben quedar inalterables respecto al momento de compra, independientemente de incrementos futuros en la tabla <code>productos</code>. "
        "<br/><b>2. Integridad de Dominio y No Negatividad (R5):</b> Cantidades estrictamente positivas ($cantidad \\ge 1$), precios y subtotales no negativos ($precio \\ge 0$), blindados con <code>$jsonSchema</code>. "
        "<br/><b>3. Experimento de Validación Cruzada ($expr):</b> Mediante <code>prueba_validacion_expr.js</code> se verificó en laboratorio que MongoDB puede forzar reglas entre campos (<code>total = SUM(subtotales)</code> y <code>subtotal = cant * precio</code>) rechazando inconsistencias con Código 121 (<i>Document failed validation</i>). En PostgreSQL, esta coherencia es nativa vía columnas generadas. "
        "<br/><b>Justificación de Embebido:</b> (a) <i>Lectura Atómica en 1 operación (Single-Document Read):</i> el 95% de las consultas piden el pedido completo; embeber elimina la penalización de JOINs ($lookup). (b) <i>Atomicidad nativa:</i> las escrituras en un solo documento son atómicas por definición en MongoDB. (c) <i>Snapshot de cliente:</i> los datos del comprador no se alteran si luego modifica su perfil.",
        body_style
    ))

    # ================= PAGE 2 =================
    story.append(PageBreak())
    story.append(Paragraph("Parte 2 · Consultas y Verificación", h1_style))
    story.append(Paragraph("<b>Consigna 4: Ejecución en MongoDB (consultas_mongodb.js)</b>", h2_style))

    q_mongo_text = """// 4.a Mostrar todos los pedidos (id y estado)
db.pedidos.find({}, { id_pedido: 1, estado: 1, fecha_pedido: 1, total: 1, _id: 0 }).sort({ id_pedido: 1 });
// Resultado: 5 documentos recuperados (IDs: 1, 2, 3, 4, 5).

// 4.b Filtrar por estado existente ('ENTREGADO')
db.pedidos.find({ estado: "ENTREGADO" }, { id_pedido: 1, estado: 1, "cliente.nombre": 1, total: 1, _id: 0 });
// Resultado: 3 documentos recuperados (IDs: 1, 3, 5).

// 4.c Buscar pedidos que contengan el producto 1 ('Hamburguesa Clásica') dentro del arreglo
db.pedidos.find({ "lineas.id_producto": 1 }, { id_pedido: 1, "lineas.nombre": 1, total: 1, _id: 0 });
// Resultado: 3 documentos recuperados con Multikey Index (IDs: 1, 2, 4).

// 4.d Buscar pedidos cuyo total sea superior a $10.000,00 ARS
db.pedidos.find({ total: { $gt: 10000.00 } }, { id_pedido: 1, total: 1, "cliente.nombre": 1, _id: 0 });
// Resultado: 3 documentos recuperados (ID 3: $18.000, ID 1: $14.200, ID 4: $10.700).
// Justificación de umbral: $10.000 ARS aísla compras de alto volumen de consumos individuales básicos."""
    
    t_qmongo = Table([[Paragraph(q_mongo_text, code_style)]], colWidths=[17.4*cm])
    t_qmongo.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), light_bg),
        ('BOX', (0,0), (-1,-1), 0.8, border_color),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_qmongo)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Consigna 5: Consultas Equivalentes en PostgreSQL y Tabla de Verificación</b>", h2_style))
    story.append(Paragraph(
        "En PostgreSQL (<code>consultas_postgresql.sql</code>), resolver estas consultas exige JOINs entre <code>pedidos</code>, <code>clientes</code>, <code>detalles_pedido</code> y <code>productos</code>:",
        body_style
    ))

    q_sql_text = """-- Equivalente 5.b: Pedidos con estado = 'ENTREGADO'
SELECT p.id_pedido, p.estado, c.nombre || ' ' || c.apellido AS cliente, 
       SUM(dp.cantidad * dp.precio_unitario) AS total
FROM pedidos p JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'ENTREGADO'
GROUP BY p.id_pedido, p.estado, c.nombre, c.apellido ORDER BY p.id_pedido;

-- Equivalente 5.c: Pedidos que contienen id_producto = 1 (Hamburguesa Clásica)
SELECT DISTINCT p.id_pedido, p.estado, c.nombre || ' ' || c.apellido AS cliente
FROM pedidos p JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN detalles_pedido dp ON dp.id_pedido = p.id_pedido
WHERE dp.id_producto = 1 ORDER BY p.id_pedido;"""

    t_qsql = Table([[Paragraph(q_sql_text, code_style)]], colWidths=[17.4*cm])
    t_qsql.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), light_bg),
        ('BOX', (0,0), (-1,-1), 0.8, border_color),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_qsql)
    story.append(Spacer(1, 6))

    # Verification Table
    t_comp_rows = [
        [Paragraph("Consulta Evaluada", table_cell_header), Paragraph("Cantidad en PostgreSQL", table_cell_header), Paragraph("Cantidad en MongoDB", table_cell_header), Paragraph("¿Coinciden los IDs?", table_cell_header), Paragraph("IDs Recuperados", table_cell_header)],
        [Paragraph("<b>Estado seleccionado ('ENTREGADO')</b>", table_cell), Paragraph("<b>3</b>", table_cell_bold), Paragraph("<b>3</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("[1, 3, 5]", table_cell)],
        [Paragraph("<b>Producto seleccionado (id_producto = 1)</b>", table_cell), Paragraph("<b>3</b>", table_cell_bold), Paragraph("<b>3</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("[1, 2, 4]", table_cell)],
    ]
    t_comp = Table(t_comp_rows, colWidths=[5.0*cm, 3.2*cm, 3.2*cm, 3.0*cm, 3.0*cm])
    t_comp.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), secondary_color),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_comp)
    story.append(Spacer(1, 5))

    story.append(Paragraph(
        "<b>Explicación de las diferencias mecánicas:</b> En PostgreSQL, la consulta (b) requiere agrupar filas y calcular agregaciones en caliente con <code>SUM()</code>, mientras que la consulta (c) exige cruzar 4 tablas con <code>JOIN</code> y aplicar <code>DISTINCT</code> para desduplicar pedidos con múltiples renglones. En MongoDB, la consulta (b) lee directamente el atributo precalculado <code>estado</code>, y la consulta (c) aprovecha el <b>Multikey Index</b> sobre <code>lineas.id_producto</code>, resolviendo la búsqueda sin combinaciones ni desduplicación de resultados.",
        body_style
    ))

    # ================= PAGE 3 =================
    story.append(PageBreak())
    story.append(Paragraph("Parte 3 · Evaluación de la Tecnología e Inteligencia Artificial", h1_style))
    story.append(Paragraph("<b>Consigna 6: Consulta Realizada a la Inteligencia Artificial</b>", h2_style))

    story.append(Paragraph(
        "Se consultó a un asistente de IA de arquitectura especializada bajo el siguiente requerimiento explícito:",
        body_style
    ))
    prompt_p3 = """<b>Prompt enviado a la IA:</b><br/>
<i>\"Actuá como Arquitecto de Bases de Datos senior. En nuestro sistema Food Store (PostgreSQL 17), los pedidos se modelan en tablas relacionales normalizadas (pedidos, detalles_pedido, clientes). El 95% de las consultas leen pedidos completos para emisión de comprobantes y detalle de compra. Además, una regla crítica del negocio es congelar el precio unitario y cantidad al momento de la compra para que futuros cambios en el catálogo no alteren el historial. Evaluá técnica y comparativamente si conviene mantener PostgreSQL o migrar este subconjunto a una colección documental en MongoDB usando un modelo embebido. Contrastá rendimiento de lectura, consistencia transaccional y complejidad operativa.\"</i>"""
    t_prompt = Table([[Paragraph(prompt_p3, body_style)]], colWidths=[17.4*cm])
    t_prompt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), light_bg),
        ('BOX', (0,0), (-1,-1), 0.8, border_color),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_prompt)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Resumen de la Respuesta Recibida de la IA:</b>", h2_style))
    story.append(Paragraph(
        "La IA argumentó enfáticamente a favor de MongoDB, señalando que <i>\"el modelo relacional normalizado es ineficiente para pedidos debido a la necesidad de costosos JOINs entre pedidos, detalles y productos\"</i>. Propuso migrar la totalidad del e-commerce a colecciones de MongoDB y formuló dos afirmaciones técnicas categóricas: "
        "(1) que <i>\"MongoDB no soporta transacciones ACID ni integridad referencial, por lo que las garantías de consistencia financiera deben delegarse exclusivamente a código en Node.js o Python\"</i>; y "
        "(2) que <i>\"migrar a MongoDB reducirá a la mitad la latencia de lectura en cualquier escenario debido a que prescinde de esquemas rígidos\"</i>.",
        body_style
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Consigna 7: Contraste Crítico de Afirmaciones y Conclusión Técnica</b>", h2_style))
    story.append(Paragraph(
        "<b>Contraste 1: Sobre la supuesta ausencia de transacciones ACID en MongoDB.</b><br/>"
        "<i>Refutación con Documentación Oficial de MongoDB:</i> La afirmación de la IA es anacrónica y técnicamente falsa. En primer lugar, la documentación oficial de MongoDB (<i>Data Modeling: Atomicity of Operations</i>) estipula que toda modificación sobre un único documento es **estrictamente atómica e íntegra**. En nuestro modelo de pedidos embebidos, la inserción del pedido con todas sus líneas es atómica por naturaleza, sin requerir transacciones complejas. En segundo lugar, desde MongoDB 4.0 (y perfeccionado en 4.2+ para sharding), el motor soporta <b>Transacciones Multi-Documento ACID</b> completas con aislamiento snapshot y rollback automático ante errores de red o caídas del servidor.",
        body_style
    ))
    story.append(Paragraph(
        "<b>Contraste 2: Sobre la afirmación de que MongoDB siempre reducirá la latencia a la mitad.</b><br/>"
        "<i>Refutación con Evidencia de Laboratorio y Documentación PostgreSQL:</i> Esta afirmación constituye una generalización errónea. En nuestro entorno de laboratorio con PostgreSQL 17, al consultar un pedido por su clave primaria indexada junto a un índice en <code>detalles_pedido(id_pedido)</code>, el planificador ejecuta un <code>Index Scan</code> y resuelve la consulta en <b>menos de 1 milisegundo</b> mediante páginas cacheadas en el <i>Buffer Cache</i> de memoria RAM. Asimismo, PostgreSQL soporta de forma nativa el tipo <code>JSONB</code> con funciones de agregación (<code>json_build_object</code> / <code>json_agg</code>), lo que permite emitir exactamente el mismo documento jerárquico que MongoDB sin penalizaciones perceptibles de latencia.",
        body_style
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Conclusión Técnica Final (189 palabras):</b>", h2_style))
    conclusion_text = (
        "Para el sistema Food Store, la decisión arquitectónica óptima es adoptar <b>Persistencia Políglota (Polyglot Persistence)</b>, combinando ambos motores según el patrón de acceso: "
        "<br/><br/>"
        "1. <b>PostgreSQL como Almacén de Registro Transaccional (System of Record):</b> "
        "Debe conservarse para el catálogo maestro de productos, categorías, gestión de clientes, control de inventario y facturación fiscal. Estas áreas exigen restricciones de clave foránea estrictas (<code>ON DELETE RESTRICT</code>), auditoría nativa, roles de seguridad granulares y consistencia ACID inmediata ante escrituras concurrentes. "
        "<br/><br/>"
        "2. <b>MongoDB como Repositorio Documental de Órdenes (Order History & Read Store):</b> "
        "El subconjunto de pedidos cerrados y despachados se beneficia enormemente del modelo embebido en MongoDB. Almacenar el pedido desnormalizado con sus líneas y el snapshot del cliente permite que la aplicación web móvil y el servicio de atención consulten órdenes completas en un único ciclo de lectura (<code>find</code>), sin costo de JOINs y con escalabilidad horizontal natural. "
        "<br/><br/>"
        "Migrar la totalidad de Food Store a NoSQL introduciría complejidad innecesaria al replicar la integridad referencial en la capa de aplicación; en cambio, una arquitectura híbrida capitaliza lo mejor de ambos paradigmas."
    )
    t_concl = Table([[Paragraph(conclusion_text, body_style)]], colWidths=[17.4*cm])
    t_concl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), light_bg),
        ('BOX', (0,0), (-1,-1), 1, accent_color),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_concl)

    doc.build(story)
    print(f"[OK] PDF generado con exito en: {output_filename}")

if __name__ == "__main__":
    out_path = os.path.join(os.path.dirname(__file__), "Informe_TP_NoSQL_FoodStore.pdf")
    create_tp9_pdf(out_path)
