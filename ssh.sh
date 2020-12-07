#! /bin/bash
branch=$(git symbolic-ref --short -q HEAD)
echo "分支: ${branch}"
ssh root@34.92.66.218 'bash -s' < deploy.sh ${branch}
