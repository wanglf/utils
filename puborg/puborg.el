;;; puborg.el
;;; This file is used for publish org mode files, which can be used seperatedly,
;;; don't add it to emacs configure.

;;; global settings
(setq ad-redefinition-action 'accept)
(package-initialize)
(global-font-lock-mode t)               ; syntax highlight

;;; theme settings
(add-to-list 'load-path "/etc/puborg")
(require 'whitetheme)

;;; org mode settings
(require 'org)
(require 'ox-html)
(require 'ox-md)
(require 'ox-latex)
(require 'ox-beamer)
(require 'ox-reveal)

;;; ###autoload
(defun org-reveal-publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'reveal filename
                      (concat "." (or (plist-get plist :html-extension)
                                      org-html-extension "html"))
                      plist pub-dir))
(setq org-emphasis-alist
      `(("*" bold)
        ("/" italic)
        ;; disable underline, because python __del__ like string
        ;; ("_" underline)
        ("=" org-verbatim verbatim)
        ("~" org-code verbatim)))
(setq org-emphasis-regexp-components
      '(" \t('\"{，。、：；！" "- \t.,:!?;\")}\\，。、：；！" " \t\r\n," "." 1))
(org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

;; -------------------- Generic settings --------------------
(setq org-src-preserve-indentation t)   ; dnot change indentation

;; footnote settings
(setq org-footnote-re
      (concat "\\[\\(?:"
              ;; Match inline footnotes.
              (org-re "fn:\\([-_[:word:]]+\\)?:\\|")
              ;; Match other footnotes.
              ;; "\\(?:\\([0-9]+\\)\\]\\)\\|"
              (org-re "\\(fn:[-_[:word:]]+\\)")
              "\\)"))

(setq org-footnote-definition-re
      (org-re "^\\[\\(fn:[-_[:word:]]+\\)\\]"))

(setq ditaa-jar-path
      (expand-file-name "etools/ditaa.jar" user-emacs-directory))
(setq org-ditaa-jar-path
      (expand-file-name "etools/ditaa.jar" user-emacs-directory))
(setq plantuml-jar-path
      (expand-file-name "etools/plantuml.jar" user-emacs-directory))
(setq org-plantuml-jar-path
      (expand-file-name "etools/plantuml.jar" user-emacs-directory))

;; Fix line break space for chinese
(defadvice org-html-paragraph (before fsh-org-html-paragraph-advice
                                      (paragraph contents info) activate)
  "Join consecutive Chinese lines into a single long line without
unwanted space when exporting org-mode to html."
  (let ((fixed-contents)
        (orig-contents (ad-get-arg 1))
        (reg-han "[[:multibyte:]]"))
    (setq fixed-contents (replace-regexp-in-string
                          (concat "\\(" reg-han "\\) *\n *\\(" reg-han "\\)")
                          "\\1\\2" orig-contents))
    (ad-set-arg 1 fixed-contents)
    ))
;; -------------------- publish project settings --------------------
(defun publish-html nil
  (org-publish "pub-html"))

(defun publish-jekyll nil
  (interactive)
  (org-publish "pub-jekyll"))

(defun publish-reveal nil
  (org-publish "pub-reveal"))

(defun publish-latex nil
  (interactive)
  (org-publish "pub-latex"))

(defun publish-slide nil
  (interactive)
  (setq org-latex-minted-options
        '(("autogobble")
          ("frame" "lines")
          ("framerule" "1pt")
          ("fontsize" "\\scriptsize")))
  (org-publish "pub-slide"))

(setq org-publish-project-alist
      '(("pub-html"
         :base-directory "."
         :base-extension "org"
         :publishing-directory ".html"
         :html-head "<link rel=\"stylesheet\" href=\"../theme/default.css\" />
<script src=\"../theme/jquery-2.1.1.min.js\"></script>
<script src=\"../theme/default.js\"></script>
"
         :publishing-function org-html-publish-to-html)

        ("pub-jekyll"
         :base-directory "."
         :base-extension "org"
         :publishing-directory ".html"
         :publishing-function org-html-publish-to-html
         :section-numbers nil
         :body-only t)

        ("pub-reveal"
         :base-directory "."
         :base-extension "slide"
         :publishing-directory ".html"
         :publishing-function org-reveal-publish-to-html
         :section-numbers nil)

        ("pub-latex"
         :base-directory "."
         :base-extension "org"
         :publishing-directory ".latex"
         :publishing-function org-latex-publish-to-pdf)

        ("pub-slide"
         :base-directory "."
         :base-extension "slide"
         :publishing-directory ".latex"
         :publishing-function org-beamer-publish-to-pdf)
        ))

;; -------------------- HTML export settings --------------------
(setq org-confirm-babel-evaluate nil)   ; dont ask eval code
(setq org-html-preamble nil)            ; no preamble
(setq org-html-postamble nil)           ; no postamble
(setq org-html-head-include-default-style nil) ; no default css settings
(setq org-html-head-include-scripts nil) ; no default javascript settings
(setq org-html-metadata-timestamp-format "created by emacs org-mode")

(setq org-reveal-transition "fade")     ; using fade transition
(setq org-reveal-root "../reveal.js")   ; using absolute path
(setq org-reveal-theme "white")         ; using white theme

;;; -------------------- LaTeX export settings --------------------
(setq org-latex-with-hyperref nil)      ; no hypersetup
(setq org-latex-listings 'minted)       ; using minted for list
(setq org-latex-minted-options
      '(("autogobble")
        ("frame" "lines")
        ("framerule" "1pt")
        ("fontsize" "\\small")))
(setq org-beamer-theme nil)
(setq org-latex-pdf-process
      '("xelatex -shell-escape -8bit -interaction nonstopmode %f"
        "xelatex -shell-escape -8bit -interaction nonstopmode %f"))

(setq org-latex-default-packages-alist '())

(add-to-list
 'org-latex-classes
 '("latex-probook"
   "\\documentclass[a4paper,10.5pt]{book}
\[DEFAULT-PACKAGES]
\[PACKAGES]
\[EXTRA]
\\input{/etc/puborg/latex-en.tex}
\\input{/etc/puborg/latex-cn.tex}
\\input{/etc/puborg/latex-cn-bib.tex}
% -------------------- HEADER END --------------------
"
   ("\\part{%s}" . "\\part*{%s}")
   ("\\chapter{%s}" . "\\chapter*{%s}")
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list
 'org-latex-classes
 '("latex-probook-en"
   "\\documentclass[a4paper,10.5pt]{book}
\[DEFAULT-PACKAGES]
\[PACKAGES]
\[EXTRA]
\\input{/etc/puborg/latex-en.tex}
% -------------------- HEADER END --------------------
"
   ("\\part{%s}" . "\\part*{%s}")
   ("\\chapter{%s}" . "\\chapter*{%s}")
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list
 'org-latex-classes
 '("latex-book"
   "\\documentclass[a4paper,10.5pt]{book}
\[DEFAULT-PACKAGES]
\[PACKAGES]
\[EXTRA]
\\input{/etc/puborg/latex-en.tex}
\\input{/etc/puborg/latex-cn.tex}
\\input{/etc/puborg/latex-cn-bib.tex}
% -------------------- HEADER END --------------------
"
   ("\\chapter{%s}" . "\\chapter*{%s}")
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list
 'org-latex-classes
 '("latex-book-en"
   "\\documentclass[a4paper,10.5pt]{book}
\[DEFAULT-PACKAGES]
\[PACKAGES]
\[EXTRA]
\\input{/etc/puborg/latex-en.tex}
% -------------------- HEADER END --------------------
"
   ("\\chapter{%s}" . "\\chapter*{%s}")
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list
 'org-latex-classes
 '("latex-doc"
   "\\documentclass[a4paper,10.5pt]{article}
\[DEFAULT-PACKAGES]
\[PACKAGES]
\[EXTRA]
\\input{/etc/puborg/latex-en.tex}
\\input{/etc/puborg/latex-cn.tex}
\\input{/etc/puborg/latex-cn-ref.tex}
% -------------------- HEADER END --------------------
"
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list
 'org-latex-classes
 '("latex-doc-en"
   "\\documentclass[a4paper,10.5pt]{article}
\[DEFAULT-PACKAGES]
\[PACKAGES]
\[EXTRA]
\\input{/etc/puborg/latex-en.tex}
% -------------------- HEADER END --------------------
"
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list
 'org-latex-classes
 '("latex-slide"
   "\\documentclass[presentation]{beamer}
\[DEFAULT-PACKAGES]
\[PACKAGES]
\[EXTRA]
\\input{/etc/puborg/slide-en.tex}
% -------------------- HEADER END --------------------
"
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

