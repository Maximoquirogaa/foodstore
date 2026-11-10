from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable
from reportlab.lib.enums import TA_CENTER, TA_LEFT

W, H = A4

def build_pdf(filename, tp_num, subtitle, problems):
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        rightMargin=2.5*cm, leftMargin=2.5*cm,
        topMargin=2.5*cm, bottomMargin=2.5*cm
    )

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'Title', parent=styles['Normal'],
        fontSize=22, leading=28, alignment=TA_CENTER,
        textColor=colors.HexColor('#1a237e'), fontName='Helvetica-Bold',
        spaceAfter=4
    )
    subtitle_style = ParagraphStyle(
        'Subtitle', parent=styles['Normal'],
        fontSize=13, leading=18, alignment=TA_CENTER,
        textColor=colors.HexColor('#37474f'), fontName='Helvetica',
        spaceAfter=2
    )
    section_style = ParagraphStyle(
        'Section', parent=styles['Normal'],
        fontSize=10, leading=14, alignment=TA_CENTER,
        textColor=colors.HexColor('#78909c'), fontName='Helvetica-Oblique',
        spaceAfter=0
    )
    problem_title_style = ParagraphStyle(
        'ProbTitle', parent=styles['Normal'],
        fontSize=11, leading=15, alignment=TA_LEFT,
        textColor=colors.HexColor('#1565c0'), fontName='Helvetica-Bold',
        spaceBefore=10, spaceAfter=2
    )
    bullet_label_style = ParagraphStyle(
        'BulLabel', parent=styles['Normal'],
        fontSize=9.5, leading=13, alignment=TA_LEFT,
        textColor=colors.HexColor('#4a148c'), fontName='Helvetica-Bold',
        leftIndent=14, spaceAfter=0
    )
    bullet_body_style = ParagraphStyle(
        'BulBody', parent=styles['Normal'],
        fontSize=9.5, leading=13, alignment=TA_LEFT,
        textColor=colors.HexColor('#212121'), fontName='Helvetica',
        leftIndent=14, spaceAfter=4
    )

    story = []

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph(f"Trabajo Práctico {tp_num}", title_style))
    story.append(Paragraph(subtitle, subtitle_style))
    story.append(Paragraph("Problemas Solucionados · Python", section_style))
    story.append(Spacer(1, 0.3*cm))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#1a237e')))
    story.append(Spacer(1, 0.4*cm))

    for i, (title, prob, sol) in enumerate(problems, 1):
        story.append(Paragraph(f"● Problema {i}: {title}", problem_title_style))
        story.append(Paragraph("<b>Descripción:</b>", bullet_label_style))
        story.append(Paragraph(prob, bullet_body_style))
        story.append(Paragraph("<b>Solución:</b>", bullet_label_style))
        story.append(Paragraph(sol, bullet_body_style))
        if i < len(problems):
            story.append(HRFlowable(width="100%", thickness=0.4, color=colors.HexColor('#b0bec5'), spaceAfter=2))

    story.append(Spacer(1, 0.6*cm))
    story.append(HRFlowable(width="100%", thickness=0.8, color=colors.HexColor('#1a237e')))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph("Universidad Tecnológica Nacional · 2024", ParagraphStyle(
        'Footer', parent=styles['Normal'], fontSize=8, alignment=TA_CENTER,
        textColor=colors.HexColor('#90a4ae'), fontName='Helvetica-Oblique'
    )))

    doc.build(story)
    print(f"[OK] {filename} generado correctamente.")


