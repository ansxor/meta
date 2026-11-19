# Kestrel handheld — hardware overview

## Charging / power input
The Kestrel negotiates USB Power Delivery. It only fast-charges and enables docked mode
when the source offers a **15V fixed PDO at ≥2.6A**. Sources topping out at 9V or 12V will
charge slowly in handheld mode but the console refuses docked mode.

## Video out
Docked video uses **DisplayPort Alt Mode** over the USB-C port. Docks that drive HDMI via
DisplayLink/USB graphics chips are not supported (no driver on the console).

## Power budget
In docked mode the console draws up to 39W through the dock, so the dock's **USB-C
power passthrough must be ≥39W** after the dock's own consumption.
