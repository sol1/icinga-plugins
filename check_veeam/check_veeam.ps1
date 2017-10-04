asnp VeeamPSSnapin

# Get an array of veeam jobs called 'jobs', then loop through each job querying
# its last result.
$jobs = Get-VBRJob
For ($i = 0; $i -lt $jobs.length; $i++) {
	$j = $jobs[$i]
	$status = $job.GetLastResult()
	switch ($status) {
	"Failure" { Write-Host "Last run of job" $j.Name "failed" }
	"Success" { Write-Host "Last run of job" $j.Name "succeeded" }
	default   { Write-Host "Cannot determine state of last run of" $j.Name }
	}
}
