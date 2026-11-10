#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generador del PDF oficial de entrega para TP10 (Unidad 8): Food Store en la Feria
UTN FRM - Base de Datos II - Alumno: Máximo Juan Cruz Quiroga
Cubre Consignas 1.a, 2.c, 3.a, 3.b y 3.c en exactamente 6 páginas.
"""

import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, HRFlowable
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY, TA_RIGHT

def build_pdf(filename):
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        rightMargin=1.6*cm, leftMargin=1.6*cm,
        topMargin=1.6*cm, bottomMargin=1.6*cm
    )

    styles = getSampleStyleSheet()

    # Colores corporativos de la cátedra
    primary = colors.HexColor('#1a237e')
    secondary = colors.HexColor('#283593')
    accent = colors.HexColor('#00838f')
    dark_neutral = colors.HexColor('#263238')
    light_bg = colors.HexColor('#f5f7fa')
    border_color = colors.HexColor('#cfd8dc')

    title_style = ParagraphStyle(
        'DocTitle', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=16, leading=20,
        alignment=TA_CENTER, textColor=primary, spaceAfter=2
    )
    subtitle_style = ParagraphStyle(
        'DocSubtitle', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=10, leading=13,
        alignment=TA_CENTER, textColor=secondary, spaceAfter=4
    )
    meta_style = ParagraphStyle(
        'DocMeta', parent=styles['Normal'],
        fontName='Helvetica', fontSize=8.5, leading=11,
        alignment=TA_CENTER, textColor=dark_neutral, spaceAfter=8
    )
    h1_style = ParagraphStyle(
        'H1_Custom', parent=styles['Heading1'],
        fontName='Helvetica-Bold', fontSize=12, leading=15,
        textColor=primary, spaceBefore=6, spaceAfter=4,
        keepWithNext=True
    )
    h2_style = ParagraphStyle(
        'H2_Custom', parent=styles['Heading2'],
        fontName='Helvetica-Bold', fontSize=9.5, leading=12,
        textColor=secondary, spaceBefore=5, spaceAfter=3,
        keepWithNext=True
    )
    body_style = ParagraphStyle(
        'Body_Custom', parent=styles['Normal'],
        fontName='Helvetica', fontSize=8, leading=10.5,
        textColor=dark_neutral, alignment=TA_JUSTIFY, spaceAfter=4
    )
    code_style = ParagraphStyle(
        'Code_Custom', parent=styles['Normal'],
        fontName='Courier', fontSize=7, leading=8.5,
        textColor=colors.HexColor('#212121')
    )
    table_cell = ParagraphStyle(
        'TableCell', parent=styles['Normal'],
        fontName='Helvetica', fontSize=7.5, leading=9.5,
        textColor=dark_neutral
    )
    table_cell_bold = ParagraphStyle(
        'TableCellBold', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=7.5, leading=9.5,
        textColor=primary
    )
    table_cell_header = ParagraphStyle(
        'TableHeader', parent=styles['Normal'],
        fontName='Helvetica-Bold', fontSize=7.5, leading=9.5,
        textColor=colors.white, alignment=TA_CENTER
    )

    story = []

    # =========================================================================
    # PÁGINA 1: Portada y Consigna 1.a (Qué datos viajan a la tablet)
    # =========================================================================
    story.append(Paragraph("TECNICATURA UNIVERSITARIA EN PROGRAMACIÓN · BASES DE DATOS II", subtitle_style))
    story.append(Paragraph("TRABAJO PRÁCTICO N.º 10 (UNIDAD 8): FOOD STORE EN LA FERIA", title_style))
    story.append(Paragraph("<b>La base de la tablet y el cierre de la capa de datos</b>", subtitle_style))
    story.append(Paragraph("<b>Alumno:</b> Máximo Juan Cruz Quiroga | <b>Docente:</b> Sergio Neira | UTN FRM 2026", meta_style))
    story.append(HRFlowable(width="100%", thickness=1.2, color=primary, spaceBefore=1, spaceAfter=6))

    story.append(Paragraph("Consigna 1 · La base de la tablet", h1_style))
    story.append(Paragraph("<b>1.a Qué datos viajan a la tablet</b>", h2_style))
    story.append(Paragraph(
        "Para garantizar la continuidad operativa del food truck en ferias o eventos sin conexión a Internet, la tablet "
        "móvil almacena una copia local en <b>SQLite 3 (modo STRICT)</b>. Sin embargo, no todos los datos del servidor central deben "
        "viajar al dispositivo móvil. La siguiente tabla sintetiza la partición de atributos entre el servidor y el cliente:",
        body_style
    ))

    t1a_rows = [
        [Paragraph("Columna / Atributo", table_cell_header), Paragraph("¿Viaja?", table_cell_header), Paragraph("Columna en SQLite", table_cell_header), Paragraph("Justificación Técnica y Criterio de Selección", table_cell_header)],
        [Paragraph("<b>id_producto</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("<code>producto_cache.id</code>", table_cell), Paragraph("Clave primaria obligatoria para identificar unívocamente cada ítem al armar borradores de pedido.", table_cell)],
        [Paragraph("<b>nombre</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("<code>producto_cache.nombre</code>", table_cell), Paragraph("Requerido en la interfaz para que el vendedor visualice qué comanda está cargando.", table_cell)],
        [Paragraph("<b>precio_actual</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("<code>producto_cache.precio_centavos</code>", table_cell), Paragraph("Viaja multiplicado por 100 como entero para eliminar imprecisiones de coma flotante en SQLite.", table_cell)],
        [Paragraph("<b>stock</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("<code>producto_cache.stock_visto</code>", table_cell), Paragraph("Permite al operador advertir anticipadamente al comensal si el stock está próximo a agotarse.", table_cell)],
        [Paragraph("<b>activo</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("<code>disponible</code> / <code>eliminado</code>", table_cell), Paragraph("Baja lógica: los productos descontinuados (activo=false) se ocultan del catálogo disponible.", table_cell)],
        [Paragraph("<b>fecha_copia</b>", table_cell_bold), Paragraph("<b>SÍ</b>", table_cell_bold), Paragraph("<code>producto_cache.fecha_copia</code>", table_cell), Paragraph("Marca de tiempo para auditar la frescura del catálogo recibido desde PostgreSQL.", table_cell)],
        [Paragraph("<b>id_categoria</b>", table_cell), Paragraph("NO", table_cell), Paragraph("—", table_cell), Paragraph("Innecesario en la venta rápida en feria; minimiza el payload del CSV y simplifica las consultas.", table_cell)],
        [Paragraph("<b>usuarios / passwords</b>", table_cell), Paragraph("NO", table_cell), Paragraph("—", table_cell), Paragraph("<b>Mínimo Privilegio:</b> Nunca deben viajar credenciales ni hashes de contraseñas a terminales móviles.", table_cell)],
        [Paragraph("<b>clientes / correos</b>", table_cell), Paragraph("NO", table_cell), Paragraph("—", table_cell), Paragraph("<b>Privacidad:</b> La venta al paso en feria no requiere acceso al padrón general de clientes registrados.", table_cell)],
        [Paragraph("<b>pedidos / ventas</b>", table_cell), Paragraph("NO", table_cell), Paragraph("—", table_cell), Paragraph("El historial contable reside exclusivamente en PostgreSQL y MongoDB; la tablet solo gestiona borradores.", table_cell)],
    ]
    t1a = Table(t1a_rows, colWidths=[3.2*cm, 1.4*cm, 3.8*cm, 9.4*cm])
    t1a.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('ALIGN', (1,1), (1,-1), 'CENTER'),
        ('PADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(t1a)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Regla de Oro: «El móvil propone, el servidor dispone»</b>", h2_style))
    story.append(Paragraph(
        "En la arquitectura de Food Store, <b>PostgreSQL es la única e indiscutible fuente de verdad</b>. "
        "La base de datos SQLite en la tablet opera como una caché transaccional temporal de solo lectura para el catálogo y "
        "un almacén de borradores locales. La aplicación móvil jamás descuenta stock en el servidor ni confirma ventas firmes: "
        "el estado <code>SIMULADO_APROBADO</code> es una pre-validación matemática local. Los precios finales, la deducción efectiva "
        "de existencias y la facturación fiscal son potestad exclusiva y centralizada de PostgreSQL.",
        body_style
    ))

    # =========================================================================
    # PÁGINA 2: Consigna 2.c (Sincronizar y resolver: Casos C2 a C6)
    # =========================================================================
    story.append(PageBreak())
    story.append(Paragraph("Consigna 2 · Sincronizar y resolver", h1_style))
    story.append(Paragraph("<b>2.c Simulación y Verificación de los Casos C2 a C6 del Semáforo</b>", h2_style))
    story.append(Paragraph(
        "Se prepararon escenarios intencionales en una copia de pruebas de PostgreSQL, exportando una segunda instantánea "
        "(<code>servidor_snapshot_2c.csv</code>) donde el producto 1 (Hamburguesa Clásica) subió de $4.500 a $4.800 y el producto 3 "
        "(Papas Fritas) sufrió baja lógica. El algoritmo del semáforo (<code>semaforo.sql</code>) arrojó los siguientes resultados:",
        body_style
    ))

    t2c_rows = [
        [Paragraph("Caso", table_cell_header), Paragraph("UUID Solicitud", table_cell_header), Paragraph("Situación Preparada", table_cell_header), Paragraph("Estado Semáforo", table_cell_header), Paragraph("Motivo Registrado / Resolución", table_cell_header)],
        [Paragraph("<b>C2-a</b>", table_cell_bold), Paragraph("<code>c2-solicitud-1</code>", table_cell), Paragraph("Borrador con precio anterior ($4.500) frente a nuevo precio ($4.800).", table_cell), Paragraph("<b>CONFLICTO</b>", table_cell_bold), Paragraph("Cambió el precio observado en centavos.", table_cell)],
        [Paragraph("<b>C2-b</b>", table_cell_bold), Paragraph("<code>c2-solicitud-2</code>", table_cell), Paragraph("El cliente acepta el precio: se actualiza borrador a $4.800.", table_cell), Paragraph("<b>SIMULADO_APROBADO</b>", table_cell_bold), Paragraph("Precio, disponibilidad y stock coinciden plenamente.", table_cell)],
        [Paragraph("<b>C3</b>", table_cell_bold), Paragraph("<code>c3-solicitud</code>", table_cell), Paragraph("Borrador por 99 unidades (stock real en servidor es 35).", table_cell), Paragraph("<b>RECHAZADO</b>", table_cell_bold), Paragraph("Stock insuficiente para satisfacer la cantidad demandada.", table_cell)],
        [Paragraph("<b>C4</b>", table_cell_bold), Paragraph("<code>c4-solicitud</code>", table_cell), Paragraph("Borrador con producto 3, dado de baja lógica (disponible=0).", table_cell), Paragraph("<b>RECHAZADO</b>", table_cell_bold), Paragraph("Producto no disponible / dado de baja.", table_cell)],
        [Paragraph("<b>C5</b>", table_cell_bold), Paragraph("<code>c5-solicitud</code>", table_cell), Paragraph("Borrador con catálogo actualizado sin discrepancias.", table_cell), Paragraph("<b>SIMULADO_APROBADO</b>", table_cell_bold), Paragraph("Precio, disponibilidad y stock coinciden.", table_cell)],
        [Paragraph("<b>C6</b>", table_cell_bold), Paragraph("<code>c5-solicitud</code> (bis)", table_cell), Paragraph("Reintento de reenvío con el mismo identificador UUID.", table_cell), Paragraph("<b>RECHAZO DE PK</b>", table_cell_bold), Paragraph("UNIQUE constraint failed: solicitud_uuid duplicada.", table_cell)],
    ]
    t2c = Table(t2c_rows, colWidths=[1.2*cm, 2.6*cm, 5.0*cm, 3.4*cm, 5.6*cm])
    t2c.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('ALIGN', (3,1), (3,-1), 'CENTER'),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t2c)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Demostración de Inmutabilidad en PostgreSQL (verificar_sin_cambios_2c.sql)</b>", h2_style))
    story.append(Paragraph(
        "Al finalizar las pruebas del semáforo en SQLite, se ejecutó la consulta de auditoría en la base central de PostgreSQL: "
        "<code>SELECT COUNT(*) FROM pedidos;</code> y <code>SELECT id_producto, stock FROM productos;</code>. "
        "<b>El resultado fue contundente: cero filas añadidas y stock intacto</b>. La tablet jamás alteró los datos del servidor central.",
        body_style
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Idempotencia y Protección Real en Sistemas Productivos (Parada 8)</b>", h2_style))
    story.append(Paragraph(
        "En un entorno productivo real, la protección probada en el Caso C6 debe residir en la <b>capa API transaccional de PostgreSQL</b>. "
        "Al recibir un paquete de sincronización, el backend debe registrar el <code>solicitud_uuid</code> dentro de una tabla de "
        "idempotencia bajo una transacción serializable. Si el UUID ya fue procesado, el servidor descarta el procesamiento duplicado y "
        "retorna de inmediato el comprobante previamente emitido, evitando descontar inventario dos veces o generar doble cobro al cliente.",
        body_style
    ))

    # =========================================================================
    # PÁGINA 3: Consigna 3.a (Mapa de la Capa de Datos Unificada)
    # =========================================================================
    story.append(PageBreak())
    story.append(Paragraph("Consigna 3 · Integrar y revisar", h1_style))
    story.append(Paragraph("<b>3.a Mapa de la Capa de Datos Unificada (Los Tres Motores de Food Store)</b>", h2_style))
    story.append(Paragraph(
        "Food Store consolida su arquitectura de datos mediante tres motores de persistencia especializados, articulados según "
        "sus ventajas operativas y patrones de acceso:",
        body_style
    ))

    t3a_rows = [
        [Paragraph("Motor de Base de Datos", table_cell_header), Paragraph("Base / Colección", table_cell_header), Paragraph("¿Qué datos almacena?", table_cell_header), Paragraph("Patrón de Acceso", table_cell_header), Paragraph("¿Manda? (Autoridad)", table_cell_header)],
        [
            Paragraph("<b>PostgreSQL 17</b><br/><i>(Relacional)</i>", table_cell_bold),
            Paragraph("<code>foodstore_dev</code>", table_cell),
            Paragraph("Catálogo maestro, precios de lista, stock real, clientes, usuarios, auditoría y pedidos confirmados.", table_cell),
            Paragraph("OLTP Transaccional con ACID estricto y claves foráneas.", table_cell),
            Paragraph("<b>SÍ (Fuente de Verdad).</b> Manda sobre catálogo, inventario y facturación.", table_cell_bold)
        ],
        [
            Paragraph("<b>MongoDB 7+ / 9+</b><br/><i>(NoSQL Documental)</i>", table_cell_bold),
            Paragraph("<code>foodstore_nosql<br/>.pedidos</code>", table_cell),
            Paragraph("Historial de pedidos cerrados con líneas embebidas y snapshot comercial inmutable del cliente.", table_cell),
            Paragraph("Lectura masiva (Single-Document Read) sin JOINs para apps móviles.", table_cell),
            Paragraph("<b>NO.</b> Es una copia derivada; ante cualquier discrepancia prevalece PostgreSQL.", table_cell)
        ],
        [
            Paragraph("<b>SQLite 3.50+</b><br/><i>(Embebido Móvil)</i>", table_cell_bold),
            Paragraph("<code>foodstore_movil<br/>.db</code>", table_cell),
            Paragraph("Caché local del catálogo (precios en centavos), borradores de comanda y cola del semáforo.", table_cell),
            Paragraph("Lectura y escritura local offline en la feria sin conexión a red.", table_cell),
            Paragraph("<b>Solo sobre sus borradores locales</b> mientras no se hayan transmitido.", table_cell)
        ],
    ]
    t3a = Table(t3a_rows, colWidths=[3.2*cm, 2.6*cm, 4.8*cm, 3.4*cm, 3.8*cm])
    t3a.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t3a)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Matriz de Autoridad y Flujo de Información entre Motores</b>", h2_style))
    t3b_rows = [
        [Paragraph("Dato / Atributo de Negocio", table_cell_header), Paragraph("Motor que Decide (Autoridad)", table_cell_header), Paragraph("Presencia en MongoDB (TP9)", table_cell_header), Paragraph("Presencia en SQLite (Tablet Móvil)", table_cell_header)],
        [Paragraph("<b>Precio Vigente</b>", table_cell_bold), Paragraph("PostgreSQL (<code>productos.precio_actual</code>)", table_cell), Paragraph("No almacenado (solo guarda precio histórico)", table_cell), Paragraph("<code>precio_centavos</code> (Precio visto temporal)", table_cell)],
        [Paragraph("<b>Stock en Tiempo Real</b>", table_cell_bold), Paragraph("PostgreSQL (<code>productos.stock</code>)", table_cell), Paragraph("No interviene", table_cell), Paragraph("<code>stock_visto</code> (Control offline preliminar)", table_cell)],
        [Paragraph("<b>Baja Lógica</b>", table_cell_bold), Paragraph("PostgreSQL (<code>productos.activo</code>)", table_cell), Paragraph("No interviene", table_cell), Paragraph("<code>disponible</code> y <code>eliminado</code> (0 o 1)", table_cell)],
        [Paragraph("<b>Venta Confirmada</b>", table_cell_bold), Paragraph("PostgreSQL (<code>pedidos</code> y <code>detalles</code>)", table_cell), Paragraph("Sí, como documento histórico cerrado", table_cell), Paragraph("<b>Nunca.</b> La tablet solo emite borradores", table_cell_bold)],
        [Paragraph("<b>Precio de Venta Histórico</b>", table_cell_bold), Paragraph("PostgreSQL (<code>detalles_pedido.precio_unitario</code>)", table_cell), Paragraph("Sí (<code>lineas[].precio_unitario</code>)", table_cell), Paragraph("<code>precio_centavos_visto</code> (en borrador)", table_cell)],
        [Paragraph("<b>Datos de Clientes / Passwords</b>", table_cell_bold), Paragraph("PostgreSQL (<code>clientes</code>, <code>usuarios</code>)", table_cell), Paragraph("Snapshot básico desnormalizado", table_cell), Paragraph("<b>No viajan por seguridad y privacidad</b>", table_cell_bold)],
    ]
    t3b = Table(t3b_rows, colWidths=[4.2*cm, 4.6*cm, 4.3*cm, 4.7*cm])
    t3b.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), secondary),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('PADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(t3b)

    # =========================================================================
    # PÁGINA 4: Consigna 3.b (Plan de Mantenimiento Integral)
    # =========================================================================
    story.append(PageBreak())
    story.append(Paragraph("<b>3.b Plan de Mantenimiento Integral (Ampliación de la Unidad 6)</b>", h1_style))
    story.append(Paragraph(
        "El plan de contingencia de la Unidad 6 se amplía para abarcar la infraestructura multi-motor y los dispositivos móviles:",
        body_style
    ))

    t_mant_rows = [
        [Paragraph("Motor", table_cell_header), Paragraph("¿Qué se respalda?", table_cell_header), Paragraph("Frecuencia y Herramienta", table_cell_header), Paragraph("¿Cómo se prueba la restauración?", table_cell_header)],
        [
            Paragraph("<b>PostgreSQL 17</b>", table_cell_bold),
            Paragraph("Base completa y roles globales.", table_cell),
            Paragraph("Diario a las 02:00 AM con <code>pg_dump -Fc</code> y <code>pg_dumpall --globals-only</code>.", table_cell),
            Paragraph("Restauración automatizada en <code>foodstore_restore_test</code> validando 9 métricas de integridad (RTO $\\le$ 15 min, RPO $\\le$ 24 h).", table_cell)
        ],
        [
            Paragraph("<b>MongoDB</b>", table_cell_bold),
            Paragraph("Colección documental <code>pedidos</code>.", table_cell),
            Paragraph("Semanal con <code>mongodump --gzip</code> (no crítico; reconstruible vía ETL).", table_cell),
            Paragraph("Restauración en base de ensayo <code>mongorestore</code> comprobando conteo de documentos y coherencia de subtotales.", table_cell)
        ],
        [
            Paragraph("<b>SQLite 3 (Tablet)</b>", table_cell_bold),
            Paragraph("Exclusivamente borradores y cola de sincronización.", table_cell),
            Paragraph("Al cierre de cada jornada con el comando online <code>.backup</code> de SQLite CLI.", table_cell),
            Paragraph("Verificación estructural con <code>PRAGMA integrity_check;</code> (debe devolver 'ok') y conteo de solicitudes pendientes.", table_cell)
        ],
    ]
    t_mant = Table(t_mant_rows, colWidths=[2.6*cm, 3.8*cm, 4.6*cm, 6.8*cm])
    t_mant.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_mant)
    story.append(Spacer(1, 6))

    story.append(Paragraph("<b>Comportamiento de las Tablets si se Restaura un Respaldo Viejo de PostgreSQL</b>", h2_style))
    story.append(Paragraph(
        "Si el servidor central sufre una pérdida de datos y se restaura un backup con horas de desfase, las tablets pueden contener "
        "un catálogo más reciente que el servidor restaurado. Debido a que el servidor manda, las tablets aplican este protocolo:",
        body_style
    ))
    story.append(Paragraph(
        "1. <b>Invalidación Inmediata de Catálogo:</b> La tablet descarta su caché y descarga la instantánea fresca emitida por el servidor restaurado, sobreescribiendo <code>producto_cache</code>.<br/>"
        "2. <b>Reevaluación de Solicitudes Pendientes:</b> El semáforo vuelve a evaluar las órdenes no enviadas. Si un precio retrocedió a su valor anterior, pasa a <code>CONFLICTO</code> y se informa al cliente.<br/>"
        "3. <b>Reenvío Seguro con Idempotencia:</b> Las solicitudes despachadas con posterioridad al backup se reenvían con su mismo UUID. Al no existir en el backup restaurado, el servidor las procesa en orden sin duplicar ventas.",
        body_style
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("<b>Periodicidad y Responsables de la Revisión de Conflictos y Rechazos</b>", h2_style))
    story.append(Paragraph(
        "• <b>CONFLICTO (Amarillo):</b> Resuelto en tiempo real por el <i>vendedor en mostrador</i> con el cliente presente. Si el cliente acepta el precio actualizado, se regenera la comanda (Caso C2).<br/>"
        "• <b>RECHAZADO (Rojo):</b> Revisado al final del turno por el <i>encargado del food truck</i> para anular borradores fallidos o pedir reposición de stock al centro de distribución.<br/>"
        "• <b>Auditoría Semanal del DBA:</b> El <i>Administrador de Base de Datos</i> ejecuta la consulta de agregación para detectar productos con rechazos sistemáticos por stock insuficiente, ajustando los intervalos de sincronización.",
        body_style
    ))

    # =========================================================================
    # PÁGINA 5: Consigna 3.c (Code Review con IA - Tabla de Hallazgos)
    # =========================================================================
    story.append(PageBreak())
    story.append(Paragraph("<b>3.c Revisión Integral de Código con IA (Code Review de la Cursada)</b>", h1_style))
    story.append(Paragraph(
        "Se sometieron a auditoría estática de código asistida por IA la totalidad de scripts desarrollados a lo largo de la cursada "
        "(TP2 a TP10). A continuación se resumen los 10 hallazgos más relevantes con su respectiva decisión técnica fundamentada:",
        body_style
    ))

    t_cr_rows = [
        [Paragraph("ID", table_cell_header), Paragraph("Ubicación / Módulo", table_cell_header), Paragraph("Hallazgo Identificado por la IA", table_cell_header), Paragraph("Decisión", table_cell_header), Paragraph("Motivo y Justificación Técnica", table_cell_header)],
        [Paragraph("<b>F01</b>", table_cell_bold), Paragraph("TP2 · restricciones.sql", table_cell), Paragraph("El trigger de stock lee sin FOR UPDATE: riesgo de sobreventa concurrente.", table_cell), Paragraph("Aceptado", table_cell), Paragraph("Condición de carrera real; mejora registrada para concurrencia.", table_cell)],
        [Paragraph("<b>F02</b>", table_cell), Paragraph("TP5 · views / indices", table_cell), Paragraph("DROP CASCADE sin verificar contexto de base activa.", table_cell), Paragraph("Aceptado", table_cell), Paragraph("Práctica mejorable, aunque los scripts asumen base preconfigurada.", table_cell)],
        [Paragraph("<b>F03</b>", table_cell), Paragraph("TP7 · fn_resetear_pass", table_cell), Paragraph("rol_soporte puede resetear claves de usuarios administradores.", table_cell), Paragraph("Aceptado", table_cell), Paragraph("Vulnerabilidad de privilegios; requiere cláusula WHERE rol != 'ADMIN'.", table_cell)],
        [Paragraph("<b>F04</b>", table_cell), Paragraph("TP7 · fn_autenticar", table_cell), Paragraph("Discrepancia en el uso de btrim() en contraseñas entre scripts.", table_cell), Paragraph("Aceptado", table_cell), Paragraph("Riesgo menor en contraseñas con espacios iniciales o finales.", table_cell)],
        [Paragraph("<b>F05</b>", table_cell_bold), Paragraph("TP2 · schema / triggers", table_cell), Paragraph("Un pedido ENTREGADO se puede borrar físicamente arrastrando su detalle.", table_cell), Paragraph("<b>Aceptado</b>", table_cell_bold), Paragraph("<b>Comprobado en base de datos de laboratorio (Ver detalle en pág. 6).</b>", table_cell_bold)],
        [Paragraph("<b>F06</b>", table_cell), Paragraph("TP9 · prueba_val_expr", table_cell), Paragraph("Validador $expr controla aritmética pero omite rangos de tipos.", table_cell), Paragraph("Aceptado", table_cell), Paragraph("Correcto: requiere combinar $jsonSchema con expresiones $expr.", table_cell)],
        [Paragraph("<b>F07</b>", table_cell_bold), Paragraph("TP10 · recargar_snap", table_cell), Paragraph("DELETE FROM producto_cache rompe claves foráneas con borradores activos.", table_cell), Paragraph("<b>Corregido</b>", table_cell_bold), Paragraph("<b>Comprobado y corregido mediante sentencia UPSERT (Ver detalle en pág. 6).</b>", table_cell_bold)],
        [Paragraph("<b>F08</b>", table_cell), Paragraph("TP10 · importar_snap", table_cell), Paragraph("CAST de texto no numérico en SQLite produce 0 de forma silenciosa.", table_cell), Paragraph("Aceptado", table_cell), Paragraph("Riesgo bajo: el CSV proviene de columnas bigint tipadas de PostgreSQL.", table_cell)],
        [Paragraph("<b>F09</b>", table_cell_bold), Paragraph("TP10 · recargar_snap", table_cell), Paragraph("Afirma que un producto dado de baja permanece disponible en la tablet.", table_cell), Paragraph("<b>Descartado</b>", table_cell_bold), Paragraph("<b>Descartado con fundamento técnico y refutado (Ver detalle en pág. 6).</b>", table_cell_bold)],
        [Paragraph("<b>F10</b>", table_cell), Paragraph("TP8 · backup_foodstore", table_cell), Paragraph("Métricas de control medidas en transacción ajena a pg_dump.", table_cell), Paragraph("Descartado", table_cell), Paragraph("En reposo durante la ventana nocturna no hay escrituras concurrentes.", table_cell)],
    ]
    t_cr = Table(t_cr_rows, colWidths=[0.9*cm, 3.2*cm, 4.8*cm, 1.8*cm, 7.1*cm])
    t_cr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, light_bg]),
        ('ALIGN', (0,1), (0,-1), 'CENTER'),
        ('ALIGN', (3,1), (3,-1), 'CENTER'),
        ('PADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(t_cr)
    story.append(Spacer(1, 6))

    story.append(Paragraph(
        "<b>Criterio Metodológico de Clasificación:</b><br/>"
        "• <b>Aceptado:</b> El hallazgo describe una debilidad real del código. En TPs anteriores ya calificados, queda asentado como lección aprendida sin alterar la entrega original.<br/>"
        "• <b>Corregido:</b> El hallazgo fue identificado en la etapa de diseño de este trabajo práctico y se refactorizó activamente antes de la versión final.<br/>"
        "• <b>Descartado con Fundamento:</b> La observación de la IA constituye una mala interpretación del modelo de negocio o fue desestimada mediante pruebas empíricas en el motor.",
        body_style
    ))

    # =========================================================================
    # PÁGINA 6: Consigna 3.c Continuación (Desarrollo en Profundidad de 3 Hallazgos)
    # =========================================================================
    story.append(PageBreak())
    story.append(Paragraph("<b>3.c Desarrollo en Profundidad de Tres Hallazgos Críticos</b>", h1_style))

    # Desarrollo 1: F05 Aceptado
    story.append(Paragraph("<b>1. Hallazgo F05 (TP2) — Borrado físico de pedidos cerrados · [ACEPTADO]</b>", h2_style))
    story.append(Paragraph(
        "<b>Observación de la IA:</b> La IA advirtió que el trigger de integridad de TP2 únicamente interceptaba eventos <code>UPDATE</code>. "
        "Dado que la clave foránea entre <code>detalles_pedido</code> y <code>pedidos</code> poseía la cláusula <code>ON DELETE CASCADE</code>, "
        "un usuario con privilegios podía ejecutar <code>DELETE FROM pedidos WHERE id_pedido = 1;</code>, eliminando permanentemente la venta "
        "y sus renglones sin disparar ningún error.<br/>"
        "<b>Comprobación Empírica en PostgreSQL 17:</b> Dentro de un bloque <code>BEGIN ... ROLLBACK</code>, se verificó que un <code>UPDATE</code> "
        "sobre el pedido entregado 1 era rechazado por el trigger, pero un <code>DELETE</code> sobre el mismo pedido eliminaba la fila y "
        "purgaba sus 3 líneas de detalle. El hallazgo fue aceptado e incorporado como lección aprendida: las reglas de inmutabilidad "
        "deben aplicarse a eventos <code>BEFORE DELETE OR UPDATE</code>.",
        body_style
    ))
    story.append(Spacer(1, 4))

    # Desarrollo 2: F07 Corregido
    story.append(Paragraph("<b>2. Hallazgo F07 (TP10) — La recarga destructiva rompe la tablet · [CORREGIDO]</b>", h2_style))
    story.append(Paragraph(
        "<b>Observación de la IA:</b> Al recargar la instantánea del servidor en la tablet móvil, el diseño inicial contemplaba vaciar "
        "la caché con <code>DELETE FROM producto_cache;</code> antes de reinsertar los productos actualizados. La IA detectó que al estar "
        "activas las claves foráneas (<code>PRAGMA foreign_keys = ON;</code>), si existía un borrador abierto en <code>item_borrador</code> "
        "haciendo referencia a un producto de la caché, la recarga se abortaba con error de violación de clave foránea.<br/>"
        "<b>Comprobación y Corrección en SQLite:</b> Se recreó el fallo en el simulador y se corrigió el script <code>recargar_snapshot.sql</code> "
        "implementando la cláusula <b>UPSERT</b> (<code>INSERT INTO producto_cache ... ON CONFLICT (id) DO UPDATE SET ...</code>). "
        "De este modo, las filas maestras se actualizan en su lugar sin borrarse, preservando la integridad de los borradores en comanda.",
        body_style
    ))
    story.append(Spacer(1, 4))

    # Desarrollo 3: F09 Descartado
    story.append(Paragraph("<b>3. Hallazgo F09 (TP10) — Falso positivo sobre productos dados de baja · [DESCARTADO CON FUNDAMENTO]</b>", h2_style))
    story.append(Paragraph(
        "<b>Observación de la IA:</b> La IA argumentó que: <i>\"Al recargar mediante UPSERT, si un producto es eliminado en el servidor, "
        "no sufrirá UPDATE y continuará disponible para la venta en la tablet indefinidamente, provocando rechazos masivos en la feria\"</i>.<br/>"
        "<b>Refutación Técnica y Comprobación en Laboratorio:</b> La afirmación de la IA es <b>falsa y fue descartada con fundamento</b> por dos razones:<br/>"
        "1. En Food Store la baja de productos es <b>lógica</b> (regla R7), no física. La vista <code>v_snapshot_movil</code> en PostgreSQL "
        "<b>sí exporta el producto inactivo</b>, enviándolo con los indicadores <code>disponible = 'f'</code> y <code>eliminado = 't'</code>.<br/>"
        "2. Al ejecutarse el UPSERT en la tablet, el producto se actualiza con <code>disponible = 0</code> y <code>eliminado = 1</code>. "
        "Inmediatamente la consulta offline del Caso C1 (<code>WHERE disponible = 1 AND eliminado = 0</code>) lo excluye de la pantalla del vendedor. "
        "Asimismo, si existía una solicitud previa, el semáforo la clasifica en <b>`RECHAZADO` (Rojo)</b> con el motivo 'Producto no disponible'. "
        "Se demostró que la IA asumió erróneamente que una baja de producto implicaba su desaparición del CSV.",
        body_style
    ))
    story.append(Spacer(1, 6))

    # Conclusión final del entregable
    concl_box = (
        "<b>Conclusión de la Capa de Datos:</b> La integración de PostgreSQL como motor transaccional de registro (System of Record), "
        "MongoDB como almacén optimizado de lectura para historial de ventas, y SQLite como base local desconectada bajo el principio "
        "«El móvil propone, el servidor dispone», consolida una arquitectura de datos robusta, tolerante a fallas y 100% alineada a las mejores prácticas de la industria."
    )
    t_box = Table([[Paragraph(concl_box, body_style)]], colWidths=[17.8*cm])
    t_box.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), light_bg),
        ('BOX', (0,0), (-1,-1), 1, accent),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_box)

    doc.build(story)
    print(f"[OK] PDF generado exitosamente en: {filename}")

if __name__ == "__main__":
    out_pdf = os.path.join(os.path.dirname(os.path.abspath(__file__)), "informe.pdf")
    build_pdf(out_pdf)
