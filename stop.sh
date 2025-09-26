BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[38;2;0;128;0m"
YELLOW="\033[38;2;255;211;0m"
RED="\033[38;2;220;50;47m"

CONTAINER_NAME="bios611project_container"

ACTION="remove"

if [[ "$1" == "--stop" ]]; then
    ACTION="stop"
elif [[ "$1" == "--remove" ]]; then
    ACTION="remove"
elif [[ "$1" == "--force-remove" ]]; then
    ACTION="force-remove"
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    case $ACTION in
        stop)
            docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
            echo -e "${BOLD}Container '${CONTAINER_NAME}' stopped (but not removed).${RESET}"
            ;;
        remove)
            docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
            docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
            echo -e "${BOLD}Container '${CONTAINER_NAME}' stopped and removed.${RESET}"
            ;;
        force-remove)
            docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
            echo -e "${RED} ${BOLD}Container '${CONTAINER_NAME}' force removed while running.${RESET}"
            ;;
    esac
else
    echo -e "${YELLOW} No container named '${CONTAINER_NAME}' found.${RESET}"
fi