// Copyright (C) 2021 Florian Loitsch. All rights reserved.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import gpio
import pubsub
import .notification as notification

TOPIC ::= "cloud:bell_ring"

TRIGGER ::= 13

main:
  print "Detecting when the bell rings"
  pin := gpio.Pin TRIGGER --input
  while true:
    pin.wait_for 0
    // print "bell is ringing"
    // pubsub.publish TOPIC "ringing"
    notification.send
    sleep --ms=200  // Debounce.
    pin.wait_for 1
    sleep --ms=200  // Debounce
