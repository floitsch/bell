import certificate_roots
import http
import net
import tls
import encoding.json
import pubsub

HOST ::= "fcm.googleapis.com"
URL ::= "https://fcm.googleapis.com/fcm/send"
// From firebase-console -> settings -> cloud-messaging.
KEY ::= PUT YOUR SERVER KEY HERE
// From the application itself (`FirebaseMessaging.instance.getToken()`)
DEVICE_ID ::= PUT YOUR INSTANCE_TOKEN HERE

main:
  send

send:
  network := net.open
  socket := network.tcp_connect HOST 443
  secure := tls.Socket.client socket
      --server_name=HOST
      --root_certificates=[certificate_roots.GTS_ROOT_R1] //GLOBALSIGN_ROOT_CA]
  connection := http.Connection secure HOST
  request/http.Request := connection.new_request "POST" URL
  headers := request.headers
  headers.set "Content-Type" "application/json"
  headers.set "Authorization" "key=$KEY"
  request.body = json.encode {
    "to": DEVICE_ID,
    "notification": {
      "title": "from esp32",
      "body": "bell",
    },
  }
  response := request.send
  bytes := ByteArray 0
  while data := response.read:
    bytes += data
  // print bytes.to_string
  connection.close