# ── TP6: Programación Orientada a Objetos ──────────────────────────────────
tp6_problems = [
    (
        "Clase Persona con herencia",
        "Definir una clase Persona con atributos nombre y edad, y una subclase Estudiante que agregue el atributo carrera. Instanciar objetos y mostrar sus datos.",
        "Se define Persona con __init__ y __str__. Estudiante hereda de Persona y llama a super().__init__(). Se instancian objetos y se imprime con print(), que invoca __str__ automáticamente."
    ),
    (
        "Polimorfismo con figuras geométricas",
        "Crear clases Circulo y Rectangulo que implementen un método area(). Calcular el área de una lista de figuras sin conocer su tipo específico.",
        "Ambas clases definen area(). Se recorre una lista polimórfica llamando figura.area() en cada elemento; Python resuelve el método correcto en tiempo de ejecución (duck typing)."
    ),
    (
        "Encapsulamiento y propiedades",
        "Modelar una cuenta bancaria con saldo privado. Permitir depósitos y retiros con validaciones, impidiendo saldo negativo.",
        "El atributo _saldo es privado. Se usan métodos depositar() y retirar() que validan la operación antes de modificarlo. Se lanza ValueError si el retiro supera el saldo disponible."
    ),
    (
        "Sobrecarga de operadores",
        "Implementar una clase Vector2D y sobrecargar los operadores + y * para sumar vectores y escalar por un número.",
        "Se definen __add__ para la suma componente a componente y __mul__ para la multiplicación escalar. Se retorna una nueva instancia de Vector2D con los valores resultantes."
    ),
    (
        "Clase abstracta con ABC",
        "Definir una clase abstracta Animal con el método abstracto hablar(). Implementarla en Perro y Gato, forzando que toda subclase defina ese método.",
        "Se importa ABC y abstractmethod. Animal hereda de ABC y decora hablar() con @abstractmethod. Perro y Gato implementan hablar(). Intentar instanciar Animal directamente lanza TypeError."
    ),
    (
        "Composición de objetos",
        "Modelar un Motor y un Automovil, donde Automovil contiene un Motor como atributo. Encender el auto delega al motor.",
        "Automovil recibe una instancia de Motor en su constructor (composición). El método encender() de Automovil llama a self.motor.iniciar(), ilustrando el principio 'tener-un' frente a 'es-un'."
    ),
    (
        "Iterador personalizado",
        "Implementar un iterador que recorra un rango de números pares dado un límite superior.",
        "La clase IteradorPares define __iter__ (retorna self) y __next__ (incrementa de 2 en 2 y lanza StopIteration al superar el límite). Se usa en un bucle for de forma transparente."
    ),
    (
        "Gestión de excepciones personalizada",
        "Crear una excepción SaldoInsuficienteError que herede de Exception y lanzarla desde la cuenta bancaria.",
        "Se define class SaldoInsuficienteError(Exception) con un mensaje descriptivo. El método retirar() la lanza con raise. El bloque try/except del cliente la captura específicamente."
    ),
]

# ── TP7: Archivos y Manejo de Datos ───────────────────────────────────────
tp7_problems = [
    (
        "Leer y escribir archivos de texto",
        "Escribir una lista de nombres en un archivo .txt, luego leerlo y mostrar cada línea numerada.",
        "Se usa open() con modo 'w' para escribir con writelines() y modo 'r' para leer con enumerate(f). El bloque with garantiza el cierre automático del archivo en ambos casos."
    ),
    (
        "Procesamiento de CSV con csv.reader",
        "Leer un archivo CSV de productos (nombre, precio, stock) y calcular el valor total del inventario.",
        "Se importa csv y se abre el archivo en modo 'r'. csv.reader itera fila por fila; se salta el encabezado con next(). El total se acumula multiplicando precio × stock para cada producto."
    ),
    (
        "Escritura de CSV con csv.DictWriter",
        "Generar un reporte CSV de ventas diarias con encabezados Fecha, Producto y Monto desde una lista de diccionarios.",
        "Se usa csv.DictWriter con fieldnames predefinidos. Se llama writeheader() una vez y luego writerows() pasa la lista completa. El resultado es un archivo con encabezado y datos alineados."
    ),
    (
        "Serialización con JSON",
        "Convertir un diccionario de configuración a JSON, guardarlo en disco y volver a cargarlo verificando integridad.",
        "json.dump() serializa el dict al archivo con indent=2 para legibilidad. json.load() lo deserializa de vuelta. Se compara el dict original con el cargado usando == para verificar integridad."
    ),
    (
        "Búsqueda en archivo de log",
        "Leer un archivo de log línea por línea y extraer solo las líneas que contienen la palabra 'ERROR'.",
        "Se abre el archivo en modo 'r' y se itera con un generador: (línea for línea in f if 'ERROR' in línea). Esto evita cargar todo el archivo en memoria, siendo eficiente para logs grandes."
    ),
    (
        "Manejo de rutas con pathlib",
        "Listar todos los archivos .py de un directorio, mostrar su tamaño en KB y ordenarlos de mayor a menor.",
        "Path('.').glob('**/*.py') recorre recursivamente. stat().st_size da el tamaño en bytes; se divide entre 1024. Se ordena la lista resultante con sorted(key=lambda x: x[1], reverse=True)."
    ),
    (
        "Archivo binario con pickle",
        "Serializar una lista de objetos Producto (con nombre y precio) a un archivo binario y recuperarla.",
        "pickle.dump() escribe los objetos en modo 'wb'. pickle.load() los recupera en modo 'rb'. Los objetos se restauran completos, incluyendo métodos; no se necesita reconstrucción manual."
    ),
    (
        "Comparación y fusión de archivos",
        "Dados dos archivos de texto con listas de IDs, encontrar los IDs comunes, solo en A y solo en B.",
        "Se leen ambos archivos como conjuntos (set). La intersección (A & B) da los comunes, A - B los exclusivos de A y B - A los de B. Las operaciones de conjuntos son O(n) en promedio."
    ),
]

