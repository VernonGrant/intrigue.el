;;; intrigue.el --- Pin important project files  -*- lexical-binding: t -*-

;; Copyright (C) 2023 by Vernon Grant.

;; Author: Vernon Grant <info@vernon-grant.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: project, pin, find, bookmark, package, intrigue
;; Homepage: https://github.com/VernonGrant/intrigue.el

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Intrigue gives you a way to pin important files on a per project basis.

;;; Code:

(require 'project)

;;;;;;;;;;;;;;;;;;;;
;; Customizations ;;
;;;;;;;;;;;;;;;;;;;;

(defgroup intrigue nil
    "Intrigue settings."
    :group 'settings
    :prefix "intrigue-package-")

(defcustom intrigue-package-enable-icons t
    "Should Intrique place icons in front of file names."
    :group 'intrique
    :type 'boolean)

(defcustom intrigue-package-file-location "~/.emacs-intrigue.el"
    "Your Intrique entries will be saved inside of this file."
    :group 'intrique
    :type 'file)

;;;;;;;;;;;;;;;;;;;;;;
;; Global Variables ;;
;;;;;;;;;;;;;;;;;;;;;;

(defvar intrigue--files nil)

(defun intrigue--get-project-key()
  "Get the current projects root path."
  (project-root (project-current nil)))

(defun intrigue--init()
  "Load the saved intrique data into memory."
  (message "initialized intrique!")
  (write-region "" nil intrigue-package-file-location t)
  (with-temp-buffer
    (insert-file-contents intrigue-package-file-location)
    (goto-char (point-min))
    (set 'intrigue--files (read (current-buffer)))))

(defun intrigue--save()
  "Write the current Intrigue state to disk."
  (when intrigue--files
    (with-temp-file intrigue-package-file-location
      (prin1 intrigue--files (current-buffer)))))

(defun intrigue-add()
  "Add the current file to the Intrique list."
  (interactive)
  (let* ((p-key (intrigue--get-project-key))
         (f-name (file-name-nondirectory (buffer-file-name)))
         (f-path (buffer-file-name))
         (p-list (assoc p-key intrigue--files)))
    (if p-list
        (let ((p-files (cdr p-list)))
          (when (not (assoc f-name p-files))
            (add-to-list 'p-files (cons f-name f-path))
            (setcdr p-list p-files)))
      (add-to-list 'intrigue--files (cons p-key (list (cons f-name f-path))))))
  (intrigue--save)
  (message "File added to intrigue"))

(defun intrigue--maybe-add-icons-to-files (file-alist)
  "Maybe choices with their related icon.
FILE-ALIST: The alist containing the Intrigue files."
  (if intrigue-package-enable-icons
      (let ((decorated-choices nil))
        (dolist (cell file-alist)
          (let ((icon (all-the-icons-icon-for-file (car cell)))
                (label (car cell)))
            ;; Add decorated entries.
            (setf (alist-get (concat icon " " label) decorated-choices) (cdr cell))))
        decorated-choices)
    file-alist))

(defun intrigue-remove (choice)
  "Remove a file entry associated to the current project.
CHOICE: hello world."
  (interactive
   (list (completing-read "Remove Intrigue Entry: "
                          (intrigue--maybe-add-icons-to-files
                           (cdr (assoc (intrigue--get-project-key) intrigue--files)))
                          nil t nil t)))
  (let* ((f-choice (if intrigue-package-enable-icons (substring choice 2) choice))
         (p-files (assoc (intrigue--get-project-key) intrigue--files)))
    (assoc-delete-all f-choice p-files))
  (intrigue--save)
  (message "File removed from intrigue"))

(defun intrigue-find (choice)
  "Find a file entry associated to the current project.
CHOICE: hello world."
  (interactive
   (list (completing-read "Intrigue Entries: "
                          (intrigue--maybe-add-icons-to-files
                           (cdr (assoc (intrigue--get-project-key) intrigue--files)))
                          nil t nil t)))
  (let* ( (p-files (cdr (assoc (intrigue--get-project-key) intrigue--files)))
          (f-choice (if intrigue-package-enable-icons (substring choice 2) choice))
          (f-path (cdr (assoc f-choice p-files)))
          (current? (string= f-path (buffer-file-name))))
    (when (not current?)
      (find-file f-path))))

;; TODO: Implement an intrique next and previous

(eval-after-load 'intrique (intrigue--init))
(provide 'intrigue)

;;; intrigue.el ends here
