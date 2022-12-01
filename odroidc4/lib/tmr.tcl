# tmr road location
# https://www.data.qld.gov.au/dataset/road-location-and-traffic-data

oo::object create tmr

oo::objdefine tmr {
    variable scr pt2ch

    method definescreen {} {
        set scr [namespace tail [self]]
        set pt2ch [db prepare {
            SELECT (d1 * cos(b1-b0)/1000 + tstart ) as ch,
                 (d1 * sin(b1-b0)) as os,
                 section,
                 code,
                 description
            FROM
                (SELECT section,
                    code,
                    description,
                    tstart,
                    tend,
                    ST_Distance(ST_Startpoint(s.geog::geometry)::geography,
                                ST_Endpoint(s.geog::geometry)::geography) as d0,
                    ST_Azimuth(ST_Startpoint(s.geog::geometry)::geography,
                               ST_Endpoint(s.geog::geometry)::geography) as b0,
                    ST_Distance(ST_Startpoint(s.geog::geometry)::geography, p.geog) as d1,
                    ST_Azimuth(ST_Startpoint(s.geog::geometry)::geography, p.geog) as b1
                FROM
                    tmr.segs as s
                CROSS JOIN
                   (SELECT ST_Setsrid(ST_Point(:lon,:lat),4283)::geography as geog) as p
                WHERE left(code,1) = any(string_to_array('123AKQ', NULL))
                ORDER by s.geog <-> p.geog 
                LIMIT 1) as foo
        }]

        lcd puts "screen_add $scr"
        #lcd puts "screen_set $scr -heartbeat off"
        lcd puts "widget_add $scr title title"
        lcd puts "widget_set $scr title {tmr roadloc}"
        #lcd puts "widget_add $scr ${scr}1 string"
        lcd puts "widget_add $scr ${scr}2 string"
        lcd puts "widget_add $scr ${scr}3 scroller"
        lcd puts "widget_add $scr ${scr}4 string"
    }

    method updatescreen {tpv} {
        dict with tpv {}
        if {[info exists mode]} {
            if {$mode >= 2} {
                lassign [$pt2ch allrows [dict create lat $lat lon $lon]] res
                dict with res {}
                lassign [split $time T] date time
                #lassign [split $description |] sec desc
                set chos [format "%.3f km  %.0f m" $ch $os]
                set vehicle [format "speed %.0f m/s  %s" $speed [ compass $track]]
                #lcd puts "widget_set $scr ${scr}1 1 1 {$time}"
                lcd puts "widget_set $scr ${scr}2 1 2 {$vehicle}"
                lcd puts "widget_set $scr ${scr}3 1 3 20 3 h 2 {$description}"
                lcd puts "widget_set $scr ${scr}4 1 4 {$chos}"
            } else {
                lcd puts "widget_set $scr ${scr}2 1 2 {NO FIX}"
            }
        } else {
            lcd puts "widget_set $scr ${scr}2 1 2 {NO GPS?}"
        }
    }
}

package provide tmr 1.0
