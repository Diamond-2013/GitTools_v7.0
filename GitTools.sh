#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/git_tool.log"
CONFIG_FILE="$SCRIPT_DIR/git_tool.ini"
CURRENT_DIR="$(pwd)"

COLOR_ENABLED=1
DEBUG_MODE=0
SAFE_MODE=1
MAX_LOG_SIZE=2097152
GIT_TIMEOUT=30
BACKUP_ENABLED=1
CURRENT_BRANCH=""
AUTO_PUSH=0
DEFAULT_REMOTE=origin
DEFAULT_BRANCH=main
CONFIRM_DANGEROUS=1
LOG_LEVEL=INFO
SHOW_HEADER=1
AUTO_CLEAN_NUL=1

CUR_DATE="$(date +%Y%m%d)"
CUR_TIME="$(date +%H%M%S)"

C_RESET=$'\e[0m'
C_RED=$'\e[91m'
C_GREEN=$'\e[92m'
C_YELLOW=$'\e[93m'
C_BLUE=$'\e[94m'
C_MAGENTA=$'\e[95m'
C_CYAN=$'\e[96m'
C_WHITE=$'\e[97m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'

init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<'EOF'
[DEFAULT]
COLOR=1
SAFE_MODE=1
BACKUP_ENABLED=1
AUTO_PUSH=0
DEFAULT_REMOTE=origin
DEFAULT_BRANCH=main
CONFIRM_DANGEROUS=1
LOG_LEVEL=INFO
SHOW_HEADER=1
AUTO_CLEAN_NUL=1
EOF
    fi
    while IFS='=' read -r key val; do
        key="${key//[$'\r\n']/}"; val="${val//[$'\r\n']/}"
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# || "$key" =~ ^\[ ]] && continue
        case "$key" in
            COLOR)            COLOR_ENABLED=$val ;;
            SAFE_MODE)        SAFE_MODE=$val ;;
            BACKUP_ENABLED)   BACKUP_ENABLED=$val ;;
            AUTO_PUSH)        AUTO_PUSH=$val ;;
            DEFAULT_REMOTE)   DEFAULT_REMOTE=$val ;;
            DEFAULT_BRANCH)   DEFAULT_BRANCH=$val ;;
            CONFIRM_DANGEROUS) CONFIRM_DANGEROUS=$val ;;
            LOG_LEVEL)        LOG_LEVEL=$val ;;
            SHOW_HEADER)      SHOW_HEADER=$val ;;
            AUTO_CLEAN_NUL)   AUTO_CLEAN_NUL=$val ;;
        esac
    done < "$CONFIG_FILE"
}

init_colors() {
    if [[ "$COLOR_ENABLED" != "1" ]]; then
        C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
        C_MAGENTA=""; C_CYAN=""; C_WHITE=""; C_BOLD=""; C_DIM=""
    fi
}

check_git() {
    if ! command -v git >/dev/null 2>&1; then
        cls
        print_error "Git 未安装或未连接到 PATH 环境变量"
        echo
        print_yellow " 请使用包管理器安装，例如：sudo apt install git"
        print_yellow " 或参考官方地址：https://git-scm.com/download/linux"
        echo
        read -r -p "按任意键退出..."
        exit 1
    fi
    local ver
    ver="$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
    local major="${ver%%.*}"
    if [[ "${major:-0}" -lt 2 ]]; then
        print_warn "Git 版本过旧，建议使用 2.x 及以上版本"
    fi
}

check_environment() {
    print_info "开始检查环境..."
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Git Tool Log - $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"
        echo "========================================" >> "$LOG_FILE"
    fi
    echo
    print_cyan "==================== 环境状态 ===================="
    if [[ "$SAFE_MODE" == "1" ]]; then
        print_green "  安全模式        : 已启用"
        print_yellow "    - 所有操作需要确认后才执行"
        print_yellow "    - 危险操作需要输入 YES 才能继续"
    else
        print_red "  安全模式        : 已关闭"
        print_red "    - 警告：所有操作直接执行，无法保护！"
    fi
    if [[ "$BACKUP_ENABLED" == "1" ]]; then
        print_green "  自动备份        : 已启用"
        print_yellow "    - 危险操作前自动暂存当前更改"
    else
        print_red "  自动备份        : 已关闭"
        print_red "    - 警告：危险操作前不自动备份，数据可能丢失！"
    fi
    if [[ "$AUTO_PUSH" == "1" ]]; then
        print_green "  自动推送        : 已启用"
        print_yellow "    - 提交成功后自动推送到远程"
    else
        print_dim "  自动推送        : 已关闭"
    fi
    if [[ "$CONFIRM_DANGEROUS" == "1" ]]; then
        print_yellow "  危险确认        : 需要输入 YES"
    else
        print_yellow "  危险确认        : 输入 y 即可"
    fi
    if [[ "$SHOW_HEADER" == "1" ]]; then
        print_green "  显示表头        : 完整模式"
        print_yellow "    - 显示当前目录和分支信息"
    else
        print_dim "  显示表头        : 简单模式"
    fi
    if [[ "$AUTO_CLEAN_NUL" == "1" ]]; then
        print_green "  清理 NUL 文件   : 已启用"
        print_yellow "    - 自动清理 Windows 设备文件（Linux 下无此问题）"
    else
        print_dim "  清理 NUL 文件   : 已关闭"
    fi
    print_cyan "  彩色显示        : $([ "$COLOR_ENABLED" == "1" ] && echo 已启用 || echo 已关闭)"
    print_cyan "  默认远程        : $DEFAULT_REMOTE"
    print_cyan "  默认分支        : $DEFAULT_BRANCH"
    print_cyan "  日志级别        : $LOG_LEVEL"
    print_cyan "===================================================="
    echo
    print_dim "按任意键继续..."
    read -r -n 1 -s
    echo
}

rotate_log() {
    [[ ! -f "$LOG_FILE" ]] && return
    local size
    size="$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)"
    if [[ "$size" -gt "$MAX_LOG_SIZE" ]]; then
        local backup_name="git_tool_old_${CUR_DATE}_${CUR_TIME}.log"
        [[ -f "$backup_name" ]] && rm -f "$backup_name"
        mv "$LOG_FILE" "$backup_name" 2>/dev/null
        echo "Log rotated - $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"
        print_info "日志已轮转: $backup_name"
    fi
}

