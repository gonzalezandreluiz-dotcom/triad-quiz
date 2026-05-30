FROM nginx:alpine
# commit: 4843935
RUN apk add --no-cache curl \
 && curl -sf "https://raw.githubusercontent.com/gonzalezandreluiz-dotcom/triad-quiz/4843935/index.html" \
         -o /usr/share/nginx/html/index.html \
 && curl -sf "https://raw.githubusercontent.com/gonzalezandreluiz-dotcom/triad-quiz/4843935/logo.svg" \
         -o /usr/share/nginx/html/logo.svg \
 && apk del curl
