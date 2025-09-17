docker build . -t bios611project

docker run -d \
-v "$(pwd -W)":/home/rstudio/work \
-v ${HOME}/.ssh:/home/rstudio/.ssh \
-v ${HOME}/.gitconfig:/home/rstudio/.gitconfig \
-e PASSWORD=611project \
-p 8787:8787 \
--name bios611project_container \
bios611project 

BOLD="\033[1m"
RESET="\033[0m"
BLUE="\033[38;2;75;156;211m"

echo ""
echo -e "${BOLD}Container started!${RESET} Open localhost:8787 in your browser."
echo -e "Username: ${BLUE}rstudio${RESET}"
echo -e "Password: ${BLUE}611project${RESET}"