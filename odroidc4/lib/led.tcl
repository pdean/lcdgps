# led

oo::class create Led {

    constructor {} {
        my off
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
        my Trigger timer
    }

    method noblink {} {
        my Trigger none
    }
}

package provide led 1.0

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
