(in-package :cl-bodge.distribution)


(declaim (special *distribution*))

(defun list-system-pathnames (system-designator)
  (labels ((%extract-name (sys-def)
             (if (listp sys-def)
                 (ecase (first sys-def)
                   (:version (second sys-def)))
                 sys-def))

           (%list-dependencies (system)
             (mapcar #'%extract-name (append (asdf:system-depends-on system)
                                             (asdf:system-defsystem-depends-on system))))

           (%proper-path-p (sys-path)
             (and sys-path
                  (> (length (trim-whitespaces (namestring sys-path))) 0)))

           (%list-system-pathnames (system-designator)
             (let* ((system (asdf:find-system system-designator))
                    (sys-path (asdf:system-definition-pathname system)))
               (append (when (%proper-path-p sys-path) (list sys-path))
                       (loop for sys-name in (%list-dependencies system) append
                            (%list-system-pathnames sys-name))))))
    (remove-duplicates (%list-system-pathnames system-designator) :test #'equal)))


(defun generate-manifest ()
  (let ((manifest-file (fad:merge-pathnames-as-file (build-directory-of *distribution*)
                                                    "manifest-file")))
    (alexandria:write-string-into-file (format nil "~{~a~^~%~}"
                                               (list-system-pathnames
                                                (target-system-of *distribution*)))
                                       manifest-file
                                       :if-exists :supersede)
    manifest-file))


(defun build-executable ()
  (let ((manifest-file (generate-manifest))
        (output-file (fad:merge-pathnames-as-file (directory-of *distribution*)
                                                  (format nil "~(~a~).bin"
                                                          (name-of *distribution*)))))
    (unless (fad:file-exists-p output-file)
      (run-program "buildapp ~{\"~a\" ~}"
                   (list "--output"
                         "--entry" (entry-function-of *distribution*)
                         "--manifest-file" manifest-file
                         "--load" (file (distribution-system-path) "prologue.lisp")
                         "--load-system" (format nil "~(~a~)" (target-system-of *distribution*))
                         "--compress-core")))))


(defun prepare ()
  (ensure-directories-exist (directory-of *distribution*)))


(defun copy-assets ()
  (loop for (src dst) in (assets-of *distribution*) do
       (copy-path src dst)))


(defun compress ()
  (compress-directory (directory-of *distribution*)
                      (format nil "~(~A~)" (name-of *distribution*))))


(defun copy-foreign-dependencies (lib-path lib-dir &optional target-filename)
  (unless (system-library-p lib-path)
    (let ((dst (fad:merge-pathnames-as-file lib-dir (or target-filename
                                                        (file-namestring lib-path)))))
      (unless (fad:file-exists-p dst)
        (fad:copy-file lib-path dst)
        (loop for dep in (list-foreign-dependencies lib-path)
           do (copy-foreign-dependencies dep lib-dir))))))


(defun pack-foreign-libraries ()
  (let ((lib-dir (library-directory-of *distribution*))
        (dirs (append (cffi::parse-directories cffi:*foreign-library-directories*)
                      (list-platform-search-paths))))
    (ensure-directories-exist lib-dir)
    (loop for lib in (cffi:list-foreign-libraries) do
         (let ((path (cffi:foreign-library-pathname lib)))
           (if-let (file (cffi::find-file path dirs))
             (copy-foreign-dependencies file lib-dir (file-namestring path))
             (error "Cannot find foreign library ~a" (cffi:foreign-library-name lib)))))))


(defun copy-engine-assets ()
  (let ((dir (engine-assets-directory-of *distribution*)))
    (when (asdf:system-registered-p :cl-bodge/assets)
      (when-let* ((pkg (find-package :ge.as))
                  (fsym (find-symbol (symbol-name 'copy-assets) pkg))
                  (copy-fn (symbol-function fsym)))
        (ensure-directories-exist dir)
        (funcall copy-fn dir)))))


(defun shout (string)
  (format t "~%~A" string)
  (finish-output))


(defun make-distribution (name)
  (let* ((*distribution* (distribution-by-name name)))
    (let ((*load-verbose* nil)
          (*compile-verbose* nil)
          (*load-print* nil)
          (*compile-print* nil))
      (declare #+sbcl (sb-ext:muffle-conditions sb-ext:compiler-note))
      (handler-bind ((style-warning #'muffle-warning))
        (load-system (target-system-of *distribution*) :verbose nil)))
    (shout "Preparing build directory")
    (prepare)
    (shout "Building executable")
    (build-executable)
    (shout "Packing foreign libraries")
    (pack-foreign-libraries)
    (shout "Copying system assets")
    (copy-assets)
    (shout "Copying engine assets")
    #++(copy-engine-assets)
    (when (compressedp *distribution*)
      (shout "Compressing distribution")
      (compress))
    (when (bundle-run-file-of *distribution*)
      (shout "Creating bundle")
      (make-app-bundle))
    (format t "~%Done~%")
    *distribution*))
