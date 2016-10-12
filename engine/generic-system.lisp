(in-package :cl-bodge.engine)


(defclass generic-system (system)
  ((state-lock :initform (make-recursive-lock "generic-system-state-lock")
               :reader lock-of)))


(defgeneric initialize-system (system)
  (:method (system) (declare (ignore system))))


(defgeneric discard-system (system)
  (:method (system) (declare (ignore system))))


(defmethod execute ((this system) fn)
  (execute (engine) fn))


(defmacro with-system-lock-held ((system &optional lock-var) &body body)
  (once-only (system)
    `(let ,(unless (null lock-var)
           `((,lock-var (bge.ng::lock-of ,system))))
       (with-recursive-lock-held ((bge.ng::lock-of ,system))
         ,@body))))


(defmethod enabledp :around ((this generic-system))
  (with-system-lock-held (this)
    (call-next-method)))


(defmethod enable ((this generic-system))
  (with-system-lock-held (this)
    (when (enabledp this)
      (error "~a already enabled" (class-name (class-of this))))
    (initialize-system this)))


(defmethod disable ((this generic-system))
  (with-system-lock-held (this)
    (unless (enabledp this)
      (error "~a already disabled" (class-name (class-of this))))
    (discard-system this)))