# Bell

Toit and Flutter app for a (more) intelligent door bell.

The door bell has been modified to contain an ESP32 which can
control the volume and melody of the bell.

At the same time, one of the ESP32's pins is pulled high when
the door bell is ringing. It uses that as signal to send
a notification to the phone app.


The phone app is a simple Flutter app that controls the bell.
