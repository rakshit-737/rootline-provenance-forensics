# ROOTLINE API + attack-replay UI. Lab use only, no authentication. It listens on 0.0.0.0 inside the
# container; publish it on loopback only:  docker run --rm -p 127.0.0.1:8000:8000 ghcr.io/rakshit-737/rootline-provenance-forensics
# python:3.12-slim, pinned by digest (Dependabot's docker updates keep it current)
FROM python:3.14-slim@sha256:a2b82f3c48559aa0a8446d9af49826b6e2b2016f4cd2afabfe6013ec53729170
WORKDIR /app
COPY pyproject.toml README.md LICENSE ./
COPY docker/requirements.lock ./docker/
COPY src ./src
COPY tests/fixtures ./fixtures
# Runtime dependencies from a hash-locked file (uv pip compile ... --generate-hashes, see its header;
# kept outside Dependabot's pip scope, which would bump single pins and break the lock);
# the package itself is then installed without resolving anything else.
RUN pip install --no-cache-dir --require-hashes -r docker/requirements.lock && \
    pip install --no-cache-dir --no-deps . && \
    useradd -r -u 10001 rootline
USER rootline
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=4)"]
# Preloads the committed OTRF Log4Shell capture (Sysmon + AUOMS, fused) so the UI has a story.
CMD ["rootline", "serve", "fixtures/log4shell_sysmon.json", "fixtures/log4shell_auoms.json", "--fuse", "--host", "0.0.0.0", "--port", "8000"]
