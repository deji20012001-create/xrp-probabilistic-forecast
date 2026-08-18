FROM python:3.11-slim
WORKDIR /service

# Keep numerical libraries inside Render's memory/CPU limits.
ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Extract separately so Render logs identify archive failures distinctly.
COPY source.zip /tmp/source.zip
RUN python -m zipfile -e /tmp/source.zip /service

# Install the build backend explicitly, then disable isolated-build's redundant
# backend download. Prefer wheels so scientific packages are never compiled.
RUN python -m pip install --no-cache-dir --retries 10 --timeout 60 --upgrade \
      "pip>=24" "setuptools>=68" wheel
RUN python -m pip install --no-cache-dir --no-build-isolation --prefer-binary \
      --retries 10 --timeout 60 .

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"
CMD ["sh", "-c", "python -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
