#!/bin/bash
# ====================================================================
# 天网系统 V22+ (致敬 V9.5 暴君回档 + 9大API轮巡 + 脱壳降噪版)
# ====================================================================
clear
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;37m                 🛡️ 天网系统 V22+ (暴君回档重构版) 🛡️\033[0m"
echo -e "\033[1;36m=================================================================\033[0m"
echo -e "\033[1;33m[前置要求] 执行安装前，请确保您已手动完成以下两步：\033[0m"
echo -e "  1. 已安装 WARP (VPS 必须已具备 IPv4 出口能力)。"
echo -e "  2. 已通过第三方脚本安装了包含赛风的协议，且\033[1;31m端口必须设为 40000\033[0m。"
echo -e "\033[1;36m-----------------------------------------------------------------\033[0m"
echo -e "  \033[1;32m[1]\033[0m 🚀 嗅探环境并部署天网 (无损克隆，激活暴君回档引擎)"
echo -e "  \033[1;31m[2]\033[0m 🗑️ 定向卸载天网 (仅剥离天网组件，\033[1;32m绝对保留 WARP 与原版脚本\033[0m)"
echo -e "  \033[1;33m[0]\033[0m 🚪 退出"
echo -e "\033[1;36m=================================================================\033[0m"
read -p "👉 请选择操作序号: " menu_choice

if [ "$menu_choice" == "2" ]; then
    echo -e "\n\033[1;31m⚠️ 正在启动【天网自毁剥离程序】...\033[0m"
    systemctl stop front-box w_master 2>/dev/null
    systemctl disable front-box w_master 2>/dev/null
    
    # 物理超度所有天网进程
    pkill -9 -f front-box; pkill -9 -f w_master; pkill -9 -f "127.0.0.1:208"
    fuser -k -9 1081/tcp 1082/tcp 1083/tcp 2081/tcp 2082/tcp 2083/tcp 2084/tcp >/dev/null 2>&1
    
    rm -rf /etc/skynet /usr/bin/tw /usr/bin/w_master
    rm -f /etc/systemd/system/front-box.service /etc/systemd/system/w_master.service
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
echo -e "\033[1;31m🔥 正在执行【天网 V22+】环境嗅探与暴君重构...\033[0m"

# ====================================================================
# 1. 前置条件检测
# ====================================================================
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget socat net-tools psmisc jq unzip tar openssl cron nano haveged rng-tools >/dev/null 2>&1
systemctl enable --now haveged >/dev/null 2>&1

echo -ne "⏳ 检查 IPv4 (WARP) 连通性... "
IPV4=$(curl -s4 -m 5 api.ipify.org 2>/dev/null)
if [ -z "$IPV4" ]; then
    echo -e "\033[1;31m[失败]\033[0m\n💀 未检测到 IPv4 出口！"
    exit 1
fi
echo -e "\033[1;32m[通过] (IP: $IPV4)\033[0m"

echo -ne "⏳ 检查 40000 端口及赛风核心... "
TARGET_PID=$(netstat -tlnp 2>/dev/null | grep ":40000 " | awk '{print $7}' | cut -d'/' -f1 | head -n 1)
CORE_FILE=$(readlink -f /proc/$TARGET_PID/exe 2>/dev/null)
CORE_DIR=$(readlink -f /proc/$TARGET_PID/cwd 2>/dev/null)
[ "$CORE_DIR" == "/" ] && CORE_DIR="/etc/s-box"

if [ -z "$CORE_FILE" ] || [ ! -f "$CORE_FILE" ]; then
    echo -e "\033[1;31m[失败]\033[0m\n❌ 40000端口未开启，或无法定位核心物理路径！"
    exit 1
fi
echo -e "\033[1;32m[通过] (核心: $CORE_FILE)\033[0m"

# ====================================================================
# 2. 基因克隆：建立绝对隔离的 /etc/skynet 基地
# ====================================================================
USER_PASS=$(grep -Eo '"password":[ \t]*"[^"]+"' /etc/s-box/sb.json 2>/dev/null | tail -n 1 | awk -F'"' '{print $4}')
[ -z "$USER_PASS" ] && USER_PASS="Skynet_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"
PORT_S1=40000; PORT_S2=40001; PORT_S3=40002; VLESS_UUID=$(cat /proc/sys/kernel/random/uuid)

# 暴力斩杀原版占用
systemctl stop sing-box 2>/dev/null; systemctl disable sing-box 2>/dev/null
kill -9 $TARGET_PID 2>/dev/null

rm -rf /etc/skynet; mkdir -p /etc/skynet
# 建立工作区与黄金回档区 (完全分离)
for i in {1..4}; do
    mkdir -p /etc/skynet/sub$i /etc/skynet/golden_$i
    cp -a "$CORE_DIR/." /etc/skynet/sub$i/ 2>/dev/null
    cp -a "$CORE_DIR/." /etc/skynet/golden_$i/ 2>/dev/null
    cp "$CORE_FILE" /etc/skynet/sub$i/sbwpph
    chmod +x /etc/skynet/sub$i/sbwpph
done
mkdir -p /etc/skynet/blacklist

openssl req -new -x509 -days 3650 -nodes -out /etc/skynet/hy2.crt -keyout /etc/skynet/hy2.key -subj "/CN=bing.com" 2>/dev/null
echo "us.domain.com" > /etc/skynet/cf_s1.info; echo "uk.domain.com" > /etc/skynet/cf_s2.info; echo "jp.domain.com" > /etc/skynet/cf_s3.info
echo "$VLESS_UUID" > /etc/skynet/vless_uuid.info; echo "$USER_PASS" > /etc/skynet/hy2_pass.info

# 拉取官方纯正的前端核心
curl -sL -o /tmp/sbox.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv /tmp/sing-box-*/sing-box /etc/skynet/front-box; chmod +x /etc/skynet/front-box

# ====================================================================
# 3. 部署前端路由
# ====================================================================
cat << EOF > /etc/skynet/front.json
{
  "log": {"level": "fatal"},
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-in-1", "listen": "::", "listen_port": $PORT_S1, "users": [{"password": "$USER_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/skynet/hy2.crt", "key_path": "/etc/skynet/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-2", "listen": "::", "listen_port": $PORT_S2, "users": [{"password": "$USER_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/skynet/hy2.crt", "key_path": "/etc/skynet/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-3", "listen": "::", "listen_port": $PORT_S3, "users": [{"password": "$USER_PASS"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/skynet/hy2.crt", "key_path": "/etc/skynet/hy2.key"} },
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
ExecStart=/etc/skynet/front-box run -c /etc/skynet/front.json
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now front-box >/dev/null 2>&1

