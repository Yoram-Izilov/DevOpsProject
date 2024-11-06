# Dockerfile.nginx
FROM nginx:latest

# Create application directory
RUN mkdir -p /opt/status-page/statuspage/static/

# Copy your custom NGINX config and Static files
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./default.conf /etc/nginx/conf.d/default.conf
COPY ./static/ /opt/status-page/statuspage/static/

