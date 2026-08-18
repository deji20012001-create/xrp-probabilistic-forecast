FROM python:3.11-slim
WORKDIR /service

# Keep numerical libraries inside Render's memory/CPU limits.
ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1

# The signed-in GitHub upload includes the tested source bundle.
COPY source.zip /tmp/source.zip
RUN python -m zipfile -e /tmp/source.zip /service \
    && pip install --no-cache-dir .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"
CMD ["sh", "-c", "python -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
