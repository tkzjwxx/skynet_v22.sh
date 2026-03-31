#!/bin/bash
# ====================================================================
# 天网系统 V22+ (V9.8沙盒秒测 + 免死金牌守护版)
# ====================================================================
clear
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;37m                 🛡️ 天网系统 V22+ (沙盒引擎+免疫护甲版) 🛡️\033[0m"
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;33m[前置要求] 执行安装前，请确保您已手动完成以下两步：\033[0m"
echo -e "  1. 已安装 WARP (VPS 必须已具备 IPv4 出口能力)。"
echo -e "  2. 已通过第三方脚本安装了包含赛风的协议，且\033[1;31m端口必须设为 40000\033[0m。"
echo -e "\033[1;36m-----------------------------------------------------------------\033[0m"
echo -e "  \033[1;32m[1]\033[0m 🚀 嗅探环境并部署天网 (无损寄生，激活沙盒四核引擎)"
echo -e "  \033[1;31m[2]\033[0m 🗑️ 定向卸载天网 (仅剥离天网组件，\033[1;32m绝对保留 WARP 与原版脚本\033[0m)"
echo -e "  \033[1;33m[0]\033[0m 🚪 退出"
echo -e "\033[1;36m=================================================================\033[0m"
read -p "👉 请选择操作序号: " menu_choice

if [ "$menu_choice" == "2" ]; then
    echo -e "\n\033[1;31m⚠️ 正在启动【天网自毁剥离程序】...\033[0m"
    systemctl stop front-box w_master skynet-s1 skynet-s2 skynet-s3 skynet-s4 2>/dev/null
    systemctl disable front-box w_master skynet-s1 skynet-s2 skynet-s3 skynet-s4 2>/dev/null
    
    pkill -9 -f front-box; pkill -9 -f w_master; pkill -9 -f "run_core.sh"; pkill -9 -f "sl1"; pkill -9 -f "sl2"; pkill -9 -f "sl3"
    
    rm -rf /etc/s-box/sub1 /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist
    rm -f /etc/s-box/front-box /etc/s-box/front.json /etc/s-box/sl[1-4]
    rm -f /etc/s-box/cf_*.info /etc/s-box/vless_uuid.info /etc/s-box/hy2_pass.info /etc/s-box/hy2.crt /etc/s-box/hy2.key
    rm -f /etc/s-box/stability.log
    
    rm -f /usr/bin/tw /usr/bin/w_master
    rm -f /etc/systemd/system/skynet-s*.service /etc/systemd/system/front-box.service /etc/systemd/system/w_master.service
    systemctl daemon-reload
    
    crontab -l 2>/dev/null | grep -v "stability.log" | crontab -
    
    echo -e "\033[1;32m🎉 卸载完毕！天网系统已完美物理剥离。\033[0m"
    exit 0
elif [ "$menu_choice" == "0" ]; then
    exit 0
elif [ "$menu_choice" != "1" ]; then
    echo "❌ 输入错误，已退出。"; exit 1
fi

clear
echo -e "\033[1;31m🔥 正在执行【天网 V22+】环境嗅探与重构部署...\033[0m"

# ====================================================================
# 1. 前置条件检测 (WARP IPv4 与 依赖包)
# ====================================================================
echo -e "\n\033[1;33m[阶段 1] 正在校验前置环境...\033[0m"

apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget socat net-tools psmisc jq unzip tar openssl cron nano haveged rng-tools >/dev/null 2>&1
systemctl enable --now haveged >/dev/null 2>&1

echo -ne "⏳ 检查 IPv4 (WARP) 连通性... "
IPV4=$(curl -s4 -m 5 api.ipify.org)
if [ -z "$IPV4" ]; then
    echo -e "\033[1;31m[失败]\033[0m\n💀 未检测到 IPv4 出口！"
    exit 1
else
    echo -e "\033[1;32m[通过] (IP: $IPV4)\033[0m"
fi

echo -ne "⏳ 检查 40000 端口及赛风核心... "
if ! netstat -tlnp 2>/dev/null | grep -q ":40000 "; then
    echo -e "\033[1;31m[失败]\033[0m\n💀 致命错误：40000 端口未处于监听状态！"
    exit 1
fi

TARGET_PID=$(netstat -tlnp 2>/dev/null | grep ":40000 " | awk '{print $7}' | cut -d'/' -f1 | head -n 1)
CORE_FILE=$(readlink -f /proc/$TARGET_PID/exe 2>/dev/null)

if [ -z "$CORE_FILE" ] || [ ! -f "$CORE_FILE" ]; then
    echo -e "\033[1;31m[失败]\033[0m\n❌ 无法定位核心文件物理路径！"
    exit 1
fi
echo -e "\033[1;32m[通过] (定位到核心: $CORE_FILE)\033[0m"
sleep 2

# ====================================================================
# 2. 无损寄生：提取配置与裂变隔离
# ====================================================================
echo -e "\n\033[1;33m[阶段 2] 正在进行配置劫持与沙盒裂变...\033[0m"

USER_PASS=$(grep -Eo '"password":[ \t]*"[^"]+"' /etc/s-box/sb.json 2>/dev/null | tail -n 1 | awk -F'"' '{print $4}')
[ -z "$USER_PASS" ] && USER_PASS="Skynet_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"

PORT_S1=40000
PORT_S2=40001
PORT_S3=40002
VLESS_UUID=$(cat /proc/sys/kernel/random/uuid)

echo -e "\033[1;32m🎯 配置确立！主入口端口: $PORT_S1，协议密码已保存。\033[0m"

cp "$CORE_FILE" /tmp/sbwpph_core || { echo "核心备份失败！"; exit 1; }

systemctl stop sing-box 2>/dev/null
systemctl disable sing-box 2>/dev/null
kill -9 $TARGET_PID 2>/dev/null

rm -rf /etc/s-box/sub1 /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist
mkdir -p /etc/s-box/sub1 /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist

cp /etc/s-box/cert.pem /etc/s-box/hy2.crt 2>/dev/null || openssl req -new -x509 -days 3650 -nodes -out /etc/s-box/hy2.crt -keyout /etc/s-box/hy2.key -subj "/CN=bing.com" 2>/dev/null
cp /etc/s-box/private.key /etc/s-box/hy2.key 2>/dev/null

echo "us.domain.com" > /etc/s-box/cf_s1.info
echo "uk.domain.com" > /etc/s-box/cf_s2.info
echo "jp.domain.com" > /etc/s-box/cf_s3.info
echo "$VLESS_UUID" > /etc/s-box/vless_uuid.info
echo "$USER_PASS" > /etc/s-box/hy2_pass.info

cp /tmp/sbwpph_core /etc/s-box/front-box
for i in {1..4}; do
    cp /tmp/sbwpph_core /etc/s-box/sub$i/sbwpph
    chmod +x /etc/s-box/sub$i/sbwpph
done
chmod +x /etc/s-box/front-box

# ====================================================================
# 3. 部署前端路由
# ====================================================================
cat << EOF > /etc/s-box/front.json
{
  "log": {"level": "fatal"},
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-in-1", "listen": "::", "listen_port": $PORT_S1, "users": [{"password": "$USER_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-2", "listen": "::", "listen_port": $PORT_S2, "users": [{"password": "$USER_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-3", "listen": "::", "listen_port": $PORT_S3, "users": [{"password": "$USER_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    
    { "type": "vless", "tag": "vless-in-1", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "$VLESS_UUID"}], "transport": {"type": "ws", "path": "/?ed=2048"} },
    { "type": "vless", "tag": "vless-in-2", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": "$VLESS_UUID"}], "transport": {"type": "ws", "path": "/?ed=2048"} },
    { "type": "vless", "tag": "vless-in-3", "listen": "127.0.0.1", "listen_port": 10003, "users": [{"uuid": "$VLESS_UUID"}], "transport": {"type": "ws", "path": "/?ed=2048"} }
  ],
  "outbounds": [
    { "type": "socks", "tag": "out-s1", "server": "127.0.0.1", "server_port": 1081 },
    { "type": "socks", "tag": "out-s2", "server": "127.0.0.1", "server_port": 1082 },
    { "type": "socks", "tag": "out-s3", "server": "127.0.0.1", "server_port": 1083 }
  ],
  "route": {"rules": [ 
    {"inbound": ["hy2-in-1", "vless-in-1"], "outbound": "out-s1"}, 
    {"inbound": ["hy2-in-2", "vless-in-2"], "outbound": "out-s2"}, 
    {"inbound": ["hy2-in-3", "vless-in-3"], "outbound": "out-s3"} 
  ]}
}
EOF

