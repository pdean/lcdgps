
lcdgps
======
requires 
raspberry pi 4,
preferably [arch linux](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4), 
[rtc](https://www.adafruit.com/product/3295),
[lcd 20x4](https://www.adafruit.com/product/198),
[rotary encoder with button](https://www.adafruit.com/product/377), 
extra button as menu button,
leds,
[piio](https://wiki.tcl-lang.org/page/piio),
[evsieve](https://github.com/KarsMulder/evsieve),
[lcdproc](https://github.com/lcdproc/lcdproc),
gps mouse usb,
[gpsd](https://gpsd.gitlab.io/gpsd/client-howto.html),
[postgis](http://www.refractions.net/products/postgis/), 
[tcl](https://www.tcl.tk/)


inspired by [cacheberry-pi](https://github.com/jclement/Cacheberry-Pi) but the code will make you vomit

todo
-------
- fix service file - make sure usb is mounted
- check speed in nav
- check offset in tmr
- ini file
- led functions
- [power button](https://embeddedcomputing.com/technology/open-source/development-kits/raspberry-pi-power-up-and-shutdown-with-a-physical-button)
- add menu for enabling/disabling plugins
- logger