display_header() {
    echo
    if [[ "$SHOW_HEADER" == "1" ]]; then
        CURRENT_BRANCH="$(git branch --show-current 2>/dev/null)"
        print_bold_cyan "Git 工具集 v7.0 - Professional Edition"
        print_cyan "================================================================"
        echo -n "${C_BOLD}当前目录: ${C_RESET}${C_YELLOW}$CURRENT_DIR${C_RESET} ${C_DIM}(${C_RESET}${C_BLUE}$CURRENT_BRANCH${C_DIM})${C_RESET}"
        echo
        print_cyan "================================================================"
    else
        echo "Git 工具集 v7.0"
        echo "================================================================"
    fi
    echo
}

display_menu() {
    print_menu_item " 1" "全部添加并修改"     "21" "获取远程更新"
    print_menu_item " 2" "提交修改"           "22" "克隆远程仓库"
    print_menu_item " 3" "一键添加并提交"     "23" "添加远程仓库"
    print_menu_item " 4" "查看仓库状态"       "24" "查看远程仓库"
    print_menu_item " 5" "查看提交日志"       "25" "删除远程仓库"
    print_menu_item " 6" "取消暂存"           "26" "暂存当前修改"
    print_menu_item " 7" "删除本地仓库"       "27" "恢复暂存工作"
    print_menu_item " 8" "切换工作目录"       "28" "查看暂存列表"
    print_menu_item " 9" "初始化仓库"         "29" "删除暂存项"
    print_menu_item "10" "递归添加源代码"     "30" "清理未跟踪文件"
    print_menu_item "11" "硬性回退提交"       "31" "还原所有修改"
    print_menu_item "12" "修改提交注释"       "32" "设置用户配置"
    print_menu_item "13" "查看文件差异"       "33" "中止合并/变基冲突"
    print_menu_item "14" "查看提交内容"       "34" "交互式变基"
    print_menu_item "15" "创建并切换分支"     "35" "标签管理"
    print_menu_item "16" "切换到已有分支"     "36" "子模块管理"
    print_menu_item "17" "查看所有分支"       "37" "拣选提交"
    print_menu_item "18" "删除分支"           "38" "二分查找"
    print_menu_item "19" "合并分支"           "39" "工作树管理"
    print_menu_item "20" "推送到远程仓库"     "40" "退出工具"
    print_cyan "================================================================"
    echo
}

print_menu_item() {
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        printf "%s%3s%s. %-14s    %s%3s%s. %s\n" \
            "$C_CYAN" "$1" "$C_RESET" "$2" "$C_CYAN" "$3" "$C_RESET" "$4"
    else
        printf "%3s. %-14s    %3s. %s\n" "$1" "$2" "$3" "$4"
    fi
}

get_input() {
    local prompt="$1"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_BOLD}${C_WHITE}$prompt${C_RESET}" choice
    else
        read -r -p "$prompt" choice
    fi
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        choice=0
    fi
}

check_repo() {
    cd "$CURRENT_DIR" 2>/dev/null || { print_error "无法进入目录 $CURRENT_DIR"; return 1; }
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "当前目录不是 Git 仓库"
        echo
        print_info "可执行 [9] 初始化仓库 或 [8] 切换选择正确目录"
        wait_key
        return 1
    fi
    return 0
}

cls() {
    [[ -n "$TERM" ]] && command clear 2>/dev/null
}

print_info()    { echo "${C_BLUE}[信息]${C_RESET} $1"; }
print_success() { echo "${C_GREEN}[成功]${C_RESET} $1"; }
print_warn()    { echo "${C_YELLOW}[警告]${C_RESET} $1"; }
print_error()   { echo "${C_RED}[错误]${C_RESET} $1"; }
print_green()   { echo "${C_GREEN}$1${C_RESET}"; }
print_yellow()  { echo "${C_YELLOW}$1${C_RESET}"; }
print_red()     { echo "${C_RED}$1${C_RESET}"; }
print_cyan()    { echo "${C_CYAN}$1${C_RESET}"; }
print_dim()     { echo "${C_DIM}$1${C_RESET}"; }
print_bold_cyan() { echo "${C_BOLD}${C_CYAN}$1${C_RESET}"; }
print_bold()    { echo "${C_BOLD}$1${C_RESET}"; }

wait_key() {
    echo
    print_dim "按任意键返回菜单..."
    read -r -n 1 -s
    echo
}

log_action() {
    if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "DEBUG" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" 2>/dev/null
    fi
}

confirm_action() {
    [[ "$SAFE_MODE" != "1" ]] && return 0
    local confirm
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_YELLOW}确认执行此操作？[y/N]：${C_RESET}" confirm
    else
        read -r -p "确认执行此操作？[y/N]：" confirm
    fi
    case "${confirm,,}" in
        y|yes) return 0 ;;
        *) print_warn "操作已取消"; wait_key; return 1 ;;
    esac
}

confirm_dangerous() {
    [[ "$SAFE_MODE" != "1" ]] && return 0
    local confirm
    if [[ "$CONFIRM_DANGEROUS" == "1" ]]; then
        if [[ "$COLOR_ENABLED" == "1" ]]; then
            read -r -p "${C_RED}危险操作！请输入 YES 确认继续，否则取消：${C_RESET}" confirm
        else
            read -r -p "危险操作！请输入 YES 确认继续，否则取消：" confirm
        fi
        case "${confirm^^}" in
            YES|Y) return 0 ;;
            *) print_warn "操作已取消"; wait_key; return 1 ;;
        esac
    else
        if [[ "$COLOR_ENABLED" == "1" ]]; then
            read -r -p "${C_YELLOW}确认执行？[y/N]：${C_RESET}" confirm
        else
            read -r -p "确认执行？[y/N]：" confirm
        fi
        case "${confirm,,}" in
            y|yes) return 0 ;;
            *) print_warn "操作已取消"; wait_key; return 1 ;;
        esac
    fi
}

read_commit_message() {
    local msg=""
    while :; do
        local line
        read -r line
        [[ -z "$line" ]] && break
        msg="$msg$line "
    done
    echo "${msg% }"
}

