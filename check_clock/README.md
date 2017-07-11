# check_clock configuration for icinga2(1)
In a default icinga2(1) installation, this CheckCommand definition may be placed
in commands.conf:

    object CheckCommand "check_clock" {
        import "plugin-check-command"
        command = [ PluginDir + "/check_clock", + "$host.vars.ntp_server$" ]

        arguments = { 
            "-w" = { 
                value = "$offset_warning$"
                order = "-2"
            }

            "-c" = { 
                value = "$offset_critical$"
                order = "-1"
            }
        }
        /*
         * If left unspecified, these default offset values are assumed:
         *
         * vars.offset_warning = "1" 
         * vars.offset_critical = "2" 
         */
    }

To monitor the drift of a host, these Service and Host objects may be defined:

    object Host "myserver.sol1.net" {
        import "generic-host"
        address = "192.168.0.1"
        vars.ntp_server = "ntp.internode.on.net"
    }

    apply Service "ntpdrift" {
        import "generic-service"
        check_command = "check_clock"

        assign where host.vars.ntp_server
    }
