FROM python:3.11-slim
WORKDIR /service

# LightGBM wheels require the GNU OpenMP runtime on Debian slim.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY source.zip.b64.* /tmp/source-parts/
RUN cat /tmp/source-parts/source.zip.b64.* | base64 -d > /tmp/source.zip \
    && python -m zipfile -t /tmp/source.zip \
    && python -m zipfile -e /tmp/source.zip /service

RUN python -m pip install --no-cache-dir --retries 10 --timeout 60 --upgrade \
      "pip>=24" "setuptools>=68" wheel
RUN python -m pip install --no-cache-dir --no-build-isolation --prefer-binary \
      --retries 10 --timeout 60 .

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"
CMD ["sh", "-c", "python -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
