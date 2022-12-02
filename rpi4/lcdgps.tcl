#!/usr/bin/env tclsh
#
# lcdgps
#

# screens to display 
#### global variables are nasty ####

set datadir /mnt/usb
set screens [list nav tmr]
#set screens [list tmr]

# load modules

lappend auto_path lib
package require lcd
package require gps
package require led

Led create yellow
Led create green
Led create red

# database

package require tdbc::postgres
set conninfo [list -host localhost -db gis -user gis]
tdbc::postgres::connection create db {*}$conninfo

# some maths

namespace path {::tcl::mathop ::tcl::mathfunc}

proc fmod {x y} {
    return [- $x [* [floor [/ $x $y]] $y]]
}

proc compass {a} {
    set tab [list N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW N]
    return [lindex $tab [round [/ [fmod $a 360] 22.5]]]
}

# define screens

proc definescreens {} {
    foreach scr $::screens {
        package require $scr
        $scr definescreen
    }
}

# event loop

proc listen {} {
    gps poll
}

proc ignore {} {
    gps stop
    foreach led [info class instances Led] {
        $led off
    }
}

proc updatescreen {tpv} {
    set scr [lcd screen]
    if {[string length $scr]} {
        $scr updatescreen $tpv
    }
}

proc init {} {
    lcd connect
    gps connect
    gps repeat 125
    definescreens
    gps action  "updatescreen"
    lcd onlisten "listen"
    lcd onignore "ignore"
}

after 0 init
vwait forever
