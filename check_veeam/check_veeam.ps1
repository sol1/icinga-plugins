asnp VeeamPSSnapin

$period = 1

$jobs = Get-VBRJob | Select name
For ($i = 0; $i -lt $jobs.length; $i++ {
	$job = Get-VBRJob -Name $jobs[$i]
	$status = $job.GetLastResult()
	switch ($status) {
	"Failure" { Write-Host "Last run of job $name failed"; exit 2 }
	"Success" { Write-Host "Last run of job $job succeeded"; exit 0 }
	default   { Write-Host "Unknown last result of job $job"; exit 3 }
	}
}

$now = (Get-Date).AddDays(-$period)
$now = $now.ToString("yyyy-MM-dd")
$last = $job.GetScheduleOptions()
$last = $last -replace '.*Latest run time: \[', ''
$last = $last -replace '\], Next run time: .*', ''
$last = $last.split(' ')[0]
