#README#

A program used to pub emacs org-files as html files

clone from https://github.com/mickyching

#Prerequisite

1. emacs >= 24.0
2. emacs ox-reveal plugin
3. python >= 2.7

#Usage#

1. make install
2. cd dir_of_org_files
3. make posts
4. copy _config.yml index.html, themes etc to jekyll serve directory
5. cd jekyll_serve_directory
6. jekyll build && jekyll serve

#FAQ#

## 1. Error: Wrong type argument: listp ##
- From the command line:
  Run emacs without loading the init file: emacs -q
- In emacs:

  run C-u M-x org-reload

  Use package-list-packages to uninstall org: select it then d x

  Use package-list-packages to reinstall org: select it then i x