git_add_all() {
    check_repo || return
    if git status --porcelain 2>/dev/null | grep -q .; then
        :
    else
        print_warn "没有发现任何修改"
        wait_key; return
    fi
    print_info "正在添加所有修改..."
    if git add . 2>&1; then
        print_success "已添加所有修改"
        log_action "ADD_ALL_SUCCESS"
    else
        print_error "添加失败"
        log_action "ADD_ALL_FAILED"
    fi
    wait_key
}

git_commit() {
    check_repo || return
    if ! git diff --cached --name-only 2>/dev/null | grep -q .; then
        print_warn "暂存区为空，请先添加文件"
        wait_key; return
    fi
    print_cyan "请输入提交注释（支持多行，输入空行结束）"
    local commit_msg
    commit_msg="$(read_commit_message)"
    if [[ -z "$commit_msg" ]]; then
        commit_msg="自动提交 $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    print_info "提交注释: $commit_msg"
    if git commit -m "$commit_msg" 2>&1; then
        print_success "提交成功"
        git log --oneline -1 2>/dev/null
        log_action "COMMIT_SUCCESS: $commit_msg"
        if [[ "$AUTO_PUSH" == "1" ]]; then
            print_info "自动推送中..."
            git push 2>&1
        fi
    else
        print_error "提交失败"
        log_action "COMMIT_FAILED"
    fi
    wait_key
}

git_add_commit() {
    check_repo || return
    if ! git status --porcelain 2>/dev/null | grep -q .; then
        print_warn "没有发现任何修改"
        wait_key; return
    fi
    print_info "正在添加并提交..."
    if ! git add . 2>&1; then
        print_error "添加失败"
        wait_key; return
    fi
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入提交注释：${C_RESET}" commit_msg
    else
        read -r -p "请输入提交注释：" commit_msg
    fi
    [[ -z "$commit_msg" ]] && commit_msg="一键提交 $(date '+%Y-%m-%d %H:%M:%S')"
    if git commit -m "$commit_msg" 2>&1; then
        print_success "提交成功"
        git log --oneline -1 2>/dev/null
        log_action "ADD_COMMIT_SUCCESS: $commit_msg"
        if [[ "$AUTO_PUSH" == "1" ]]; then
            print_info "自动推送中..."
            git push 2>&1
        fi
    else
        print_error "提交失败"
        log_action "ADD_COMMIT_FAILED"
    fi
    wait_key
}

git_status() {
    check_repo || return
    print_bold "仓库状态："
    echo
    git status 2>&1
    wait_key
}

git_log() {
    check_repo || return
    print_bold "提交历史（最近 20 条）："
    echo
    git log --oneline --graph --decorate --all -20 2>&1
    echo
    print_bold "详细日志（最近 10 条）："
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        git log --pretty=format:"${C_CYAN}%h${C_RESET} ${C_GREEN}%ad${C_RESET} ${C_YELLOW}%an${C_RESET}%n%s%n" --date=short -10 2>&1
    else
        git log --pretty=format:"%h %ad %an%n%s%n" --date=short -10 2>&1
    fi
    wait_key
}

git_unstage() {
    check_repo || return
    if ! git diff --cached --name-only 2>/dev/null | grep -q .; then
        print_warn "暂存区为空"
        wait_key; return
    fi
    confirm_action || return
    print_info "正在取消暂存..."
    if git reset 2>&1; then
        print_success "已取消暂存"
        log_action "UNSTAGE_SUCCESS"
    else
        print_error "取消失败"
        log_action "UNSTAGE_FAILED"
    fi
    wait_key
}

git_delete_repo() {
    print_error "此操作将会删除整个 Git 仓库"
    confirm_dangerous || return
    cd "$CURRENT_DIR" 2>/dev/null || return
    if [[ ! -d ".git" ]]; then
        print_warn "当前目录不是 Git 仓库"
        wait_key; return
    fi
    print_info "正在删除 Git 仓库..."
    log_action "DELETE_REPO_START"
    rm -rf ".git" 2>/dev/null
    if [[ ! -d ".git" ]]; then
        print_success "Git 仓库已删除"
        if [[ -f ".gitignore" ]]; then
            rm -f ".gitignore"
            print_info ".gitignore 已删除"
        fi
        log_action "DELETE_REPO_SUCCESS"
    else
        print_error "删除失败，请手动删除 .git 目录"
        log_action "DELETE_REPO_FORCED"
    fi
    wait_key
}

git_change_path() {
    print_bold "当前路径：$CURRENT_DIR"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入新路径：${C_RESET}" new_path
    else
        read -r -p "请输入新路径：" new_path
    fi
    if [[ -z "$new_path" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if [[ ! -d "$new_path" ]]; then
        print_error "路径不存在"
        wait_key; return
    fi
    if cd "$new_path" 2>/dev/null; then
        CURRENT_DIR="$(pwd)"
        print_success "已切换到: $CURRENT_DIR"
        log_action "CHANGE_PATH: $CURRENT_DIR"
    else
        print_error "无法切换到该目录"
    fi
    wait_key
}

git_init() {
    cd "$CURRENT_DIR" 2>/dev/null || return
    if [[ -d ".git" ]]; then
        print_warn "当前目录已经是 Git 仓库"
        local confirm
        if [[ "$COLOR_ENABLED" == "1" ]]; then
            read -r -p "${C_YELLOW}是否重新初始化？[y/N]：${C_RESET}" confirm
        else
            read -r -p "是否重新初始化？[y/N]：" confirm
        fi
        case "${confirm,,}" in
            y|yes) ;;
            *) print_warn "操作已取消"; wait_key; return ;;
        esac
        print_info "正在删除旧仓库..."
        rm -rf ".git" 2>/dev/null
        if [[ -d ".git" ]]; then
            print_error "删除失败"
            wait_key; return
        fi
    fi
    print_info "正在初始化 Git 仓库..."
    if git init --initial-branch="$DEFAULT_BRANCH" 2>&1; then
        :
    elif git init 2>&1; then
        print_warn "当前 Git 版本不支持 --initial-branch，已使用默认分支名"
    else
        print_error "初始化失败"
        wait_key; return
    fi
    print_success "Git 仓库初始化完成"
    create_gitignore
    git add ".gitignore" 2>/dev/null
    print_info ".gitignore 已添加到暂存区"
    log_action "INIT_REPO"
    wait_key
}

