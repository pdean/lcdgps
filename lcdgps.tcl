#!/usr/bin/env tclsh
#
# lcdgps
#

lappend auto_path .
package require lcd
package require gps
package require led

Led create blue 5
Led create green  6
Led create red 13

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

# screens

package require tmr
package require loc

proc definescreens {} {
    tmr definescreen
    loc definescreen
}

proc updatescreen {tpv} {
    set scr [lcd screen]
    if {[string length $scr]} {
        $scr updatescreen $tpv
    }
}

# event loop

proc init {} {
    lcd connect
    gps connect
    gps repeat 125
    definescreens
    gps action  "updatescreen"
    lcd onlisten "gps poll"
    lcd onignore "gps stop"
}

after 0 init
vwait forever
