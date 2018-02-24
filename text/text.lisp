(cl:in-package :cl-bodge.text)


(defclass text (disposable)
  ((text :initform nil :reader string-of)
   (font :initarg :font)
   (text-mesh :initform nil)
   (glyphs-count :initform 0)
   (position-buffer :initform nil)
   (texture-coord-buffer :initform nil)
   (width :initform nil :reader width-of)
   (height :initform nil :reader height-of)
   (atlas-tex :initform nil)))


(define-destructor text (text-mesh position-buffer texture-coord-buffer)
  (dispose texture-coord-buffer)
  (dispose position-buffer)
  (dispose text-mesh))


(defun prepare-text (text font)
  (let ((pos-list (list))
        (tex-list (list)))
    (flet ((set-coords (x0 y0 x1 y1 s0 t0 s1 t1)
             (push (list x0 y0 x1 y1) pos-list)
             (push (list s0 t0 s1 t1) tex-list)))
      (multiple-value-bind (size text-width text-height)
          (walk-string text font #'set-coords)
        (let ((box-array (make-array (list size 4)
                                     :element-type 'single-float
                                     :initial-contents (nreverse pos-list)))
              (tex-coord-array (make-array (list size 4)
                                           :element-type 'single-float
                                           :initial-contents (nreverse tex-list))))
          (values box-array tex-coord-array text-width text-height))))))


(define-system-function update-text graphics-system
    (text string &key (start 0) end)
  (with-slots ((this-text text) width height position-buffer texture-coord-buffer font) text
    (setf (subseq this-text start (or end (length this-text))) string)
    (multiple-value-bind (box-array tex-coord-array text-width text-height)
        (prepare-text this-text font)
      (setf width text-width
            height text-height)
      (update-array-buffer position-buffer box-array)
      (update-array-buffer texture-coord-buffer tex-coord-array))))



(defmethod initialize-instance :after ((this text) &key text font)
  (with-slots ((this-text text) text-mesh atlas-tex width height
               position-buffer texture-coord-buffer glyphs-count)
      this
    (setf this-text (make-array (length text)
                                :element-type 'character
                                :initial-contents text))
    (multiple-value-bind (box-array tex-coord-array text-width text-height)
        (prepare-text this-text font)
      (setf glyphs-count (array-dimension box-array 0)
            width text-width
            height text-height
            text-mesh (make-mesh glyphs-count :points)
            atlas-tex (font-atlas-texture font))
      (let ((pbuf (make-array-buffer box-array))
            (tbuf (make-array-buffer tex-coord-array)))
        (attach-array-buffer pbuf text-mesh 0)
        (attach-array-buffer tbuf text-mesh 1)
        (setf position-buffer pbuf
              texture-coord-buffer tbuf)))))


(defun make-text (string font)
  (make-instance 'text :text string :font font))


(defun render-text (text start &optional end)
  (with-slots (text-mesh atlas-tex glyphs-count) text
    (with-bound-texture (atlas-tex)
      (render-mesh text-mesh start (or end glyphs-count)))))


(defmethod render ((this text))
  (render-text this 0))