create_gitignore() {
    [[ -f ".gitignore" ]] && return
    cat > .gitignore <<'EOF'
# ========== 操作系统
Thumbs.db
ehthumbs.db
Desktop.ini
.DS_Store
.Spotlight-V100
.Trashes
nul
/nul
CON
PRN
AUX
LPT1
LPT2
LPT3
LPT4
LPT5
LPT6
LPT7
LPT8
COM1
COM2
COM3
COM4
COM5
COM6
COM7
COM8
COM9

# ========== IDE 和编辑器
.vscode/
.idea/
.vs/
*.swp
*.swo
*~
*.bak
*.tmp
.project
.classpath
.settings/

# ========== 编译产物
*.exe
*.dll
*.so
*.dylib
*.class
*.o
*.obj
*.pdb
*.pyc
*.pyo
__pycache__/
*.jar
*.war
*.ear
target/
build/
dist/
out/
bin/

# ========== 日志文件
*.log
logs/
*.pid

# ========== 压缩文件
*.zip
*.rar
*.7z
*.tar
*.gz
*.bz2
*.xz

# ========== 依赖包
node_modules/
.pnpm-store/
vendor/
packages/
*.egg-info/
.mypy_cache/
.pytest_cache/
.coverage
htmlcov/

# ========== 环境配置
.env
.env.local
.env.*.local
.env.production
.env.development
*.local

# ========== 数据库
*.db
*.sqlite
*.sqlite3

# ========== 缓存
.cache/
*.cache
*.min.js
*.min.css
*.map

# ========== 系统文件
.fuse_hidden*
.directory
.lock-wscript
.npm/
.yarn/
package-lock.json
yarn.lock
pnpm-lock.yaml
EOF
}

git_add_source() {
    check_repo || return
    print_info "正在扫描源代码文件..."
    local SOURCE_EXTS="c cpp cc cxx h hpp hxx java py pyw js ts jsx tsx go rs rb php html htm css scss less vue svelte xml json yaml yml toml ini cfg conf sh bash zsh fish ps1 pl pm lua r m swift kt kts dart erl hrl ex exs clj cljs edn scala sbt groovy gradle lisp cl el sql prisma proto md markdown txt rst adoc asciidoc org tex latex bib"
    local expr=()
    for ext in $SOURCE_EXTS; do
        expr+=( -name "*.$ext" -o )
    done
    unset 'expr[${#expr[@]}-1]'
    local tmpfile="$SCRIPT_DIR/temp_filelist.txt"
    : > "$tmpfile"
    find . -type f \( "${expr[@]}" \) 2>/dev/null | sed 's|^\./||' > "$tmpfile"
    if [[ ! -s "$tmpfile" ]]; then
        print_warn "未找到任何源代码文件"
        rm -f "$tmpfile"
        wait_key; return
    fi
    local file_count
    file_count="$(wc -l < "$tmpfile")"
    print_success "找到 $file_count 个源代码文件"
    echo
    print_dim "正在添加文件..."
    local display_count=0 add_count=0 line
    while IFS= read -r line; do
        if [[ "$display_count" -lt 20 ]]; then
            display_count=$((display_count+1))
            echo "  $display_count. $(basename "$line")"
        fi
        git add "$line" 2>/dev/null
        add_count=$((add_count+1))
        if [[ "$add_count" -eq 100 ]]; then
            add_count=0
            print_dim "."
        fi
    done < "$tmpfile"
    rm -f "$tmpfile"
    print_success "已添加 $file_count 个源代码文件"
    if [[ -f ".gitignore" ]]; then
        git add ".gitignore" 2>/dev/null
        print_info ".gitignore 已添加到暂存区"
    fi
    log_action "ADD_SOURCE: $file_count files"
    wait_key
}

git_reset_hard() {
    check_repo || return
    if ! git log -1 >/dev/null 2>&1; then
        print_warn "没有提交记录"
        wait_key; return
    fi
    print_warn "此操作将丢弃所有未提交的修改"
    if [[ "$BACKUP_ENABLED" == "1" ]]; then
        if git stash push -m "auto_backup_${CUR_DATE}_${CUR_TIME}" 2>/dev/null; then
            print_info "已自动备份当前更改"
        else
            print_warn "没有需要备份的更改"
        fi
    else
        print_warn "自动备份已关闭，无法恢复"
    fi
    print_bold "最近的提交记录："
    git log --oneline --decorate -10 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入要回退的提交 ID（前7位）：${C_RESET}" commit_hash
    else
        read -r -p "请输入要回退的提交 ID（前7位）：" commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if ! git cat-file -t "$commit_hash" 2>/dev/null | grep -q "commit"; then
        print_error "提交 ID 无效"
        wait_key; return
    fi
    confirm_dangerous || return
    print_info "正在回退到 $commit_hash..."
    if git reset --hard "$commit_hash" 2>&1; then
        print_success "已回退到 $commit_hash"
        git log --oneline -5 2>&1
        log_action "RESET_SUCCESS: $commit_hash"
    else
        print_error "回退失败"
        log_action "RESET_FAILED: $commit_hash"
    fi
    wait_key
}

git_amend() {
    check_repo || return
    if ! git log -1 >/dev/null 2>&1; then
        print_warn "没有提交记录"
        wait_key; return
    fi
    print_bold "最近的提交记录："
    git log --oneline --decorate -10 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入要修改的提交 ID（前7位）：${C_RESET}" commit_hash
    else
        read -r -p "请输入要修改的提交 ID（前7位）：" commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if ! git cat-file -t "$commit_hash" 2>/dev/null | grep -q "commit"; then
        print_error "提交 ID 无效"
        wait_key; return
    fi
    local old_msg new_msg head_hash
    old_msg="$(git log --format=%s -n 1 "$commit_hash" 2>/dev/null)"
    print_info "当前注释: $old_msg"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入新的注释：${C_RESET}" new_msg
    else
        read -r -p "请输入新的注释：" new_msg
    fi
    if [[ -z "$new_msg" ]]; then
        print_warn "注释不能为空"
        wait_key; return
    fi
    head_hash="$(git rev-parse HEAD 2>/dev/null)"
    if [[ "${head_hash:0:7}" == "$commit_hash" ]]; then
        if git commit --amend -m "$new_msg" 2>&1; then
            print_success "已修改提交注释"
            log_action "AMEND_SUCCESS: $commit_hash"
        else
            print_error "修改失败"
        fi
    else
        print_warn "修改历史提交需要重写历史"
        confirm_dangerous || return
        local commit_count
        commit_count="$(git rev-list --count HEAD 2>/dev/null)"
        local rebase_range
        if [[ "$commit_count" -lt 5 ]]; then
            rebase_range="HEAD~$commit_count"
        else
            rebase_range="HEAD~5"
        fi
        if git rebase -i "$rebase_range" 2>&1; then
            print_success "提交已修改"
            log_action "AMEND_REBASE: $commit_hash"
        else
            print_error "变基失败，请手动处理"
        fi
    fi
    wait_key
}

