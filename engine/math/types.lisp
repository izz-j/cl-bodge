(cl:in-package :cl-bodge.math)

(defgeneric lerp (this that f))
(defgeneric normalize (this))
(defgeneric inverse (this))


(defgeneric multiply (this that))
(defgeneric addere (this that))
(defgeneric divide (this that))
(defgeneric subtract (this that))


(defgeneric dot-product (this that))
(defgeneric cross-product (this that))

(defgeneric transform-of (this))

(macrolet ((defreduced (name generic)
             `(definline ,name (arg0 &rest args)
                (reduce (lambda (this that) (,generic this that))
                        args :initial-value arg0))))

  (defreduced mult multiply)
  (defreduced add addere)
  (defreduced div divide)
  (defreduced subt subtract)
  (defreduced dot dot-product)
  (defreduced cross cross-product))


(definline nlerp (this that f)
  (normalize (lerp this that f)))

;;;
;;; Vectors
;;;
(defclass vec () ())

(defgeneric value-of (vec))

(defmethod print-object ((object vec) stream)
  (format stream "#<~A ~{~A~^ ~}>"
          (class-name-of object) (map 'list #'identity (value-of object))))


(defclass vec2 (vec)
  ((value :initarg :value :initform (v2:make 0.0 0.0) :type rtg-math.types:vec2
          :reader value-of)))


(defclass vec3 (vec)
  ((value :initarg :value :initform (v3:make 0.0 0.0 0.0) :type rtg-math.types:vec3
          :reader value-of)))


(defclass vec4 (vec)
  ((value :initarg :value :initform (v4:make 0.0 0.0 0.0 0.0) :type rtg-math.types:vec4
          :reader value-of)))

;;;
;;; Matricies
;;;
(defclass mat () ())


(defclass square-mat (mat) ())


(defclass mat2 (square-mat)
  ((value :initarg :value
          :initform (make-array 4 :element-type 'single-float :initial-element 0.0)
          :type (simple-array single-float (4)) :reader value-of)))


(defclass mat3 (square-mat)
  ((value :initarg :value :initform (m3:0!) :type rtg-math.types:mat3 :reader value-of)))


(defclass mat4 (square-mat)
  ((value :initarg :value :initform (m4:0!) :type rtg-math.types:mat4 :reader value-of)))



(declaim (ftype (function (square-mat) (integer 2 4)) square-matrix-size))
(definline square-matrix-size (square-mat)
  (etypecase square-mat
    (mat2 2)
    (mat3 3)
    (mat4 4)))


;;;
;;; Quaternions
;;;
(defclass quat ()
  ((value :initarg :value :initform (q:0!) :type rtg-math.types:quaternion :reader value-of)))
