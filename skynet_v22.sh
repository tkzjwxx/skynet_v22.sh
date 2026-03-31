#!/bin/bash
# ====================================================================
# 天网系统 V22+ 终极大一统版 (解决卡死与域名逻辑)
# ====================================================================
clear
echo -e "\033[1;31m🔥 正在执行【天网 V22+ 终极大一统版】全量创世重筑...\033[0m"

# ====================================================================
# 0. 前置打底：fscarmen WARP 介入 (纯 IPv6 救星)
# ====================================================================
echo -e "\n\033[1;33m[阶段 0] 纯 IPv6 环境初始化 - 准备接入 WARP\033[0m"
echo -e "\033[1;36m👉 如果您已经成功安装过全局 WARP (已获取 IPv4)，请直接按【回车键】跳过此步！\033[0m"
read -t 10 -p "👉 否则，输入 'y' 呼出 fscarmen 的 WARP 菜单进行安装: " run_warp
if [[ "$run_warp" == "y" || "$run_warp" == "Y" ]]; then
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
    echo -e "\n\033[1;35m⏸️ 主脚本恢复执行...\033[0m"
fi

# ====================================================================
# 1. 深度环境清理 & 物理引擎保护
# ====================================================================
echo -e "\n\033[1;33m[阶段 1] 正在进行深度环境清理与依赖安装...\033[0m"
systemctl stop sing-box front-box w_master sl1 sl2 sl3 2>/dev/null
killall -9 sbwpph sing-box w_master 2>/dev/null

# 🚨 【核心防卡死保险】：如果已经存在勇哥的第三方赛风核心，立刻备份！防止被 rm 删除！
if [ -f "/etc/s-box/sbwpph" ]; then
    echo -e "\033[1;32m📦 检测到系统中已存在 sbwpph 核心，正在紧急备份...\033[0m"
    cp -f /etc/s-box/sbwpph /tmp/sbwpph_backup
fi

rm -rf /etc/s-box /usr/bin/tw /usr/bin/w_master /etc/systemd/system/front-box.service /etc/systemd/system/w_master.service
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget socat net-tools psmisc jq unzip tar openssl cron nano >/dev/null 2>&1

mkdir -p /etc/s-box/sub1 /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/blacklist
cd /etc/s-box

# 生成随机凭证 (安装时静默生成，不打扰用户)
VLESS_UUID=$(cat /proc/sys/kernel/random/uuid)
HY2_PASS="Skynet_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"
echo "us.domain.com" > /etc/s-box/cf_s1.info
echo "uk.domain.com" > /etc/s-box/cf_s2.info
echo "jp.domain.com" > /etc/s-box/cf_s3.info
echo "$VLESS_UUID" > /etc/s-box/vless_uuid.info
echo "$HY2_PASS" > /etc/s-box/hy2_pass.info

# ====================================================================
# 2. 引擎智能拉取 (官方前端 + 勇哥后端)
# ====================================================================
echo -e "\n\033[1;33m[阶段 2] 智能拉取双核物理引擎...\033[0m"

# 拉取官方核心 (作为前端路由门面)
echo -e "\033[1;36m⏳ 正在拉取官方 Sing-box 前端接客引擎...\033[0m"
S_URL=$(curl -sL --connect-timeout 5 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)
[ -z "$S_URL" ] && S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
curl -sL -o /tmp/sbox.tar.gz "$S_URL"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv -f /tmp/sing-box-*/sing-box /etc/s-box/front-box
chmod +x /etc/s-box/front-box