git_diff() {
    check_repo || return
    print_bold "差异查看："
    echo "1. 工作区 vs 暂存区"
    echo "2. 暂存区 vs HEAD"
    echo "3. 工作区 vs HEAD"
    echo "4. 两个提交之间"
    echo "5. 分支之间"
    read -r -p "请选择 [1-5]：" diff_choice
    case "$diff_choice" in
        1) git diff 2>&1 ;;
        2) git diff --cached 2>&1 ;;
        3) git diff HEAD 2>&1 ;;
        4)
            git log --oneline -10 2>&1
            read -r -p "第一个提交 ID：" commit1
            read -r -p "第二个提交 ID：" commit2
            git diff "$commit1" "$commit2" 2>&1
            ;;
        5)
            git branch 2>&1
            read -r -p "第一个分支名：" branch1
            read -r -p "第二个分支名：" branch2
            git diff "$branch1" "$branch2" 2>&1
            ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

git_show() {
    check_repo || return
    print_bold "提交内容查看："
    git log --oneline -15 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入提交 ID：${C_RESET}" commit_hash
    else
        read -r -p "请输入提交 ID：" commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    git show "$commit_hash" --stat 2>&1
    print_dim "按任意键查看完整内容..."
    read -r -n 1 -s
    echo
    git show "$commit_hash" 2>&1 | "${PAGER:-less -R}"
    wait_key
}

git_branch_create() {
    check_repo || return
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入新分支名：${C_RESET}" branch_name
    else
        read -r -p "请输入新分支名：" branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if ! git branch "$branch_name" 2>&1; then
        print_error "创建分支失败"
        wait_key; return
    fi
    if git switch "$branch_name" 2>&1; then
        :
    elif git checkout "$branch_name" 2>&1; then
        :
    else
        print_error "切换分支失败"
        wait_key; return
    fi
    print_success "已创建并切换到分支: $branch_name"
    log_action "BRANCH_CREATE: $branch_name"
    wait_key
}

git_branch_switch() {
    check_repo || return
    print_bold "本地分支："
    git branch 2>&1
    print_bold "远程分支："
    git branch -r 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入要切换到的分支名：${C_RESET}" branch_name
    else
        read -r -p "请输入要切换到的分支名：" branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if git switch "$branch_name" 2>&1; then
        :
    elif git checkout "$branch_name" 2>&1; then
        :
    else
        print_error "切换分支失败"
        wait_key; return
    fi
    print_success "已切换到分支: $branch_name"
    log_action "BRANCH_SWITCH: $branch_name"
    wait_key
}

git_branch_list() {
    check_repo || return
    print_bold "本地分支："
    git branch -v 2>&1
    echo
    print_bold "远程分支："
    git branch -r -v 2>&1
    echo
    print_bold "所有分支："
    git branch -a -v 2>&1
    wait_key
}

git_branch_delete() {
    check_repo || return
    print_bold "所有分支："
    git branch 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入要删除的分支名：${C_RESET}" branch_name
    else
        read -r -p "请输入要删除的分支名：" branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    local current
    current="$(git branch --show-current 2>/dev/null)"
    if [[ "$branch_name" == "$current" ]]; then
        print_error "不能删除当前分支"
        wait_key; return
    fi
    print_yellow "1. 安全删除（已合并的）"
    print_red "2. 强制删除（未合并的）"
    read -r -p "请选择 [1-2]：" del_choice
    case "$del_choice" in
        1) git branch -d "$branch_name" 2>&1 ;;
        2)
            confirm_dangerous || return
            git branch -D "$branch_name" 2>&1
            ;;
        *) print_error "无效选择"; wait_key; return ;;
    esac
    if [[ $? -eq 0 ]]; then
        print_success "分支已删除: $branch_name"
        log_action "BRANCH_DELETE: $branch_name"
    else
        print_error "删除分支失败"
    fi
    wait_key
}

git_branch_merge() {
    check_repo || return
    print_bold "当前分支："
    git branch --show-current 2>&1
    echo
    print_bold "可用的分支："
    git branch 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}请输入要合并的分支名：${C_RESET}" branch_name
    else
        read -r -p "请输入要合并的分支名：" branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    local current
    current="$(git branch --show-current 2>/dev/null)"
    if [[ "$branch_name" == "$current" ]]; then
        print_warn "不能合并自己"
        wait_key; return
    fi
    confirm_action || return
    print_info "正在合并 $branch_name..."
    if git merge --no-ff "$branch_name" 2>&1; then
        print_success "合并成功"
        log_action "MERGE_SUCCESS: $branch_name"
    else
        print_error "合并失败，可能存在冲突"
        print_info "解决冲突后执行 git add . 和 git commit"
        log_action "MERGE_FAILED: $branch_name"
    fi
    wait_key
}

git_push() {
    check_repo || return
    print_bold "远程仓库："
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}远程仓库名（默认 $DEFAULT_REMOTE）回车确认：${C_RESET}" remote_name
    else
        read -r -p "远程仓库名（默认 $DEFAULT_REMOTE）回车确认：" remote_name
    fi
    [[ -z "$remote_name" ]] && remote_name="$DEFAULT_REMOTE"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}分支名（默认为当前分支）回车确认：${C_RESET}" branch_name
    else
        read -r -p "分支名（默认为当前分支）回车确认：" branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        branch_name="$(git branch --show-current 2>/dev/null)"
    fi
    confirm_action || return
    print_info "正在推送到 $remote_name/$branch_name..."
    if git push -u "$remote_name" "$branch_name" 2>&1; then
        print_success "推送成功"
        log_action "PUSH_SUCCESS: $remote_name/$branch_name"
    else
        print_error "推送失败，请检查网络"
        log_action "PUSH_FAILED"
    fi
    wait_key
}

