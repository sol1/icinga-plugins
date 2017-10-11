param (
	[string]$name = $null
)

asnp VeeamPSSnapin

# Get-JobResult takes a Veeam backup job as an arugment, and returns the result
# of the most recent run.
function Get-JobResult {
	$job = $args[0]
	$session = Get-VBRBackupSession | where {$_.jobID -eq $job.Id.Guid} | Sort EndTimeUTC -Descending | Select -First 1
	$result = $session.Result
	return $result
}

$jobs = $null
if ($name) {
	$jobs = Get-VBRJob -Name $name
} else {
	$jobs = Get-VBRJob
}

$numfail = 0
$numwarn = 0
for ($index = 0; $index -lt $jobs.length; $index++) {
	$currentjob = $jobs[$index]
	$lastresult = Get-JobResult $currentjob
	switch ($lastresult) {
	"Success" { Write-Host "job" $currentjob.Name "succeeded"; continue }
	"Warning" { Write-Host "job" $currentjob.Name "finished with warning"; $numwarn++ }
	"Failed"  { Write-Host "job" $currentjob.Name "failed"; $numfail++ }
	default   { Write-Host "Cannot determine status of job" $currentjob.Name }
	}
}

if ($numfail -gt 0) {
	echo "CRITICAL: Backup jobs failed"
	exit 2
} elseif ($numwarn -gt 0) {
	echo "WARNING: Some backups completed with warnings"
	exit 1
} elseif (($numfail -eq 0) -and ($numwarn -eq 0)) {
	echo "OK: Veeam backups succeeded"
	exit 0
}
exit 3
