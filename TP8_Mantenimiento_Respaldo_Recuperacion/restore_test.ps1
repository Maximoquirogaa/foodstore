[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$MetadataPath, [string]$DumpPath,
 [string]$DbHost='localhost', [int]$Port=5432, [string]$DbUser='postgres',
 [string]$PgBin='C:\Program Files\PostgreSQL\17\bin',
 [string]$OutputDirectory=(Join-Path $PSScriptRoot 'restore_results')
)
. (Join-Path $PSScriptRoot 'pg_common.ps1')
$connection=@('-w','-h',$DbHost,'-p',"$Port",'-U',$DbUser)
$target='foodstore_restore_test'
$run=Join-Path $OutputDirectory ('restore_'+(Get-Date -Format 'yyyyMMdd_HHmmss_fff')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $run -Force | Out-Null
$logs=Join-Path $run 'logs'; New-Item -ItemType Directory -Path $logs | Out-Null
$resultPath=Join-Path $run 'result.json'
$watch=$null
$data=[ordered]@{status='FAIL';target=$target;metadata_path=$MetadataPath;started_at=[DateTimeOffset]::Now.ToString('o');rto_seconds=$null;rpo_proxy_seconds=$null;rpo_note='Age of backup start at recovery start; freshness proxy, not measured data loss or guaranteed RPO.';metrics=$null;error=$null}
try {
 $metadata=Get-Content -LiteralPath $MetadataPath -Raw | ConvertFrom-Json
 if($metadata.status -ne 'PASS' -or $metadata.source -notin @('foodstore_dev','foodstore_tp3_carga')) {throw 'Invalid backup metadata'}
 Assert-Valid $metadata.baseline
 if(!$DumpPath){$DumpPath=$metadata.dump_path}
 if((Get-FileHash -LiteralPath $DumpPath -Algorithm SHA256).Hash -ne $metadata.dump_sha256){throw 'Backup SHA256 mismatch'}
 $exists=Invoke-Pg 'psql' ($connection+@('-X','-v','ON_ERROR_STOP=1','-d','postgres','-At','-c',"SELECT count(*) FROM pg_database WHERE datname='$target'")) (Join-Path $logs 'destination_check.log')
 if($exists.Trim() -ne '0'){throw 'Destination already exists. Aborted without deletion; preserve existing database.'}
 $recoveryStart=[DateTimeOffset]::Now
 $data.rpo_proxy_seconds=($recoveryStart-[DateTimeOffset]$metadata.backup_start).TotalSeconds
 if($data.rpo_proxy_seconds -lt 0){throw 'Backup timestamp is in the future'}
 $data.recovery_start=$recoveryStart.ToString('o')
 $watch=[Diagnostics.Stopwatch]::StartNew()
 Invoke-Pg 'createdb' ($connection+@('--template=template0',$target)) (Join-Path $logs 'createdb.log') | Out-Null
 Invoke-Pg 'pg_restore' ($connection+@('--exit-on-error','--no-owner','--no-privileges','-d',$target,$DumpPath)) (Join-Path $logs 'restore.log') | Out-Null
 $data.metrics=Get-Metrics $target (Join-Path $run 'restored_metrics.json')
 Assert-Valid $data.metrics
 foreach($name in @('categoria','cliente','producto','pedido','detalle_pedido')){if($data.metrics.counts.$name -ne $metadata.baseline.counts.$name){throw "Count mismatch: $name"}}
 $watch.Stop(); $data.rto_seconds=$watch.Elapsed.TotalSeconds; $data.status='PASS'
} catch { $data.error=$_.Exception.Message; throw }
finally {
 if($null -ne $watch){$watch.Stop(); $data.elapsed_attempt_seconds=$watch.Elapsed.TotalSeconds}
 $data.finished_at=[DateTimeOffset]::Now.ToString('o')
 $data | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $resultPath
}
Write-Output $resultPath


