#!/usr/bin/env bash
set -u
echo ">>> [1/4] SSH"
mkdir -p /root/.ssh /run/sshd
ssh-keygen -A 2>/dev/null || true
if [ -n "${PUBLIC_KEY:-}" ]; then
  echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
  chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys
fi
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config 2>/dev/null || true
/usr/sbin/sshd || echo "    (sshd failed to start)"
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
# make PATH (conda -> hf) + R2 env available to SSH / interactive shells too
cat > /etc/profile.d/comfyr2.sh <<PENV
export PATH=/opt/conda/bin:\$PATH
export R2_BUCKET="${R2_BUCKET:-}"
export R2_ACCESS_KEY="${R2_ACCESS_KEY:-}"
export R2_SECRET_KEY="${R2_SECRET_KEY:-}"
export R2_ACCOUNT_ID="${R2_ACCOUNT_ID:-}"
PENV
chmod 0644 /etc/profile.d/comfyr2.sh
echo ">>> [3/4] Models"
if [ -n "${MODELS:-}" ]; then
  echo "    auto-loading: ${MODELS}"
  /app/getmodel.sh ${MODELS} || echo "    (some bundles failed)"
else
  echo "    booting empty (fast). Load one with:  getmodel <name>"
fi
echo ">>> [4/4] Starting ComfyUI on :8188 (background; container stays alive for SSH)"
cd /app/ComfyUI
python main.py --listen 0.0.0.0 --port 8188 > /var/log/comfyui.log 2>&1 &
echo "    ComfyUI PID $! — logs: /var/log/comfyui.log"
# Keep the container alive no matter what ComfyUI does, so SSH always works.
touch /var/log/comfyui.log
tail -n +1 -f /var/log/comfyui.log &
sleep infinity
