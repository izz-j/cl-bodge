(in-package :cl-bodge.host)


(defclass host-system (dispatching generic-system)
  ((enabled-p :initform nil)
   (swap-interval :initform 0)
   (window :initform nil :reader window-of)
   (gl-major-version)
   (gl-minor-version)
   (task-queue :initform (make-task-queue))))


(definline host ()
  (engine-system 'host-system))


(defclass rendering-context ()
  ((surface :initarg :surface :reader surface-of)))


(define-destructor rendering-context (surface)
  (run (-> ((host)) ()
         (glfw:destroy-window surface))))


(defmethod enabledp ((this host-system))
  (slot-value this 'enabled-p))


(defmethod dispatch ((this host-system) (fn function) invariant &key)
  (with-slots (task-queue) this
    (with-system-lock-held (this)
      (push-task fn task-queue)
      (glfw:post-empty-event)))
  t)


(glfw:def-window-close-callback on-close (window)
  (glfw:hide-window window)
  (post 'viewport-hiding-event))


(glfw:def-key-callback on-key-action (window key scancode action mod-keys)
  (declare (ignore window scancode mod-keys))
  (post 'keyboard-event
              :key (glfw-enumval->keyboard-key key)
              :state (glfw-enumval->button-state action)))


(glfw:def-mouse-button-callback on-mouse-action (window button action mod-keys)
  (declare (ignore window mod-keys))
  (post 'mouse-event
              :button (glfw-enumval->mouse-button button)
              :state (glfw-enumval->button-state action)))


(glfw:def-cursor-pos-callback on-cursor-movement (window x y)
  (let ((height (second (glfw:get-window-size window))))
    (post 'cursor-event :x x :y (- height y))))


(glfw:def-scroll-callback on-scroll (window x y)
  (declare (ignore window))
  (post 'scroll-event :x-offset x :y-offset (- y)))


(glfw:def-framebuffer-size-callback on-framebuffer-size-change (window w h)
  (declare (ignore window))
  (post 'viewport-size-change-event :width w :height h))


(%glfw:define-glfw-callback on-character-input ((window :pointer) (char-code :unsigned-int))
  (declare (ignore window))
  (let ((character (code-char char-code)))
    (post 'character-input-event :character character)))


;; if current thread is the main one, this function will block
(defmethod initialize-system :after ((this host-system))
  (with-slots (enabled-p task-queue window eve-sys gl-major-version gl-minor-version) this
    (when enabled-p
      (error "Host system already enabled"))
    (wait-with-latch (latch)
      (log:debug "Injecting loop into main thread")
      (with-body-in-main-thread ()
        (unwind-protect
             (log-errors
               (destructuring-bind (major-version minor-version)
                   (property '(:host :opengl-version) '(4 1))
                 (log:debug "Initializing GLFW context for OpenGL version ~A.~A"
                            major-version minor-version)
                 (setf gl-major-version major-version
                       gl-minor-version minor-version)
                 (glfw:with-init-window (:title "Scene"
                                                :width 640 :height 480
                                                :context-version-major major-version
                                                :context-version-minor minor-version
                                                :opengl-profile :opengl-core-profile
                                                :opengl-forward-compat t
                                                :depth-bits 24
                                                :resizable nil
                                                :stencil-bits 8
                                                :visible t)
                   (glfw:set-window-close-callback 'on-close)
                   (glfw:set-key-callback 'on-key-action)
                   (glfw:set-mouse-button-callback 'on-mouse-action)
                   (glfw:set-cursor-position-callback 'on-cursor-movement)
                   (glfw:set-scroll-callback 'on-scroll)
                   (glfw:set-framebuffer-size-callback 'on-framebuffer-size-change)
                   (glfw:set-char-callback 'on-character-input)
                   (glfw:swap-interval 0)
                   (setf window glfw:*window*
                         enabled-p t)
                   (log:debug "Host main loop running")
                   (glfw:make-context-current (cffi:null-pointer))
                   (log:debug "GL context detached from main loop thread")
                   (let ((*system* this))
                     (open-latch latch)
                     (loop while enabled-p
                        do (log-errors
                             (glfw:wait-events)
                             (drain task-queue))))))
               (log:debug "Main loop stopped. Host system offline"))
          (open-latch latch))))
    (log:debug "Host system initialized")))


(defmethod discard-system :before ((this host-system))
  (with-slots (enabled-p task-queue) this
    (unless enabled-p
      (error "Host system already disabled"))
    (wait-with-latch (latch)
      (run
       (-> this ()
         (setf enabled-p nil)
         (clearup task-queue)
         (open-latch latch))))
    (log:debug "Stopping main thread runner")
    (stop-main-runner)))


(define-system-function make-rendering-context host-system (&key (width 1) (height 1))
  (with-slots (gl-major-version gl-minor-version) *system*
    (glfw:create-window :title ""
                        :width width :height height
                        :context-version-major gl-major-version
                        :context-version-minor gl-minor-version
                        :opengl-profile :opengl-core-profile
                        :opengl-forward-compat t
                        :depth-bits 24
                        :resizable nil
                        :stencil-bits 8
                        :visible nil
                        :shared (window-of *system*))
    (make-instance 'rendering-context :surface glfw:*window*)))


(defun bind-rendering-context (host-sys &optional rendering-context)
  (with-slots (window) host-sys
    (if rendering-context
        (glfw:make-context-current (surface-of rendering-context))
        (glfw:make-context-current window))))


(defun swap-buffers (host-sys)
  (with-slots (window) host-sys
    (with-system-lock-held (host-sys)
      (glfw:swap-buffers window))))


(defun swap-interval (host-sys)
  (with-slots (swap-interval) host-sys
    swap-interval))


(defun (setf swap-interval) (value host-sys)
  (with-slots (swap-interval) host-sys
    (with-system-lock-held (host-sys)
      (setf swap-interval value)
      (glfw:swap-interval value))))


(define-system-function (setf viewport-title) host-system (value &key (host-sys *system*))
  (with-slots (window) host-sys
    (glfw:set-window-title (format nil "~a" value) window)))


(define-system-function viewport-size host-system ()
  (let ((val (glfw:get-window-size (window-of *system*))))
    (vec2 (first val) (second val))))


(define-system-function (setf viewport-size) host-system (value)
  (glfw:set-window-size (floor (x value)) (floor (y value)) (window-of *system*)))


(define-system-function cursor-position host-system ()
  (let ((height (second (viewport-size))))
    (destructuring-bind (x y) (glfw:get-cursor-position (window-of *system*))
      (list x (- height y)))))


(define-system-function mouse-button-state host-system (button)
  (glfw-enumval->button-state
   (glfw:get-mouse-button (mouse-button->glfw-enumval button) (window-of *system*))))


(define-system-function lock-cursor host-system (&key (host *system*))
  (with-slots (window) host
    (glfw:set-input-mode :cursor :disabled)))


(define-system-function unlock-cursor host-system (&key (host *system*))
  (with-slots (window) host
    (glfw:set-input-mode :cursor :normal)))


(define-system-function (setf fullscreen-viewport-p) host-system (value)
  (with-slots (window) *system*
    (if value
        (let* ((monitor (glfw:get-primary-monitor))
               (video-mode (%glfw:get-video-mode monitor))
               (width (getf video-mode '%glfw:width))
               (height (getf video-mode '%glfw:height)))
          (glfw:set-window-monitor monitor width height :window window))
        (glfw:set-window-monitor nil 640 480 :window window :x-position 100 :y-position 100))))
