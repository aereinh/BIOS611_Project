#! /bin/bash
docker build . -t bios611 -f Dockerfile
docker run --rm -p 8787:8787 -ti -e DISABLE_AUTH=true -v $(pwd):/home/rstudio/project -t bios611