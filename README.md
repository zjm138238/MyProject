
user root;
worker_processes auto;

        error_log /usr/local/nginx/logs/error.log info;
        events {
            worker_connections 1024;
        }

        stream {
            upstream backend {
                #hash $remote_addr consistent;
                server 99.13.30.182:2424 weight=1 max_fails=3 fail_timeout=30s;
                server 99.13.30.183:2424 weight=1 max_fails=3 fail_timeout=30s;
                server 99.13.30.184:2424 weight=1 max_fails=3 fail_timeout=30s;
                #server 99.13.30.183:2424;
                #server 99.13.30.184:2424;
                #check interval=3000 rise=2 fall=5 timeout=1000;
            }

            server {
                listen 80;
                proxy_connect_timeout 1s;
                proxy_timeout 3s;
                proxy_pass backend;
            }

        }
