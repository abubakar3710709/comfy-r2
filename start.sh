#!/usr/bin/env bash
set -u
echo ">>> [1/4] SSH"
mkdir -p /root/.ssh /run/sshd
if [ -n "${PUBLIC_KEY:-}" ]; then
  echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
  chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys
fi
/usr/sbin/sshd || true
echo ">>> [2/4] Configuring rclone for R2"
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOF
[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY:-}
secret_access_key = ${R2_SECRET_KEY:-}
endpoint = https://${R2_ACCOUNT_ID:-}.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
EOF
install -m 0755 /app/getmodel.sh /usr/local/bin/getmodel 2>/dev/null || true
install -m 0755 /app/addmodel.sh /usr/local/bin/addmodel 2>/dev/null || true
echo ">>> [3/4] Models"
if [ -n "${MODELS:-}" ]; then
  echo "    auto-loading: ${MODELS}"
  /app/getmodel.sh ${MODELS} || echo "    (some bundles failed)"
else
  echo "    booting empty (fast). Load one with:  getmodel <name>"
fi
echo ">>> [4/4] Starting ComfyUI on :8188"
cd /app/ComfyUI
exec python main.py --listen 0.0.0.0 --port 8188
