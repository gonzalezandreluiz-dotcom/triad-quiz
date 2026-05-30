FROM nginx:alpine
# bust cache: 2026-05-30
COPY index.html /usr/share/nginx/html/index.html
COPY logo.svg /usr/share/nginx/html/logo.svg
