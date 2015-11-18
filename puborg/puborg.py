#!/bin/python
# -*- coding:utf-8 -*-

import os
from os import path
import argparse


debug_mode = False
jekyll_tag_template = """---
layout: body
---

<div class="home">
  <h3>-TAG-</h3>
  {% for post in site.tags["-TAG-"] %}
  <header class="post-header">
    <a href="{{ post.url | prepend: site.baseurl }}">
      <span class="post-meta"> {{ post.date | date: "%Y-%m-%d" }} </span>
      {{ post.title }}
    </a>
  </header>
  {% endfor %}
</div>
"""


def epath(p):
    return path.normpath(path.expanduser(p))


def jpath(dname, bname):
    return path.normpath(path.join(epath(dname), bname))


def rpath(p):
    return path.normpath(path.join(os.getcwd(), p))


def send_cmd(cmd):
    if debug_mode:
        print cmd
    os.system(cmd)


def file_type(fname, sufix):
    """@sufix:          should include dot.
    """
    return fname[-len(sufix):] == sufix


def file_retype(fname, sufix):
    """@sufix:          should include dot.
    """
    n, s = fname.rsplit(".")
    return n + sufix


def file_nodate(fname):
    """description:     remove date string in filename
    """
    namelist = fname.split("-", 3)
    if len(namelist) > 3:
        return namelist[3]
    return fname


def file_insert(fname, line, lino=0):
    """description:     insert line(s) to @lino line.
    """
    if not line:
        return

    with open(fname, "r+") as fd:
        lines = fd.readlines()
        if (lino < 0):                  # insert to end
            lines.append(line)
        else:
            lines.insert(lino, line)
        fd.seek(0)
        for line in lines:
            fd.write(line)
        fd.truncate()


def file_replace(fname, old, new):
    """description:     replace @old to @new for each line.
    """
    with open(fname, "r+") as fd:
        lines = fd.readlines()
        fd.seek(0)
        for line in lines:
            fd.write(line.replace(old, new))
        fd.truncate()


def line_fix_per25(line):
    """description: fix org-mode bug, escape % for html link.
    """
    if '%25' in line and 'href="' in line:
        print "WARNING: ", line[:80]
        line = line.replace("%25", "%")
        print "changed: ", line[:80]
    return line


def file_fix_per25(fname):
    """description:     fix org-mode bug, escape % for html link.
    """
    with open(fname, "r+") as fd:
        lines = fd.readlines()
        fd.seek(0)
        for line in lines:
            line = line_fix_per25(line)
            fd.write(line)
        fd.truncate()


def file_fixup(fname, head, tail, replist, fix_per25=False):
    """description:     fix files
    """
    file_insert(fname, head)
    file_insert(fname, tail, -1)

    if fix_per25:
        file_fix_per25(fname)

    for old, new in replist:
        file_replace(fname, old, new)


def page_header(fname, categ):
    """description:         extract page header from org file.
    """
    replist = [
        ["#+TITLE:", "title:"],
        ["#+PAGE_CATEGORIES:", "categories:"],
        ["#+PAGE_TAGS:", "tags:"],
        ["#+PAGE_LAYOUT:", "layout:"],
    ]
    hline = "---\n"
    with open(fname, "r") as fd:
        for line in fd:
            line = line.strip()
            if line and line[0] != "#":
                break               # reach context
            for old, new in replist:
                if old in line:
                    hline += line.replace(old, new) + "\n"
    if "categories:" not in hline and categ[:1] != ".":
        hline += "categories: {}\n".format(categ)
    hline += "---\n"
    return hline


def page_tags(fname, tags):
    """description          extract tags from org file.
    """
    with open(fname, "r") as fd:
        for line in fd:
            line = line.strip()
            if tags in line:
                return line.replace(tags, "").strip()
    return ""


