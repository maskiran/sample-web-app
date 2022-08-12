apt update
apt install -y nginx ssl-cert python3-flask gunicorn node-ws

echo "Create nginx default site"
cat <<EOF > /etc/nginx/sites-enabled/default
# to support websocket
map \$http_upgrade \$connection_upgrade {
	default upgrade;
	''      close;
}
server {
	listen 80 default_server;
	listen 443 ssl default_server;
	include snippets/snakeoil.conf;
	location / {
		proxy_pass http://localhost:8000;
		proxy_set_header x-forwarded-for \$proxy_add_x_forwarded_for;
		# hop-by-hop headers must be explicitly set, these headers are not
		# automatically proxied/forwarded from the client to the upstream
		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection \$connection_upgrade;
	}
}
EOF

echo "Create /svc and the restapp.py"
mkdir /svc
cat <<EOF > /svc/restapp.py
import os
import json
import argparse
from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST', 'PUT', 'DELETE'])
@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def index(path=""):
    hdrs = dict(request.headers)
    hdrs['Method'] = request.method
    hdrs['Client'] = request.remote_addr
    return json.dumps(hdrs, indent=4) + "\n"
EOF

num_workers=$(cat /proc/cpuinfo | grep processor | wc -l)

echo "Create restapp systemd service"
cat <<EOF > /etc/systemd/system/restapp.service
[Unit]
Description=Run restapp that returns back all the headers
After=network.target

[Service]
User=ubuntu
Group=ubuntu
ExecStart=/usr/bin/gunicorn --chdir /svc -w $num_workers restapp:app

[Install]
WantedBy=multi-user.target
EOF

echo "Restart services"
systemctl daemon-reload
systemctl restart nginx
systemctl start restapp

cat <<EOF > /root/notes.txt
# To run app directly without going through nginx
systemctl stop nginx
systemctl stop restapp
gunicorn --chdir /svc -w $num_workers --bind 0.0.0.0:80 restapp:app
gunicorn --chdir /svc -w $num_workers --bind 0.0.0.0:443 --keyfile /etc/ssl/private/ssl-cert-snakeoil.key --certfile /etc/ssl/certs/ssl-cert-snakeoil.pem restapp:app
wscat -l 80
EOF