# 🚨 【智能获取勇哥 sbwpph 核心】 (绝不再卡死)
echo -e "\033[1;36m⏳ 正在智能解析勇哥脚本中的第三方最新核心...\033[0m"
# 先尝试从勇哥的脚本源码里正则提取最新直链
YG_SCRIPT=$(curl -sL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
CORE_URL=$(echo "$YG_SCRIPT" | grep -Eo 'https://[^"[:space:]]*sbwpph-linux-amd64[^"[:space:]]*' | head -n 1)

[ -z "$CORE_URL" ] && CORE_URL="https://github.com/yonggekkk/sing-box-yg/raw/main/Core/sbwpph-linux-amd64"
curl -sL -o /tmp/sbwpph "$CORE_URL"

# 校验下载是否成功 (大小需 > 5MB)
if [ ! -s /tmp/sbwpph ] || [ $(stat -c%s /tmp/sbwpph 2>/dev/null || echo 0) -lt 5000000 ]; then
    if [ -f "/tmp/sbwpph_backup" ]; then
        echo -e "\033[1;33m⚠️ 在线拉取失败，安全回退：使用您本地已安装的 sbwpph 核心！\033[0m"
        cp -f /tmp/sbwpph_backup /tmp/sbwpph
    else
        echo -e "\n\033[1;41;37m 💀 致命错误：无法获取勇哥带有 Psiphon 的 sbwpph 核心！ \033[0m"
        echo -e "\033[1;32m👉 终极解决方案 (仅需一次)：\033[0m"
        echo -e "请先手动运行勇哥的官方脚本：\n \033[1;36mbash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)\033[0m"
        echo -e "随便选择安装一个包含赛风的协议 (为了让它把核心下载到你的 VPS)，完成后退出。"
        echo -e "然后再重新拉取运行我的 Github 脚本即可，系统会自动识别并保留核心！"
        exit 1
    fi
fi

# 分发到三核物理隔离区
chmod +x /tmp/sbwpph
cp /tmp/sbwpph /etc/s-box/sub1/sbwpph
cp /tmp/sbwpph /etc/s-box/sub2/sbwpph
cp /tmp/sbwpph /etc/s-box/sub3/sbwpph

# ====================================================================
# 3. 部署前端路由 (Sing-box 多端口解耦分流)
# ====================================================================
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 3650 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null

cat << EOF > /etc/s-box/front.json
{
  "log": {"level": "fatal"},
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-in-1", "listen": "::", "listen_port": 8443, "users": [{"password": "$HY2_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-2", "listen": "::", "listen_port": 8444, "users": [{"password": "$HY2_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-3", "listen": "::", "listen_port": 8445, "users": [{"password": "$HY2_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    
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
# 4. 后端猎犬 (时光倒流引擎) -> sl1, sl2, sl3
# ====================================================================
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; DIR="/etc/s-box/sub1"; REG="US"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; DIR="/etc/s-box/sub2"; REG="GB"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; DIR="/etc/s-box/sub3"; REG="JP"; }
    
    echo "$REG" > "$DIR/region.info"

    cat << EOF > /etc/s-box/sl${NODE}
#!/bin/bash
NODE="${NODE}"; IN_PORT="${IN_PORT}"; OUT_PORT="${OUT_PORT}"; WORK="${DIR}"; SLA_LOG="/etc/s-box/stability.log"
TARGET=\$(cat "\$WORK/s\${NODE}.lock" 2>/dev/null); [ -z "\$TARGET" ] && exit 0
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ENDPOINTS=("162.159.192.1:2408" "162.159.193.1:2408" "162.159.195.1:2408" "engage.cloudflareclient.com:2408" "162.159.36.1:2408" "162.159.132.53:2408")

ATTEMPTS=0; CHASE_START=\$(date +%s)
REG=\$(cat "\$WORK/region.info")
echo "\$(date '+[%m-%d %H:%M:%S]') [🕵️ 猎犬] S\${NODE} 出动！第一轨：尝试黄金快照回档..." >> "\$SLA_LOG"

while true; do
    ((ATTEMPTS++))
    if [ -f "\$WORK/s\${NODE}.manual" ] || [ -f "\$WORK/s\${NODE}.disabled" ]; then exit 0; fi
    if [ \$((\$(date +%s) - CHASE_START)) -ge 1200 ]; then
        echo "\$(date '+[%m-%d %H:%M:%S]') [🌙 休眠] S\${NODE} 追捕超时，防爆休眠！" >> "\$SLA_LOG"
        touch "\$WORK/s\${NODE}.hibernating"; fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1; pkill -f "\$WORK/sbwpph"; exit 0
    fi
    
    fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1
    pkill -f "\$WORK/sbwpph"
    
    # 清理当前被污染的缓存
    rm -rf "\$WORK"/.cache "\$WORK"/*.db* "\$WORK"/*.os 2>/dev/null
    
    if [ -d "\$WORK/golden_snapshot" ] && [ \$ATTEMPTS -le 2 ]; then
        cp -a "\$WORK/golden_snapshot/." "\$WORK/" 2>/dev/null
        EP=\$(cat "\$WORK/current.endpoint" 2>/dev/null)
        [ -z "\$EP" ] && EP="162.159.192.1:2408"
    else
        EP=\${ENDPOINTS[\$RANDOM % \${#ENDPOINTS[@]}]}
        echo "\$EP" > "\$WORK/current.endpoint"
    fi

    cd "\$WORK"; export HOME="\$WORK"
    nohup ./sbwpph -b 127.0.0.1:\$IN_PORT --cfon --country \$REG -4 --endpoint "\$EP" >/dev/null 2>&1 &
    
    sleep 10
    IP=""
    for i in {1..3}; do
        API=\${APIS[\$RANDOM % \${#APIS[@]}]}
        IP=\$(curl -s4 -m 5 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -n "\$IP" ] && break
        sleep 2
    done

    if [ "\$IP" == "\$TARGET" ]; then
        rm -f "\$WORK/s\${NODE}.hibernating" 2>/dev/null
        COST=\$((\$(date +%s) - CHASE_START))
        if [ \$ATTEMPTS -le 2 ]; then
            echo "\$(date '+[%m-%d %H:%M:%S]') [🚀 回档] S\${NODE} 时光倒流成功！耗时 \$COST 秒恢复极品 IP: \$IP" >> "\$SLA_LOG"
        else
            echo "\$(date '+[%m-%d %H:%M:%S]') [🟢 洗牌] S\${NODE} 降级死磕成功！历经 \$ATTEMPTS 次夺回目标: \$IP" >> "\$SLA_LOG"
        fi
        fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
        socat TCP4-LISTEN:\$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:\$IN_PORT &
        [ ! -f "\$WORK/s\${NODE}.session" ] && date +%s > "\$WORK/s\${NODE}.session"
        exit 0
    fi
done
EOF
    chmod +x /etc/s-box/sl${NODE}
done

# ====================================================================
# 5. 大后台哨兵 (w_master)
# ====================================================================
cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")

find /etc/s-box -name "*.manual" -o -name "*.session" -o -name "*.hibernating" | xargs rm -f 2>/dev/null
echo "$(date '+[%m-%d %H:%M:%S]') 🚀 VPS 开机/重置！天网哨兵就绪，准备引导快照回档。" >> "$SLA_LOG"

while true; do
    for NODE in 1 2 3; do
        [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box/sub1"; }
        [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; }
        [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; }
        
        if [ -f "$WORK/s${NODE}.manual" ] || [ -f "$WORK/s${NODE}.disabled" ] || [ -f "$WORK/s${NODE}.hibernating" ]; then continue; fi
        
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
            fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
            rm -f "$WORK/s${NODE}.session" 2>/dev/null
            if [[ -n "$CURRENT" && "$CURRENT" != "$TARGET" ]]; then
                echo "$(date '+[%m-%d %H:%M:%S]') [🚨 漂移] S${NODE} 漂移($CURRENT)！斩断气闸，启动回档！" >> "$SLA_LOG"
            else
                echo "$(date '+[%m-%d %H:%M:%S]') [🟡 假死] S${NODE} 寻路超时！斩断气闸，启动回档！" >> "$SLA_LOG"
            fi
            nohup /etc/s-box/sl${NODE} >/dev/null 2>&1 &
            sleep 15
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
systemctl daemon-reload && systemctl enable --now w_master >/dev/null 2>&1

# ====================================================================
# 6. 终极控制台 tw (全新分离出向导菜单)
# ====================================================================
cat << 'EOF' > /usr/bin/tw
#!/bin/bash
cleanup_manual() { rm -f /etc/s-box/sub*/s*.manual 2>/dev/null; }
trap 'cleanup_manual; echo -e "\n\033[1;31m[安全中断] 退出天网总控台...\033[0m"; exit 0' INT TERM QUIT HUP
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ENDPOINTS=("162.159.192.1:2408" "162.159.193.1:2408" "162.159.195.1:2408" "engage.cloudflareclient.com:2408" "162.159.36.1:2408" "162.159.132.53:2408")

