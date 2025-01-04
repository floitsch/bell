import certificate_roots
import http
import net
import tls
import encoding.json

HOST ::= "fcm.googleapis.com"
PATH ::= "/fcm/send"
// From firebase-console -> settings -> cloud-messaging.
KEY ::= PUT YOUR SERVER KEY HERE
// From the application itself (`FirebaseMessaging.instance.getToken()`)
DEVICE_ID ::= PUT YOUR INSTANCE_TOKEN HERE

main:
  send net.open

send network/net.Interface:
  print "Sending notification to phone"
  client := http.Client.tls network
      --root_certificates=[certificate_roots.GTS_ROOT_R1]
      --server_name=HOST

  headers := http.Headers
  headers.set "Authorization" "key=$KEY"
  response := client.post_json --host=HOST --path=PATH --headers=headers {
    "to": DEVICE_ID,
    "notification": {
      "title": "from esp32",
      "body": "bell",
    },
  }
  bytes := ByteArray 0
  while data := response.body.read:
    bytes += data
  print "Got response"
  print bytes.to_string