git_pull() {
    check_repo || return
    print_bold "远程仓库："
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}远程仓库名（默认 $DEFAULT_REMOTE）回车确认：${C_RESET}" remote_name
    else
        read -r -p "远程仓库名（默认 $DEFAULT_REMOTE）回车确认：" remote_name
    fi
    [[ -z "$remote_name" ]] && remote_name="$DEFAULT_REMOTE"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}分支名（默认为当前分支）回车确认：${C_RESET}" branch_name
    else
        read -r -p "分支名（默认为当前分支）回车确认：" branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        branch_name="$(git branch --show-current 2>/dev/null)"
    fi
    print_info "正在获取 $remote_name/$branch_name..."
    if git pull --rebase "$remote_name" "$branch_name" 2>&1; then
        print_success "获取成功"
        log_action "PULL_SUCCESS: $remote_name/$branch_name"
    else
        print_error "获取失败，可能存在冲突"
        log_action "PULL_FAILED"
    fi
    wait_key
}

git_clone() {
    print_bold "当前路径：$CURRENT_DIR"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}远程仓库 URL：${C_RESET}" repo_url
    else
        read -r -p "远程仓库 URL：" repo_url
    fi
    if [[ -z "$repo_url" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}目标文件夹名（回车自动命名）：${C_RESET}" folder_name
    else
        read -r -p "目标文件夹名（回车自动命名）：" folder_name
    fi
    if [[ -z "$folder_name" ]]; then
        folder_name="$(basename "$repo_url" .git)"
        folder_name="${folder_name%.git}"
    fi
    print_info "正在克隆仓库..."
    if git clone --progress "$repo_url" "$folder_name" 2>&1; then
        print_success "克隆成功"
        cd "$folder_name" 2>/dev/null && CURRENT_DIR="$(pwd)"
        log_action "CLONE_SUCCESS: $repo_url"
    else
        print_error "克隆失败"
        log_action "CLONE_FAILED: $repo_url"
    fi
    wait_key
}

git_remote_add() {
    check_repo || return
    print_bold "当前远程仓库："
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}远程仓库名称：${C_RESET}" remote_name
    else
        read -r -p "远程仓库名称：" remote_name
    fi
    if [[ -z "$remote_name" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}远程仓库 URL：${C_RESET}" remote_url
    else
        read -r -p "远程仓库 URL：" remote_url
    fi
    if [[ -z "$remote_url" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    if git remote add "$remote_name" "$remote_url" 2>&1; then
        print_success "远程仓库已添加: $remote_name"
        log_action "REMOTE_ADD: $remote_name"
    else
        print_error "添加失败，可能存在同名远程"
    fi
    wait_key
}

git_remote_list() {
    check_repo || return
    print_bold "远程仓库列表："
    git remote -v 2>&1
    echo
    local remote_count=0 name
    for name in $(git remote); do
        remote_count=$((remote_count+1))
        echo
        print_cyan "[$name]"
        git remote show "$name" 2>&1
    done
    if [[ "$remote_count" -eq 0 ]]; then
        print_warn "没有配置远程仓库"
    fi
    wait_key
}

git_remote_remove() {
    check_repo || return
    print_bold "当前远程仓库："
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}要删除的远程仓库名：${C_RESET}" remote_name
    else
        read -r -p "要删除的远程仓库名：" remote_name
    fi
    if [[ -z "$remote_name" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    confirm_dangerous || return
    if git remote remove "$remote_name" 2>&1; then
        print_success "远程仓库已删除: $remote_name"
        log_action "REMOTE_REMOVE: $remote_name"
    else
        print_error "删除失败"
    fi
    wait_key
}

git_stash_push() {
    check_repo || return
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}暂存说明（回车使用默认）：${C_RESET}" stash_msg
    else
        read -r -p "暂存说明（回车使用默认）：" stash_msg
    fi
    [[ -z "$stash_msg" ]] && stash_msg="stash $(date '+%Y-%m-%d %H:%M:%S')"
    if git stash push -m "$stash_msg" 2>&1; then
        print_success "已暂存修改"
        log_action "STASH_PUSH: $stash_msg"
    else
        print_error "暂存失败"
    fi
    wait_key
}

git_stash_pop() {
    check_repo || return
    if ! git stash list 2>/dev/null | grep -q .; then
        print_warn "没有暂存的工作"
        wait_key; return
    fi
    print_bold "暂存列表："
    git stash list 2>&1
    echo
    print_yellow "1. 恢复最新并删除"
    print_yellow "2. 恢复最新但保留"
    print_yellow "3. 选择恢复指定暂存"
    read -r -p "请选择 [1-3]：" pop_choice
    case "$pop_choice" in
        1) git stash pop 2>&1 ;;
        2) git stash apply 2>&1 ;;
        3)
            if [[ "$COLOR_ENABLED" == "1" ]]; then
                read -r -p "${C_CYAN}暂存编号（如 0）：${C_RESET}" stash_index
            else
                read -r -p "暂存编号（如 0）：" stash_index
            fi
            if [[ -z "$stash_index" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            git stash pop "stash@{$stash_index}" 2>&1
            ;;
        *) print_error "无效选择"; wait_key; return ;;
    esac
    if [[ $? -eq 0 ]]; then
        print_success "暂存已恢复"
        log_action "STASH_POP"
    else
        print_error "恢复失败，可能存在冲突"
    fi
    wait_key
}

git_stash_list() {
    check_repo || return
    print_bold "暂存列表："
    git stash list 2>&1
    echo
    print_bold "暂存内容："
    git stash show -p 2>&1 | "${PAGER:-less -R}"
    wait_key
}