# 初始化战区
echo "US" > /etc/skynet/sub1/region.info; echo "GB" > /etc/skynet/sub2/region.info
echo "JP" > /etc/skynet/sub3/region.info; echo "US" > /etc/skynet/sub4/region.info

# ====================================================================
# 4. 暴君哨兵 w_master (容忍延迟，双重校验，直接裸奔接管)
# ====================================================================
cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/skynet/stability.log"
# 9 大轮巡 API，彻底防止猛薅被封
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com" "http://ipecho.net/plain" "http://whatismyip.akamai.com" "http://eth0.me" "http://wgetip.com")

echo "$(date '+[%m-%d %H:%M:%S]') 🚀 VPS开机！暴君哨兵就绪，启动全境巡逻。" >> "$SLA_LOG"

while true; do
    for N in 1 2 3; do
        WORK="/etc/skynet/sub$N"
        IN_PORT=$((2080 + N)); OUT_PORT=$((1080 + N))
        
        if [ -f "$WORK/s$N.manual" ] || [ -f "$WORK/s$N.disabled" ]; then continue; fi
        
        # 免死金牌：60秒内刚启动，不查杀，给足握手时间！
        if [ -f "$WORK/s$N.boot" ]; then
            if [ $(($(date +%s) - $(cat "$WORK/s$N.boot" 2>/dev/null))) -lt 60 ]; then continue; fi
            rm -f "$WORK/s$N.boot"
        fi

        LOCK="$WORK/s$N.lock"; [ ! -f "$LOCK" ] && continue
        TARGET=$(cat "$LOCK" | tr -d '[:space:]'); [ -z "$TARGET" ] && continue
        
        CURRENT=$(curl -s --max-time 8 --socks5-hostname 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        
        # 【双重校验防误杀】：如果空，再给 6 秒机会复测！
        if [ -z "$CURRENT" ]; then
            sleep 6
            CURRENT=$(curl -s --max-time 8 --socks5-hostname 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        fi

        if [[ "$CURRENT" == "$TARGET" ]]; then
            if ! netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT "; then
                # setsid 脱壳启动气闸，终端绝不弹 Killed
                setsid socat TCP4-LISTEN:$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:$IN_PORT >/dev/null 2>&1 &
                echo "$(date '+[%m-%d %H:%M:%S]') [🟢 守护] S$N 快照无损，气闸畅通！" >> "$SLA_LOG"
                [ ! -f "$WORK/s$N.session" ] && date +%s > "$WORK/s$N.session"
            fi
        else
            # 【暴君执法】：确诊离线或漂移，杀掉、回档、重启！
            REASON=$([ -z "$CURRENT" ] && echo "假死断流" || echo "IP漂移至 $CURRENT")
            echo "$(date '+[%m-%d %H:%M:%S]') [🚨 执法] S$N 发生 $REASON！执行斩首回档..." >> "$SLA_LOG"
            
            fuser -k -9 $OUT_PORT/tcp >/dev/null 2>&1
            fuser -k -9 $IN_PORT/tcp >/dev/null 2>&1
            pkill -9 -f "127.0.0.1:$IN_PORT" 2>/dev/null
            rm -f "$WORK/s$N.session" 2>/dev/null
            
            # 清除被污染的记忆，覆写黄金快照
            rm -rf $WORK/.cache $WORK/*.os $WORK/*.db* 2>/dev/null
            cp -a /etc/skynet/golden_$N/. $WORK/ 2>/dev/null
            
            EP=$(cat "$WORK/current.endpoint" 2>/dev/null); [ -z "$EP" ] && EP="162.159.192.1:2408"
            cd $WORK; export HOME=$WORK
            # setsid 脱壳裸奔拉起，终端绝无报错
            setsid ./sbwpph -b 127.0.0.1:$IN_PORT --cfon --country $(cat region.info) -4 --endpoint "$EP" >/dev/null 2>&1 &
            date +%s > "$WORK/s$N.boot" # 颁发免死金牌
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
# 5. 终极控制台 tw (后台并发，大盘秒开)
# ====================================================================
cat << 'EOF' > /usr/bin/tw
#!/bin/bash
rm -f /etc/skynet/sub*/s*.manual 2>/dev/null
cleanup_manual() { rm -f /etc/skynet/sub*/s*.manual 2>/dev/null; }
trap 'cleanup_manual; echo -e "\n\033[1;31m[安全中断] 退出天网总控台...\033[0m"; exit 0' INT TERM QUIT HUP

APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com" "http://ipecho.net/plain" "http://whatismyip.akamai.com" "http://eth0.me" "http://wgetip.com")
ENDPOINTS=("162.159.192.1:2408" "162.159.193.1:2408" "162.159.195.1:2408" "engage.cloudflareclient.com:2408" "162.159.36.1:2408" "162.159.132.53:2408")

get_node_vars() {
    N_IN=$((2080 + $1)); N_OUT=$((1080 + $1)); N_DIR="/etc/skynet/sub$1"
    N_REG=$(cat "$N_DIR/region.info" 2>/dev/null)
}

draw_dashboard() {
    clear
    echo -e "\033[1;36m=========================================================================================================\033[0m"
    echo -e "\033[1;37m                                🛡️ 天网系统 V22+ (暴君执法大一统中心) 🛡️\033[0m"
    echo -e "\033[1;36m=========================================================================================================\033[0m"
    printf " %-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\n" "通道" "战区" "锁定目标 IP" "当前真实 IP" "对外气闸" "总存活" "未漂移" "健康状态及行动指示"
    echo "---------------------------------------------------------------------------------------------------------"
    
    # 核心优化：并行执行三个通道的探测，防止大盘刷新缓慢
    rm -f /tmp/skynet_cur_*
    for N in 1 2 3; do
        (
            get_node_vars $N
            CUR=$(curl -s --max-time 8 --socks5-hostname 127.0.0.1:$N_IN ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
            echo "$CUR" > /tmp/skynet_cur_$N
        ) &
    done
    wait # 等待三个并发探测结束

    for N in 1 2 3; do
        get_node_vars $N
        TAR=$(cat "$N_DIR/s$N.lock" 2>/dev/null)
        CUR=$(cat "/tmp/skynet_cur_$N" 2>/dev/null)
        if netstat -tlnp 2>/dev/null | grep -q ":$N_OUT "; then G_R="🟢开启"; else G_R="🔴截断"; fi
        
        UP_TOT="--:--:--"; UP_SES="--:--:--"
        NW=$(date +%s)
        if [ -n "$TAR" ]; then
            if [ -f "$N_DIR/s$N.uptime" ]; then ST_TOT=$(cat "$N_DIR/s$N.uptime" 2>/dev/null); DF=$((NW - ST_TOT)); [ $DF -gt 0 ] && UP_TOT=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
            if [ -f "$N_DIR/s$N.session" ]; then ST_SES=$(cat "$N_DIR/s$N.session" 2>/dev/null); DF=$((NW - ST_SES)); [ $DF -gt 0 ] && UP_SES=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
        fi

        if [ -f "$N_DIR/s$N.disabled" ]; then C="\033[1;90m"; G_R="⚫关闭"; S="💤 深度休眠 (通道已物理断开)"
        elif [ -f "$N_DIR/s$N.manual" ]; then C="\033[1;35m"; G_R="🛑截断"; S="🛑 人工调优防泄露中"
        elif [ -z "$CUR" ]; then C="\033[1;33m"; G_R="🔴截断"; S="🟡 假死断流 / 暴君即将执法重启"
        elif [ "$CUR" == "$TAR" ]; then C="\033[1;32m"; G_R="🟢开启"; S="✅ 极品无损运行中"
        else C="\033[1;31m"; G_R="🔴截断"; S="🚨 漂移！暴君即将执法回档"; fi
        printf " ${C}%-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\033[0m\n" "S$N" "$N_REG" "$TAR" "${CUR:-空}" "$G_R" "$UP_TOT" "$UP_SES" "$S"
    done
    echo -e "\033[1;36m=========================================================================================================\033[0m"
}

action_draw() {
    local N=$1; get_node_vars $N
    rm -f "$N_DIR/s$N.disabled" 2>/dev/null
    fuser -k -9 $N_OUT/tcp >/dev/null 2>&1
    echo $$ > "$N_DIR/s$N.manual"
    
    clear
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "              🐺 [S$N] 无极扩池安全抽卡引擎 (大道至简版)"
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "  [1] 🇺🇸 美国  [2] 🇬🇧 英国  [3] 🇯🇵 日本  [4] 🇸🇬 新加坡"
    echo -ne "\033[1;33m👉 选择目标战区 (默认当前 $N_REG): \033[0m"; read r
    case "$r" in 1) N_REG="US";; 2) N_REG="GB";; 3) N_REG="JP";; 4) N_REG="SG";; esac
    echo "$N_REG" > "$N_DIR/region.info"

    while true; do
        # 1. 杀掉老进程，彻底清空老记忆
        fuser -k -9 $N_IN/tcp >/dev/null 2>&1
        pkill -9 -f "127.0.0.1:$N_IN" 2>/dev/null
        rm -rf "$N_DIR"/.cache "$N_DIR"/*.db* "$N_DIR"/*.os 2>/dev/null
        
        EP=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}
        echo "$EP" > "$N_DIR/current.endpoint"
        
        # 2. 原地裸奔拉起，setsid 脱壳绝不报警
        echo -ne "\r\033[K\033[1;36m⏳ 清空旧忆，带端点 ($EP) 重新拉起中...\033[0m"
        cd "$N_DIR"; export HOME="$N_DIR"
        setsid ./sbwpph -b 127.0.0.1:$N_IN --cfon --country $N_REG -4 --endpoint "$EP" >/dev/null 2>&1 &
        
        # 3. 极速测端口，一旦启动再睡5秒缓冲
        sleep 2
        for i in {20..1}; do netstat -tlnp 2>/dev/null | grep -q ":$N_IN " && break; sleep 1; done
        sleep 5
        
        # 4. 测 IP (用足API池)
        IP=""
        for i in {1..3}; do
            API=${APIS[$RANDOM % ${#APIS[@]}]}
            IP=$(curl -s --max-time 8 --socks5-hostname 127.0.0.1:$N_IN $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
            if [ -n "$IP" ]; then break; fi
            echo -ne "\r\033[K\033[1;35m⏳ 隧道搭建中，第 $i 次轮巡测网...\033[0m"
            sleep 4
        done
        
        if [ -z "$IP" ]; then continue; fi
        
        echo -e "\n\033[1;32m🎯 命中极品 IP: \033[1;37m$IP\033[0m"
        echo -ne "\033[1;33m✨ 满意按 [Y] 挂锁，按回车杀掉重抽: \033[0m"; read k
        if [[ "$k" == "y" || "$k" == "Y" ]]; then
            # 【核心真理】满意就让它继续跑！只备份数据即可！
            rm -rf /etc/skynet/golden_$N/* /etc/skynet/golden_$N/.* 2>/dev/null
            cp -a "$N_DIR/." /etc/skynet/golden_$N/ 2>/dev/null
            
            echo "$IP" > "$N_DIR/s$N.lock"; date +%s > "$N_DIR/s$N.uptime"; date +%s > "$N_DIR/s$N.session"
            date +%s > "$N_DIR/s$N.boot" # 给个免死金牌
            
            # 脱壳接通气闸
            setsid socat TCP4-LISTEN:$N_OUT,fork,reuseaddr TCP4:127.0.0.1:$N_IN >/dev/null 2>&1 &
            echo -e "\033[1;32m✅ 快照已存入金库！气闸接通！\033[0m"; sleep 2; break
        fi
    done
    rm -f "$N_DIR/s$N.manual" 2>/dev/null
}

action_toggle() {
    local N=$1; get_node_vars $N
    if [ -f "$N_DIR/s$N.disabled" ]; then
        rm -f "$N_DIR/s$N.disabled"
        echo -e "\033[1;32m✅ S$N 已解除休眠，暴君哨兵即将在 20 秒内将其拉起！\033[0m"
    else
        touch "$N_DIR/s$N.disabled"
        fuser -k -9 $N_OUT/tcp >/dev/null 2>&1
        fuser -k -9 $N_IN/tcp >/dev/null 2>&1
        pkill -9 -f "127.0.0.1:$N_IN" 2>/dev/null
        echo -e "\033[1;33m💤 S$N 已物理切断并进入深度休眠！\033[0m"
    fi
    sleep 2
}

action_s4() {
    DIR="/etc/skynet/sub4"; BLACKLIST_FILE="/etc/skynet/blacklist/bad_ips.txt"; IN_PORT=2084; touch "$BLACKLIST_FILE"
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
        
        read -p "打捞网数 (默认 20): " SCAN_MAX; [ -z "$SCAN_MAX" ] && SCAN_MAX=20
        A=0; VALID=()
        
        while [ $A -lt $SCAN_MAX ]; do
            ((A++)); echo -ne "\r\033[K🔍 [$A/$SCAN_MAX] 下网..."
            
            fuser -k -9 $IN_PORT/tcp >/dev/null 2>&1
            pkill -9 -f "127.0.0.1:$IN_PORT" 2>/dev/null
            rm -rf $DIR/.cache $DIR/*.os $DIR/*.db* 2>/dev/null
            
            EP=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}
            cd $DIR; export HOME=$DIR
            setsid ./sbwpph -b 127.0.0.1:$IN_PORT --cfon --country $TR -4 --endpoint "$EP" >/dev/null 2>&1 &
            
            sleep 2
            for i in {20..1}; do netstat -tlnp 2>/dev/null | grep -q ":$IN_PORT " && break; sleep 1; done
            sleep 5
            
            IP=""
            for i in {1..3}; do
                API=${APIS[$RANDOM % ${#APIS[@]}]}
                IP=$(curl -s --max-time 8 --socks5-hostname 127.0.0.1:$IN_PORT $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
                if [ -n "$IP" ]; then break; fi
                echo -ne "\r\033[K\033[1;35m⏳ 潜水员憋气中，第 $i 次轮巡测网...\033[0m"
                sleep 4
            done

            if [ -n "$IP" ]; then
                if grep -q "^${IP}$" "$BLACKLIST_FILE" 2>/dev/null; then echo -e "\n  ├─ 🚫 触发黑名单: $IP"
                else echo -e "\n  └─ 🌟 捕获极品: \033[1;32m$IP\033[0m"; VALID+=("$IP"); fi
            else echo -e "\n  ├─ \033[1;31m❌ 寻路超时 (已自动换网)\033[0m"; fi
        done
        fuser -k -9 $IN_PORT/tcp >/dev/null 2>&1
        pkill -9 -f "127.0.0.1:$IN_PORT" 2>/dev/null
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
    echo -e "点击你的隧道，进入 Public Hostname，添加以下三条映射记录："
    echo -e "   - 域名 1 (用于 S1) -> 转发给 Service: \033[1;32mHTTP://localhost:10001\033[0m"
    echo -e "   - 域名 2 (用于 S2) -> 转发给 Service: \033[1;32mHTTP://localhost:10002\033[0m"
    echo -e "   - 域名 3 (用于 S3) -> 转发给 Service: \033[1;32mHTTP://localhost:10003\033[0m"
    echo -e "-----------------------------------------------------------------"
    
    read -p "👉 想要将这三个域名写入脚本，生成准确的 VLESS 链接吗？(y/n): " set_cf
    if [[ "$set_cf" == "y" || "$set_cf" == "Y" ]]; then
        read -p "  输入 S1(美国) 域名 (例 us.abc.com): " c1; [ -n "$c1" ] && echo "$c1" > /etc/skynet/cf_s1.info
        read -p "  输入 S2(英国) 域名 (例 uk.abc.com): " c2; [ -n "$c2" ] && echo "$c2" > /etc/skynet/cf_s2.info
        read -p "  输入 S3(日本) 域名 (例 jp.abc.com): " c3; [ -n "$c3" ] && echo "$c3" > /etc/skynet/cf_s3.info
        echo -e "\033[1;32m✅ 域名已更新保存！\033[0m\n"
    fi

    IP=$(curl -s6 -m 5 api64.ipify.org 2>/dev/null || ip -6 addr show dev eth0 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | head -n 1)
    [ -z "$IP" ] && IP="[获取IPv6失败]"
    CF1=$(cat /etc/skynet/cf_s1.info); CF2=$(cat /etc/skynet/cf_s2.info); CF3=$(cat /etc/skynet/cf_s3.info)
    UUID=$(cat /etc/skynet/vless_uuid.info); PASS=$(cat /etc/skynet/hy2_pass.info)
    
    echo -e "\033[1;35m【第二步：提取 VLESS 节点 (Argo CDN 分流)】\033[0m"
    gen_v() { echo "vless://$(echo -n "$UUID@$2:443?encryption=none&security=tls&sni=$2&type=ws&host=$2&path=/?ed=2048#$1")"; }
    echo -e "🇺🇸 S1: \033[40;32m $(gen_v "SkyNet-CF-S1" "$CF1") \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m $(gen_v "SkyNet-CF-S2" "$CF2") \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m $(gen_v "SkyNet-CF-S3" "$CF3") \033[0m"

    echo -e "\n\033[1;35m【第三步：提取 Hysteria2 节点 (纯 IPv6 穿透直连)】\033[0m"
    echo -e "🇺🇸 S1: \033[40;32m hysteria2://$PASS@[$IP]:40000/?sni=bing.com&insecure=1#SkyNet-HY2-S1 \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m hysteria2://$PASS@[$IP]:40001/?sni=bing.com&insecure=1#SkyNet-HY2-S2 \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m hysteria2://$PASS@[$IP]:40002/?sni=bing.com&insecure=1#SkyNet-HY2-S3 \033[0m"
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
        1) action_draw 1 ;; 2) action_draw 2 ;; 3) action_draw 3 ;;
        4) action_s4 ;; 5) action_cf_nodes ;;
        6) clear; echo -e "\033[1;36m📜 正在追踪史记 (按 Ctrl+C 返回大盘)...\033[0m\n"; tail -f /etc/skynet/stability.log ;;
        0) clear; exit 0 ;;
    esac
done
EOF
chmod +x /usr/bin/tw

(crontab -l 2>/dev/null | grep -v "stability.log"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重置，引导每日快照回档 ===\" > /etc/skynet/stability.log && /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 天网 V22+ 部署完毕！抛弃复杂体系，全面回归暴君极简内核！\033[0m"
echo -e "\033[1;37m👉 终端输入 \033[1;36mtw\033[1;37m 享受零报错秒测抽卡！\033[0m"
