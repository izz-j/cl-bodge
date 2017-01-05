(in-package :cl-bodge.asdf)


(defpackage :cl-bodge.graphics
  (:nicknames :ge.gx)
  (:use :cl :cl-bodge.engine :cl-bodge.host :cl-bodge.utils
        :cl-bodge.event :cl-bodge.assets)
  (:export graphics-system
           graphics
           in-wireframe-mode
           preserving-state

           render

           make-vertex-array

           attach-array-buffer
           make-array-buffer
           make-index-buffer

           primitive
           make-mesh
           make-patch-mesh

           load-shader-source
           compile-shader
           make-shading-program
           make-separable-shading-program
           link-separable-shading-program
           build-separable-shading-program
           uniforms-of
           uniform-name

           use-shading-program
           with-active-shading-program
           program-uniform-variable

           dimensions-of
           with-bound-texture
           with-texture-unit
           make-2d-texture
           wrap-mode-of

           make-blank-image

           make-shading-pipeline
           use-shading-program-stages
           with-bound-shading-pipeline

           make-framebuffer
           with-bound-framebuffer
           attach-color-buffer
           attach-depth-buffer
           attach-stencil-buffer
           attach-depth-stencil-buffer
           detach-color-buffer
           detach-depth-buffer
           detach-stencil-buffer
           detach-depth-stencil-buffer
           with-complete-framebuffer

           make-renderbuffer

           define-shader-library
           define-shading-program
           shading-program-asset-name
           find-program-descriptor
           load-shading-program
           build-shading-program))
