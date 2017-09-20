CHECK\_HWRAID(1) - General Commands Manual

# NAME

**check\_hwraid** - query the health of a RAID controller

# SYNOPSIS

**check\_hwraid**
\[**-t**]
*familytype*

# DESCRIPTION

The
**check\_hwraid**
icinga2(8)
plugin returns the status of supported hardware RAID controllers and optionally
any diagnostic information from the controller.

The plugin itself does not query the controller; helper scripts are called from
**check\_hwraid**
which return a predefined JSON structure to be processed.

The options are as follows:

**-t**

> Set the device type. If undefined, standard input is read.

# EXIT STATUS

**check\_hwraid**
exits with good exit codes

# EXAMPLES

Check an intel raid device...

	$ raidcat -t intel

# SEE ALSO

icinga2(1)

OpenBSD 6.1 - September 20, 2017
