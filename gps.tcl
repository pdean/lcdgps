#!/usr/bin/env tclsh
#
# poll gpsd

package require json  

oo::object create gps

oo::objdefine gps {
    variable Sock Timer Repeat Script Locked

    method connect {} {
        set Sock [socket localhost 2947]
        chan configure $Sock -blocking off
        chan event $Sock readable [list [self] read]
        puts $Sock {?WATCH={"enable":true}}
        flush $Sock
        set Script [list ::puts]
        set Repeat 5000
        set Locked 0
    }

    method read {} {
        if {[gets $Sock line] < 0} { return }
        set data [::json::json2dict $line]
        dict with data {}
        if {$class eq "POLL"} {
            if {[info exists tpv]} {
                {*}$Script [lindex $tpv end]
            }
        } else {
            puts $data
        }
    }

    method  poll {} {
        if {!$Locked} {
            puts $Sock {?POLL;}
            flush $Sock
            set Timer [after $Repeat [list [self] poll]]
        }
    }

    method stop {} { 
        if {!$Locked} {
            after cancel $Timer 
        }
    }

    method repeat {repeat} { set Repeat $repeat }
    method action {script} { set Script $script }
    method lock {} { set Locked 1 }
    method unlock {} { set Locked 0 }
}

package provide gps 1.0
