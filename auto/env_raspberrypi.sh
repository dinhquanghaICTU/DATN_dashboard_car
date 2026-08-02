#!/bin/bash
set -euo pipefail

cat << 'BANNER'
  ___  _   _   _    _   _  ____   _   _    _      ___ ____ _____ _   _
 / _ \| | | | / \  | \ | |/ ___| | | | |  / \    |_ _/ ___|_   _| | | |
| | | | | | |/ _ \ |  \| | |  _  | |_| | / _ \    | | |     | | | | | |
| |_| | |_| / ___ \| |\  | |_| |  |  _  |/ ___ \   | | |___  | | | |_| |
 \__\_\\___/_/   \_\_| \_|\____|  |_| |_/_/   \_\ |___\____| |_|  \___/

                         QUANG HA ICTU
BANNER

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.txt"

if [ "${EUID}" -ne 0 ]; then
  echo "Can quyen root. Dang chay lai bang sudo..."
  exec sudo "$0" "$@"
fi

if [ ! -r "$CONFIG_FILE" ]; then
  echo "Khong tim thay hoac khong doc duoc: $CONFIG_FILE" >&2
  exit 1
fi

# Doc cac dong khong rong va khong phai comment trong config.txt.
config_values=()
while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  line="$(printf '%s' "$raw_line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ -z "$line" ] || [[ "$line" == \#* ]]; then
    continue
  fi
  config_values+=("$line")
done < "$CONFIG_FILE"

HOST_USER="${config_values[0]:-}"
HOST_PASS="${config_values[1]:-}"
RASPI_USER="${config_values[2]:-}"
RASPI_PASS="${config_values[3]:-}"
RASPI_IP="${config_values[4]:-}"
RDP_USER="${config_values[5]:-}"
RDP_PASS="${config_values[6]:-}"

# Khi chay truc tiep tren Pi bang sudo, user goi sudo moi la Raspberry Pi user that.
LOCAL_PI_USER="${SUDO_USER:-}"
if [ -n "$LOCAL_PI_USER" ] && [ "$LOCAL_PI_USER" != "root" ] && \
   getent passwd "$LOCAL_PI_USER" >/dev/null 2>&1; then
  if [ "$RASPI_USER" != "$LOCAL_PI_USER" ]; then
    echo "[WARN] Raspberry Pi user trong config la '$RASPI_USER', tu dong dung user dang chay: '$LOCAL_PI_USER'."
  fi
  RASPI_USER="$LOCAL_PI_USER"
fi

# HOST_USER va HOST_PASS danh cho auto.sh tren host, khong dung trong file nay.
: "$HOST_USER" "$HOST_PASS"

if [ -z "$RASPI_USER" ] || [ -z "$RASPI_PASS" ] || [ -z "$RASPI_IP" ] ||
   [ -z "$RDP_USER" ] || [ -z "$RDP_PASS" ]; then
  echo "config.txt phai co du tai khoan Raspberry Pi, IP va tai khoan Remote Desktop." >&2
  exit 1
fi

if ! [[ "$RASPI_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Username Raspberry Pi khong hop le: $RASPI_USER" >&2
  exit 1
fi

if [ "$RDP_USER" = "$RASPI_USER" ]; then
  echo "Remote Desktop user phai khac Raspberry Pi user de tranh loi man hinh xanh: $RDP_USER" >&2
  exit 1
fi
if ! [[ "$RDP_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Username Remote Desktop khong hop le: $RDP_USER" >&2
  exit 1
fi

echo
echo "Raspberry Pi user : $RASPI_USER"
echo "Raspberry Pi IP   : $RASPI_IP"
echo "Remote Desktop user: $RDP_USER"
echo

# Tao user rieng de dang nhap Windows Remote Desktop, tranh dung session desktop hien tai.
if getent passwd "$RDP_USER" >/dev/null 2>&1; then
  echo "User Remote Desktop '$RDP_USER' da ton tai, bo qua buoc tao user."
else
  useradd --create-home --shell /bin/bash "$RDP_USER"
fi

if ! getent passwd "$RDP_USER" >/dev/null 2>&1; then
  echo "Khong tao duoc user Remote Desktop: $RDP_USER" >&2
  exit 1
fi

printf '%s:%s\n' "$RDP_USER" "$RDP_PASS" | chpasswd
usermod -aG sudo "$RDP_USER"
RDP_GROUP="$(id -gn "$RDP_USER")"

APT_GET=(apt-get -o DPkg::Lock::Timeout=300)

echo "Cap nhat danh sach package..."
"${APT_GET[@]}" update

echo "Cai XRDP..."
DEBIAN_FRONTEND=noninteractive "${APT_GET[@]}" install -y xrdp xorgxrdp
usermod -aG ssl-cert xrdp
systemctl enable xrdp
systemctl restart xrdp

echo "Cai cac package can cho Qt 6..."
QT_PACKAGES_1=(
  libboost-all-dev libudev-dev libinput-dev libts-dev libmtdev-dev
  libjpeg-dev libfontconfig1-dev libssl-dev libdbus-1-dev libglib2.0-dev
  libxkbcommon-dev libegl1-mesa-dev libgbm-dev libgles2-mesa-dev
  mesa-common-dev libasound2-dev libpulse-dev
  gstreamer1.0-plugins-base gstreamer1.0-plugins-good
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-alsa
  libvpx-dev libsrtp2-dev libsnappy-dev libnss3-dev flex bison
  libxslt-dev ruby gperf libbz2-dev libcups2-dev libatkmm-1.6-dev
  libxi6 libxcomposite1 libfreetype6-dev libicu-dev libsqlite3-dev
  libxslt1-dev
)

QT_PACKAGES_2=(
  libavcodec-dev libavformat-dev libswscale-dev libx11-dev freetds-dev
  libsqlite3-dev libpq-dev libiodbc2-dev firebird-dev libxext-dev
  libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev
  libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev
  libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev
  libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev
  libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev
  libxcb-glx0-dev libxi-dev libdrm-dev libxcb-xinerama0
  libxcb-xinerama0-dev libatspi2.0-dev libxcursor-dev libxcomposite-dev
  libxdamage-dev libxss-dev libxtst-dev libpci-dev libcap-dev
  libxrandr-dev libdirectfb-dev libaudio-dev libxkbcommon-x11-dev gdbserver
)

DEBIAN_FRONTEND=noninteractive "${APT_GET[@]}" install -y "${QT_PACKAGES_1[@]}"
DEBIAN_FRONTEND=noninteractive "${APT_GET[@]}" install -y "${QT_PACKAGES_2[@]}"

# gstreamer1.0-omx khong con co tren mot so ban Raspberry Pi OS moi.
if apt-cache show gstreamer1.0-omx >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive "${APT_GET[@]}" install -y gstreamer1.0-omx
else
  echo "Bo qua gstreamer1.0-omx: package khong co trong repo hien tai."
fi

# Thu muc cai Qt tren Raspberry Pi.
if ! getent passwd "$RASPI_USER" >/dev/null 2>&1; then
  echo "Khong ton tai Raspberry Pi user trong config: $RASPI_USER" >&2
  exit 1
fi
RASPI_GROUP="$(id -gn "$RASPI_USER")"
install -d -m 0755 /usr/local/qt6
chown -R "$RASPI_USER:$RASPI_GROUP" /usr/local/qt6

# Them duong dan thu vien cho user dung Remote Desktop, khong ghi vao .bashrc cua root.
RDP_HOME="$(getent passwd "$RDP_USER" | cut -d: -f6)"
if [ -z "$RDP_HOME" ] || [ ! -d "$RDP_HOME" ]; then
  echo "Home directory cua Remote Desktop user khong hop le: $RDP_USER" >&2
  exit 1
fi
LD_LIBRARY_LINE='export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/qt6/lib/'
touch "$RDP_HOME/.bashrc"
if ! grep -Fqx "$LD_LIBRARY_LINE" "$RDP_HOME/.bashrc"; then
  printf '\n%s\n' "$LD_LIBRARY_LINE" >> "$RDP_HOME/.bashrc"
fi
chown "$RDP_USER:$RDP_GROUP" "$RDP_HOME/.bashrc"

echo
echo "Da cai xong moi truong Raspberry Pi va XRDP."
echo "Tu Windows, mo Remote Desktop Connection va ket noi toi: $RASPI_IP"
echo "Dang nhap bang user moi: $RDP_USER"
echo "Neu user nay dang dang nhap truc tiep tren man hinh Pi, hay logout truoc khi vao XRDP."
