[CmdletBinding()]
param(
 [ValidateSet('foodstore_dev','foodstore_tp3_carga')][string]$SourceDatabase='foodstore_dev',
 [string]$DbHost='localhost', [int]$Port=5432, [string]$DbUser='postgres',
 [string]$PgBin='C:\Program Files\PostgreSQL\17\bin',
 [string]$OutputDirectory=(Join-Path ([Environment]::GetFolderPath('UserProfile')) 'TP8_Backups')
)
. (Join-Path $PSScriptRoot 'pg_common.ps1')
$connection=@('-w','-h',$DbHost,'-p',"$Port",'-U',$DbUser)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss_fff'; $id=[guid]::NewGuid().ToString('N').Substring(0,8)
$run=Join-Path $OutputDirectory ($SourceDatabase+'_'+$stamp+'_'+$id)
New-Item -ItemType Directory -Path $run -Force | Out-Null
$logs=Join-Path $run 'logs'; New-Item -ItemType Directory -Path $logs | Out-Null
$manifest=Join-Path $run 'metadata.json'
$data=[ordered]@{status='FAIL';source=$SourceDatabase;host=$DbHost;port=$Port;started_at=[DateTimeOffset]::Now.ToString('o');baseline=$null;dump_path=(Join-Path $run ($SourceDatabase+'_'+$stamp+'_'+$id+'.dump'));dump_sha256=$null;dump_bytes=0;error=$null}
try {
 $data.baseline=Get-Metrics $SourceDatabase (Join-Path $run 'baseline.json')
 Assert-Valid $data.baseline
 $data.backup_start=[DateTimeOffset]::Now.ToString('o')
 Invoke-Pg 'pg_dump' ($connection+@('-d',$SourceDatabase,'-Fc','-f',$data.dump_path)) (Join-Path $logs 'pg_dump.log') | Out-Null
 Invoke-Pg 'pg_restore' @('--list',$data.dump_path) (Join-Path $logs 'archive_contents.log') | Out-Null
 $data.dump_bytes=(Get-Item $data.dump_path).Length
 if($data.dump_bytes -le 0){throw 'Empty backup'}
 $data.dump_sha256=(Get-FileHash $data.dump_path -Algorithm SHA256).Hash
 $data.status='PASS'
} catch { $data.error=$_.Exception.Message; throw }
finally { $data.finished_at=[DateTimeOffset]::Now.ToString('o'); $data | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $manifest }
Write-Output $manifest


