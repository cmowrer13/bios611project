docker build . -t bios611project

docker run -v ${PWD}:/home/rstudio/work -v ${HOME}/.ssh:/home/rstudio/.ssh -v ${HOME}/.gitconfig:/home/rstudio/.gitconfig -e PASSWORD=611project -p 8787:8787 rocker/verse