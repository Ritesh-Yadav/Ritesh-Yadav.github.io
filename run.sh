#!/bin/bash
set -x
jekyll build
jekyll serve --incremental