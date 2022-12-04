# lcd

oo::object create lcd

oo::objdefine lcd {
    variable Sock Wid Hgt Screen Onlisten Onignore last

    method connect {} {
        set Sock [socket localhost 13666]
        chan configure $Sock -blocking no
        chan event $Sock readable [list [self] read]
        set Screen {}
        set Onlisten {}
        set Onignore {}
        my puts "hello"
        my puts "client_set name {lcdgps}"
    }

    method read {} {
        if {[gets $Sock line] < 0} {return}
        set cmd [lindex $line 0]
        switch $cmd {
            connect {
                set Wid [lindex $line 7]
                set Hgt [lindex $line 9]
            }
            listen {
                set Screen [lindex $line 1]
                tailcall {*}$Onlisten
            }
            ignore {
                set Screen {}
                tailcall {*}$Onignore
            }
            success { }
            default {
                puts $line
                puts "    $last"
            }
        }
    }

    method puts {str} {
        set last $str
        puts $Sock $str
        flush $Sock
    }

    method onlisten {script} { set Onlisten $script }
    method onignore {script} { set Onignore $script }

    method screen {} {set Screen}

}

package provide lcd 1.0
