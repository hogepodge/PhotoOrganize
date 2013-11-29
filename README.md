# PhotoOrganize

This program is a somewhat brute force method for finding every photo on your hard drive
and organizing them according to date and type. It tries to introduce some smarts by
taking a hash of every photo and rejecting images with a hash collision. However, it
does nothing to check for content.

Many types are supported, but keep in mind this project is simplistic. You will likely want
to modify the progam to fit your particular needs.

## Usage

'''PhotoOrganize <source> <target>'''

'<source>' is the directory you want to start searching in. The software recursively descends to find every photo.
'<target>' is the directory you want to copy all of your files to. Make sure you have enough space. Depending upon
how large your archive is, this may take a long time to complete.

## Changelog

* Initial upload of PhotoOrganize.
