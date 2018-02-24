(cl:in-package :cl-bodge.math)


(defmacro %raw-> (type val)
  `(make-instance ',type :value ,val))


(definline vec->array (vec)
  (value-of vec))


(definline vec3 (&optional (x 0.0) (y 0.0) (z 0.0))
  (%raw-> vec3 (v3:make (f x) (f y) (f z))))


(definline vec4 (&optional (x 0.0) (y 0.0) (z 0.0) (w 0.0))
  (%raw-> vec4 (v4:make (f x) (f y) (f z) (f w))))


(definline vec2 (&optional (x 0.0) (y 0.0))
  (%raw-> vec2 (v2:make (f x) (f y))))


(definline copy-vec3 (vec)
  (%raw-> vec3 (v3:make (vref vec 0) (vref vec 1) (vref vec 2))))


(defgeneric vector-length (vec))


(defmethod vector-length ((this vec2))
  (v2:length (value-of this)))


(defmethod vector-length ((this vec3))
  (v3:length (value-of this)))


(defmethod vector-length ((this vec4))
  (v4:length (value-of this)))


(defgeneric make-vec3 (val &key))


(defmethod make-vec3 ((vec vec4) &key)
  (%raw-> vec3 (v3:make (vref vec 0) (vref vec 1) (vref vec 2))))


(defgeneric make-vec4 (val &key))


(defmethod make-vec4 ((vec vec3) &key (w 0.0))
  (%raw-> vec4 (v4:make (vref vec 0) (vref vec 1) (vref vec 2) w)))


(definline sequence->vec2 (seq)
  (vec2 (elt seq 0)
        (elt seq 1)))


(definline sequence->vec3 (seq)
  (vec3 (elt seq 0)
        (elt seq 1)
        (elt seq 2)))


(definline sequence->vec4 (seq)
  (vec4 (elt seq 0)
        (elt seq 1)
        (elt seq 2)
        (elt seq 3)))


(defun vref (vec idx)
  (let ((vec (value-of vec)))
    (ecase idx
      (0 (v:x vec))
      (1 (v:y vec))
      (2 (v:z vec))
      (3 (v:w vec)))))


(defun (setf vref) (value vec idx)
  (let ((vec (value-of vec)))
    (ecase idx
      (0 (setf (v:x vec) value))
      (1 (setf (v:y vec) value))
      (2 (setf (v:z vec) value))
      (3 (setf (v:w vec) value)))))


(definline x (vec)
  (v:x (value-of vec)))


(definline (setf x) (value vec)
  (setf (v:x (value-of vec)) (f value)))


(definline y (vec)
  (v:y (value-of vec)))


(definline (setf y) (value vec)
  (setf (v:y (value-of vec)) (f value)))


(definline z (vec)
  (v:z (value-of vec)))


(definline (setf z) (value vec)
  (setf (v:z (value-of vec)) (f value)))


(definline w (vec)
  (v:w (value-of vec)))


(definline (setf w) (value vec)
  (setf (v:w (value-of vec)) (f value)))


;;;
;;; VEC2
;;;
(defmethod addere ((this vec2) (that vec2))
  (%raw-> vec2 (v2:+ (value-of this) (value-of that))))


(defmethod addere ((this vec2) (scalar number))
  (%raw-> vec2 (v2:+s (value-of this) (f scalar))))


(defmethod addere ((scalar number) (this vec2))
  (addere this scalar))


(defmethod subtract ((this vec2) (that vec2))
  (%raw-> vec2 (v2:- (value-of this) (value-of that))))


(defmethod subtract ((this vec2) (scalar number))
  (%raw-> vec2 (v2:-s (value-of this) (f scalar))))


(defmethod subtract ((scalar number) (this vec2))
  (multiply (subtract this scalar) -1))


(defmethod lerp ((this vec2) (that vec2) (f number))
  (%raw-> vec2 (v2:lerp (value-of this) (value-of that) (f f))))


(defmethod normalize ((this vec2))
  (%raw-> vec2 (v2:normalize (value-of this))))


(defmethod multiply ((this vec2) (scalar number))
  (%raw-> vec2 (v2:*s (value-of this) (f scalar))))


(defmethod multiply ((scalar number) (this vec2))
  (multiply this scalar))


(defmethod multiply ((this vec2) (that vec2))
  (%raw-> vec2 (v2:* (value-of this) (value-of that))))


(defmethod divide ((this vec2) (scalar number))
  (%raw-> vec2 (v2:/s (value-of this) (f scalar))))


(defmethod divide ((this vec2) (that vec2))
  (%raw-> vec2 (v2:/ (value-of this) (value-of that))))


(defmethod cross-product ((this vec2) (that vec2))
  (%raw-> vec2 (v2:cross (value-of this) (value-of that))))


(defmethod dot-product ((this vec2) (that vec2))
  (v2:dot (value-of this) (value-of that)))


;;;
;;; VEC3
;;;
(defmethod addere ((this vec3) (that vec3))
  (%raw-> vec3 (v3:+ (value-of this) (value-of that))))


(defmethod addere ((this vec3) (scalar number))
  (%raw-> vec3 (v3:+s (value-of this) (f scalar))))


(defmethod addere ((scalar number) (this vec3))
  (addere this scalar))


(defmethod subtract ((this vec3) (that vec3))
  (%raw-> vec3 (v3:- (value-of this) (value-of that))))


(defmethod subtract ((this vec3) (scalar number))
  (%raw-> vec3 (v3:-s (value-of this) (f scalar))))


(defmethod subtract ((scalar number) (this vec2))
  (multiply (subtract this scalar) -1))


(defmethod lerp ((this vec3) (that vec3) (f number))
  (%raw-> vec3 (v3:lerp (value-of this) (value-of that) (f f))))


(defmethod normalize ((this vec3))
  (%raw-> vec3 (v3:normalize (value-of this))))


(defmethod multiply ((this vec3) (scalar number))
  (%raw-> vec3 (v3:*s (value-of this) (f scalar))))


(defmethod multiply ((scalar number) (this vec3))
  (multiply this scalar))


(defmethod multiply ((this vec3) (that vec3))
  (%raw-> vec3 (v3:* (value-of this) (value-of that))))


(defmethod divide ((this vec3) (scalar number))
  (%raw-> vec3 (v3:/s (value-of this) (f scalar))))


(defmethod divide ((this vec3) (that vec3))
  (%raw-> vec3 (v3:/s (value-of this) (value-of that))))


(defmethod cross-product ((this vec3) (that vec3))
  (%raw-> vec3 (v3:cross (value-of this) (value-of that))))


(defmethod dot-product ((this vec3) (that vec3))
  (v3:dot (value-of this) (value-of that)))


;;;
;;; VEC4
;;;
(defmethod multiply ((this vec4) (scalar number))
  (%raw-> vec4 (v4:*s (value-of this) (f scalar))))


(defmethod multiply ((scalar number) (this vec4))
  (multiply this scalar))


(defmethod divide ((this vec4) (scalar number))
  (%raw-> vec4 (v4:/s (value-of this) (f scalar))))


(defmethod addere ((this vec4) (that vec4))
  (%raw-> vec4 (v4:+ (value-of this) (value-of that))))


(defmethod subtract ((this vec4) (that vec4))
  (%raw-> vec4 (v4:- (value-of this) (value-of that))))

;;;
;;; VEC2
;;;
(defmethod addere ((this vec2) (that vec2))
  (%raw-> vec2 (v2:+ (value-of this) (value-of that))))


(defmethod subtract ((this vec2) (that vec2))
  (%raw-> vec2 (v2:- (value-of this) (value-of that))))


(defmethod lerp ((this vec2) (that vec2) (f number))
  (%raw-> vec2 (v2:lerp (value-of this) (value-of that) (f f))))


(defmethod normalize ((this vec2))
  (%raw-> vec2 (v2:normalize (value-of this))))


(defmethod multiply ((this vec2) (scalar number))
  (%raw-> vec2 (v2:*s (value-of this) (f scalar))))


(defmethod multiply ((scalar number) (this vec2))
  (multiply this scalar))


(defmethod divide ((this vec2) (scalar number))
  (%raw-> vec2 (v2:/s (value-of this) (f scalar))))


(defmethod cross-product ((this vec2) (that vec2))
  (%raw-> vec2 (v2:cross (value-of this) (value-of that))))


(defmethod dot-product ((this vec2) (that vec2))
  (v2:dot (value-of this) (value-of that)))