class puborg(object):
    def __init__(self):
        self.puborg_el = epath("/etc/puborg/puborg.el")
        self.timestamp_dir = epath("~/.org-timestamps")

        self.cmd_list = []
        self.dir_list = []
        self.ddir_sub = True
        self.ddir_posts = ""
        self.slide_org = "slide.org"
        self.slide_site = "/slide/"

        self.temp_html = ".html"
        self.temp_latex = ".latex"

        self.path_jekyll = rpath("build/jekyll")
        self.path_jekyll_menu = rpath("build/jekyll/menu")
        self.path_reveal = rpath("build/reveal")
        self.path_latex = rpath("build/latex")

    def set_output(self, output):
        if output:
            output = rpath(output)
            self.path_jekyll = output
            self.path_reveal = output
            self.path_latex = output

    def set_sub(self, sub):
        self.ddir_sub = sub

    def set_posts(self, posts):
        self.ddir_posts = posts

    def add_cmd(self, cmd, cond):
        if cond:
            self.cmd_list.append(cmd)

    def add_dir(self, dname):
        self.dir_list.append(dname)

    def show_config(self):
        print 80 * "-"
        print "path_jekyll:\t", self.path_jekyll
        print "path_reveal:\t", self.path_reveal
        print "path_latex:\t", self.path_latex
        print "publish sub-directory:\t", self.ddir_sub
        print "publish command:\t", self.cmd_list
        print "publish directories:\t", self.dir_list
        print 80 * "-"

    def cleanup_dir(self, dname):
        files = ".html .latex *.html *.pdf *.tex *.tex~ *.html~ *.pyg *.cache "
        files += "*.vrb *.nav *.snm *.out *.log *.toc *.aux _minted-*"
        for fname in files.split():
            send_cmd("rm -rf {}/{}".format(rpath(dname), fname))

    def cleanup_all(self):
        send_cmd("rm -rf {}".format(self.timestamp_dir))
        for dname in self.dir_list:
            self.cleanup_dir(dname)

    def pub_jekyll_tags(self, dtags, tags):
        for tag in tags:
            tname = jpath(dtags, tag + ".html")
            with open(tname, "w+") as f:
                f.write(jekyll_tag_template.replace("-TAG-", tag))

    def pub_jekyll(self, dname):
        posts = self.path_jekyll
        resource = self.path_jekyll
        dtags = ""
        if self.ddir_posts:
            posts = path.join(posts, "_posts")
            resource = path.join(resource, "resource")
            dtags = jpath(resource, "tags")
            send_cmd("mkdir -p {}".format(dtags))
        if self.ddir_sub:
            posts = path.join(posts, dname)
            resource = path.join(resource, dname)

        send_cmd("mkdir -p {} {}".format(posts, resource))
        if os.path.exists("fig"):
            send_cmd("cp -a fig {}".format(resource))
        if os.path.exists("src"):
            send_cmd("cp -a src {}".format(resource))

        temp = rpath(self.temp_html)
        for fname in os.listdir(temp):
            if not file_type(fname, ".html"):
                continue
            forg = file_retype(fname, ".org")
            html = path.join(temp, fname)
            head = page_header(forg, dname)
            tags = page_tags(forg, "#+PAGE_TAGS:")
            replist = [
                ['src="fig/', 'src="/resource/{}/fig/'.format(dname)],
                ['href="src/', 'href="/resource/{}/src/'.format(dname)],
                ['href="file:///', 'href="/'],
                [' <code>', '<code>'],
                ['</code> ', '</code>']
            ]
            file_fixup(html, head, "", replist, True)
            if dtags:
                self.pub_jekyll_tags(dtags, tags.split())
            send_cmd("mv {} {}".format(html, posts))

    def pub_reveal_menu(self):
        hlines = """#+TITLE: 演示文档列表
#+OPTIONS: H:4 ^:nil toc:nil
#+LATEX_CLASS: latex-doc
#+PAGE_LAYOUT: body

* 演示文档列表
"""
        root = self.path_reveal
        menu = self.path_jekyll_menu

        with open(self.slide_org, "w") as fd:
            fd.write(hlines + "\n")

            for dname in self.dir_list:
                dname = path.normpath(dname)
                pub_dname = path.join(root, dname)
                files = []
                for fname in os.listdir(pub_dname):
                    if file_type(fname, ".html"):
                        files.append(fname)
                files.sort(reverse=True)
                fd.write("** {} ({})\n".format(dname, len(files)))
                for fname in files:
                    forg = jpath(dname, file_retype(fname, ".slide"))
                    title = page_tags(forg, "#+TITLE:")
                    url = self.slide_site + "{}/{}".format(dname, fname)
                    fd.write("- [[{}][{}]]\n".format(url, title))

    def pub_reveal(self, dname):
        html = self.path_reveal
        if self.ddir_sub:
            html = path.join(html, dname)

        send_cmd("mkdir -p {}".format(html))
        if os.path.exists("fig"):
            send_cmd("cp -a fig {}".format(html))
        if os.path.exists("src"):
            send_cmd("cp -a src {}".format(html))

        temp = rpath(self.temp_html)
        for fname in os.listdir(temp):
            filename = path.join(temp, fname)
            if not file_type(filename, ".html"):
                continue
            dstname = path.join(html, fname)
            send_cmd("mv {} {}".format(filename, dstname))

    def pub_pdf(self, dname, slide=False):
        ddst = self.path_latex
        ddst = path.join(ddst, dname)

        temp = rpath(self.temp_latex)
        send_cmd("mkdir -p {}".format(temp))
        for fname in os.listdir(temp):
            fname = path.join(temp, fname)
            if not file_type(fname, ".pdf"):
                continue

            send_cmd("mkdir -p {}".format(ddst))
            send_cmd("mv {} {}".format(fname, ddst))

    def publish_dir(self, dname, cmd):
        dname = path.normpath(dname)
        cwd = os.getcwd()
        emacs = "emacs -batch -l {} -f ".format(self.puborg_el)

        os.chdir(dname)

        basename = path.basename(dname)
        if not basename:
            basename = dname

        send_cmd(emacs + cmd)

        if cmd == "publish-jekyll":
            self.pub_jekyll(basename)
        if cmd == "publish-reveal":
            self.pub_reveal(basename)
        if cmd == "publish-latex":
            self.pub_pdf(basename)
        if cmd == "publish-slide":
            self.pub_pdf(basename, True)

        os.chdir(cwd)

    def publish(self):
        for dname in self.dir_list:
            for cmd in self.cmd_list:
                self.publish_dir(dname, cmd)
        if "publish-reveal" in self.cmd_list:
            self.pub_reveal_menu()


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("dirs", nargs="*",
                        help="publish directories list")
    parser.add_argument("-n", "--nosub", action="store_true",
                        help="publish with no sub-directory")
    parser.add_argument("-o", "--output",
                        help="publish target directory")
    parser.add_argument("-j", "--jekyll", action="store_true",
                        help="publish jekyll pages")
    parser.add_argument("-p", "--posts", action="store_true",
                        help="publish jekyll posts")
    parser.add_argument("-r", "--reveal", action="store_true",
                        help="publish reveal slide")
    parser.add_argument("-l", "--latex", action="store_true",
                        help="publish latex pdf document")
    parser.add_argument("-c", "--clean", action="store_true",
                        help="cleanup directories and cache")
    parser.add_argument("-P", "--port",
                        help="start HTTP service with specified port")
    parser.add_argument("-S", "--serve", action="store_true",
                        help="start jekyll service on 4001 port")

    return parser.parse_args()

if __name__ == "__main__":
    pa = parse_arguments()
    po = puborg()
    for dname in pa.dirs:
        po.add_dir(dname)
    po.set_output(pa.output)
    po.set_sub(not pa.nosub)

    po.set_posts(pa.posts)
    po.add_cmd("publish-jekyll", pa.jekyll or pa.posts)
    po.add_cmd("publish-reveal", pa.reveal)
    po.add_cmd("publish-latex", pa.latex)
    po.add_cmd("publish-slide", pa.latex)

    po.show_config()
    if pa.clean:
        po.cleanup_all()
    po.publish()

    if pa.port:
        send_cmd("python -m SimpleHTTPServer {}".format(pa.port))
    elif pa.serve:
        send_cmd("jekyll serve")
