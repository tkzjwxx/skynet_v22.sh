#!/bin/bash
# ====================================================================
# 天网系统 V22+ 终极大一统版 (前端分流 + 后端三核隔离 + 快照回档 + 端点扩池)
# ====================================================================
clear
echo -e "\033[1;31m🔥 正在执行【天网 V22+ 终极大一统版】全量创世重筑...\033[0m"

# ====================================================================
# 0. 前置打底：fscarmen WARP 介入 (纯 IPv6 救星)
# ====================================================================
echo -e "\n\033[1;33m[阶段 0] 纯 IPv6 环境初始化 - 准备接入 WARP\033[0m"
echo -e "\033[1;36m👉 即将呼出 fscarmen 的 WARP 菜单。请手动安装 (建议选 IPv4 优先或双栈)。\033[0m"
echo -e "\033[1;32m👉 安装成功并看到获取到 IPv4 后，请退出 WARP 菜单回到这里。\033[0m"
sleep 5
wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh

echo -e "\n\033[1;35m⏸️ 主脚本已挂起！\033[0m"
read -p "⚠️ 确认 WARP 已成功获取 IPv4 连通性后，请按【回车键】继续部署天网主程序..." 

# ====================================================================
# 1. 深度环境清理 & 基础工具
# ====================================================================
echo -e "\n\033[1;33m[阶段 1] 正在进行深度环境清理与依赖安装...\033[0m"
systemctl stop sing-box front-box w_master sl1 sl2 sl3 2>/dev/null
killall -9 sbwpph sing-box w_master 2>/dev/null
rm -rf /etc/s-box /usr/bin/tw /usr/bin/w_master /etc/systemd/system/front-box.service /etc/systemd/system/w_master.service
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget socat net-tools psmisc jq unzip tar openssl cron nano >/dev/null 2>&1

mkdir -p /etc/s-box/sub1 /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/blacklist
cd /etc/s-box

# ====================================================================
# 2. CF Argo 域名交互向导
# ====================================================================
clear
echo -e "\033[1;36m========================================================\033[0m"
echo -e "        ☁️ Cloudflare Argo Tunnel 域名分流向导"
echo -e "\033[1;36m========================================================\033[0m"
echo -e "\033[1;33m请提前想好你要分配给 3 个战区的 CF 子域名。\033[0m"
read -p "👉 请输入 S1(美国) 的 CF 子域名 (例: us.你的域名.com): " CF_S1
read -p "👉 请输入 S2(英国) 的 CF 子域名 (例: uk.你的域名.com): " CF_S2
read -p "👉 请输入 S3(日本) 的 CF 子域名 (例: jp.你的域名.com): " CF_S3

[ -z "$CF_S1" ] && CF_S1="us.domain.com"
[ -z "$CF_S2" ] && CF_S2="uk.domain.com"
[ -z "$CF_S3" ] && CF_S3="jp.domain.com"

# 生成随机凭证
VLESS_UUID=$(cat /proc/sys/kernel/random/uuid)
HY2_PASS="Skynet_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"

# ====================================================================
# 3. 引擎拉取 (官方前端 + 勇哥后端)
# ====================================================================
echo -e "\n\033[1;33m[阶段 2] 拉取双核物理引擎...\033[0m"
# 拉取官方核心 (作为前端路由门面)
S_URL=$(curl -sL --connect-timeout 5 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)
[ -z "$S_URL" ] && S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
curl -sL -o /tmp/sbox.tar.gz "$S_URL"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv -f /tmp/sing-box-*/sing-box /etc/s-box/front-box
chmod +x /etc/s-box/front-box

# 模拟静默拉取勇哥 sbwpph (作为后端赛风核心)
# 这里直接利用勇哥仓库编译好的带 psiphon 的单文件核心 (适配 amd64)
curl -sL -o /tmp/sbwpph "https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sbwpph"
# 分发到三核物理隔离区
cp /tmp/sbwpph /etc/s-box/sub1/sbwpph
cp /tmp/sbwpph /etc/s-box/sub2/sbwpph
cp /tmp/sbwpph /etc/s-box/sub3/sbwpph
chmod +x /etc/s-box/sub*/sbwpph

