// Copyright (C) 2025 Florian Loitsch <florian@loitsch.com>
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import gpio
import simple-config show *

import .src.notifier

RING ::= 13

main:
  notifier := Notifier
  notifier.start

  pin := gpio.Pin RING --input
  print "Pin is now: $pin.get"

  while true:
    pin.wait-for 0
    print "Pin changed to 0"
    notifier.notify
    sleep --ms=200  // Debounce.
    pin.wait-for 1
    sleep --ms=200  // Debounce.
