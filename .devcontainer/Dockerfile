# ================================
# Stage 1: Builder
# ================================
FROM python:3.12-slim AS builder

# --- Proxy para build y runtime ---
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV NO_PROXY=${NO_PROXY}

# --- Configurar proxy para APT ---
RUN echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" > /etc/apt/apt.conf.d/proxy.conf \
 && echo "Acquire::https::Proxy \"${HTTPS_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf

# --- Probar que APT usa el proxy ---
#RUN apt-get update

WORKDIR /app
COPY . .

# ================================
# Stage 2: Runtime
# ================================
FROM python:3.12-slim AS runtime

ENV HTTP_PROXY="http://10.219.155.114:44355"
ENV HTTPS_PROXY="http://10.219.155.114:44355"
#ENV NO_PROXY=${NO_PROXY}

WORKDIR /app
COPY --from=builder /app /app

EXPOSE 3000
CMD ["bash", "-c", "\
HTTP_PROXY=\"${HTTP_PROXY:-1.1.1.1:80}}\"\
&& HTTPS_PROXY=\"${HTTPS_PROXY:-1.1.1.1:80}}\"\
&& echo \"Acquire::http::Proxy \\\"$HTTP_PROXY\\\";\" > /etc/apt/apt.conf.d/proxy.conf\
&& echo \"Acquire::https::Proxy \\\"$HTTPS_PROXY\\\";\" >> /etc/apt/apt.conf.d/proxy.conf\
&& python3 -m http.server 3000"]

#docker run -d -e HTTP_PROXY=http://10.219.155.114:44355 -e HTTPS_PROXY=http://10.219.155.114:44355 -p 3000:3000 --name testproxy mi_simplespa_app
#docker exec -it testproxy bash