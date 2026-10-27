# DỰ THẢO SR-V. Chưa build, chưa push. Cú pháp kiểm bằng `docker build --check` hoặc hadolint.
# Verifier B2: Godot 4.7.2 headless Linux x86_64 + pck của game, KHÔNG mạng ra, KHÔNG secret.
# Egress phải tắt ở tầng chạy (docker --network none / Container không egress), không chỉ ở image.
FROM debian:bookworm-slim AS fetch
ARG GODOT_VERSION=4.7.2-stable
# Điền sha256 chính thức của zip trước khi build; build fail nếu sai.
ARG GODOT_SHA256=REPLACE_ME
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /g.zip "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
 && echo "${GODOT_SHA256}  /g.zip" | sha256sum -c - \
 && unzip /g.zip -d /g && mv /g/Godot_v${GODOT_VERSION}_linux.x86_64 /godot

FROM debian:bookworm-slim
# Thư viện tối thiểu cho Godot headless (không GPU): fontconfig/libstdc++ là đủ cho text server.
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig1 libstdc++6 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -u 10001 -M verifier && mkdir -p /app /work && chown verifier /work
COPY --from=fetch /godot /app/godot
# verifier.pck do verifier/build.sh xuất từ godot/ (không nằm trong repo). Không COPY secret, không .env.
COPY verifier.pck /app/verifier.pck
USER verifier
ENV HOME=/work
WORKDIR /work
# Job đã ký được lớp ngoài (Worker/queue consumer) kiểm chữ ký rồi mới đặt log vào /work/in.json.
# Verifier chỉ đọc /work/in.json, ghi /work/out.json (JSON schema cố định), không gì khác.
ENTRYPOINT ["/app/godot", "--headless", "--main-pack", "/app/verifier.pck", "res://tools/verify_run.tscn", "--", "--in=/work/in.json", "--out=/work/out.json"]
