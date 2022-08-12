# A Sample WebApp Setup on Ubuntu

1. Install nginx python-flask gunicorn node-ws (websocket)
1. Install dummy TLS Certificates
1. Create a sample python flask app and a systemctl script to run this via gunicorn
1. Create nginx sites-enabled/default to proxy to this gunicorn/flask app
1. Start nginx, restapp
1. Add /root/notes.txt that shows how to run the app as standalone instead of proxying via nginx
