### Update Gurnicorn.py
change from: bind = '127.0.0.1:8001' to: bind = '0.0.0.0:8001'

### Update Nginx.conf
chagne from: proxy_pass http://127.0.0.1:8001;
to: proxy_pass http://{container-name}:8001;

make sure that you have the static files inside the nginx container (see the NGINX dockerfile)
