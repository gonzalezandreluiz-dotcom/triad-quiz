FROM nginx:alpine
ARG CACHEBUST=2026-05-30T00:30
RUN apk add --no-cache curl \
 && curl -sf "https://raw.githubusercontent.com/gonzalezandreluiz-dotcom/triad-quiz/master/index.html" \
         -o /usr/share/nginx/html/index.html \
 && curl -sf "https://raw.githubusercontent.com/gonzalezandreluiz-dotcom/triad-quiz/master/logo.svg" \
         -o /usr/share/nginx/html/logo.svg \
 && apk del curl
