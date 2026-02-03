#!/usr/bin/env fish

magick mogrify -resize 700 -format webp ./assets/**/*.{jpg,jpeg,png}