cat > /etc/systemd/system/front-box.service << 'EOF'
[Unit]
Description=SkyNet Front Router
After=network.target
[Service]
ExecStart=/etc/s-box/front-box run -c /etc/s-box/front.json
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now front-box >/dev/null 2>&1

# ====================================================================
# 4. 建立 Systemd 物理守护进程
# ====================================================================
for NODE in 1 2 3 4; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; REG="US"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; REG="GB"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; REG="JP"; }
    [ "$NODE" == "4" ] && { IN_PORT=2084; REG="US"; }

    DIR="/etc/s-box/sub$NODE"
    echo "$REG" > "$DIR/region.info"
    
    cat > "$DIR/run_core.sh" << EOF
#!/bin/bash
cd $DIR
EP=\$(cat current.endpoint 2>/dev/null)
[ -z "\$EP" ] && EP="162.159.192.1:2408"
REG=\$(cat region.info 2>/dev/null)
[ -z "\$REG" ] && REG="US"
exec ./sbwpph -b 127.0.0.1:$IN_PORT --cfon --country \$REG -4 --endpoint "\$EP"
EOF
    chmod +x "$DIR/run_core.sh"

    cat > /etc/systemd/system/skynet-s${NODE}.service << EOF
[Unit]
Description=SkyNet Backend S${NODE}
After=network.target
[Service]
WorkingDirectory=$DIR
ExecStart=$DIR/run_core.sh
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    if [ "$NODE" != "4" ]; then
        systemctl enable skynet-s${NODE} >/dev/null 2>&1
    fi
