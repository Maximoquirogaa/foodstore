$ErrorActionPreference='Stop'
$delivery=Split-Path $PSScriptRoot -Parent
$testRoot=Join-Path $env:TEMP ([guid]::NewGuid().ToString('N')); New-Item -ItemType Directory $testRoot | Out-Null
$bin=Join-Path $testRoot 'bin'; New-Item -ItemType Directory $bin | Out-Null
$fake=@'
$allArgs=@($args); Add-Content $env:TP8_CALLS ($MyInvocation.MyCommand.Name+' '+($allArgs -join ' '))
$global:LASTEXITCODE=0
$name=$MyInvocation.MyCommand.Name
if($name -eq 'pg_dump.ps1') { if($env:TP8_MODE -eq 'dumpfail'){$global:LASTEXITCODE=7; return}; $i=[array]::IndexOf($allArgs,'-f'); Set-Content $allArgs[$i+1] 'fake archive'; return }
if($name -eq 'pg_restore.ps1'){if($env:TP8_MODE -eq 'restorefail' -and $allArgs -notcontains '--list'){$global:LASTEXITCODE=9}; return}
if($name -eq 'psql.ps1'){
 if(($allArgs -join ' ') -match 'pg_database'){if($env:TP8_MODE -eq 'exists'){'1'}else{'0'}; return}
 if($env:TP8_MODE -eq 'reordered' -and $allArgs -contains 'foodstore_restore_test'){'{"invalid":{"detalle_producto_huerfano":0,"detalle_pedido_huerfano":0,"pedido_cliente_huerfano":0,"producto_categoria_huerfana":0,"detalle_subtotal_incorrecto":0,"detalle_precio_negativo":0,"detalle_cantidad_no_positiva":0,"producto_stock_negativo":0,"producto_precio_negativo":0},"counts":{"detalle_pedido":1,"pedido":1,"producto":1,"cliente":1,"categoria":1}}'; return}
 $n=1; $bad=0; $orphan=0
 if($allArgs -contains 'foodstore_restore_test') {if($env:TP8_MODE -eq 'mismatch'){$n=2}; if($env:TP8_MODE -eq 'invalid'){$bad=1}; if($env:TP8_MODE -eq 'orphan'){$orphan=1}}
 '{"counts":{"categoria":1,"cliente":1,"producto":'+$n+',"pedido":1,"detalle_pedido":1},"invalid":{"producto_precio_negativo":'+$bad+',"producto_stock_negativo":0,"detalle_cantidad_no_positiva":0,"detalle_precio_negativo":0,"detalle_subtotal_incorrecto":0,"producto_categoria_huerfana":0,"pedido_cliente_huerfano":0,"detalle_pedido_huerfano":0,"detalle_producto_huerfano":'+$orphan+'}}'
}
'@
foreach($name in @('psql','pg_dump','pg_restore','createdb')){Set-Content (Join-Path $bin "$name.ps1") $fake}
$env:TP8_CALLS=Join-Path $testRoot 'calls.txt'
$passed=0
function Expect-Failure([scriptblock]$action,[string]$message){$failed=$false; try {& $action | Out-Null}catch{$failed=$true}; if(!$failed){throw "Expected failure: $message"}; $script:passed++}
$backup=Join-Path $delivery 'backup_foodstore.ps1'; $restore=Join-Path $delivery 'restore_test.ps1'
Expect-Failure {& $backup -SourceDatabase forbidden -PgBin $bin -OutputDirectory $testRoot} 'source whitelist'
$env:TP8_MODE='dumpfail'; Expect-Failure {& $backup -PgBin $bin -OutputDirectory $testRoot} 'pg_dump nonzero'
$env:TP8_MODE='ok'; $manifest=& $backup -PgBin $bin -OutputDirectory $testRoot
$m=Get-Content $manifest -Raw | ConvertFrom-Json
if($m.status -ne 'PASS' -or $m.dump_bytes -le 0 -or $m.dump_sha256.Length -ne 64){throw 'Backup success metadata incorrect'}; $passed++
if([IO.Path]::GetFileName($m.dump_path) -cnotmatch '^foodstore_dev_\d{8}_\d{6}_\d{3}_[0-9a-f]{8}\.dump$'){throw 'Dump name lacks date, time and id'}; $passed++
$m2=& $backup -SourceDatabase foodstore_tp3_carga -PgBin $bin -OutputDirectory $testRoot
if((Get-Content $m2 -Raw|ConvertFrom-Json).source -ne 'foodstore_tp3_carga'){throw 'Second source not preserved'}; $passed++
foreach($mode in @('exists','restorefail','mismatch','invalid','orphan')){
 $env:TP8_MODE=$mode; Set-Content $env:TP8_CALLS ''
 Expect-Failure {& $restore -MetadataPath $manifest -PgBin $bin -OutputDirectory $testRoot} $mode
 $calls=Get-Content $env:TP8_CALLS -Raw
 if($mode -eq 'exists' -and $calls -match 'createdb|pg_restore'){throw 'Existing destination was touched'}
 if($calls -match 'dropdb|DROP DATABASE'){throw 'Deletion attempted'}
}
$env:TP8_MODE='ok'; $result=& $restore -MetadataPath $manifest -PgBin $bin -OutputDirectory $testRoot
$r=Get-Content $result -Raw | ConvertFrom-Json
if($r.status -ne 'PASS' -or $null -eq $r.rto_seconds -or $r.rpo_proxy_seconds -lt 0){throw 'Restore success evidence invalid'}; $passed++
$env:TP8_MODE='reordered'; $reordered=& $restore -MetadataPath $manifest -PgBin $bin -OutputDirectory $testRoot
if((Get-Content $reordered -Raw|ConvertFrom-Json).status -ne 'PASS'){throw 'JSON field order affected validation'}; $passed++
Add-Content $m.dump_path 'tampered'
Set-Content $env:TP8_CALLS ''
Expect-Failure {& $restore -MetadataPath $manifest -PgBin $bin -OutputDirectory $testRoot} 'hash mismatch'
if((Get-Content $env:TP8_CALLS -Raw) -match 'createdb|pg_restore'){throw 'Tampered archive reached restore'}
$failures=@(Get-ChildItem $testRoot -Directory -Filter 'restore_*' | Where-Object {(Get-Content (Join-Path $_.FullName 'result.json') -Raw|ConvertFrom-Json).status -eq 'FAIL'})
if($failures.Count -ne 6){throw "Failure results not persisted: $($failures.Count)"}; $passed++
Write-Output "PASS $passed checks; isolated fake tools; root=$testRoot"


