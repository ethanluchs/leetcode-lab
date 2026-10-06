FROM python:3.12-slim

# Pin the two packages we install directly. Their own dependencies are not
# pinned, so for identical environments build once and hand out the image
# (docker save / docker load) rather than having everyone build.
ARG LCPY_VERSION=1.0.14
ARG PYTEST_VERSION=8.3.4

# Which problems to bake in. Default is a focused five: arrays, stacks,
# strings, trees. Override in compose.yaml -- e.g. "-t grind-75".
ARG GEN_ARGS="-n 1 -n 20 -n 121 -n 125 -n 226"

# OPTIONAL -- left off on purpose. Graphviz only renders diagrams inside
# Jupyter; in a terminal the data structures print as ASCII either way.
# Uncomment to demo layer-cache invalidation: every layer below it rebuilds.
# RUN apt-get update \
#  && apt-get install -y --no-install-recommends graphviz \
#  && rm -rf /var/lib/apt/lists/*

# The PyPI name is `leetcode-py-sdk`, NOT `leetcode-py`.
# pytest is not a dependency of the package, so install it explicitly.
RUN pip install --no-cache-dir \
      "leetcode-py-sdk==${LCPY_VERSION}" \
      "pytest==${PYTEST_VERSION}"

# Generate at BUILD time from templates bundled in the wheel -- no network
# needed at run time, so the finished image works offline.
RUN mkdir -p /opt/seed \
 && lcpy gen ${GEN_ARGS} -o /opt/seed/leetcode \
 && echo "Baked in $(find /opt/seed/leetcode -maxdepth 1 -mindepth 1 -type d | wc -l) problems"

RUN useradd -m -u 1000 -s /bin/bash student

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Strip CRLF in case the repo was checked out on Windows without .gitattributes
# (e.g. downloaded as a zip). A CRLF shebang fails with a misleading
# "no such file or directory".
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/entrypoint.sh \
 && mkdir -p /work && chown student:student /work

USER student
WORKDIR /work

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