git_stash_drop() {
    check_repo || return
    if ! git stash list 2>/dev/null | grep -q .; then
        print_warn "没有暂存的工作"
        wait_key; return
    fi
    print_bold "暂存列表："
    git stash list 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}要删除的暂存编号（回车删除最新）：${C_RESET}" stash_index
    else
        read -r -p "要删除的暂存编号（回车删除最新）：" stash_index
    fi
    confirm_action || return
    if [[ -z "$stash_index" ]]; then
        git stash drop 2>&1
    else
        git stash drop "stash@{$stash_index}" 2>&1
    fi
    if [[ $? -eq 0 ]]; then
        print_success "暂存项已删除"
        log_action "STASH_DROP"
    else
        print_error "删除失败"
    fi
    wait_key
}

git_clean() {
    check_repo || return
    print_bold "未跟踪文件："
    git ls-files --others --exclude-standard 2>&1
    echo
    print_yellow "1. 预览将要清理的文件"
    print_yellow "2. 删除未跟踪文件"
    print_yellow "3. 删除所有未跟踪（含忽略文件）"
    print_yellow "4. 删除未跟踪目录"
    read -r -p "请选择 [1-4]：" clean_choice
    case "$clean_choice" in
        1) git clean -n 2>&1 ;;
        2)
            confirm_action || return
            git clean -f 2>&1
            log_action "CLEAN_FILES"
            ;;
        3)
            confirm_dangerous || return
            git clean -fx 2>&1
            log_action "CLEAN_ALL"
            ;;
        4)
            confirm_dangerous || return
            git clean -fd 2>&1
            log_action "CLEAN_DIRS"
            ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

git_restore() {
    check_repo || return
    print_bold "修改的文件："
    git status --porcelain 2>&1
    echo
    print_yellow "1. 还原指定文件"
    print_yellow "2. 还原所有修改"
    print_yellow "3. 还原所有修改（包含新增）"
    read -r -p "请选择 [1-3]：" restore_choice
    case "$restore_choice" in
        1)
            if [[ "$COLOR_ENABLED" == "1" ]]; then
                read -r -p "${C_CYAN}文件路径：${C_RESET}" file_path
            else
                read -r -p "文件路径：" file_path
            fi
            if [[ -z "$file_path" ]]; then
                print_warn "操作已取消"
            else
                if git restore "$file_path" 2>&1; then
                    :
                elif git checkout -- "$file_path" 2>&1; then
                    :
                else
                    print_error "还原失败"
                fi
                print_success "已还原: $file_path"
            fi
            ;;
        2)
            confirm_action || return
            git restore . 2>&1 || git checkout -- . 2>&1
            print_success "已还原所有修改"
            log_action "RESTORE_ALL"
            ;;
        3)
            confirm_dangerous || return
            git clean -fd 2>&1
            git restore . 2>&1 || git checkout -- . 2>&1
            print_success "已还原所有修改（含新增）"
            log_action "RESTORE_ALL_INCL_NEW"
            ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

git_config() {
    check_repo || return
    print_bold "Git 配置管理："
    echo "1. 设置用户名"
    echo "2. 设置邮箱"
    echo "3. 设置默认编辑器"
    echo "4. 查看全局配置"
    echo "5. 查看本地配置"
    echo "6. 清除配置"
    read -r -p "请选择 [1-6]：" cfg_choice
    case "$cfg_choice" in
        1)
            read -r -p "用户名：" git_user
            if [[ -n "$git_user" ]]; then
                git config --global user.name "$git_user"
                print_success "用户名已设置"
                log_action "CONFIG_USER: $git_user"
            fi
            ;;
        2)
            read -r -p "邮箱：" git_mail
            if [[ -n "$git_mail" ]]; then
                git config --global user.email "$git_mail"
                print_success "邮箱已设置"
                log_action "CONFIG_EMAIL: $git_mail"
            fi
            ;;
        3)
            read -r -p "编辑器命令（如 vim、code）：" git_editor
            if [[ -n "$git_editor" ]]; then
                git config --global core.editor "$git_editor"
                print_success "编辑器已设置"
            fi
            ;;
        4) git config --global --list ;;
        5) git config --local --list ;;
        6)
            confirm_dangerous || return
            git config --global --unset-all user.name 2>/dev/null
            git config --global --unset-all user.email 2>/dev/null
            print_success "配置已清除"
            ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

git_abort() {
    check_repo || return
    git merge --abort 2>/dev/null
    git rebase --abort 2>/dev/null
    git cherry-pick --abort 2>/dev/null
    print_success "已中止所有冲突操作"
    log_action "ABORT_CONFLICT"
    wait_key
}