get_node_vars() {
    case $1 in
        1) N_IN=2081; N_OUT=1081; N_DIR="/etc/s-box/sub1"; ;;
        2) N_IN=2082; N_OUT=1082; N_DIR="/etc/s-box/sub2"; ;;
        3) N_IN=2083; N_OUT=1083; N_DIR="/etc/s-box/sub3"; ;;
    esac
    N_REG=$(cat "$N_DIR/region.info" 2>/dev/null)
}

draw_dashboard() {
    clear
    echo -e "\033[1;36m=========================================================================================================\033[0m"
    echo -e "\033[1;37m                                🛡️ 天网系统 V22+ (快照隔离大一统中心) 🛡️\033[0m"
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

        if [ -f "$N_DIR/s$N.disabled" ]; then C="\033[1;90m"; G_R="⚫关闭"; S="💤 深度休眠 (后端进程已杀)"
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
    echo -e "              🐺 [S$N] 无极扩池安全抽卡引擎"
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "  [1] 🇺🇸 美国  [2] 🇬🇧 英国  [3] 🇯🇵 日本  [4] 🇸🇬 新加坡"
    echo -ne "\033[1;33m👉 选择目标战区 (默认当前 $N_REG): \033[0m"; read r
    case "$r" in 1) N_REG="US";; 2) N_REG="GB";; 3) N_REG="JP";; 4) N_REG="SG";; esac
    echo "$N_REG" > "$N_DIR/region.info"

    while true; do
        fuser -k -9 "$N_IN/tcp" >/dev/null 2>&1; pkill -f "$N_DIR/sbwpph"
        rm -rf "$N_DIR"/.cache "$N_DIR"/*.db* "$N_DIR"/*.os 2>/dev/null
        
        EP=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}
        echo "$EP" > "$N_DIR/current.endpoint"
        
        echo -ne "\r\033[K\033[1;36m⏳ 携带端点 ($EP) 盲抽洗牌中...\033[0m"
        cd "$N_DIR"; export HOME="$N_DIR"
        nohup ./sbwpph -b 127.0.0.1:$N_IN --cfon --country $N_REG -4 --endpoint "$EP" >/dev/null 2>&1 &
        sleep 8
        
        IP=$(curl -s4 -m 5 --socks5 127.0.0.1:$N_IN ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -z "$IP" ] && continue
        
        echo -e "\n\033[1;32m🎯 命中极品 IP: \033[1;37m$IP\033[0m"
        echo -ne "\033[1;33m✨ 满意按 [Y] 制作黄金快照并挂锁，按回车重抽: \033[0m"; read k
        if [[ "$k" == "y" || "$k" == "Y" ]]; then
            rm -rf "$N_DIR/golden_snapshot"; mkdir -p "$N_DIR/golden_snapshot"
            cp -a "$N_DIR/." "$N_DIR/golden_snapshot/" 2>/dev/null
            echo "$IP" > "$N_DIR/s$N.lock"; date +%s > "$N_DIR/s$N.uptime"; date +%s > "$N_DIR/s$N.session"
            rm -f "$N_DIR/s$N.hibernating" 2>/dev/null
            echo -e "\033[1;32m✅ 快照已封印！挂锁完毕！监控引擎已同步。\033[0m"; sleep 2; break
        fi
    done
    rm -f "$N_DIR/s$N.manual" 2>/dev/null
}

action_cf_nodes() {
    clear
    echo -e "\033[1;36m=================================================================\033[0m"
    echo -e "           ☁️ Cloudflare Argo Tunnel 分流配置向导"
    echo -e "\033[1;36m=================================================================\033[0m"
    echo -e "\033[1;33m【第一步：在 CF 后台建立映射规则】\033[0m"
    echo -e "1. 登录 CF 后台 -> Zero Trust -> Networks -> Tunnels"
    echo -e "2. 穿透方式选择 cloudflared，在你的 VPS 上安装好客户端隧道。"
    echo -e "3. 点击你的隧道，进入 Public Hostname，添加以下三条映射记录："
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
    
    echo -e "\033[1;35m【第二步：提取 VLESS 节点 (Argo CDN 分流)】\033[0m"
    gen_v() { echo "vless://$(echo -n "$UUID@$2:443?encryption=none&security=tls&sni=$2&type=ws&host=$2&path=/?ed=2048#$1")"; }
    echo -e "🇺🇸 S1: \033[40;32m $(gen_v "SkyNet-CF-S1" "$CF1") \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m $(gen_v "SkyNet-CF-S2" "$CF2") \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m $(gen_v "SkyNet-CF-S3" "$CF3") \033[0m"

    echo -e "\n\033[1;35m【第三步：提取 Hysteria2 节点 (纯 IPv6 穿透直连)】\033[0m"
    echo -e "🇺🇸 S1: \033[40;32m hysteria2://$PASS@[$IP]:8443/?sni=bing.com&insecure=1#SkyNet-HY2-S1 \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m hysteria2://$PASS@[$IP]:8444/?sni=bing.com&insecure=1#SkyNet-HY2-S2 \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m hysteria2://$PASS@[$IP]:8445/?sni=bing.com&insecure=1#SkyNet-HY2-S3 \033[0m"
    echo -e "\033[1;36m=================================================================\033[0m"
    read -p "按回车键返回大盘..."
}

while true; do
    draw_dashboard
    echo -e "  \033[1;33m⚙️ 【天网矩阵调度中心】\033[0m"
    echo -e "  [1] 🇺🇸 S1 战区 (抽卡挂锁/通道休眠)     [4] ☁️ 配置并提取 Argo/HY2 节点链接"
    echo -e "  [2] 🇬🇧 S2 战区 (抽卡挂锁/通道休眠)     [5] 📜 追踪系统实时史记 (日志)"
    echo -e "  [3] 🇯🇵 S3 战区 (抽卡挂锁/通道休眠)     [0] 🚪 退出总控台"
    echo ""
    read -t 10 -p "👉 请输入指令 (10秒无操作将自动刷新大盘): " cmd
    if [ $? -gt 128 ]; then continue; fi
    
    case "$cmd" in
        1) action_draw 1 ;;
        2) action_draw 2 ;;
        3) action_draw 3 ;;
        4) action_cf_nodes ;;
        5) clear; echo -e "\033[1;36m📜 正在追踪史记 (按 Ctrl+C 返回大盘)...\033[0m\n"; tail -f /etc/s-box/stability.log ;;
        0) clear; exit 0 ;;
    esac
done
EOF
chmod +x /usr/bin/tw

# ====================================================================
# 7. 系统自启机制与凌晨重置任务
# ====================================================================
(crontab -l 2>/dev/null | grep -v "stability.log"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重置，引导每日快照回档 ===\" > /etc/s-box/stability.log && /sbin/reboot") | crontab -

nohup /usr/bin/w_master >/dev/null 2>&1 &

echo -e "\n\033[1;32m🎉 天网系统 V22+ 终极版部署完毕！所有逻辑已通顺！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;36mtw\033[1;37m，然后按 \033[1;36m[4]\033[1;37m 查看 CF 配置向导并提取节点！\033[0m"
