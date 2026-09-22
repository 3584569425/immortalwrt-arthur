#!/bin/bash
# Runs before feeds update.
set -e

echo "Using official ImmortalWrt feeds"
echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default
echo "Added nikki feed"