git_rebase() {
    check_repo || return
    print_bold "交互式变基："
    git log --oneline -10 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}从哪个提交开始变基（前7位）：${C_RESET}" base_commit
    else
        read -r -p "从哪个提交开始变基（前7位）：" base_commit
    fi
    if [[ -z "$base_commit" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    confirm_action || return
    print_info "正在执行交互式变基..."
    if git rebase -i "$base_commit" 2>&1; then
        print_success "变基成功"
        log_action "REBASE_SUCCESS"
    else
        print_error "变基失败，如有冲突可执行 [33] 中止"
        log_action "REBASE_FAILED"
    fi
    wait_key
}

git_tag() {
    check_repo || return
    print_bold "标签管理："
    echo "1. 查看标签"
    echo "2. 创建标签"
    echo "3. 删除标签"
    echo "4. 推送标签到远程"
    read -r -p "请选择 [1-4]：" tag_choice
    case "$tag_choice" in
        1) git tag -l 2>&1 ;;
        2)
            read -r -p "标签名称：" tag_name
            if [[ -z "$tag_name" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            read -r -p "标签说明：" tag_msg
            if git tag -a "$tag_name" -m "$tag_msg" 2>&1; then
                print_success "标签已创建: $tag_name"
                log_action "TAG_CREATE: $tag_name"
            else
                print_error "创建标签失败"
            fi
            ;;
        3)
            read -r -p "要删除的标签名：" tag_name
            if [[ -z "$tag_name" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            confirm_action || return
            if git tag -d "$tag_name" 2>&1; then
                print_success "标签已删除"
                log_action "TAG_DELETE: $tag_name"
            else
                print_error "删除失败"
            fi
            ;;
        4)
            read -r -p "要推送的标签名（回车推送全部）：" tag_name
            if [[ -z "$tag_name" ]]; then
                git push --tags 2>&1
            else
                git push origin "$tag_name" 2>&1
            fi
            if [[ $? -eq 0 ]]; then
                print_success "标签已推送"
                log_action "TAG_PUSH: $tag_name"
            else
                print_error "推送失败"
            fi
            ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

git_submodule() {
    check_repo || return
    print_bold "子模块管理："
    echo "1. 查看子模块"
    echo "2. 添加子模块"
    echo "3. 更新子模块"
    echo "4. 初始化子模块"
    read -r -p "请选择 [1-4]：" sub_choice
    case "$sub_choice" in
        1) git submodule status 2>&1 ;;
        2)
            read -r -p "子模块 URL：" sub_url
            if [[ -z "$sub_url" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            read -r -p "目标路径：" sub_path
            if [[ -z "$sub_path" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            if git submodule add "$sub_url" "$sub_path" 2>&1; then
                print_success "子模块已添加"
                log_action "SUBMODULE_ADD: $sub_url"
            else
                print_error "添加失败"
            fi
            ;;
        3) git submodule update --remote 2>&1 ;;
        4) git submodule init 2>&1 ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

git_cherry_pick() {
    check_repo || return
    print_bold "拣选提交："
    git log --oneline -15 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}要拣选的提交 ID：${C_RESET}" commit_hash
    else
        read -r -p "要拣选的提交 ID：" commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "操作已取消"
        wait_key; return
    fi
    confirm_action || return
    if git cherry-pick "$commit_hash" 2>&1; then
        print_success "拣选成功"
        log_action "CHERRY_PICK_SUCCESS: $commit_hash"
    else
        print_error "拣选失败，可能存在冲突"
        log_action "CHERRY_PICK_FAILED: $commit_hash"
    fi
    wait_key
}

git_bisect() {
    check_repo || return
    print_bold "二分查找："
    echo "1. 开始二分查找"
    echo "2. 标记为坏提交"
    echo "3. 标记为好提交"
    echo "4. 结束二分查找"
    read -r -p "请选择 [1-4]：" bisect_choice
    case "$bisect_choice" in
        1)
            read -r -p "坏提交 ID：" bad_commit
            if [[ -z "$bad_commit" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            read -r -p "好提交 ID：" good_commit
            if [[ -z "$good_commit" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            git bisect start "$bad_commit" "$good_commit" 2>&1
            print_info "二分查找已开始，请测试后标记好坏"
            ;;
        2) git bisect bad 2>&1; print_info "已标记为坏提交" ;;
        3) git bisect good 2>&1; print_info "已标记为好提交" ;;
        4) git bisect reset 2>&1; print_success "二分查找已结束" ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

git_worktree() {
    check_repo || return
    print_bold "工作树管理："
    echo "1. 查看工作树列表"
    echo "2. 添加工作树"
    echo "3. 删除工作树"
    read -r -p "请选择 [1-3]：" worktree_choice
    case "$worktree_choice" in
        1) git worktree list 2>&1 ;;
        2)
            read -r -p "工作树路径：" worktree_path
            if [[ -z "$worktree_path" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            read -r -p "分支名称：" worktree_branch
            if [[ -z "$worktree_branch" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            if git worktree add "$worktree_path" "$worktree_branch" 2>&1; then
                print_success "工作树已添加"
                log_action "WORKTREE_ADD: $worktree_path"
            else
                print_error "添加失败"
            fi
            ;;
        3)
            read -r -p "要删除的工作树路径：" worktree_path
            if [[ -z "$worktree_path" ]]; then
                print_warn "操作已取消"
                wait_key; return
            fi
            confirm_action || return
            if git worktree remove "$worktree_path" 2>&1; then
                print_success "工作树已删除"
                log_action "WORKTREE_REMOVE: $worktree_path"
            else
                print_error "删除失败"
            fi
            ;;
        *) print_error "无效选择" ;;
    esac
    wait_key
}

exit_tool() {
    cls
    echo
    print_bold_cyan "Git 工具集 v7.0"
    print_cyan "================================================================"
    print_green "感谢使用，再见！"
    print_cyan "================================================================"
    echo
    log_action "EXIT_TOOL"
    exit 0
}

menu() {
    while :; do
        CURRENT_BRANCH="$(git branch --show-current 2>/dev/null)"
        cls
        if [[ "$SHOW_HEADER" == "1" ]]; then
            display_header
        else
            echo
            echo "Git 工具集 v7.0"
            echo "================================================================"
            echo
        fi
        display_menu

        get_input "请选择操作 [1-40]："
        case "$choice" in
            1)  git_add_all ;;
            2)  git_commit ;;
            3)  git_add_commit ;;
            4)  git_status ;;
            5)  git_log ;;
            6)  git_unstage ;;
            7)  git_delete_repo ;;
            8)  git_change_path ;;
            9)  git_init ;;
            10) git_add_source ;;
            11) git_reset_hard ;;
            12) git_amend ;;
            13) git_diff ;;
            14) git_show ;;
            15) git_branch_create ;;
            16) git_branch_switch ;;
            17) git_branch_list ;;
            18) git_branch_delete ;;
            19) git_branch_merge ;;
            20) git_push ;;
            21) git_pull ;;
            22) git_clone ;;
            23) git_remote_add ;;
            24) git_remote_list ;;
            25) git_remote_remove ;;
            26) git_stash_push ;;
            27) git_stash_pop ;;
            28) git_stash_list ;;
            29) git_stash_drop ;;
            30) git_clean ;;
            31) git_restore ;;
            32) git_config ;;
            33) git_abort ;;
            34) git_rebase ;;
            35) git_tag ;;
            36) git_submodule ;;
            37) git_cherry_pick ;;
            38) git_bisect ;;
            39) git_worktree ;;
            40) exit_tool ;;
            *)  print_error "无效选项，请输入 1-40 之间的数字"
                wait_key ;;
        esac
    done
}

init_config
init_colors

if ping -c 1 -W 2 github.com >/dev/null 2>&1; then
    print_green "[信息] GitHub 网络连接正常"
else
    print_yellow "[警告] GitHub 网络连接失败，远程操作可能无法执行"
fi

check_git
check_environment
rotate_log
menu
#（注：内容由AI生成）
