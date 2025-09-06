# Stage 2: runtime
FROM nginx:alpine
COPY . /usr/share/nginx/html:ro

EXPOSE 80
