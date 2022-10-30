# nav to nearest point in line of travel approx
#

package require tdom

oo::object create nav

oo::objdefine nav {

    variable scr findnext findclose loaded file

    method initvars {} {

        set scr [string trim [self] :]
        set file $::navfile
        set loaded [my makedb $file]

        if {$loaded} {
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
                ORDER by dist
                LIMIT 1
            }]
        }
    }

    method makedb {file} {

        if {![file exists $file]} {
            return 0
        }

        db allrows { DROP SCHEMA IF EXISTS nav CASCADE}
        db allrows { CREATE SCHEMA nav }
        db allrows {
            CREATE table nav.point (
                id serial primary key, 
                name text, 
                description text, 
                geog geography(point, 4283))}

        set dbpoint [ db prepare {
            INSERT into nav.point (name, description, geog)
            VALUES (:name, :desc, ST_SetSRID( ST_Point(:lon, :lat), 4283)::geography )
        }]

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
            puts " $desc, $lon, $lat, $name"
            $dbpoint allrows \
                    [dict create name $desc desc $name lat $lat lon $lon]
        }

        db allrows { CREATE INDEX idx_point_geog on nav.point USING gist(geog) }
        return 1
    }

    method updatescreen {tpv} {
        if {!$loaded} {
            lcd puts "widget_set $scr ${scr}1 1 1 NO"
            lcd puts "widget_set $scr ${scr}2 1 2 NAV"
            lcd puts "widget_set $scr ${scr}3 1 3 FILE"
            lcd puts "widget_set $scr ${scr}4 1 4 { }"
            return
        }
        dict with tpv {
            if {[info exists mode]} {
                if {$mode >= 2} {
                    lassign [$findnext allrows \
                        [dict create lat $lat lon $lon track $track]] res
                    dict with res {}
                    if {$dist < 300} {
                        blue blink
                    } else {
                        blue off
                    }
                    if {$dist < 200} {
                        green blink
                    } else {
                        green off
                    }
                    if {$dist < 100} {
                        red blink
                    } else {
                        red off
                    }
                    set vehicle [format "%.0f m/s  %s" $speed [ compass $track]]
                    set point [format "%.0f m %s" $dist [ compass $brg]]
                    lcd puts "widget_set $scr ${scr}1 1 1 {$vehicle}"
                    lcd puts "widget_set $scr ${scr}2 1 2 {$name}"
                    lcd puts "widget_set $scr ${scr}3 1 3 {$description}"
                    lcd puts "widget_set $scr ${scr}4 1 4 {$point}"
                } else {
                    lcd puts "widget_set $scr ${scr}1 1 1 NO"
                    lcd puts "widget_set $scr ${scr}2 1 2 FIX"
                    lcd puts "widget_set $scr ${scr}3 1 3 { }"
                    lcd puts "widget_set $scr ${scr}4 1 4 { }"
                }
            } else {
                lcd puts "widget_set $scr ${scr}1 1 1 NO"
                lcd puts "widget_set $scr ${scr}2 1 2 GPS?"
                lcd puts "widget_set $scr ${scr}3 1 3 { }"
                lcd puts "widget_set $scr ${scr}4 1 4 { }"
            }
        }
    }
    
    method definescreen {} {

        my initvars

        lcd puts "screen_add $scr"
        lcd puts "screen_set $scr -heartbeat off"
        lcd puts "widget_add $scr ${scr}1 string"
        lcd puts "widget_add $scr ${scr}2 string"
        lcd puts "widget_add $scr ${scr}3 string"
        lcd puts "widget_add $scr ${scr}4 string"
    }

}

package provide nav 1.0
