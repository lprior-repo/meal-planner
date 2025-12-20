#!/bin/bash
# Web server launcher with library path setup

export LD_LIBRARY_PATH=/tmp/usr/lib:$LD_LIBRARY_PATH
exec gleam run -- web
