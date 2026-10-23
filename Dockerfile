FROM python:3.12.15-slim-bookworm@sha256:6a0e06f5ba0b373d051aabd3fffb9b873f27f9a2a3a14bcbe37dee6f0e3bbc70 AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

FROM base AS builder
WORKDIR /build
COPY requirements/build.txt requirements/build.txt
RUN python -m pip install --require-hashes --only-binary=:all: -r requirements/build.txt
COPY pyproject.toml README.md LICENSE ./
COPY src/ src/
RUN python -m pip wheel --no-deps --no-build-isolation --wheel-dir /wheels .

FROM base AS runtime
COPY requirements/runtime.txt /tmp/runtime.txt
COPY --from=builder /wheels/ /tmp/wheels/
RUN python -m pip install --require-hashes --only-binary=:all: -r /tmp/runtime.txt \
    && python -m pip install --no-index --no-deps /tmp/wheels/*.whl \
    && python -m pip check \
    && rm -rf /tmp/wheels /tmp/runtime.txt
COPY docker/smoke_test.py /usr/local/bin/soly-smoke-test.py
USER 10001:10001
WORKDIR /tmp
CMD ["python", "-I", "/usr/local/bin/soly-smoke-test.py"]
