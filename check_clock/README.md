# check_clock - compare 
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
         * If left unspecified, assumes default values as per below
         *
         * vars.offset_warning = "1" 
         * vars.offset_critical = "2" 
	 */
}
