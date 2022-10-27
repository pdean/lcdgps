# led
#
package require piio

oo::class create Led {
    variable Pin Script Blinking

    constructor {pin} {
        set Pin $pin
        piio function $pin output
        set Blinking 0
        set Script {}
        my off
    }

    method on {} {
        my Noblink
        piio output $Pin 1
    }

    method off {} {
        my Noblink
        piio output $Pin 0
    }

    method blink {} {
        if {!$Blinking} {
            set Blinking 1
            my blinker
        }
    }

    method blinker {{state 1}} {
        piio output $Pin $state 
        set Script [after 500 [list [self object] blinker [expr {!$state}]]]
    }

    method Noblink {} {
        if {$Blinking} {
            after cancel $Script
            set Script {}
            set Blinking 0
        }
    }
}

package provide led 1.0
