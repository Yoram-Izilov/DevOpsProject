FROM ubuntu:22.04

# Create application directory
RUN mkdir -p /opt/status-page
WORKDIR /opt/status-page

# Copy application code and systemd service files
COPY . .

# maybe not needed 
COPY contrib/*.service /etc/systemd/system/ 

# Update package list and install dependencies
# maybe not needed (last 4 lines of RUN from systemd)
RUN apt-get update && \
    apt install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev && \
    bash upgrade.sh && \    
    apt-get install -y systemd && \
    apt-get clean && \ 
    addgroup --system status-page && \
    adduser --system --group status-page

# Expose the application port (WSGI PORT)
EXPOSE 8001

# Command to run systemd
CMD ["/opt/status-page/venv/bin/gunicorn", "--pid" ,"/var/tmp/status-page.pid" ,"--pythonpath" ,"/opt/status-page/statuspage" ,"--config" ,"/opt/status-page/gunicorn.py", "statuspage.wsgi"]
