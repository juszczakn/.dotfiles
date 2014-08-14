(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(blink-cursor-mode nil)
 '(c-basic-offset 4)
 '(c-default-style "linux" t)
 '(c-offsets-alist (quote ((inline-open . 0))))
 '(custom-enabled-themes (quote (wombat)))
 '(delete-selection-mode nil)
 '(global-linum-mode t)
 '(inhibit-startup-screen t)
 '(mark-even-if-inactive t)
 '(scroll-bar-mode nil)
 '(show-paren-mode t)
 '(tab-width 4)
 '(tool-bar-mode nil)
 '(transient-mark-mode 1))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Sans Mono" :foundry "unknown" :slant normal :weight normal :height 98 :width normal))))
 '(linum ((t (:inherit (shadow default) :foreground "medium slate blue")))))
(put 'downcase-region 'disabled nil)

(require 'package)
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

(defvar my-packages
  '(paredit
	smex clojure-mode emacs-eclim company git-gutter
	autopair highlight-current-line buffer-move magit
    json-reformat))

(dolist (p my-packages)
  (when (not (package-installed-p p))
	(package-install p)))

(add-to-list 'load-path "~/.emacs.d/manual-packages/rest-url-string")
(add-to-list 'load-path "~/.emacs.d/manual-packages/emacs-git-gutter-fringe")
(require 'rest-url-string)

(load (expand-file-name "~/quicklisp/slime-helper.el"))
;; Replace "sbcl" with the path to your implementation
(setf inferior-lisp-program "sbcl")

;; so killing at end of line doesn't cause this.
(defun kill-and-join-forward (&optional arg)
  (interactive "P")
  (if (and (eolp) (not (bolp)))
      (progn (forward-char 1)
             (just-one-space 0)
             (backward-char 1)
             (kill-line arg))
    (kill-line arg)))

;; auto indent code pasted into emacs
(dolist (command '(yank yank-pop))
  (eval `(defadvice ,command (after indent-region activate)
           (and (not current-prefix-arg)
                (member major-mode '(emacs-lisp-mode
                                     lisp-mode
                                     clojure-mode scheme-mode
                                     haskell-mode ruby-mode
                                     rspec-mode python-mode
                                     c-mode c++-mode
                                     objc-mode latex-mode
                                     plain-tex-mode))
                (let ((mark-even-if-inactive transient-mark-mode))
                  (indent-region (region-beginning) (region-end) nil))))))

;;Turn on paredit mode in clojure-mode
(require 'clojure-mode)
(defun turn-on-paredit () (paredit-mode 1))
(add-hook 'clojure-mode-hook 'turn-on-paredit)
(add-hook 'lisp-mode-hook 'turn-on-paredit)
(add-hook 'emacs-lisp-mode-hook 'turn-on-paredit)

;;Stop emacs from jumping around when scrolling
(setf scroll-step 1)
(setf scroll-conservatively 9001)

(global-linum-mode 1)

;;Open new files in current emacs instance
(server-start)

;;Title for frame
(setf frame-title-format "%b -- %f")

(menu-bar-mode -1)

;;IDO mode stuff

(ido-mode t)
(setf ido-enable-flex-matching t)

(add-hook 'ido-setup-hook
          (lambda ()
            (define-key ido-completion-map [tab] 'ido-complete)))

(require 'smex)
(smex-initialize)

(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
;; This is your old M-x.
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;;END IDO stuff


(global-set-key [f6] 'apropos)

(defun my-refresh-buffer ()
  (interactive)
  (revert-buffer t t))

(global-set-key [f5] 'my-refresh-buffer)

(global-set-key [f12] 'eval-buffer)

;;Eclipse-like C-backspace
(defun my-kill-back ()
  (interactive)
  (if (bolp)
      (backward-delete-char 1)
    (if (string-match "[^[:space:]]" (buffer-substring (point-at-bol) (point)))
        (backward-kill-word 1)
      (delete-region (point-at-bol) (point)))))

(global-set-key [C-backspace] 'my-kill-back)

;;c-x p to previous window
(global-set-key "\C-xp" #'(lambda () (interactive) (other-window -1)))

;; Make emacs indent like eclipse
(defun my-java-newline-indent ()
  (interactive)
  (let ((s (buffer-substring (point-at-bol) (point))))
    (cond
     ;; javadoc
     ((string-match "^\\s-*\\/\\*\\*" s)
      (insert "**/") (backward-char 3)
      (newline-and-indent) (forward-char 1)
      (newline-and-indent) (move-beginning-of-line nil)
      (backward-char 1) (insert " "))
     ;; javadoc
     ((string-match "^\\s-+\\*" s)
      (newline-and-indent) (insert " * "))
     ;; remove unneeded whitespace
     ((string-match "^\\s-+$" s)
      (move-beginning-of-line nil) (kill-line 0)
      (newline-and-indent))
     ;; default
     (t (newline-and-indent)))))

;;Eclim
(defun my-eclim-hook ()
  (local-set-key (kbd "C-c i") 'eclim-java-import-organize)
  (local-set-key (kbd "M-c") 'company-complete)
  (local-set-key (kbd "C-j") 'my-java-newline-indent)
  (local-set-key (kbd "C-c e") 'eclim-problems))
(add-hook 'eclim-mode-hook 'my-eclim-hook)

(defun my-rust-hook ()
  (local-set-key (kbd "C-j") 'my-java-newline-indent))
(add-hook 'rust-mode-hook 'my-rust-hook)

(require 'eclim)
(global-eclim-mode)
(require 'eclimd)

(require 'company)
(require 'company-emacs-eclim)
(company-emacs-eclim-setup)
;;(global-company-mode t)

(setf c-default-style
      '((java-mode . "linux")
        (awk-mode . "awk")
        (other . "linux")))

(when (window-system)
  (require 'git-gutter-fringe))
(global-git-gutter-mode +1)
(setq-default indicate-buffer-boundaries 'left)
(setq-default indicate-empty-lines +1)

(setf mouse-wheel-follow-mouse 't)
(setf mouse-wheel-scroll-amount '(1 ((shift) . 1)))

(require 'uniquify)
(setf uniquify-buffer-name-style 'forward)
(setf TeX-PDF-mode t)

(require 'autopair)
(autopair-global-mode)

(setq-default indent-tabs-mode nil)

(require 'highlight-current-line)
(highlight-current-line-on t)
(set-face-background 'highlight-current-line-face "black")

(defun show-file-path ()
  "Show the full path file name in the minibuffer."
  (interactive)
  (kill-new (buffer-file-name))
  (message (buffer-file-name)))
(defun show-file-name ()
  (interactive)
  (kill-new (buffer-name))
  (message (buffer-name)))

(require 'buffer-move)
(global-set-key (kbd "<C-s-up>") 'buf-move-up)
(global-set-key (kbd "<C-s-down>") 'buf-move-down)
(global-set-key (kbd "<C-s-left>") 'buf-move-left)
(global-set-key (kbd "<C-s-right>") 'buf-move-right)

(defun my-next-git-gutter-diff (arg)
  (interactive "p")
  (git-gutter:next-diff arg)
  (recenter))
(defun my-prev-git-gutter-diff (arg)
  (interactive "p")
  (git-gutter:previous-diff arg)
  (recenter))
(global-set-key (kbd "C-s-n") 'my-next-git-gutter-diff)
(global-set-key (kbd "C-s-p") 'my-prev-git-gutter-diff)

(global-set-key (kbd "C-c m") 'magit-status)

;; center screen after every C-s or C-r
(defadvice
  isearch-repeat-forward
  (after isearch-repeat-forward-recenter activate)
  (recenter))
(defadvice
  isearch-repeat-backward
  (after isearch-repeat-backward-recenter activate)
  (recenter))
(ad-activate 'isearch-repeat-forward)
(ad-activate 'isearch-repeat-backward)

(defalias 'ff 'find-file)
(defalias 'ffw 'find-file-other-window)
(defalias 'rus-extract 'rest-string-url-extract-decode-print)
(defalias 'rus-reencode 'rest-string-url-reencode-print)
(defalias 'rus-http-get 'rest-string-url-http-get-print)

(setf eclim-executable "~/bin/eclipse/plugins/org.eclim_2.3.4/bin/eclim")

(defun my-nrepl-doc (arg)
  (interactive)
  (nrepl-doc arg)
  (other-window -1))

(defun my-nrepl-hook ()
  (local-set-key (kbd "C-c C-d") 'my-nrepl-doc))
(add-hook 'nrepl-interaction-mode-hook 'my-nrepl-hook)