# ── TP8: Bases de Datos con SQLite ─────────────────────────────────────────
tp8_problems = [
    (
        "Crear base de datos y tabla",
        "Crear una base de datos SQLite con una tabla Clientes que tenga id, nombre, email y fecha_registro.",
        "Se importa sqlite3 y se conecta con connect('tienda.db'). cursor.execute() crea la tabla con IF NOT EXISTS. Los tipos TEXT e INTEGER se mapean automáticamente a Python str e int."
    ),
    (
        "Insertar registros con parámetros",
        "Insertar 5 clientes en la tabla usando parámetros para prevenir inyección SQL.",
        "Se usa execute() con placeholders ? y una tupla de valores. Para múltiples registros, executemany() recibe una lista de tuplas. Se llama conn.commit() para confirmar la transacción."
    ),
    (
        "Consulta SELECT con filtros",
        "Obtener todos los clientes registrados después de una fecha dada y ordenarlos por nombre.",
        "SELECT * FROM Clientes WHERE fecha_registro > ? ORDER BY nombre ASC. El ? previene inyección. fetchall() retorna una lista de tuplas; fetchone() retorna la primera fila o None."
    ),
    (
        "Actualizar y eliminar registros",
        "Actualizar el email de un cliente por su id y luego eliminar clientes con email inválido (sin '@').",
        "UPDATE usa SET campo = ? WHERE id = ?. DELETE usa WHERE con la condición de filtro. Ambos requieren commit(). rowcount del cursor indica cuántas filas fueron afectadas."
    ),
    (
        "JOIN entre dos tablas",
        "Modelar Clientes y Pedidos. Obtener el nombre del cliente junto con el total de cada pedido.",
        "Se crea la tabla Pedidos con cliente_id como clave foránea. La consulta usa INNER JOIN Pedidos ON Clientes.id = Pedidos.cliente_id. Se activa PRAGMA foreign_keys = ON para integridad."
    ),
    (
        "Transacciones y manejo de errores",
        "Realizar una transferencia entre cuentas de forma atómica: descontar de una y acreditar en otra.",
        "Se usa try/except alrededor de ambos UPDATE. Si alguno falla, conn.rollback() revierte los cambios. Solo si ambos tienen éxito se llama conn.commit(), garantizando atomicidad (ACID)."
    ),
    (
        "Uso de Row Factory",
        "Acceder a los resultados de una consulta por nombre de columna en lugar de índice numérico.",
        "Se asigna conn.row_factory = sqlite3.Row antes de crear el cursor. Las filas retornadas permiten acceso por nombre: fila['nombre'], fila['email']. Mejora legibilidad sin ORM externo."
    ),
    (
        "Índices y optimización de consultas",
        "Crear un índice en la columna email de Clientes y medir su impacto en consultas de búsqueda.",
        "CREATE INDEX idx_email ON Clientes(email) acelera búsquedas WHERE email = ?. EXPLAIN QUERY PLAN muestra si el índice es utilizado. Para tablas pequeñas el impacto es menor; es crítico a escala."
    ),
]

OUT = r"c:\Users\Administrador\Documents\Trabajos UTN\foodstore_github\TP5"

build_pdf(f"{OUT}\\TP6.pdf", "6", "Programación Orientada a Objetos", tp6_problems)
build_pdf(f"{OUT}\\TP7.pdf", "7", "Archivos y Manejo de Datos",        tp7_problems)
build_pdf(f"{OUT}\\TP8.pdf", "8", "Bases de Datos con SQLite",          tp8_problems)
