FROM python:3.12-slim-bookworm AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN groupadd --gid 10001 helpdesk \
    && useradd --uid 10001 --gid 10001 --home-dir /tmp --shell /sbin/nologin --no-create-home helpdesk

COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY gunicorn.conf.py ./
COPY app ./app

FROM base AS test

COPY requirements-dev.txt ./
RUN python -m pip install --no-cache-dir -r requirements-dev.txt

COPY pytest.ini ./
COPY tests ./tests

USER 10001:10001

CMD ["python", "-m", "pytest", "-q", "-p", "no:cacheprovider"]

FROM base AS runtime

ARG APP_VERSION=local
ENV APP_VERSION=${APP_VERSION}

EXPOSE 8000

USER 10001:10001

CMD ["gunicorn", "--config", "gunicorn.conf.py", "app:create_app()"]
