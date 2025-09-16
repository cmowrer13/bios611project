docker build . -t bios611project

docker run -d \
-v "$(pwd -W)":/home/rstudio/work \
-v ${HOME}/.ssh:/home/rstudio/.ssh \
-v ${HOME}/.gitconfig:/home/rstudio/.gitconfig \
-e PASSWORD=611project \
-p 8787:8787 \
--name bios611project_container \
bios611project 

echo "Container started! Open localhost:8787 in your browser."
echo "Username: rstudio"
echo "Password: 611project"