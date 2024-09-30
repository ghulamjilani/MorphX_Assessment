#!/bin/bash

die () {
  echo "Usage: `basename $0` [environment] - environment could be staging/qa/production"
}

if [ "$1" == "-h" ]; then
	die ""
  exit 0
fi

if [ $# -eq 0 ]; then
	die ""
  exit 0
fi

case "$1" in
"qa")  echo "Pulling logs from qa..."
		rsync -chavzP --stats qa-portal.unite.live:~/Portal/current/log/ ./remote_logs/qa
    echo "Done. See ./remote_logs/qa"
    exit 0
    ;;
"staging")  echo "Pulling logs from staging..."
		rsync -chavzP --stats staging-portal-b.immerss.com:~/Portal/current/log/ ./remote_logs/staging
    echo "Done. See ./remote_logs/staging"
    exit 0
    ;;
"production")  echo "Pulling logs from production servers"
		rsync -chavzP --stats imrubprd0.unite.live:~/Portal/current/log/ ./remote_logs/production/imrubprd0
    echo "Done. See ./remote_logs/imrubprd0"
		rsync -chavzP --stats imrubprd1.unite.live:~/Portal/current/log/ ./remote_logs/production/imrubprd1
    echo "Done. See ./remote_logs/imrubprd1"
    exit 0
    ;;
*) die ""
  exit 1
   ;;
esac
