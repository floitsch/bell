// Copyright (C) 2022 Florian Loitsch. All rights reserved.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import gpio
import pubsub
import net
import net.tcp

TOPIC ::= "cloud:bell"

VOLUME ::= 27
UP ::= 14
DOWN ::= 12

/** Simulates a button press on the given $pin. */
simulate_button pin:
  button := gpio.Pin pin --output
  button.set 0
  sleep --ms=200
  button.set 1
  button.close

change_volume: simulate_button VOLUME
melody_up: simulate_button UP
melody_down: simulate_button DOWN

main:
  network := net.open
  socket/tcp.ServerSocket := network.tcp_listen port
  address := "http://$network.address:$socket.local_address.port"
  listen --no-blocking

listen --blocking/bool:
  print "wakeup - checking messages"
  pubsub.subscribe TOPIC --blocking=blocking: | msg/pubsub.Message |
    content := msg.payload.to_string
    if content == "volume":
      change_volume
    else if content == "up":
      melody_up
    else:
      assert: content == "down"
      melody_down
  print "done processing"
