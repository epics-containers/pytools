# This file is for use as a .vscode devcontainer
# The devcontainer should run as root and use user-mode podman or
# docker with user namespaces.

FROM python:3.9 as environment

ENV VIRTUALENV=/venv
ENV PATH=${VIRTUALENV}:${PATH}

# developer target includes the build tools ####################################
FROM environment as developer

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python3-pyqt5


RUN python3 -m venv ${VIRTUALENV}

ENV DEV_PROMPT=PYTOOLS

# PVAccess tools
RUN pip install p4p
# PVAccess viewer
RUN pip install c2dataviewer

RUN echo dummy line for cache blow AGAIN

# runtime target holds just the venv ###########################################

FROM environment as runtime

COPY --from=developer ${VIRTUALENV} ${VIRTUALENV}
