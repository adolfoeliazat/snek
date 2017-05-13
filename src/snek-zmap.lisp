
; TODO: make this into a package that does not depend on snek.

(defun zmap-xy-to-zone (xy zwidth)
  (mapcar (lambda (x) (floor x zwidth)) xy))


(defun zmap-v-to-zone (verts v zwidth)
  (list
    (floor (aref verts v 0) zwidth)
    (floor (aref verts v 1) zwidth)))


(defun zmap-add-v-to-zone (zmap z v)
  (multiple-value-bind (vals exists)
    (gethash z zmap)
    (if (not exists)
      (progn
        (setf
          vals
          (make-array 20 :fill-pointer 0 :element-type 'integer))
        (setf (gethash z zmap) vals)))
    (vector-push-extend v vals)))


(defun zmap-update (snk width)
  (with-struct (snek- verts num-verts) snk
  (let ((zmap (make-hash-table :test #'equal)))
    (loop for v from 0 below num-verts
      do
        (zmap-add-v-to-zone
          zmap
          (zmap-v-to-zone verts v (to-dfloat width))
          v))
    (setf (snek-zmap snk) zmap)
    (setf (snek-zwidth snk) width))))


(defmacro -extend (x y &body body)
  `(dolist
    (,x '(-1 0 1))
    (dolist
      (,y '(-1 0 1))
      ,@body)))

(defun zmap-nearby-zones (z)
  (destructuring-bind (a b)
    z
    (let ((zs (make-array 9 :fill-pointer 0)))
      (-extend i j (vector-push (list (+ a i) (+ b j)) zs))
      zs)))


(defun verts-in-rad (snk xy rad)
  (with-struct (snek- verts zmap zwidth) snk
    (let ((zs (zmap-nearby-zones
                (zmap-xy-to-zone xy zwidth)))
          (inds (make-array 20 :fill-pointer 0 :element-type 'integer))
          (rad2 (* rad rad)))
      (loop for i from 0 below 9 do
        (multiple-value-bind (vals exists)
        (gethash (aref zs i) zmap)
        (if exists
          (loop for j from 0 below (length vals)
            do
            (let ((zj (aref vals j)))
              (if
                (< (dst2 xy (get-as-list verts zj)) rad2)
                (vector-push-extend zj inds)))))))
      inds)))