# ====================================================================
# 4. 部署前端路由 (Sing-box 域名分流)
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
# 5. 生成系统全局信息库 (给 tw 面板提取节点用)
# ====================================================================
echo "$CF_S1" > /etc/s-box/cf_s1.info
echo "$CF_S2" > /etc/s-box/cf_s2.info
echo "$CF_S3" > /etc/s-box/cf_s3.info
echo "$VLESS_UUID" > /etc/s-box/vless_uuid.info
echo "$HY2_PASS" > /etc/s-box/hy2_pass.info

# ====================================================================
# 6. 后端猎犬 (时光倒流引擎) -> sl1, sl2, sl3
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
    
    # 清理僵尸
    fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1
    pkill -f "\$WORK/sbwpph"
    
    # --- 快照回档核心逻辑 ---
    # 清理当前被污染的缓存 (严格限定清理)
    rm -rf "\$WORK"/.cache "\$WORK"/*.db* "\$WORK"/*.os 2>/dev/null
    
    if [ -d "\$WORK/golden_snapshot" ] && [ \$ATTEMPTS -le 2 ]; then
        # 前两次尝试完全沿用主人的极品快照和当时敲门的 Endpoint
        cp -a "\$WORK/golden_snapshot/." "\$WORK/" 2>/dev/null
        EP=\$(cat "\$WORK/current.endpoint" 2>/dev/null)
        [ -z "\$EP" ] && EP="162.159.192.1:2408"
    else
        # 快照失效，进入第二轨：降级暴力洗牌 (无限扩池)
        EP=\${ENDPOINTS[\$RANDOM % \${#ENDPOINTS[@]}]}
        echo "\$EP" > "\$WORK/current.endpoint"
    fi

    # 启动勇哥物理隔离核心
    cd "\$WORK"; export HOME="\$WORK"
    nohup ./sbwpph -b 127.0.0.1:\$IN_PORT --cfon --country \$REG -4 --endpoint "\$EP" >/dev/null 2>&1 &
    
    # 缓冲等待并测速
    sleep 10
    IP=""
    for i in {1..3}; do
        API=\${APIS[\$RANDOM % \${#APIS[@]}]}
        IP=\$(curl -s4 -m 5 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -n "\$IP" ] && break
        sleep 2
    done

    # 命中校验
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
# 7. 大后台哨兵 (w_master)
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
            # 发现漂移或断流！果断斩断气闸
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
# 8. 终极控制台 tw (含安全抽卡与黄金快照封印)
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
        
        # 随机抽取敲门砖 Endpoint (无级扩池核心)
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
            # 制作黄金快照 (拷贝所有隐藏文件)
            rm -rf "$N_DIR/golden_snapshot"; mkdir -p "$N_DIR/golden_snapshot"
            cp -a "$N_DIR/." "$N_DIR/golden_snapshot/" 2>/dev/null
            
            echo "$IP" > "$N_DIR/s$N.lock"; date +%s > "$N_DIR/s$N.uptime"; date +%s > "$N_DIR/s$N.session"
            rm -f "$N_DIR/s$N.hibernating" 2>/dev/null
            echo -e "\033[1;32m✅ 快照已封印！挂锁完毕！监控引擎已同步。\033[0m"; sleep 2; break
        fi
    done
    rm -f "$N_DIR/s$N.manual" 2>/dev/null
}

action_toggle() {
    local N=$1; get_node_vars $N
    if [ -f "$N_DIR/s$N.disabled" ]; then
        rm -f "$N_DIR/s$N.disabled" "$N_DIR/s$N.hibernating"
        echo -e "\033[1;32m✅ S$N 已唤醒，哨兵即将介入恢复快照！\033[0m"
    else
        touch "$N_DIR/s$N.disabled"
        fuser -k -9 "$N_IN/tcp" "$N_OUT/tcp" >/dev/null 2>&1; pkill -f "$N_DIR/sbwpph"; pkill -f "/etc/s-box/sl$N"
        echo -e "\033[1;33m💤 S$N 已彻底斩断后端物理进程并休眠！\033[0m"
    fi
    sleep 2
}

action_nodes() {
    clear
    IP=$(curl -s6 -m 5 api64.ipify.org 2>/dev/null || ip -6 addr show dev eth0 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | head -n 1)
    [ -z "$IP" ] && IP="[获取IPv6失败]"
    
    CF1=$(cat /etc/s-box/cf_s1.info); CF2=$(cat /etc/s-box/cf_s2.info); CF3=$(cat /etc/s-box/cf_s3.info)
    UUID=$(cat /etc/s-box/vless_uuid.info); PASS=$(cat /etc/s-box/hy2_pass.info)
    
    echo -e "\033[1;36m=================================================================\033[0m"
    echo -e "\033[1;35m【第一步】前往 CF Zero Trust -> Tunnels -> Public Hostname 绑定:\033[0m"
    echo -e "👉 战区 S1: \033[1;32m$CF1\033[0m -> 转发至 \033[1;33mHTTP://localhost:10001\033[0m"
    echo -e "👉 战区 S2: \033[1;32m$CF2\033[0m -> 转发至 \033[1;33mHTTP://localhost:10002\033[0m"
    echo -e "👉 战区 S3: \033[1;32m$CF3\033[0m -> 转发至 \033[1;33mHTTP://localhost:10003\033[0m"
    
    echo -e "\n\033[1;35m【第二步】提取 VLESS (Argo CDN 节点) 复制到客户端:\033[0m"
    gen_v() { echo "vless://$(echo -n "$UUID@$2:443?encryption=none&security=tls&sni=$2&type=ws&host=$2&path=/?ed=2048#$1")"; }
    echo -e "🇺🇸 S1: \033[40;32m $(gen_v "SkyNet-CF-S1" "$CF1") \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m $(gen_v "SkyNet-CF-S2" "$CF2") \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m $(gen_v "SkyNet-CF-S3" "$CF3") \033[0m"

    echo -e "\n\033[1;35m【第三步】提取 Hysteria2 (纯 IPv6 原生直连节点):\033[0m"
    echo -e "🇺🇸 S1: \033[40;32m hysteria2://$PASS@[$IP]:8443/?sni=bing.com&insecure=1#SkyNet-HY2-S1 \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m hysteria2://$PASS@[$IP]:8444/?sni=bing.com&insecure=1#SkyNet-HY2-S2 \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m hysteria2://$PASS@[$IP]:8445/?sni=bing.com&insecure=1#SkyNet-HY2-S3 \033[0m"
    echo -e "\033[1;36m=================================================================\033[0m"
    read -p "按回车键返回大盘..."
}

while true; do
    draw_dashboard
    echo -e "  \033[1;33m⚙️ 【天网矩阵调度中心】\033[0m"
    echo -e "  [1] 🇺🇸 S1 战区 (抽卡挂锁/通道休眠)     [4] 🔗 提取全节点链接与 CF 配置向导"
    echo -e "  [2] 🇬🇧 S2 战区 (抽卡挂锁/通道休眠)     [5] 📜 追踪系统实时史记 (日志)"
    echo -e "  [3] 🇯🇵 S3 战区 (抽卡挂锁/通道休眠)     [0] 🚪 退出总控台"
    echo ""
    read -t 10 -p "👉 请输入指令 (10秒无操作将自动刷新大盘): " cmd
    if [ $? -gt 128 ]; then continue; fi
    
    case "$cmd" in
        1) action_draw 1 ;;
        2) action_draw 2 ;;
        3) action_draw 3 ;;
        4) action_nodes ;;
        5) clear; echo -e "\033[1;36m📜 正在追踪史记 (按 Ctrl+C 返回大盘)...\033[0m\n"; tail -f /etc/s-box/stability.log ;;
        0) clear; exit 0 ;;
    esac
done
EOF
chmod +x /usr/bin/tw

# ====================================================================
# 9. 系统自启机制与凌晨重置任务
# ====================================================================
# 保留你习惯的凌晨 4 点重置任务
(crontab -l 2>/dev/null | grep -v "stability.log"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重置，引导每日快照回档 ===\" > /etc/s-box/stability.log && /sbin/reboot") | crontab -

# 触发一波初始唤醒
nohup /usr/bin/w_master >/dev/null 2>&1 &

echo -e "\n\033[1;32m🎉 天网系统 V22+ 终极版部署完毕！所有模块已大一统！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;36mtw\033[1;37m 唤醒天网总控台提取你的节点！\033[0m"
