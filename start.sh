set -e

BOLD="\033[1m"
RESET="\033[0m"
BLUE="\033[38;2;75;156;211m"
RED="\033[38;2;220;50;47m"
YELLOW="\033[38;2;215;215;85m"

CONTAINER_NAME="bios611project_container"
IMAGE_NAME="bios611project"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Container '${CONTAINER_NAME}' is already running.${RESET}"
    echo "Open http://localhost:8787 in your browser."
    exit 0
elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Container '${CONTAINER_NAME}' exists but is stopped.${RESET}"
    echo "Starting it now..."
    docker start "${CONTAINER_NAME}" >/dev/null 2>&1
    echo -e "${BOLD}Container started!${RESET} Open http://localhost:8787 in your browser."
    echo -e "Username: ${BLUE}rstudio${RESET}"
    echo -e "Password: ${BLUE}611project${RESET}"
    exit 0
fi

if ! docker build . -t "${IMAGE_NAME}"; then
    echo -e "${RED}Docker build failed. Exiting.${RESET}"
    exit 1
fi

if ! docker run -d \
    -v "$(pwd -W)":/home/rstudio/work \
    -v "${HOME}/.ssh":/home/rstudio/.ssh \
    -v "${HOME}/.gitconfig":/home/rstudio/.gitconfig \
    -e PASSWORD=611project \
    -p 8787:8787 \
    --name "${CONTAINER_NAME}" \
    "${IMAGE_NAME}"; then
    echo -e "${RED}Docker run failed. Exiting.${RESET}"
    exit 1
fi

echo ""
echo -e "${BOLD}Container started!${RESET} Open http://localhost:8787 in your browser."
echo ""

echo -e "Work directory mounted at: ${BLUE}$(pwd -W)${RESET}"
echo -e "Username: ${BLUE}rstudio${RESET}"
echo -e "Password: ${BLUE}611project${RESET}"