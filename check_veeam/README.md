CHECK\_VEEAM(1) - General Commands Manual

# NAME

**check\_veeam** - Veeam backup state checker

# SYNOPSIS

**check\_veeam**
\[**-Name**&nbsp;*filter*]

# DESCRIPTION

**check\_veeam**
collects the result of the most recent run of Veeam backup or backup copy jobs.
The names of any jobs that did not succeed are printed to standard output.
This includes jobs in a
'warning'
or
'failed'
state.

The following options may be set:

**-Name** *filter*

> Only check jobs whose names match the given filter. The \* character may be used
> as a wildcard.

# EXAMPLES

Check whether the job 'database offsite' completed successfully:

	$ check_veeam -Name "database offsite"

Check that all the jobs starting with 'web' completed successfully:

	$ check_veeam -Name web*

# FILES

*icinga2.conf*

> Example
> icinga2(8)
> configuration for use with
> **check\_veeam**,
> distributed with the source code.

# EXIT STATUS

The **check\_veeam** utility exits&#160;0 on success, and&#160;&gt;0 if an error occurs.
Error codes are suitable for nagios/icinga-style checks.

# SEE ALSO

icinga2(8)
icinga2.conf(5)

 \- October 9, 2017
