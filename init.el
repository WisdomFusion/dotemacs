;;; -*- mode: emacs-Lisp; coding: utf-8 -*-
;; Copyright (C) 2010-2013 Gavin
;;
;; @auther: WisdomFusion <WisdomFusion[at]gmail[dot]com>
;; @date:   2013/07/24

(defconst *is-mac-p* (eq system-type 'darwin))
(defconst *is-win-p* (eq system-type 'windows-nt))

;;; bootstrap confign

(require 'cl)

;; load path
(let* ((my-lisp-dir "~/.emacs.d/")
       (default-directory my-lisp-dir))
  (setq load-path (cons my-lisp-dir load-path))
  (normal-top-level-add-subdirs-to-load-path))

;; load files
(load "wf-alias")
(load "wf-abbrev")

;; elpa
(when (> emacs-major-version 23)
  (require 'package)
  (setq package-archives
        '(("gnu"       . "http://elpa.gnu.org/packages/")
          ("marmalade" . "http://marmalade-repo.org/packages/")
          ("melpa"     . "http://melpa.milkbox.net/packages/")
          ("org"       . "http://orgmode.org/elpa/")))
  (package-initialize))

;;; basic & misc settings

(setq user-full-name    "WisdomFusion")
(setq user-mail-address "WisdomFusion@gmail.com")

(when window-system
  (setq frame-title-format '(buffer-file-name "%f" ("%b")))
  (tool-bar-mode -1)
  ;;(menu-bar-mode -1)
  (tooltip-mode -1)
  ;;(set-scroll-bar-mode 'left)
  (mouse-wheel-mode t)
  (blink-cursor-mode -1))

;; clean mode line
(defvar mode-line-cleaner-alist
  `((abbrev-mode . "")
    (undo-tree-mode . "")
    (paredit-mode . " Par")
    ;; Major modes
    (lisp-interaction-mode . "λ")
    (cperl-mode . "pl")
    (python-mode . "py")
    (ruby-mode . "rb")
    (emacs-lisp-mode . "EL")
    (js2-mode . "js2")))
(defun clean-mode-line ()
  (interactive)
  (loop for cleaner in mode-line-cleaner-alist
        do (let* ((mode (car cleaner))
                 (mode-str (cdr cleaner))
                 (old-mode-str (cdr (assq mode minor-mode-alist))))
             (when old-mode-str
                 (setcar old-mode-str mode-str))
               ;; major mode
             (when (eq mode major-mode)
               (setq mode-name mode-str)))))
(add-hook 'after-change-major-mode-hook 'clean-mode-line)

;; unicad -  Universal Charset Auto Detector
;; http://www.emacswiki.org/emacs/Unicad
(require 'unicad)

;; enforce utf-8 as the default coding system
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-language-environment 'utf-8)
;; backwards compatibility as default-buffer-file-coding-system
;; is deprecated in 23.2.
(if (boundp 'buffer-file-coding-system)
    (setq-default buffer-file-coding-system 'utf-8)
  (setq default-buffer-file-coding-system 'utf-8))
;; Treat clipboard input as UTF-8 string first; compound text next, etc.
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))
;; 时间戳中文变英文，包括 mode-line
(setq system-time-locale "C")

(when window-system
  ;; Setting English Font
  (if *is-mac-p*
      (set-face-attribute 'default nil :font "Monaco 14"))
  (if *is-win-p*
      (set-face-attribute 'default nil :font "Monaco 10"))
  ;; Chinese Font
  (dolist (charset '(kana han symbol cjk-misc bopomofo))
    (set-fontset-font (frame-parameter nil 'font)
                      charset
                      (font-spec :family "Microsoft YaHei" :size 14))))

;; 如果想让 org-mode 下表格中英文对齐，使用这个配置
;; 缺点是英文偏小
;; (defun wf-set-font (english chinese english-size chinese-size)
;;   (set-face-attribute 'default nil :font
;;       (format "%s:pixelsize=%d" english english-size))
;;   (dolist (charset '(kana han symbol cjk-misc bopomofo))
;;     (set-fontset-font (frame-parameter nil 'font) charset
;;       (font-spec :family chinese :size chinese-size))))
;; (wf-set-font "Monaco" "Microsoft Yahei" 14 16)

;; disable bold or underline globally
;; (set-face-attribute face nil :weight 'normal :underline nil)
(mapc
 (lambda (face)
   (set-face-attribute face nil :weight 'normal :underline nil))
 (face-list))

;; follow-mode allows easier editing of long files
(follow-mode t)

;; color-theme
;;(load-theme 'deeper-blue)

;;; tabbar
(when (require 'tabbar nil 'noerror)
  (tabbar-mode t)
  (setq tabbar-home-button-enabled-image-orig tabbar-home-button-enabled-image
        tabbar-home-button-disabled-image-orig tabbar-home-button-disabled-image
        tabbar-scroll-left-button-enabled-image-orig tabbar-scroll-left-button-enabled-image
        tabbar-scroll-right-button-enabled-image-orig tabbar-scroll-right-button-enabled-image)
  (define-key tabbar-mode-map [C-prior] 'tabbar-backward)
  (define-key tabbar-mode-map [C-next] 'tabbar-forward)
  (defadvice tabbar-buffer-tab-label (after modified-flag activate)
    (setq ad-return-value
          (if (and (or (not (featurep 'tabbar-ruler))
                       (not window-system))
                   (buffer-modified-p (tabbar-tab-value tab)))
                   ;; (buffer-file-name (tabbar-tab-value tab))
              (concat ad-return-value "*")
            ad-return-value)))
  (defun update-tabbar-modified-state ()
    (tabbar-set-template tabbar-current-tabset nil)
    (tabbar-display-update))
  (defadvice undo (after update-tabbar-tab-label activate)
    (update-tabbar-modified-state))
  (add-hook 'first-change-hook 'update-tabbar-modified-state)
  (add-hook 'after-save-hook 'update-tabbar-modified-state))

(setq tabbar-ruler-invert-deselected nil)
(eval-after-load "tabbar"
  '(when (require 'tabbar-ruler nil 'noerror)
     ;; restore original button image
     (setq tabbar-home-button-enabled-image tabbar-home-button-enabled-image-orig
           tabbar-home-button-disabled-image tabbar-home-button-disabled-image-orig
           tabbar-scroll-left-button-enabled-image tabbar-scroll-left-button-enabled-image-orig
           tabbar-scroll-right-button-enabled-image tabbar-scroll-right-button-enabled-image-orig)
     (setq tabbar-home-button
           (cons (cons "[o]" tabbar-home-button-enabled-image)
                 (cons "[x]" tabbar-home-button-disabled-image)))
     (setq tabbar-buffer-home-button
           (cons (cons "[+]" tabbar-home-button-enabled-image)
                 (cons "[-]" tabbar-home-button-disabled-image)))
     (setq tabbar-scroll-left-button
           (cons (cons " <" tabbar-scroll-left-button-enabled-image)
                 (cons " =" nil)))
     (setq tabbar-scroll-right-button
           (cons (cons " >" tabbar-scroll-right-button-enabled-image)
                 (cons " =" nil)))
     (defadvice tabbar-popup-menu (after add-menu-item activate)
       "Add customize menu item to tabbar popup menu."
       (setq ad-return-value
             (append ad-return-value
                     '("--"
                       ["Copy Buffer Name" (kill-new
                                            (buffer-name
                                             (tabbar-tab-value
                                              tabbar-last-tab)))]
                       ["Copy File Path" (kill-new
                                          (buffer-file-name
                                           (tabbar-tab-value
                                            tabbar-last-tab)))
                        :active (buffer-file-name
                                 (tabbar-tab-value tabbar-last-tab))]
                       ["Open Dired" dired-jump
                        :active (fboundp 'dired-jump)]
                       ;; ["Open Dired" (dired
                       ;;                (let ((file (buffer-file-name
                       ;;                             (tabbar-tab-value
                       ;;                              tabbar-last-tab))))
                       ;;                  (if file
                       ;;                      (file-name-directory file)
                       ;;                    default-directory)))
                       ;;  :active (buffer-file-name
                       ;;           (tabbar-tab-value tabbar-last-tab))]
                       "--"
                       ["Undo Close Tab" undo-kill-buffer
                        :active (fboundp 'undo-kill-buffer)]))))
     (defadvice tabbar-line-tab (around window-or-terminal activate)
       "Fix tabbar-ruler in window-system and terminal"
       (if window-system
           ad-do-it
         (setq ad-return-value
               (let ((tab (ad-get-arg 0))
                     (tabbar-separator-value "|"))
                 (concat (propertize
                          (if tabbar-tab-label-function
                              (funcall tabbar-tab-label-function tab)
                            tab)
                          'tabbar-tab tab
                          'local-map (tabbar-make-tab-keymap tab)
                          'help-echo 'tabbar-help-on-tab
                          'mouse-face 'tabbar-highlight
                          'face (if (tabbar-selected-p tab
                                                       (tabbar-current-tabset))
                                    'tabbar-selected
                                  'tabbar-unselected)
                          'pointer 'hand)
                         tabbar-separator-value)))))
     ;; (unless (eq system-type 'windows-nt)
     (set-face-attribute 'tabbar-default nil
                         :family (face-attribute 'default :family))
     (add-hook 'after-make-frame-functions
               (lambda (frame)
                 (with-selected-frame frame
                   (set-face-attribute 'tabbar-default frame
                                       :family (face-attribute 'default
                                                               :family)))));; )
     (set-face-attribute 'tabbar-selected nil
                         :foreground "blue")
     (setq tabbar-buffer-groups-function 'tabbar-buffer-groups)
     (setq tabbar-ruler-excluded-buffers '())))

;; quiet, please! No dinging!
(setq visible-bell t)
(setq ring-bell-function (lambda () t))

;; get rid of the default messages on startup
(setq initial-scratch-message nil)
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message t)

;; make the last line end in a carriage return
(setq require-final-newline t)
;; will disallow creation of new lines when you press the "arrow-down key"
;; at end of the buffer
(setq next-line-add-newlines t)

(setq x-select-enable-clipboard t) ;; use clipboard

;; display time on mode-line
(setq display-time-day-and-date t)
(setq display-time-format "%m/%d %H:%M")          ;; 11/10 15:26
;; (setq display-time-format "%a %d %b %I:%M %p") ;; Fri 10 Nov 3:26 PM
;; (setq display-time-format "%a %d %b %H:%M")    ;; Fri 10 Nov 15:26
(display-time)

(setq column-number-mode t)        ;; display column number
(global-hl-line-mode t)            ;; highlight current line

;; kill-ring and other settings
(setq kill-ring-max 1024)
(setq max-lisp-eval-depth 40000)
(setq max-specpdl-size 10000)
(setq undo-outer-limit 5000000)
(setq message-log-max t)
(setq eval-expression-print-length nil)
(setq eval-expression-print-level nil)
(setq global-mark-ring-max 1024)
(setq history-delete-duplicates t)
(setq default-fill-column 78)           ;; set fill-column
(setq tab-always-indent t)
(setq-default indent-tabs-mode nil)     ;; use space instead of tab
(setq default-tab-width 4)

;; disable line wrap
(setq default-truncate-lines t)
;; make side by side buffers function the same as the main window
(setq truncate-partial-width-windows nil)
;; Add F12 to toggle line wrap
(global-set-key (kbd "<f12>") 'toggle-truncate-lines)

;; get rid of yes-or-no questions - y or n is enough
(fset 'yes-or-no-p 'y-or-n-p)
;; confirm on quitting emacs
(setq confirm-kill-emacs 'yes-or-no-p)

;; sentence-end
(setq sentence-end
      "\\([。！？]\\|……\\|[.?!][]\"')}]*\\($\\|[ \t]\\)\\)[ \t\n]*")
(setq sentence-end-double-space nil)

;; recursive minibuffers
(setq enable-recursive-minibuffers t)

(setq scroll-step 1
      scroll-conservatively 10000)

;; text-mode default
(setq default-major-mode 'text-mode)

;; show matched parentheses
(show-paren-mode t)
;; highlight just brackets
(setq show-paren-style 'parenthesis)
;; highlight entire bracket expression
;; (setq show-paren-style 'expression)
;; typing any left bracket automatically insert the right matching bracket
;; new feature in Emacs 24
(electric-pair-mode t)
;; setting for auto-close brackets for electric-pair-mode
;; regardless of current major mode syntax table
(setq electric-pair-pairs '(
                            (?\" . ?\")
                            (?\{ . ?\})
                            ))

;; mouse avoidance
;; banish, exile, jump, animate,
;; cat-and-mouse, proteus
(mouse-avoidance-mode 'animate)
(auto-image-file-mode)
(global-font-lock-mode t)               ;; syntax
(transient-mark-mode t)                 ;; highlight mark area
(setq shift-select-mode t)              ;; hold shift to mark area
(delete-selection-mode 1)               ;; overwrite selection

;; enable some figures
(put 'set-goal-column 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; frame demostration
(defun set-frame-size-according-to-resolution ()
  (interactive)
  (when window-system
    (if (> (x-display-pixel-width) 1280)
        (add-to-list 'default-frame-alist (cons 'width 100))
      (add-to-list 'default-frame-alist (cons 'width 80)))
    (add-to-list 'default-frame-alist (cons 'height 35))))
(set-frame-size-according-to-resolution)
;; frame postition
(setq initial-frame-alist '((top . 30) (left . 100)))

;; when in Mac OS X, alt is alt, command is meta
;; however, qq and some apps use command key frequently
;; drop it...
;; (when (string-equal system-type 'darwin)
;;   (setq mac-option-key-is-meta nil)
;;   (setq mac-command-key-is-meta t)
;;   (setq mac-command-modifier 'meta)
;;   (setq mac-option-modifier nil))

;; Maximize emacs frames vertically or horizontally
(when window-system
  (require 'maximize)
  (global-set-key [f9]  'maximize-toggle-frame-vmax)
  (global-set-key [f11] 'maximize-toggle-frame-hmax))

;; ibuffer
(when (require 'ibuffer nil 'noerror)
  (global-set-key (kbd "C-x C-b") 'ibuffer)
  (setq ibuffer-saved-filter-groups
        (quote (("default"
                 ("dired" (mode . dired-mode))
                 ("perl"  (mode . cperl-mode))
                 ("erc"   (mode . erc-mode))
                 ("planner"
                  (or
                   (name . "^\\*Calendar\\*$")
                   (name . "^diary$")
                   (mode . muse-mode)))
                 ("emacs"
                  (or
                   (name . "^\\*scratch\\*$")
                   (name . "^\\*Messages\\*$")))
                 ("gnus"
                  (or
                   (mode . message-mode)
                   (mode . bbdb-mode)
                   (mode . mail-mode)
                   (mode . gnus-group-mode)
                   (mode . gnus-summary-mode)
                   (mode . gnus-article-mode)
                   (name . "^\\.bbdb$")
                   (name . "^\\.newsrc-dribble"))))))))
(add-hook 'ibuffer-mode-hook
          (lambda ()
            (ibuffer-switch-to-saved-filter-groups "default")))

;; ido-mode is like magic pixie dust!
(ido-mode t)
(require 'ido-ubiquitous) ;; Does what you expected ido-everywhere to do
(setq ido-enable-prefix nil
      ido-enable-flex-matching t
      ido-auto-merge-work-directories-length nil
      ido-create-new-buffer 'always
      ido-use-filename-at-point 'guess
      ido-use-virtual-buffers t
      ido-handle-duplicate-virtual-buffers 2
      ido-max-prospects 10
      ido-save-directory-list-file "~/.emacs.d/ido.last")

;; smex
(when (require 'smex nil 'noerror)
     (setq smex-save-file (concat user-emacs-directory ".smex-items"))
     (smex-initialize)
     (global-set-key (kbd "M-x") 'smex))

;; recent files
(when (require 'recentf nil 'noerror)
  (recentf-mode 1)
  (setq recentf-max-saved-items 500)
  (setq recentf-max-menu-items 60)
  (setq recentf-save-file "~/.emacs.d/recentf"))

;; undo-tree
(when (require 'undo-tree nil 'noerror)
     (global-undo-tree-mode 1)
     (defalias 'redo 'undo-tree-redo)
     (global-set-key (kbd "C-z") 'undo)
     (global-set-key (kbd "C-S-z") 'redo))

;; save cursor place
(when (require 'saveplace nil 'noerror)
  (setq-default save-place t)
  (setq save-place-file "~/.emacs.d/saved-places"))

;; re-builder
(require 're-builder)
(setq reb-re-syntax 'string)

(defun reb-query-replace (to-string)
  "Replace current RE from point with `query-replace-regexp'."
  (interactive
   (progn (barf-if-buffer-read-only)
          (list (query-replace-read-to (reb-target-binding reb-regexp)
                                       "Query replace"  t))))
  (with-current-buffer reb-target-buffer
    (query-replace-regexp (reb-target-binding reb-regexp) to-string)))
(defun reb-beginning-of-buffer ()
  "In re-builder, move target buffer point position back to beginning."
  (interactive)
  (set-window-point (get-buffer-window reb-target-buffer)
                    (with-current-buffer reb-target-buffer (point-min))))
(defun reb-end-of-buffer ()
  "In re-builder, move target buffer point position back to beginning."
  (interactive)
  (set-window-point (get-buffer-window reb-target-buffer)
                    (with-current-buffer reb-target-buffer (point-max))))
;; end of re-builder

;; ace-jump-mode
(autoload 'ace-jump-mode "ace-jump-mode" nil t)
(define-key global-map (kbd "C-c SPC") 'ace-jump-mode)
(eval-after-load "ace-jump-mode"
  '(set-face-background 'ace-jump-face-foreground "yellow"))
(eval-after-load "viper-keym"
  '(define-key viper-vi-global-user-map (kbd "SPC") 'ace-jump-mode))

;; to prevent error like:
;; "help-setup-xref: Symbol's value as variable is void: help-xref-following"
(require 'help-mode)

(require 'fuzzy)

(require 'htmlize)

(require 'uniquify)
(setq uniquify-buffer-name-style 'reverse)

(require 'bs)
(global-set-key (kbd "C-x C-b") 'bs-show)

;; iswitchb
(iswitchb-mode 1)
(setq iswitchb-buffer-ignore '("^ " "*Buffer"))

;; same window switch
(setq iswitchb-default-method 'samewindow)

(setq make-backup-files nil)  ;; stop creating those backup~ files
(setq auto-save-default nil)  ;; stop creating those #auto-save# files
(setq backup-by-copying t)
(setq dired-recursive-deletes 'always)
(setq dired-recursive-copies  'top)
;; delete to trach
(setq delete-by-moving-to-trash t)

(eval-after-load "diff-mode"
  '(progn
     (set-face-foreground 'diff-added "green4")
     (set-face-foreground 'diff-removed "red3")))

(eval-after-load "magit"
  '(progn
     (set-face-foreground 'magit-diff-add "green4")
     (set-face-foreground 'magit-diff-del "red3")))

;; Get around the emacswiki spam protection
(eval-after-load "oddmuse"
  '(add-hook 'oddmuse-mode-hook
            (lambda ()
              (unless (string-match "question" oddmuse-post)
                (setq oddmuse-post (concat "uihnscuskc=1;" oddmuse-post))))))

;;; defuns - my defuns

(defun wf-local-comment-auto-fill ()
  (set (make-local-variable 'comment-auto-fill-only-comments) t)
  (auto-fill-mode t))

(defun wf-pretty-lambdas ()
  (font-lock-add-keywords
   nil `(("(?\\(lambda\\>\\)"
          (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                    ,(make-char 'greek-iso8859-7 107))
                    nil))))))

(add-hook 'prog-mode-hook 'wf-local-comment-auto-fill)
(add-hook 'prog-mode-hook 'wf-pretty-lambdas)
(add-hook 'prog-mode-hook 'idle-highlight-mode)

(defun wf-prog-mode-hook ()
  (run-hooks 'prog-mode-hook))

(defun wf-untabify-buffer ()
  (interactive)
  (untabify (point-min) (point-max)))

(defun wf-indent-buffer ()
  (interactive)
  (indent-region (point-min) (point-max)))

(defun wf-cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer."
  (interactive)
  (wf-indent-buffer)
  (wf-untabify-buffer)
  (delete-trailing-whitespace))

(defun wf-eol-conversion (new-eol)
  "Specify new end-of-line conversion NEW-EOL for the buffer's file
   coding system. This marks the buffer as modified.
   specifying `unix', `dos', or `mac'."
  (interactive "SEnd-of-line conversion for visited file: \n")
  ;; Check for valid user input.
  (unless (or (string-equal new-eol "unix")
              (string-equal new-eol "dos")
              (string-equal new-eol "mac"))
    (error "Invalid EOL type, %s" new-eol))
  (if buffer-file-coding-system
      (let ((new-coding-system (coding-system-change-eol-conversion
                                buffer-file-coding-system new-eol)))
        (set-buffer-file-coding-system new-coding-system))
    (let ((new-coding-system (coding-system-change-eol-conversion
                              'undecided new-eol)))
      (set-buffer-file-coding-system new-coding-system)))
  (message "EOL conversion now %s" new-eol))

;; alpha of frame
;;(when window-system
;;  (setq alpha-list '((95 75) (100 100)))
;;  (defun wf-toggle-alpha ()
;;    "Toggle alpha of frame"
;;    (interactive)
;;    (let ((h (car alpha-list)))
;;      ((lambda (a ab)
;;         (set-frame-parameter (selected-frame) 'alpha (list a ab))
;;         (add-to-list 'default-frame-alist (cons 'alpha (list a ab)))
;;         ) (car h) (car (cdr h)))
;;      (setq alpha-list (cdr (append alpha-list (list h))))))
;;  (wf-toggle-alpha))

;; Commands

(defun wf-eval-and-replace ()
  "Replace the preceding sexp with its value."
  (interactive)
  (backward-kill-sexp)
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
             (current-buffer))
    (error (message "Invalid expression")
           (insert (current-kill 0)))))

(defun wf-lorem ()
  "Insert a lorem ipsum."
  (interactive)
  (insert "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do "
          "eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim"
          "ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut "
          "aliquip ex ea commodo consequat. Duis aute irure dolor in "
          "reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla "
          "pariatur. Excepteur sint occaecat cupidatat non proident, sunt in "
          "culpa qui officia deserunt mollit anim id est laborum."))

(defun wf-insert-date ()
  "Insert a time-stamp according to locale's date and time format."
  (interactive)
  (insert (format-time-string "%c" (current-time))))

(defun wf-pairing-bot ()
  "If you can't pair program with a human, use this instead."
  (interactive)
  (message (if (y-or-n-p "Do you have a test for that? ") "Good." "Bad!")))

(defun wf-paredit-nonlisp ()
  "Turn on paredit mode for non-lisps."
  (interactive)
  (set (make-local-variable 'paredit-space-for-delimiter-predicates)
       '((lambda (endp delimiter) nil)))
  (paredit-mode 1))

(defun wf-align-repeat (start end regexp)
  "Repeat alignment with respect to the given regular expression."
  (interactive "r\nsAlign regexp: ")
  (align-regexp start end
                (concat "\\(\\s-*\\)" regexp) 1 1 t))

;; swap lines
;; just like org-metaup/org-metadown
(defun wf-swap-line-up ()
  "Swap the current line with the line above."
  (interactive)
  (transpose-lines 1)
  (beginning-of-line -1))
(defun wf-swap-line-down ()
  "Swap current line with the line below."
  (interactive)
  (beginning-of-line 2)
  (transpose-lines 1)
  (beginning-of-line 0))

;; http://www.emacswiki.org/emacs/WholeLineOrRegion#toc2
;; cut, copy, yank
(defadvice kill-ring-save (around slick-copy activate)
  "When called interactively with no active region, copy a single line instead."
  (if (or (use-region-p) (not (called-interactively-p)))
      ad-do-it
    (kill-new (buffer-substring (line-beginning-position)
                                (line-beginning-position 2))
              nil '(yank-line))
    (message "Copied line")))
(defadvice kill-region (around slick-copy activate)
  "When called interactively with no active region, kill a single line instead."
  (if (or (use-region-p) (not (called-interactively-p)))
      ad-do-it
    (kill-new (filter-buffer-substring (line-beginning-position)
                                       (line-beginning-position 2) t)
              nil '(yank-line))))
(defun yank-line (string)
  "Insert STRING above the current line."
  (beginning-of-line)
  (unless (= (elt string (1- (length string))) ?\n)
    (save-excursion (insert "\n")))
  (insert string))

;; registers - multiple clipboards
(defun copy-to-register-1 ()
  "Copy current line or text selection to register 1.
   See also: `paste-from-register-1', `copy-to-register'."
  (interactive)
  (let* (
         (bds (get-selection-or-unit 'line ))
         (inputStr (elt bds 0) )
         (p1 (elt bds 1) )
         (p2 (elt bds 2) )
         )
    (copy-to-register ?1 p1 p2)
    (message "copied to register 1: 「%s」." inputStr)
    ))

(defun paste-from-register-1 ()
  "Paste text from register 1.
   See also: `copy-to-register-1', `insert-register'."
  (interactive)
  (insert-register ?1))

;; Commands to Navigate Brackets
(defun forward-open-bracket ()
  "Move cursor to the next occurrence of left bracket or quotation mark."
  (interactive)
  (forward-char 1)
  (search-forward-regexp "(\\|{\\|\\[\\|<\\|〔\\|【\\|〖\\|〈\\|「\\|『\\|“\\|‘\\|‹\\|«")
  (backward-char 1))

(defun backward-open-bracket ()
  "Move cursor to the previous occurrence of left bracket or quotation mark.."
  (interactive)
  (search-backward-regexp "(\\|{\\|\\[\\|<\\|〔\\|【\\|〖\\|〈\\|「\\|『\\|“\\|‘\\|‹\\|«"))

(defun forward-close-bracket ()
  "Move cursor to the next occurrence of right bracket or quotation mark."
  (interactive)
  (search-forward-regexp ")\\|\\]\\|}\\|>\\|〕\\|】\\|〗\\|〉\\|」\\|』\\|”\\|’\\|›\\|»"))

(defun backward-close-bracket ()
  "Move cursor to the next occurrence of right bracket or quotation mark."
  (interactive)
  (backward-char 1)
  (search-backward-regexp ")\\|\\]\\|}\\|>\\|〕\\|】\\|〗\\|〉\\|」\\|』\\|”\\|’\\|›\\|»")
  (forward-char 1))

;;; IDE - developing settings

;; slime
;; CLISP
(if (string-equal system-type 'darwin)
  (progn
   (setq inferior-lisp-program "sbcl")
   (load (expand-file-name "~/quicklisp/slime-helper.el"))))
(if (string-equal system-type 'windows-nt)
  (progn
    (setq inferior-lisp-program "clisp.exe")
    (load "C:\\quicklisp\\slime-helper.el")))

;;; emacs-lisp-mode
;; now '-' is not considered a word-delimiter
(add-hook 'emacs-lisp-mode-hook
          '(lambda ()
             (modify-syntax-entry ?- "w")))

;;; paredit
;;; http://pub.gajendra.net/src/paredit-refcard.pdf
(autoload 'enable-paredit-mode "paredit" "Turn on pseudo-structural editing of Lisp code." t)
(add-hook 'emacs-lisp-mode-hook       #'enable-paredit-mode)
(add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
(add-hook 'ielm-mode-hook             #'enable-paredit-mode)
(add-hook 'lisp-mode-hook             #'enable-paredit-mode)
(add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
(add-hook 'scheme-mode-hook           #'enable-paredit-mode)

(add-hook 'slime-repl-mode-hook
          (lambda ()
            (paredit-mode +1)))
;; Stop SLIME's REPL from grabbing DEL,
;; which is annoying when backspacing over a '('
(defun override-slime-repl-bindings-with-paredit ()
  (define-key slime-repl-mode-map
      (read-kbd-macro paredit-backward-delete-key) nil))
(add-hook 'slime-repl-mode-hook 'override-slime-repl-bindings-with-paredit)

(defvar electrify-return-match
    "[\]}\)\"]"
    "If this regexp matches the text after the cursor, do an \"electric\"
  return.")
(defun electrify-return-if-match (arg)
  "If the text after the cursor matches `electrify-return-match' then
open and indent an empty line between the cursor and the text.  Move the
cursor to the new line."
  (interactive "P")
  (let ((case-fold-search nil))
    (if (looking-at electrify-return-match)
    (save-excursion (newline-and-indent)))
    (newline arg)
    (indent-according-to-mode)))
;; Using local-set-key in a mode-hook is a better idea.
(global-set-key (kbd "RET") 'electrify-return-if-match)

;;; auto-complete
;;; http://cx4a.org/software/auto-complete/
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/misc/ac-dict")
(ac-config-default)
;; Use dictionaries by default
(setq-default ac-sources (add-to-list 'ac-sources 'ac-source-dictionary))
(global-auto-complete-mode t)
;; Start auto-completion after 2 characters of a word
(setq ac-auto-start 2)
;; case sensitivity is important when finding matches
(setq ac-ignore-case nil)

;;; css-mode
(autoload 'css-mode "css-mode")
;; set the indentation style to the c-mode style
(setq cssm-indent-function 'cssm-c-style-indenter)
;; use this mode when loading .css files
(setq auto-mode-alist (cons '("\\.css\\'" . css-mode) auto-mode-alist))

;;; js2-mode --- Improved JavaScript editing mode
(autoload 'js2-mode "js2-mode")
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))

;;; php-mode
(require 'php-mode)
(autoload 'php-mode "php-mode" "Major mode for editing php code." t)
(add-to-list 'auto-mode-alist '("\\.php$" . php-mode))
(add-to-list 'auto-mode-alist '("\\.inc$" . php-mode))
(add-hook 'php-mode-hook (lambda ()
    (defun wf-php-lineup-arglist-intro (langelem)
      (save-excursion
        (goto-char (cdr langelem))
        (vector (+ (current-column) c-basic-offset))))
    (defun wf-php-lineup-arglist-close (langelem)
      (save-excursion
        (goto-char (cdr langelem))
        (vector (current-column))))
    (c-set-offset 'arglist-intro 'wf-php-lineup-arglist-intro)
    (c-set-offset 'arglist-close 'wf-php-lineup-arglist-close)))
(defun wf-php-mode-init ()
  "Set some buffer-local variables."
  ;;(setq tab-width 4)
  (setq c-basic-offset 4)
  (setq case-fold-search t)
  (setq indent-tabs-mode nil)
  (c-set-offset 'case-label '+)
  (c-set-offset 'arglist-intro '+)
  (c-set-offset 'arglist-cont 0)
  (c-set-offset 'arglist-close 0))
(add-hook 'php-mode-hook 'wf-php-mode-init)

;;; multi-web-mode, mweb
;;; Multi Web Mode is a minor mode which makes web editing in Emacs much easier.
;;; https://github.com/fgallina/multi-web-mode
(require 'multi-web-mode)
(setq mweb-default-major-mode 'html-mode)
(setq mweb-tags '((php-mode "<\\?php\\|<\\? \\|<\\?=" "\\?>")
                  (js-mode "<script[^>]*>" "</script>")
                  (css-mode "<style[^>]*>" "</style>")))
(setq mweb-filename-extensions '("php" "htm" "html" "php4" "php5"))
(multi-web-global-mode 1)
;; Multi Web Mode binds the following keystrokes:
;; M-<f11> : Prompts the user to override the default major mode.
;; M-<f12> : Prompts the user to override the calculated extra indentation.
;; Useful when the automatic calculation is not good enough.

;;; lua-mode
(autoload 'lua-mode "lua-mode" "Major mode for editing lua code." t)
(add-to-list 'auto-mode-alist '("\\.lua$" . lua-mode))
(add-to-list 'interpreter-mode-alist '("lua" . lua-mode))

;;; cperl-mode
;;; http://www.emacswiki.org/emacs/CPerlMode
(mapc (lambda (pair)
        (if (eq (cdr pair) 'perl-mode)
            (setcdr pair 'cperl-mode)))
      (append auto-mode-alist interpreter-mode-alist))
;; customizing cperl-mode
(defun wf-cperl-mode-init ()
  (setq cperl-font-lock t
        cperl-electric-keywords t
        ;; http://www.emacswiki.org/emacs/IndentingPerl
        cperl-indent-level 4
        cperl-indent-parens-as-block t
        cperl-close-paren-offset -4
        cperl-continued-brace-offset -4
        cperl-continued-statement-offset 4
        cperl-extra-newline-before-brace t
        cperl-brace-offset -4
        cperl-label-offset -2
        cperl-tab-always-indent nil
        cperl-extra-newline-before-brace nil
        cperl-extra-newline-before-brace-multiline nil)
  (local-set-key (kbd "C-h f") 'cperl-perldoc)
  (define-abbrev-table 'global-abbrev-table
    '(("pdbg"   "use Data::Dumper qw( Dumper );\nwarn Dumper[];" nil 1)
      ("phbp"   "#!/usr/bin/perl -w"                             nil 1)
      ("pusc"   "use Smart::Comments;\n\n### "                   nil 1)
      ("putm"   "use Test::More 'no_plan';"                      nil 1)))
  (custom-set-faces
   '(cperl-array-face ((t (:background nil :weight normal))))
   '(cperl-hash-face  ((t (:background nil :weight normal))))))
(add-hook 'cperl-mode-hook 'wf-cperl-mode-init)

;;; ruby-mode
(autoload 'ruby-mode "ruby-mode"
  "Mode for editing ruby source files" t)
(setq auto-mode-alist
      (append '(("\\.rb$" . ruby-mode)) auto-mode-alist))
(setq interpreter-mode-alist (append '(("ruby" . ruby-mode))
                                     interpreter-mode-alist))
;;; c and cpp
(add-hook 'c-mode-common-hook
          (lambda ()
            (turn-on-auto-fill)
            (setq comment-column 60)
            (modify-syntax-entry ?_ "w")     ; now '_' is not considered a word-delimiter
            (c-set-style "ellemtel")         ; set indentation style
            (local-set-key [(control tab)]   ; move to next tempo mark
                           'tempo-forward-mark)))
(setq auto-mode-alist
      (append '(("\\.h$" . c++-mode)) auto-mode-alist))

;;; key-bindings

;; resolve conflict with Windows IME
(when window-system
  (global-set-key (kbd "M-SPC") 'set-mark-command))

;; (global-set-key (kbd "<f2>") 'kill-region)
;; (global-set-key (kbd "<f3>") 'kill-ring-save)
;; (global-set-key (kbd "<f4>") 'yank)

;; (global-set-key (kbd "C-M-h") 'backward-kill-word)

;; C-k               kill-line
;; C-0 C-k           kill line backword
;; C-a, C-k, C-k     kill-whole-line in another way
;; kill-whole-line
(global-set-key (kbd "M-9") 'kill-whole-line)

(global-set-key (kbd "C-c q") 'join-line)

;; Completion that uses many different methods to find options.
(global-set-key (kbd "M-/") 'hippie-expand)

(global-set-key (kbd "C-c n") 'wf-cleanup-buffer)

(global-set-key (kbd "C-<f10>") 'menu-bar-mode)

;; Use regex searches by default.
;; (global-set-key (kbd "C-s")   'isearch-forward-regexp)
;; (global-set-key (kbd "C-r")   'isearch-backward-regexp)
;; (global-set-key (kbd "M-%")   'query-replace-regexp)
;; (global-set-key (kbd "C-M-s") 'isearch-forward)
;; (global-set-key (kbd "C-M-r") 'isearch-backward)
;; (global-set-key (kbd "C-M-%") 'query-replace)

;; recentf
(global-set-key (kbd "M-<f12>") 'recentf-open-files)

;; Jump to a definition in the current file. (Protip: this is awesome.)
(global-set-key (kbd "C-x C-i") 'imenu)

;; Make the sequence "C-c g" execute the 'goto-line' command,
;; which prompts for a line number to jump to.
(global-set-key (kbd "C-c C-g") 'goto-line)

;; Make the sequence "C-x w" execute the 'what-line' command,
;; which prints the current line number in the echo area.
(global-set-key (kbd "C-c C-w") 'what-line)

(global-set-key (kbd "C-c e")    'wf-eval-and-replace)
(global-set-key (kbd "<M-up>")   'wf-swap-line-up)
(global-set-key (kbd "<M-down>") 'wf-swap-line-down)

;; Activate occur easily inside isearch
(define-key isearch-mode-map (kbd "C-o")
  (lambda () (interactive)
    (let ((case-fold-search isearch-case-fold-search))
      (occur (if isearch-regexp isearch-string
               (regexp-quote isearch-string))))))

;;; org-mode

(require 'org)
(require 'remember)
(require 'org-mouse)

;; I want files with the extension ".org" to open in org-mode.
(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
(add-to-list 'auto-mode-alist '("\\.txt$" . org-mode))

;; Some basic keybindings.
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cr" 'org-remember)

;; a basic set of keywords to start out
(setq org-todo-keywords
      '((sequence "TODO(t)" "WAIT(w)" "STRT(s)" "|" "DONE(d)" "CANL(c)")))

;; I use org's tag feature to implement contexts.
(setq org-tag-alist '(("OFFICE"  . ?o)
                      ("HOME"    . ?h)
                      ("SERVER"  . ?s)
                      ("PROJECT" . ?p)))

;; I put the archive in a separate file, because the gtd file will
;; probably already get pretty big just with current tasks.
(setq org-archive-location "%s_archive::")

(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states)   ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

;; allow access from emacsclient
(require 'server)
(unless (server-running-p)
  (server-start))

;;; init.el ends here
