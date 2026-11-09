$ErrorActionPreference = 'Stop'

function Invoke-Pg([string]$Name, [string[]]$Arguments, [string]$Log) {
    $tool = Join-Path $PgBin "$Name.exe"
    if (!(Test-Path $tool)) { $tool = Join-Path $PgBin "$Name.ps1" }
    if (!(Test-Path $tool)) { throw "PostgreSQL tool missing: $Name in $PgBin" }
    $global:LASTEXITCODE = 0
    $oldPreference = $ErrorActionPreference
    try { 
        $ErrorActionPreference = 'Continue'
        $lines = & $tool @Arguments 2>&1
        $code = $LASTEXITCODE 
    }
    finally { 
        $ErrorActionPreference = $oldPreference 
    }
    $lines | Out-File -Encoding utf8 $Log
    if ($code -ne 0) { throw "$Name exit=$code; log=$Log" }
    return ($lines -join "`n")
}

function Get-Metrics([string]$Database, [string]$Log) {
    $sql=@'
DO $$
BEGIN
    -- Mapeo transparente para bases con esquema plural canonico Food Store
    IF to_regclass('public.categorias') IS NOT NULL AND to_regclass('public.categoria') IS NULL THEN
        CREATE TEMP VIEW categoria AS SELECT id_categoria AS id, nombre, activo FROM public.categorias;
    END IF;
    IF to_regclass('public.clientes') IS NOT NULL AND to_regclass('public.cliente') IS NULL THEN
        CREATE TEMP VIEW cliente AS SELECT id_cliente AS id, nombre, apellido, correo_electronico AS email, fecha_creacion FROM public.clientes;
    END IF;
    IF to_regclass('public.productos') IS NOT NULL AND to_regclass('public.producto') IS NULL THEN
        CREATE TEMP VIEW producto AS SELECT id_producto AS id, id_categoria, nombre, precio_actual AS precio_lista, stock, activo, fecha_creacion FROM public.productos;
    END IF;
    IF to_regclass('public.pedidos') IS NOT NULL AND to_regclass('public.pedido') IS NULL THEN
        CREATE TEMP VIEW pedido AS SELECT id_pedido AS id, id_cliente, forma_pago, fecha_pedido FROM public.pedidos;
    END IF;
    IF to_regclass('public.detalles_pedido') IS NOT NULL AND to_regclass('public.detalle_pedido') IS NULL THEN
        CREATE TEMP VIEW detalle_pedido AS SELECT id_pedido, id_producto, cantidad, precio_unitario, (cantidad * precio_unitario) AS subtotal FROM public.detalles_pedido;
    END IF;
END $$;

SELECT json_build_object('counts', json_build_object(
'categoria', (SELECT count(*) FROM categoria),
'cliente', (SELECT count(*) FROM cliente),
'producto', (SELECT count(*) FROM producto),
'pedido', (SELECT count(*) FROM pedido),
'detalle_pedido', (SELECT count(*) FROM detalle_pedido)),
'invalid', json_build_object(
'producto_precio_negativo', (SELECT count(*) FROM producto WHERE precio_lista < 0 OR precio_lista IS NULL),
'producto_stock_negativo', (SELECT count(*) FROM producto WHERE stock < 0 OR stock IS NULL),
'detalle_cantidad_no_positiva', (SELECT count(*) FROM detalle_pedido WHERE cantidad <= 0 OR cantidad IS NULL),
'detalle_precio_negativo', (SELECT count(*) FROM detalle_pedido WHERE precio_unitario < 0 OR precio_unitario IS NULL),
'detalle_subtotal_incorrecto', (SELECT count(*) FROM detalle_pedido WHERE subtotal IS DISTINCT FROM (cantidad * precio_unitario)),
'producto_categoria_huerfana', (SELECT count(*) FROM producto p WHERE NOT EXISTS (SELECT 1 FROM categoria c WHERE c.id = p.id_categoria)),
'pedido_cliente_huerfano', (SELECT count(*) FROM pedido p WHERE NOT EXISTS (SELECT 1 FROM cliente c WHERE c.id = p.id_cliente)),
'detalle_pedido_huerfano', (SELECT count(*) FROM detalle_pedido dp WHERE NOT EXISTS (SELECT 1 FROM pedido p WHERE p.id = dp.id_pedido)),
'detalle_producto_huerfano', (SELECT count(*) FROM detalle_pedido dp WHERE NOT EXISTS (SELECT 1 FROM producto p WHERE p.id = dp.id_producto))));
'@
    $json = Invoke-Pg 'psql' ($connection + @('-X', '-q', '-v', 'ON_ERROR_STOP=1', '-d', $Database, '-At', '-c', $sql)) $Log
    $jsonLine = ($json -split "\r?\n" | Where-Object { $_.TrimStart().StartsWith('{') } | Select-Object -Last 1)
    if ([string]::IsNullOrWhiteSpace($jsonLine)) { throw "Empty JSON metrics from psql; output=$json" }
    return ($jsonLine | ConvertFrom-Json)
}

function Assert-Valid($Metrics) {
    foreach($name in @('categoria', 'cliente', 'producto', 'pedido', 'detalle_pedido')) {
        if ($null -eq $Metrics.counts.$name) { throw "Missing count: $name" }
    }
    foreach($name in @('producto_precio_negativo', 'producto_stock_negativo', 'detalle_cantidad_no_positiva', 'detalle_precio_negativo', 'detalle_subtotal_incorrecto', 'producto_categoria_huerfana', 'pedido_cliente_huerfano', 'detalle_pedido_huerfano', 'detalle_producto_huerfano')) {
        if ($null -eq $Metrics.invalid.$name -or $Metrics.invalid.$name -ne 0) { 
            throw "Invalid rows or missing check: $name (value=$($Metrics.invalid.$name))" 
        }
    }
}
