#!/usr/bin/env bash

a2enmod rewrite
sudo apache2ctl start && sudo cron start &