# nav to nearest point in line of travel approx
#

package require tdom

oo::class create Nav {
    constructor {} {
        puts "created [self]"
    }
    method updatescreen {tpv} {
        tailcall nav updatescreen $tpv [namespace tail [self]]
    }
}

oo::object create nav

oo::objdefine nav {
    variable dbpoint findnext findclose loads

    method definescreen {} {

        db allrows { DROP SCHEMA IF EXISTS nav CASCADE}
        db allrows { CREATE SCHEMA nav }
        db allrows {
            CREATE table nav.point (
                id serial primary key,
                name text,
                description text,
                screen text,
                geog geography(point, 4283))}

        set dbpoint [ db prepare {
            INSERT into nav.point (name, description, screen, geog)
            VALUES (:name, :desc, :scr,
                 ST_SetSRID( ST_Point(:lon, :lat), 4283)::geography )
        }]

        set loads 0
        set dir $::datadir
        set fof [file join $dir fof.txt]
        set in [open $fof r]
        set files [split [read -nonewline $in] \n]
        close $in
        puts $files

        foreach f $files {
            set scr [file root $f]
            set file [file join $dir $f]
            set loaded [my makedb $file $scr]
            if {$loaded} {
                incr loads
                Nav create ::$scr
                lcd puts "screen_add $scr"
                #lcd puts "screen_set $scr -heartbeat off"
                lcd puts "widget_add $scr title title"
                lcd puts "widget_set $scr title {$scr}"
                lcd puts "widget_add $scr ${scr}2 string"
                lcd puts "widget_add $scr ${scr}3 scroller"
                lcd puts "widget_add $scr ${scr}4 string"
            }
        }

        if {$loads} {
            db allrows { 
                CREATE INDEX idx_point_geog on nav.point USING gist(geog) }
            set findnext [db prepare {
                SELECT name, 
                       description,
                       s.geog <-> p.geog as dist,
                       degrees(ST_Azimuth(p.geog, s.geog)) as brg 
                FROM
                    nav.point as s
                    CROSS JOIN
                    (SELECT
                        ST_Setsrid(ST_Point(:lon,:lat),4283)::geography as geog) as p
                WHERE cosd(degrees(ST_Azimuth(p.geog, s.geog)) - :track) >= 0.0
                        and screen = :scr
                ORDER by dist
                LIMIT 1
            }]

            set findclose [db prepare {
                SELECT name, 
                       description,
                       s.geog <-> p.geog as dist,
                       degrees(ST_Azimuth(p.geog, s.geog)) as brg 
                FROM
                    nav.point as s
                    CROSS JOIN
                    (SELECT
                        ST_Setsrid(ST_Point(:lon,:lat),4283)::geography as geog) as p
                WHERE screen=:scr
                ORDER by dist
                LIMIT 1
            }]
        }
    }

    method makedb {file scr} {

        if {![file exists $file]} {
            return 0
        }

        set doc [dom parse [tDOM::xmlReadFile $file]]
        set root [$doc documentElement]

        set ns {kml http://www.opengis.net/kml/2.2}
        $doc selectNodesNamespaces $ns

        foreach placemark [$root selectNodes //kml:Placemark] {
            set name [[lindex [$placemark getElementsByTagName name] 0] text]
            set desc [[lindex [$placemark getElementsByTagName description] 0] text]
            lassign [$placemark getElementsByTagName Point] point
            lassign [$point getElementsByTagName coordinates] coord
            lassign [split [$coord text] ,] lon lat
            puts " $desc, $lon, $lat, $name, $scr"
            $dbpoint allrows \
                    [dict create name $desc desc $name scr $scr lat $lat lon $lon]
        }
        return 1
    }

    method updatescreen {tpv scr} {
        dict with tpv {}
        if {[info exists mode]} {
            if {$mode >= 2} {
                lassign [$findnext allrows \
                    [dict create lat $lat lon $lon scr $scr track $track]] res
                if {[llength $res]} {
                    dict with res {}
                    if {$dist < 100} {
                        green blink
                        yellow off
                        red off
                    } elseif {$dist < 200} {
                        yellow blink
                        red off 
                        green off  
                    } elseif {$dist < 300} {
                        red blink
                        green off 
                        yellow off
                    }
                    set vehicle [format "speed %.0f m/s  %s" $speed [ compass $track]]
                    set point [format "dist %.0fm %s" $dist [ compass $brg]]
                    set desc "$name $description"
                    lcd puts "widget_set $scr ${scr}2 1 2 {$vehicle}"
                    lcd puts "widget_set $scr ${scr}3 1 3 20 3 h 2 {$desc}"
                    lcd puts "widget_set $scr ${scr}4 1 4 {$point}"
                } else {
                    lcd puts "widget_set $scr ${scr}2 1 2 {NO PTS FD}"
                }
            } else {
                lcd puts "widget_set $scr ${scr}2 1 2 {NO FIX}"
            }
        } else {
            lcd puts "widget_set $scr ${scr}2 1 2 {NO GPS?}"
        }
    }
}

package provide nav 1.0