done
systemctl daemon-reload

# ====================================================================
# 5. 后端猎犬 (V9.8 沙盒重构版)
# ====================================================================
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; DIR="/etc/s-box/sub1"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; DIR="/etc/s-box/sub2"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; DIR="/etc/s-box/sub3"; }

    cat << EOF > /etc/s-box/sl${NODE}
#!/bin/bash
NODE="${NODE}"; IN_PORT="${IN_PORT}"; OUT_PORT="${OUT_PORT}"; WORK="${DIR}"; SLA_LOG="/etc/s-box/stability.log"
TARGET=\$(cat "\$WORK/s\${NODE}.lock" 2>/dev/null); [ -z "\$TARGET" ] && exit 0
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ENDPOINTS=("162.159.192.1:2408" "162.159.193.1:2408" "162.159.195.1:2408" "engage.cloudflareclient.com:2408" "162.159.36.1:2408" "162.159.132.53:2408")

ATTEMPTS=0; CHASE_START=\$(date +%s)
echo "\$(date '+[%m-%d %H:%M:%S]') [🕵️ 猎犬] S\${NODE} 出动！启动沙盒回档与洗牌..." >> "\$SLA_LOG"

while true; do
    ((ATTEMPTS++))
    if [ -f "\$WORK/s\${NODE}.manual" ] || [ -f "\$WORK/s\${NODE}.disabled" ]; then exit 0; fi
    if [ \$((\$(date +%s) - CHASE_START)) -ge 1200 ]; then
        echo "\$(date '+[%m-%d %H:%M:%S]') [🌙 休眠] S\${NODE} 追捕超时，防爆休眠！" >> "\$SLA_LOG"
        touch "\$WORK/s\${NODE}.hibernating"; systemctl stop skynet-s\${NODE}; exit 0
    fi
    
    systemctl stop skynet-s\${NODE} 2>/dev/null
    fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1
    
    # 🚀 致敬 V9.8: 生成独立沙盒，彻底避开数据库锁死！
    RUN="\$WORK/tmp_\$RANDOM"
    mkdir -p \$RUN; cd \$RUN; export HOME=\$RUN
    
    if [ -d "\$WORK/golden_snapshot" ] && [ \$ATTEMPTS -le 2 ]; then
        cp -a "\$WORK/golden_snapshot/." "\$RUN/" 2>/dev/null
        EP=\$(cat "\$RUN/current.endpoint" 2>/dev/null)
        [ -z "\$EP" ] && EP="162.159.192.1:2408"
    else
        EP=\${ENDPOINTS[\$RANDOM % \${#ENDPOINTS[@]}]}
        echo "\$EP" > "\$RUN/current.endpoint"
    fi

    # 裸奔启动探测
    nohup /etc/s-box/sub\${NODE}/sbwpph -b 127.0.0.1:\$IN_PORT --cfon --country \$(cat \$WORK/region.info) -4 --endpoint "\$EP" >/dev/null 2>&1 & disown
    
    # 🚀 致敬 V9.8: 端口秒测法！一旦检测到端口开了，立马去发 curl
    sleep 2
    for i in {20..1}; do netstat -tlnp 2>/dev/null | grep -q ":\$IN_PORT " && break; sleep 1; done
    
    IP=\$(curl -s4 -m 8 --socks5 127.0.0.1:\$IN_PORT \${APIS[\$RANDOM % \${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)

    if [ "\$IP" == "\$TARGET" ]; then
        fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1
        rm -rf "\$WORK"/.cache "\$WORK"/*.db* "\$WORK"/*.os 2>/dev/null
        
        # 将沙盒转化为正式工作环境
        cp -a \$RUN/. "\$WORK/"
        rm -rf \$RUN
        
        # 🔥 免死金牌：颁发开机证明，60秒内哨兵绝对不准查杀！
        date +%s > "\$WORK/s\${NODE}.boot"
        
        systemctl start skynet-s\${NODE}
        fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
        socat TCP4-LISTEN:\$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:\$IN_PORT &
        
        rm -f "\$WORK/s\${NODE}.hibernating" 2>/dev/null
        COST=\$((\$(date +%s) - CHASE_START))
        echo "\$(date '+[%m-%d %H:%M:%S]') [🚀 回档] S\${NODE} 沙盒倒流成功！历经 \$ATTEMPTS 次，耗时 \$COST 秒！" >> "\$SLA_LOG"
        [ ! -f "\$WORK/s\${NODE}.session" ] && date +%s > "\$WORK/s\${NODE}.session"
        exit 0
    else
        # 失败则摧毁沙盒，不留任何残骸
        fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1
        rm -rf \$RUN
    fi
done
EOF
    chmod +x /etc/s-box/sl${NODE}
done

# ====================================================================
# 6. 大后台哨兵 (w_master 免疫误杀版)
# ====================================================================
cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")

find /etc/s-box -name "*.manual" -o -name "*.session" -o -name "*.hibernating" -o -name "*.boot" | xargs rm -f 2>/dev/null
echo "$(date '+[%m-%d %H:%M:%S]') 🚀 VPS 开机/重置！天网哨兵就绪，准备引导快照回档。" >> "$SLA_LOG"

while true; do
    for NODE in 1 2 3; do
        [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box/sub1"; }
        [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; }
        [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; }
        
        if [ -f "$WORK/s${NODE}.manual" ] || [ -f "$WORK/s${NODE}.disabled" ] || [ -f "$WORK/s${NODE}.hibernating" ]; then continue; fi
        
        # 🔥 护城河：检测免死金牌，如果在 60 秒内刚启动，哨兵直接绕道，给足握手时间！
        if [ -f "$WORK/s${NODE}.boot" ]; then
            BOOT_TIME=$(cat "$WORK/s${NODE}.boot" 2>/dev/null)
            NOW=$(date +%s)
            if [ $((NOW - BOOT_TIME)) -lt 60 ]; then
                continue
            else
                rm -f "$WORK/s${NODE}.boot" # 超过60秒，免死金牌失效
            fi
        fi

        LOCK="$WORK/s${NODE}.lock"; [ ! -f "$LOCK" ] && continue
        TARGET=$(cat "$LOCK" | tr -d '[:space:]'); [ -z "$TARGET" ] && continue
        
        API=${APIS[$RANDOM % ${#APIS[@]}]}
        CURRENT=$(curl -s4 -m 6 --socks5 127.0.0.1:$IN_PORT $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        
        if [[ -n "$CURRENT" && "$CURRENT" == "$TARGET" ]]; then
            if ! netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT "; then
                socat TCP4-LISTEN:$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:$IN_PORT &
                echo "$(date '+[%m-%d %H:%M:%S]') [🟢 守护] S${NODE} 快照无损，气闸畅通！" >> "$SLA_LOG"
                [ ! -f "$WORK/s${NODE}.session" ] && date +%s > "$WORK/s${NODE}.session"
            fi
        elif ! pgrep -f "/etc/s-box/sl${NODE}" > /dev/null; then
            # 宽限期：给 15 秒再查一次
            if [ -z "$CURRENT" ]; then
                sleep 15
                CURRENT=$(curl -s4 -m 6 --socks5 127.0.0.1:$IN_PORT $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
            fi

            if [[ -n "$CURRENT" && "$CURRENT" != "$TARGET" ]] || [ -z "$CURRENT" ]; then
                fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
                rm -f "$WORK/s${NODE}.session" 2>/dev/null
                nohup /etc/s-box/sl${NODE} >/dev/null 2>&1 &
                sleep 10
            fi
        fi
    done
    sleep 20
done
EOF
chmod +x /usr/bin/w_master
cat > /etc/systemd/system/w_master.service << 'EOF'
[Unit]
Description=Skynet Master Sentinel
[Service]
ExecStart=/usr/bin/w_master
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now w_master >/dev/null 2>&1

# ====================================================================
# 7. 终极控制台 tw (含沙盒抽卡与S4极速打捞)
# ====================================================================
cat << 'EOF' > /usr/bin/tw
#!/bin/bash
rm -f /etc/s-box/sub*/s*.manual 2>/dev/null

cleanup_manual() { rm -f /etc/s-box/sub*/s*.manual 2>/dev/null; }
trap 'cleanup_manual; echo -e "\n\033[1;31m[安全中断] 退出天网总控台...\033[0m"; exit 0' INT TERM QUIT HUP

APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ENDPOINTS=("162.159.192.1:2408" "162.159.193.1:2408" "162.159.195.1:2408" "engage.cloudflareclient.com:2408" "162.159.36.1:2408" "162.159.132.53:2408")

get_node_vars() {
    case $1 in
        1) N_IN=2081; N_OUT=1081; N_DIR="/etc/s-box/sub1"; N_SVC="skynet-s1" ;;
        2) N_IN=2082; N_OUT=1082; N_DIR="/etc/s-box/sub2"; N_SVC="skynet-s2" ;;
        3) N_IN=2083; N_OUT=1083; N_DIR="/etc/s-box/sub3"; N_SVC="skynet-s3" ;;
    esac
    N_REG=$(cat "$N_DIR/region.info" 2>/dev/null)
}

draw_dashboard() {
    clear
    echo -e "\033[1;36m=========================================================================================================\033[0m"
    echo -e "\033[1;37m                                🛡️ 天网系统 V22+ (Systemd 守护大一统中心) 🛡️\033[0m"
    echo -e "\033[1;36m=========================================================================================================\033[0m"
    printf " %-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\n" "通道" "战区" "锁定目标 IP" "当前真实 IP" "对外气闸" "总存活" "未漂移" "健康状态及行动指示"
    echo "---------------------------------------------------------------------------------------------------------"
    for N in 1 2 3; do
        get_node_vars $N
        TAR=$(cat "$N_DIR/s$N.lock" 2>/dev/null)
        CUR=$(curl -s4 -m 3 --socks5 127.0.0.1:$N_IN ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        if netstat -tlnp 2>/dev/null | grep -q ":$N_OUT "; then G_R="🟢开启"; else G_R="🔴截断"; fi
        
        UP_TOT="--:--:--"; UP_SES="--:--:--"
        NW=$(date +%s)
        if [ -n "$TAR" ]; then
            if [ -f "$N_DIR/s$N.uptime" ]; then ST_TOT=$(cat "$N_DIR/s$N.uptime" 2>/dev/null); DF=$((NW - ST_TOT)); [ $DF -gt 0 ] && UP_TOT=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
            if [ -f "$N_DIR/s$N.session" ]; then ST_SES=$(cat "$N_DIR/s$N.session" 2>/dev/null); DF=$((NW - ST_SES)); [ $DF -gt 0 ] && UP_SES=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
        fi

        if [ -f "$N_DIR/s$N.disabled" ]; then C="\033[1;90m"; G_R="⚫关闭"; S="💤 深度休眠 (守护进程已关)"
        elif [ -f "$N_DIR/s$N.manual" ]; then C="\033[1;35m"; G_R="🛑截断"; S="🛑 人工调优防泄露中"
        elif [ -z "$CUR" ]; then C="\033[1;33m"; G_R="🔴截断"; S="🟡 假死断流 / 时光倒流准备中"
        elif [ "$CUR" == "$TAR" ]; then C="\033[1;32m"; G_R="🟢开启"; S="✅ 极品无损运行中"
        else C="\033[1;31m"; G_R="🔴截断"; S="🚨 漂移！猎犬正在实施回档"; fi
        printf " ${C}%-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\033[0m\n" "S$N" "$N_REG" "$TAR" "${CUR:-空}" "$G_R" "$UP_TOT" "$UP_SES" "$S"
    done
    echo -e "\033[1;36m=========================================================================================================\033[0m"
}

action_draw() {
    local N=$1; get_node_vars $N
    rm -f "$N_DIR/s$N.disabled" 2>/dev/null
    fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
    echo $$ > "$N_DIR/s$N.manual"
    
    clear
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "              🐺 [S$N] 无极扩池安全抽卡引擎 (沙盒版)"
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "  [1] 🇺🇸 美国  [2] 🇬🇧 英国  [3] 🇯🇵 日本  [4] 🇸🇬 新加坡"
    echo -ne "\033[1;33m👉 选择目标战区 (默认当前 $N_REG): \033[0m"; read r
    case "$r" in 1) N_REG="US";; 2) N_REG="GB";; 3) N_REG="JP";; 4) N_REG="SG";; esac
    echo "$N_REG" > "$N_DIR/region.info"

    while true; do
        systemctl stop "$N_SVC" 2>/dev/null
        fuser -k -9 "$N_IN/tcp" >/dev/null 2>&1
        
        RUN="$N_DIR/tmp_$RANDOM"
        mkdir -p $RUN; cd $RUN; export HOME=$RUN
        
        EP=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}
        echo "$EP" > "current.endpoint"
        
        echo -ne "\r\033[K\033[1;36m⏳ 沙盒构建完毕，端点 ($EP) 盲抽中...\033[0m"
        nohup /etc/s-box/sub$N/sbwpph -b 127.0.0.1:$N_IN --cfon --country $N_REG -4 --endpoint "$EP" >/dev/null 2>&1 & disown
        
        # 🚀 端口秒测法
        sleep 2
        for i in {20..1}; do netstat -tlnp 2>/dev/null | grep -q ":$N_IN " && break; sleep 1; done
        
        IP=$(curl -s4 -m 8 --socks5 127.0.0.1:$N_IN ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        
        if [ -z "$IP" ]; then 
            fuser -k -9 "$N_IN/tcp" >/dev/null 2>&1
            rm -rf $RUN
            continue
        fi
        
        echo -e "\n\033[1;32m🎯 命中极品 IP: \033[1;37m$IP\033[0m"
        echo -ne "\033[1;33m✨ 满意按 [Y] 挂锁，按回车销毁沙盒重抽: \033[0m"; read k
        if [[ "$k" == "y" || "$k" == "Y" ]]; then
            fuser -k -9 "$N_IN/tcp" >/dev/null 2>&1
            rm -rf "$N_DIR/golden_snapshot"; mkdir -p "$N_DIR/golden_snapshot"
            cp -a $RUN/. "$N_DIR/golden_snapshot/"
            rm -rf $RUN
            
            echo "$IP" > "$N_DIR/s$N.lock"; date +%s > "$N_DIR/s$N.uptime"; date +%s > "$N_DIR/s$N.session"
            rm -f "$N_DIR/s$N.hibernating" 2>/dev/null
            
            rm -rf "$N_DIR"/.cache "$N_DIR"/*.db* "$N_DIR"/*.os 2>/dev/null
            cp -a "$N_DIR/golden_snapshot/." "$N_DIR/"
            
            # 🔥 颁发免死金牌并启动气闸，回到面板瞬间变绿
            date +%s > "$N_DIR/s$N.boot"
            systemctl start "$N_SVC"
            fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
            socat TCP4-LISTEN:$N_OUT,fork,reuseaddr TCP4:127.0.0.1:$N_IN &
            
            echo -e "\033[1;32m✅ 快照已封印！(底层已交由 Systemd 永久守护)\033[0m"; sleep 2; break
        else
            fuser -k -9 "$N_IN/tcp" >/dev/null 2>&1
            rm -rf $RUN
        fi
    done
    rm -f "$N_DIR/s$N.manual" 2>/dev/null
}

action_toggle() {
    local N=$1; get_node_vars $N
    if [ -f "$N_DIR/s$N.disabled" ]; then
        rm -f "$N_DIR/s$N.disabled" "$N_DIR/s$N.hibernating"
        date +%s > "$N_DIR/s$N.boot"
        systemctl enable --now "$N_SVC" >/dev/null 2>&1
        fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
        socat TCP4-LISTEN:$N_OUT,fork,reuseaddr TCP4:127.0.0.1:$N_IN &
        echo -e "\033[1;32m✅ S$N 已唤醒，气闸接通！\033[0m"
    else
        touch "$N_DIR/s$N.disabled"
        systemctl stop "$N_SVC" 2>/dev/null; systemctl disable "$N_SVC" 2>/dev/null
        fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
        pkill -f "/etc/s-box/sl$N" 2>/dev/null
        echo -e "\033[1;33m💤 S$N 已彻底斩断后端守护并休眠！\033[0m"
    fi
    sleep 2
}

# ====================================================================
# 🔥 幽灵斥候 S4：深海打捞旁路引擎 (沙盒防锁版)
# ====================================================================
action_s4() {
    DIR="/etc/s-box/sub4"; BLACKLIST_FILE="/etc/s-box/blacklist/bad_ips.txt"; SVC="skynet-s4"; IN_PORT=2084; touch "$BLACKLIST_FILE"
    clear; echo -e "\033[1;36m   👻 [S4] 幽灵斥候 - 旁路洗号引擎 \033[0m\n   当前黑名单拦截库: $(wc -l < $BLACKLIST_FILE 2>/dev/null || echo 0) 条\n"
    echo -e "  [1] 🌊 启动深海打捞      [2] 📥 批量导入黑名单"
    echo -e "  [3] 📜 查看当前黑名单    [4] 🗑️ 清空全部黑名单"
    echo -e "  [0] 🚪 退出"
    read -p "👉 请选择 (默认 1): " c; [ -z "$c" ] && c=1
    if [ "$c" == "3" ]; then echo -e "\n\033[1;36m📜 黑名单:\033[0m"; cat "$BLACKLIST_FILE" | column; sleep 3; return; fi
    if [ "$c" == "4" ]; then > "$BLACKLIST_FILE"; echo -e "\n\033[1;31m💥 清空完毕！\033[0m"; sleep 2; return; fi
    if [ "$c" == "2" ]; then echo -e "💡 粘贴IP(回车完成): "; read INPUT; for BAD_IP in $INPUT; do echo "$BAD_IP" >> "$BLACKLIST_FILE"; done; return; fi
    if [ "$c" == "1" ]; then
        echo -e "  [1] 🇺🇸 US   [2] 🇬🇧 GB   [3] 🇯🇵 JP"
        read -p "选择潜水战区 (默认 1): " rc
        case "$rc" in 1) TR="US";; 2) TR="GB";; 3) TR="JP";; esac
        [ -n "$TR" ] && echo "$TR" > $DIR/region.info
        
        read -p "打捞网数 (默认 20): " SCAN_MAX; [ -z "$SCAN_MAX" ] && SCAN_MAX=20
        A=0; VALID=()
        
        systemctl stop "$SVC" 2>/dev/null

        while [ $A -lt $SCAN_MAX ]; do
            ((A++)); echo -ne "\r\033[K🔍 [$A/$SCAN_MAX] 下网..."
            
            fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1
            RUN="$DIR/tmp_$RANDOM"
            mkdir -p $RUN; cd $RUN; export HOME=$RUN
            
            EP=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}
            echo "$EP" > "current.endpoint"
            
            nohup /etc/s-box/sub4/sbwpph -b 127.0.0.1:$IN_PORT --cfon --country $TR -4 --endpoint "$EP" >/dev/null 2>&1 & disown
            
            sleep 2
            for i in {20..1}; do netstat -tlnp 2>/dev/null | grep -q ":$IN_PORT " && break; sleep 1; done
            
            IP=$(curl -s4 -m 8 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)

            if [ -n "$IP" ]; then
                if grep -q "^${IP}$" "$BLACKLIST_FILE" 2>/dev/null; then echo -e "\n  ├─ 🚫 触发黑名单: $IP"
                else echo -e "\n  └─ 🌟 捕获极品: \033[1;32m$IP\033[0m"; VALID+=("$IP"); fi
            else echo -e "\n  ├─ \033[1;31m❌ 寻路超时 (已自动换网)\033[0m"; fi
            
            fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1
            rm -rf $RUN
        done
        echo -e "\n\033[1;33m📊 打捞结束，获得 ${#VALID[@]} 个极品。\033[0m"
        
        if [ ${#VALID[@]} -gt 0 ]; then
            printf "%s\n" "${VALID[@]}" | sort -V | uniq -c | sort -nr
            echo "  [1] 全部绞杀 (打入黑名单)   [0] 退出"
            read -p "请裁决: " ec
            if [ "$ec" == "1" ]; then printf "%s\n" "${VALID[@]}" | sort -u >> "$BLACKLIST_FILE"; echo "✅ 已送入黑名单。"; sleep 2; fi
        fi
    fi
}

action_cf_nodes() {
    clear
    echo -e "\033[1;36m=================================================================\033[0m"
    echo -e "           ☁️ Cloudflare Argo Tunnel 分流配置向导"
    echo -e "\033[1;36m=================================================================\033[0m"
    echo -e "\033[1;33m【第一步：在 CF 后台建立映射规则】\033[0m"
    echo -e "1. 登录 CF 后台 -> Zero Trust -> Networks -> Tunnels"
    echo -e "2. 点击你的隧道，进入 Public Hostname，添加以下三条映射记录："
    echo -e "   - 域名 1 (用于 S1) -> 转发给 Service: \033[1;32mHTTP://localhost:10001\033[0m"
    echo -e "   - 域名 2 (用于 S2) -> 转发给 Service: \033[1;32mHTTP://localhost:10002\033[0m"
    echo -e "   - 域名 3 (用于 S3) -> 转发给 Service: \033[1;32mHTTP://localhost:10003\033[0m"
    echo -e "-----------------------------------------------------------------"
    
    read -p "👉 想要将这三个域名写入脚本，生成准确的 VLESS 客户端节点链接吗？(y/n): " set_cf
    if [[ "$set_cf" == "y" || "$set_cf" == "Y" ]]; then
        read -p "  输入 S1(美国) 域名 (例 us.abc.com): " c1; [ -n "$c1" ] && echo "$c1" > /etc/s-box/cf_s1.info
        read -p "  输入 S2(英国) 域名 (例 uk.abc.com): " c2; [ -n "$c2" ] && echo "$c2" > /etc/s-box/cf_s2.info
        read -p "  输入 S3(日本) 域名 (例 jp.abc.com): " c3; [ -n "$c3" ] && echo "$c3" > /etc/s-box/cf_s3.info
        echo -e "\033[1;32m✅ 域名已更新保存！\033[0m\n"
    fi

    IP=$(curl -s6 -m 5 api64.ipify.org 2>/dev/null || ip -6 addr show dev eth0 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | head -n 1)
    [ -z "$IP" ] && IP="[获取IPv6失败]"
    CF1=$(cat /etc/s-box/cf_s1.info); CF2=$(cat /etc/s-box/cf_s2.info); CF3=$(cat /etc/s-box/cf_s3.info)
    UUID=$(cat /etc/s-box/vless_uuid.info); PASS=$(cat /etc/s-box/hy2_pass.info)
    
    P1=$(grep -oP '"listen_port":\s*\K\d+' /etc/s-box/front.json | sed -n '1p')
    P2=$(grep -oP '"listen_port":\s*\K\d+' /etc/s-box/front.json | sed -n '2p')
    P3=$(grep -oP '"listen_port":\s*\K\d+' /etc/s-box/front.json | sed -n '3p')
    
    echo -e "\033[1;35m【第二步：提取 VLESS 节点 (Argo CDN 分流)】\033[0m"
    gen_v() { echo "vless://$(echo -n "$UUID@$2:443?encryption=none&security=tls&sni=$2&type=ws&host=$2&path=/?ed=2048#$1")"; }
    echo -e "🇺🇸 S1: \033[40;32m $(gen_v "SkyNet-CF-S1" "$CF1") \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m $(gen_v "SkyNet-CF-S2" "$CF2") \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m $(gen_v "SkyNet-CF-S3" "$CF3") \033[0m"

    echo -e "\n\033[1;35m【第三步：提取 Hysteria2 节点 (纯 IPv6 穿透直连)】\033[0m"
    echo -e "🇺🇸 S1: \033[40;32m hysteria2://$PASS@[$IP]:$P1/?sni=bing.com&insecure=1#SkyNet-HY2-S1 \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m hysteria2://$PASS@[$IP]:$P2/?sni=bing.com&insecure=1#SkyNet-HY2-S2 \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m hysteria2://$PASS@[$IP]:$P3/?sni=bing.com&insecure=1#SkyNet-HY2-S3 \033[0m"
    echo -e "\033[1;36m=================================================================\033[0m"
    read -p "按回车键返回大盘..."
}

while true; do
    draw_dashboard
    echo -e "  \033[1;33m⚙️ 【天网矩阵调度中心】\033[0m"
    echo -e "  [1] 🇺🇸 S1 战区 (抽卡挂锁/通道休眠)     [4] 👻 S4 幽灵斥候 (旁路打捞)"
    echo -e "  [2] 🇬🇧 S2 战区 (抽卡挂锁/通道休眠)     [5] ☁️ 配置并提取节点链接"
    echo -e "  [3] 🇯🇵 S3 战区 (抽卡挂锁/通道休眠)     [6] 📜 追踪系统实时史记 (日志)"
    echo -e "  [0] 🚪 退出总控台"
    echo ""
    read -t 10 -p "👉 请输入指令 (10秒无操作将自动刷新大盘): " cmd
    if [ $? -gt 128 ]; then continue; fi
    
    case "$cmd" in
        1) action_draw 1 ;;
        2) action_draw 2 ;;
        3) action_draw 3 ;;
        4) action_s4 ;;
        5) action_cf_nodes ;;
        6) clear; echo -e "\033[1;36m📜 正在追踪史记 (按 Ctrl+C 返回大盘)...\033[0m\n"; tail -f /etc/s-box/stability.log ;;
        0) clear; exit 0 ;;
    esac
done
EOF
chmod +x /usr/bin/tw

# ====================================================================
# 8. 系统自启机制与凌晨重置任务
# ====================================================================
(crontab -l 2>/dev/null | grep -v "stability.log"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重置，引导每日快照回档 ===\" > /etc/s-box/stability.log && /sbin/reboot") | crontab -

nohup /usr/bin/w_master >/dev/null 2>&1 &

echo -e "\n\033[1;32m🎉 天网系统 V22+ 终极版部署完毕！沙盒引擎与免死金牌机制已启动！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;36mtw\033[1;37m 享受秒抽体验！\033[0m"
