# Purpose
Run Hugo in a container

# Requirement
Docker

# Usage
I wrote a Makefile for handling the life cycle of images and containers, the
syntax is as follows:

## Building the image
    $ make build

## Running the container
    $ make run

It will spin up a webserver, you can access it at http://localhost:1313  
By default the volume of your markdown source is located in
~/github/hugo-richardpct.github.io/source on your host, and the volume of
the static files building by Hugo is located in ~/github/richardpct.github.io,
you can override the both volumes by using the following variables:

    $ make VOL_SOURCE=~/source VOL_OUTPUT=~/output run

## Getting a shell access to the running container
    $ make shell

## Creating a new content file
    $ make new PAGE=post/my-first-post.md

## Building static pages from markdown files
    $ make static

## Stopping the container
    $ make stop

## Removing the image
    $ make clean
