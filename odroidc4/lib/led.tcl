# led

oo::class create Led {
    variable Blinking

    constructor {} {
        my off
        set Blinking 0
    }
    
    method Brightness {val} {
	set fid [open /sys/class/leds/[namespace tail [self]]/brightness w]
	puts -nonewline $fid $val
	close $fid
    }
    
    method Trigger {val} {
	set fid [open /sys/class/leds/[namespace tail [self]]/trigger w]
	puts -nonewline $fid $val
	close $fid
    }
    
    method on {} {
        my noblink
        my Brightness 1
    }
    
    method off {} {
        my noblink
        my Brightness 0
    }
    
    method blink {} {
        if {!$Blinking} {
            my Trigger timer
            set Blinking 1
        }
    }

    method noblink {} {
        my Trigger none
        set Blinking 0
    }
}

package provide led 1.0

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
