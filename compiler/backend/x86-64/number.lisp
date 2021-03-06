;;;; Copyright (c) 2017 Henry Harrington <henry.harrington@gmail.com>
;;;; This code is licensed under the MIT license.

(in-package :mezzano.compiler.backend.x86-64)

;;; FIXNUM/INTEGER operations.

(define-builtin sys.int::fixnump ((object) :z)
  (emit (make-instance 'x86-instruction
                       :opcode 'lap:test64
                       :operands (list object sys.int::+fixnum-tag-mask+)
                       :inputs (list object)
                       :outputs '())))

(define-builtin mezzano.runtime::%fixnum-+ ((lhs rhs) result)
  (let ((out (make-instance 'label :phis (list result)))
        (overflow (make-instance 'label :name :+-overflow))
        (fixnum-result (make-instance 'virtual-register))
        (bignum-result (make-instance 'virtual-register)))
    (cond ((constant-value-p rhs '(signed-byte 31))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:add64
                                :result fixnum-result
                                :lhs lhs
                                :rhs (ash (fetch-constant-value rhs)
                                          sys.int::+n-fixnum-bits+))))
          (t
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:add64
                                :result fixnum-result
                                :lhs lhs
                                :rhs rhs))))
    (emit (make-instance 'x86-branch-instruction
                         :opcode 'lap:jo
                         :target overflow))
    (emit (make-instance 'label :name :+-no-overflow))
    (emit (make-instance 'jump-instruction
                         :target out
                         :values (list fixnum-result)))
    ;; Build a bignum on overflow.
    ;; Recover the full value using the carry bit.
    (emit overflow)
    (emit (make-instance 'move-instruction
                         :source fixnum-result
                         :destination :rax))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:rcr64
                         :operands (list :rax 1)
                         :inputs (list :rax)
                         :outputs (list :rax)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov64
                         :operands (list :r13 '(:function sys.int::%%make-bignum-64-rax))
                         :inputs '()
                         :outputs (list :r13)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:call
                         :operands (list `(:object :r13 ,sys.int::+fref-entry-point+))
                         :inputs '(:r13 :rax)
                         :outputs (list :r8)
                         :clobbers '(:rax :rcx :rdx :rsi :rdi :rbx :r8 :r9 :r10 :r11 :r12 :r13 :r14 :r15
                                     :mm0 :mm1 :mm2 :mm3 :mm4 :mm5 :mm6 :mm7
                                     :xmm0 :xmm1 :xmm2 :xmm3 :xmm4 :xmm5 :xmm6 :xmm7 :xmm8
                                     :xmm9 :xmm10 :xmm11 :xmm12 :xmm13 :xmm14 :xmm15)))
    (emit (make-instance 'move-instruction
                         :destination bignum-result
                         :source :r8))
    (emit (make-instance 'jump-instruction :target out :values (list bignum-result)))
    (emit out)))

(define-builtin mezzano.compiler::%fast-fixnum-+ ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:add64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:add64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin mezzano.runtime::%fixnum-- ((lhs rhs) result)
  (let ((out (make-instance 'label :phis (list result)))
        (overflow (make-instance 'label :name :--overflow))
        (fixnum-result (make-instance 'virtual-register))
        (bignum-result (make-instance 'virtual-register)))
    (cond ((constant-value-p rhs '(signed-byte 31))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:sub64
                                :result fixnum-result
                                :lhs lhs
                                :rhs (ash (fetch-constant-value rhs)
                                          sys.int::+n-fixnum-bits+))))
          (t
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:sub64
                                :result fixnum-result
                                :lhs lhs
                                :rhs rhs))))
    (emit (make-instance 'x86-branch-instruction
                         :opcode 'lap:jo
                         :target overflow))
    (emit (make-instance 'label :name :--no-overflow))
    (emit (make-instance 'jump-instruction
                         :target out
                         :values (list fixnum-result)))
    ;; Build a bignum on overflow.
    ;; Recover the full value using the carry bit.
    (emit overflow)
    (emit (make-instance 'move-instruction
                         :source fixnum-result
                         :destination :rax))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cmc
                         :operands (list)
                         :inputs (list)
                         :outputs (list)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:rcr64
                         :operands (list :rax 1)
                         :inputs (list :rax)
                         :outputs (list :rax)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov64
                         :operands (list :r13 '(:function sys.int::%%make-bignum-64-rax))
                         :inputs '()
                         :outputs (list :r13)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:call
                         :operands (list `(:object :r13 ,sys.int::+fref-entry-point+))
                         :inputs '(:r13 :rax)
                         :outputs (list :r8)
                         :clobbers '(:rax :rcx :rdx :rsi :rdi :rbx :r8 :r9 :r10 :r11 :r12 :r13 :r14 :r15
                                     :mm0 :mm1 :mm2 :mm3 :mm4 :mm5 :mm6 :mm7
                                     :xmm0 :xmm1 :xmm2 :xmm3 :xmm4 :xmm5 :xmm6 :xmm7 :xmm8
                                     :xmm9 :xmm10 :xmm11 :xmm12 :xmm13 :xmm14 :xmm15)))
    (emit (make-instance 'move-instruction
                         :destination bignum-result
                         :source :r8))
    (emit (make-instance 'jump-instruction :target out :values (list bignum-result)))
    (emit out)))

(define-builtin mezzano.compiler::%fast-fixnum-- ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:sub64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:sub64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin mezzano.runtime::%fixnum-* ((lhs rhs) result)
  (let ((out (make-instance 'label :phis (list result)))
        (low-half (make-instance 'virtual-register :kind :integer))
        (high-half (make-instance 'virtual-register :kind :integer))
        (overflow (make-instance 'label :name :*-overflow))
        (overflow-temp (make-instance 'virtual-register :kind :integer))
        (fixnum-result (make-instance 'virtual-register))
        (bignum-result (make-instance 'virtual-register))
        (lhs-unboxed (make-instance 'virtual-register :kind :integer)))
    ;; Convert the lhs to a raw integer, leaving the rhs as a fixnum.
    ;; This will cause the result to be a fixnum.
    (emit (make-instance 'unbox-fixnum-instruction
                         :source lhs
                         :destination lhs-unboxed))
    (emit (make-instance 'move-instruction
                         :source lhs-unboxed
                         :destination :rax))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:imul64
                         :operands (list rhs)
                         :inputs (list :rax rhs)
                         :outputs (list :rax :rdx)))
    ;; Avoid keeping rax/rdx live over a branch.
    (emit (make-instance 'move-instruction
                         :destination low-half
                         :source :rax))
    (emit (make-instance 'move-instruction
                         :destination high-half
                         :source :rdx))
    (emit (make-instance 'x86-branch-instruction
                         :opcode 'lap:jo
                         :target overflow))
    (emit (make-instance 'label :name :*-no-overflow))
    (emit (make-instance 'move-instruction
                         :source low-half
                         :destination fixnum-result))
    (emit (make-instance 'jump-instruction
                         :target out
                         :values (list fixnum-result)))
    ;; Build a bignum on overflow.
    ;; 128-bit result in rdx:rax.
    (emit overflow)
    ;; Unbox the result.
    (emit (make-instance 'move-instruction
                         :destination :rax
                         :source low-half))
    (emit (make-instance 'move-instruction
                         :destination :rdx
                         :source high-half))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:shrd64
                         :operands (list :rax :rdx sys.int::+n-fixnum-bits+)
                         :inputs (list :rax :rdx)
                         :outputs (list :rax)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:sar64
                         :operands (list :rdx sys.int::+n-fixnum-bits+)
                         :inputs (list :rdx)
                         :outputs (list :rdx)))
    ;; Check if the result will fit in 64 bits.
    ;; Save the high bits.
    (emit (make-instance 'move-instruction
                         :destination overflow-temp
                         :source :rdx))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cqo
                         :operands (list)
                         :inputs (list :rax)
                         :outputs (list :rdx)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cmp64
                         :operands (list overflow-temp :rdx)
                         :inputs (list overflow-temp :rdx)
                         :outputs (list)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov64
                         :operands (list :rdx overflow-temp)
                         :inputs (list overflow-temp)
                         :outputs (list :rdx)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:mov64
                         :operands (list :r13 '(:function sys.int::%%make-bignum-128-rdx-rax))
                         :inputs (list)
                         :outputs (list :r13)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cmov64e
                         :operands (list :r13 '(:function sys.int::%%make-bignum-64-rax))
                         :inputs (list :r13)
                         :outputs (list :r13)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:call
                         :operands (list `(:object :r13 ,sys.int::+fref-entry-point+))
                         :inputs (list :r13 :rax :rdx)
                         :outputs (list :r8)
                         :clobbers '(:rax :rcx :rdx :rsi :rdi :rbx :r8 :r9 :r10 :r11 :r12 :r13 :r14 :r15
                                     :mm0 :mm1 :mm2 :mm3 :mm4 :mm5 :mm6 :mm7
                                     :xmm0 :xmm1 :xmm2 :xmm3 :xmm4 :xmm5 :xmm6 :xmm7 :xmm8
                                     :xmm9 :xmm10 :xmm11 :xmm12 :xmm13 :xmm14 :xmm15)))
    (emit (make-instance 'move-instruction
                         :destination bignum-result
                         :source :r8))
    (emit (make-instance 'jump-instruction :target out :values (list bignum-result)))
    (emit out)))

(define-builtin mezzano.compiler::%fast-fixnum-* ((lhs rhs) result)
  ;; Convert the lhs to a raw integer, leaving the rhs as a fixnum.
  ;; This will cause the result to be a fixnum.
  (let ((lhs-unboxed (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-fixnum-instruction
                         :source lhs
                         :destination lhs-unboxed))
    (emit (make-instance 'move-instruction
                         :source lhs-unboxed
                         :destination :rax))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:imul64
                         :operands (list rhs)
                         :inputs (list :rax rhs)
                         :outputs (list :rax :rdx)))
    (emit (make-instance 'move-instruction
                         :destination result
                         :source :rax))))

(define-builtin mezzano.runtime::%fixnum-truncate ((lhs rhs) (quot rem))
  (let ((quot-unboxed (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'move-instruction
                         :source lhs
                         :destination :rax))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cqo
                         :operands (list)
                         :inputs (list :rax)
                         :outputs (list :rdx)))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:idiv64
                         :operands (list rhs)
                         :inputs (list :rax :rdx rhs)
                         :outputs (list :rax :rdx)))
    ;; :rax holds the dividend as a integer.
    ;; :rdx holds the remainder as a fixnum.
    (emit (make-instance 'move-instruction
                         :source :rax
                         :destination quot-unboxed))
    (emit (make-instance 'box-fixnum-instruction
                         :source quot-unboxed
                         :destination quot))
    (emit (make-instance 'move-instruction
                         :source :rdx
                         :destination rem))))

(define-builtin mezzano.runtime::%fixnum-logand ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:and64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:and64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin sys.c::%fast-fixnum-logand ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:and64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:and64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin mezzano.runtime::%fixnum-logior ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:or64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:or64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin sys.c::%fast-fixnum-logior ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:or64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:or64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin mezzano.runtime::%fixnum-logxor ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:xor64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:xor64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin sys.c::%fast-fixnum-logxor ((lhs rhs) result)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:xor64
                              :result result
                              :lhs lhs
                              :rhs (ash (fetch-constant-value rhs)
                                        sys.int::+n-fixnum-bits+))))
        (t
         (emit (make-instance 'x86-fake-three-operand-instruction
                              :opcode 'lap:xor64
                              :result result
                              :lhs lhs
                              :rhs rhs)))))

(define-builtin mezzano.runtime::%fixnum-< ((lhs rhs) :l)
  (cond ((constant-value-p rhs '(signed-byte 31))
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:cmp64
                              :operands (list lhs (ash (fetch-constant-value rhs)
                                                       sys.int::+n-fixnum-bits+))
                              :inputs (list lhs)
                              :outputs '())))
        (t
         (emit (make-instance 'x86-instruction
                              :opcode 'lap:cmp64
                              :operands (list lhs rhs)
                              :inputs (list lhs rhs)
                              :outputs '())))))

(define-builtin mezzano.runtime::%fixnum-right-shift ((integer count) result)
  (cond ((constant-value-p count '(integer 0))
         (let ((count-value (fetch-constant-value count)))
           (cond ((>= count-value (- 64 sys.int::+n-fixnum-bits+))
                  ;; All bits shifted out.
                  ;; Turn INTEGER into 0 or -1.
                  (emit (make-instance 'move-instruction
                                       :destination :rax
                                       :source integer))
                  (emit (make-instance 'x86-instruction
                                       :opcode 'lap:cqo
                                       :operands '()
                                       :inputs '(:rax)
                                       :outputs '(:rdx)))
                  (emit (make-instance 'x86-instruction
                                       :opcode 'lap:and64
                                       :operands `(:rdx ,(- (ash 1 sys.int::+n-fixnum-bits+)))
                                       :inputs '(:rdx)
                                       :outputs '(:rdx)))
                  (emit (make-instance 'move-instruction
                                       :destination result
                                       :source :rdx)))
                 ((zerop count-value)
                  (emit (make-instance 'move-instruction
                                       :destination result
                                       :source integer)))
                 (t
                  (let ((temp1 (make-instance 'virtual-register :kind :integer))
                        (temp2 (make-instance 'virtual-register :kind :integer)))
                    (emit (make-instance 'x86-fake-three-operand-instruction
                                         :opcode 'lap:sar64
                                         :result temp1
                                         :lhs integer
                                         :rhs count-value))
                    (emit (make-instance 'x86-fake-three-operand-instruction
                                         :opcode 'lap:and64
                                         :result temp2
                                         :lhs temp1
                                         :rhs (- (ash 1 sys.int::+n-fixnum-bits+))))
                  (emit (make-instance 'move-instruction
                                       :destination result
                                       :source temp2)))))))
        (t
         (give-up))))

(define-builtin mezzano.compiler::%fast-fixnum-left-shift ((integer count) result)
  (cond ((constant-value-p count '(integer 0))
         (let ((count-value (fetch-constant-value count)))
           (cond ((>= count-value (- 64 sys.int::+n-fixnum-bits+))
                  ;; All bits shifted out.
                  ;; Turn INTEGER into 0.
                  (emit (make-instance 'constant-instruction
                                       :destination result
                                       :value 0)))
                 ((zerop count-value)
                  (emit (make-instance 'move-instruction
                                       :destination result
                                       :source integer)))
                 (t
                  (emit (make-instance 'x86-fake-three-operand-instruction
                                       :opcode 'lap:shl64
                                       :result result
                                       :lhs integer
                                       :rhs count-value))))))
        (t
         (give-up))))

;;; SINGLE-FLOAT operations.

(define-builtin sys.int::%single-float-as-integer ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-single-float-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'box-fixnum-instruction
                         :source temp
                         :destination result))))

(define-builtin sys.int::%integer-as-single-float ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-fixnum-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'box-single-float-instruction
                         :source temp
                         :destination result))))

(define-builtin mezzano.runtime::%%coerce-fixnum-to-single-float ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :integer))
        (result-unboxed (make-instance 'virtual-register :kind :single-float)))
    (emit (make-instance 'unbox-fixnum-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cvtsi2ss64
                         :operands (list result-unboxed temp)
                         :inputs (list temp)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-single-float-instruction
                         :source result-unboxed
                         :destination result))))

(define-builtin mezzano.runtime::%%coerce-double-float-to-single-float ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :double-float))
        (result-unboxed (make-instance 'virtual-register :kind :single-float)))
    (emit (make-instance 'unbox-double-float-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cvtsd2ss64
                         :operands (list result-unboxed temp)
                         :inputs (list temp)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-single-float-instruction
                         :source result-unboxed
                         :destination result))))

(define-builtin sys.int::%%single-float-< ((lhs rhs) :b)
  (cond ((constant-value-p rhs 'single-float)
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :single-float)))
           (emit (make-instance 'unbox-single-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomiss
                                :operands (list lhs-unboxed `(:literal ,(sys.int::%single-float-as-integer (fetch-constant-value rhs))))
                                :inputs (list lhs-unboxed)
                                :outputs '()))))
        (t
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :single-float))
               (rhs-unboxed (make-instance 'virtual-register :kind :single-float)))
           (emit (make-instance 'unbox-single-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'unbox-single-float-instruction
                                :source rhs
                                :destination rhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomiss
                                :operands (list lhs-unboxed rhs-unboxed)
                                :inputs (list lhs-unboxed rhs-unboxed)
                                :outputs '()))))))

;; TODO: This needs to check two conditions (P & NE), which the
;; compiler can't currently do efficiently.
(define-builtin sys.int::%%single-float-= ((lhs rhs) result)
  (cond ((constant-value-p rhs 'single-float)
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :single-float))
               (temp-result1 (make-instance 'virtual-register))
               (temp-result2 (make-instance 'virtual-register)))
           (emit (make-instance 'unbox-single-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomiss
                                :operands (list lhs-unboxed `(:literal ,(sys.int::%single-float-as-integer (fetch-constant-value rhs))))
                                :inputs (list lhs-unboxed)
                                :outputs '()))
           (emit (make-instance 'constant-instruction
                                :destination temp-result1
                                :value t))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64p
                                :result temp-result2
                                :lhs temp-result1
                                :rhs `(:constant nil)))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64ne
                                :result result
                                :lhs temp-result2
                                :rhs `(:constant nil)))))
        (t
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :single-float))
               (rhs-unboxed (make-instance 'virtual-register :kind :single-float))
               (temp-result1 (make-instance 'virtual-register))
               (temp-result2 (make-instance 'virtual-register)))
           (emit (make-instance 'unbox-single-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'unbox-single-float-instruction
                                :source rhs
                                :destination rhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomiss
                                :operands (list lhs-unboxed rhs-unboxed)
                                :inputs (list lhs-unboxed rhs-unboxed)
                                :outputs '()))
           (emit (make-instance 'constant-instruction
                                :destination temp-result1
                                :value t))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64p
                                :result temp-result2
                                :lhs temp-result1
                                :rhs `(:constant nil)))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64ne
                                :result result
                                :lhs temp-result2
                                :rhs `(:constant nil)))))))

(define-builtin sys.int::%%truncate-single-float ((value) result)
  (let ((value-unboxed (make-instance 'virtual-register :kind :single-float))
        (result-unboxed (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-single-float-instruction
                         :source value
                         :destination value-unboxed))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cvttss2si64
                         :operands (list result-unboxed value-unboxed)
                         :inputs (list value-unboxed)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-fixnum-instruction
                         :source result-unboxed
                         :destination result))))

(macrolet ((frob (name instruction)
             `(define-builtin ,name ((lhs rhs) result)
                (cond ((constant-value-p rhs 'single-float)
                       (let ((lhs-unboxed (make-instance 'virtual-register :kind :single-float))
                             (result-unboxed (make-instance 'virtual-register :kind :single-float)))
                         (emit (make-instance 'unbox-single-float-instruction
                                              :source lhs
                                              :destination lhs-unboxed))
                         (emit (make-instance 'x86-fake-three-operand-instruction
                                              :opcode ',instruction
                                              :result result-unboxed
                                              :lhs lhs-unboxed
                                              :rhs `(:literal ,(sys.int::%single-float-as-integer (fetch-constant-value rhs)))))
                         (emit (make-instance 'box-single-float-instruction
                                              :source result-unboxed
                                              :destination result))))
                      (t
                       (let ((lhs-unboxed (make-instance 'virtual-register :kind :single-float))
                             (rhs-unboxed (make-instance 'virtual-register :kind :single-float))
                             (result-unboxed (make-instance 'virtual-register :kind :single-float)))
                         (emit (make-instance 'unbox-single-float-instruction
                                              :source lhs
                                              :destination lhs-unboxed))
                         (emit (make-instance 'unbox-single-float-instruction
                                              :source rhs
                                              :destination rhs-unboxed))
                         (emit (make-instance 'x86-fake-three-operand-instruction
                                              :opcode ',instruction
                                              :result result-unboxed
                                              :lhs lhs-unboxed
                                              :rhs rhs-unboxed))
                         (emit (make-instance 'box-single-float-instruction
                                              :source result-unboxed
                                              :destination result))))))))
  (frob sys.int::%%single-float-/ lap:divss)
  (frob sys.int::%%single-float-+ lap:addss)
  (frob sys.int::%%single-float-- lap:subss)
  (frob sys.int::%%single-float-* lap:mulss))

(define-builtin sys.int::%%single-float-sqrt ((value) result)
  (let ((value-unboxed (make-instance 'virtual-register :kind :single-float))
        (result-unboxed (make-instance 'virtual-register :kind :single-float)))
    (emit (make-instance 'unbox-single-float-instruction
                         :source value
                         :destination value-unboxed))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:sqrtss
                         :operands (list result-unboxed value-unboxed)
                         :inputs (list value-unboxed)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-single-float-instruction
                         :source result-unboxed
                         :destination result))))

;;; DOUBLE-FLOAT operations.

(define-builtin sys.int::%double-float-as-integer ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-double-float-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'box-unsigned-byte-64-instruction
                         :source temp
                         :destination result))))

(define-builtin sys.int::%integer-as-double-float ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-unsigned-byte-64-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'box-double-float-instruction
                         :source temp
                         :destination result))))

(define-builtin mezzano.runtime::%%coerce-fixnum-to-double-float ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :integer))
        (result-unboxed (make-instance 'virtual-register :kind :double-float)))
    (emit (make-instance 'unbox-fixnum-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cvtsi2sd64
                         :operands (list result-unboxed temp)
                         :inputs (list temp)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-double-float-instruction
                         :source result-unboxed
                         :destination result))))

(define-builtin mezzano.runtime::%%coerce-single-float-to-double-float ((value) result)
  (let ((temp (make-instance 'virtual-register :kind :single-float))
        (result-unboxed (make-instance 'virtual-register :kind :double-float)))
    (emit (make-instance 'unbox-single-float-instruction
                         :source value
                         :destination temp))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cvtss2sd64
                         :operands (list result-unboxed temp)
                         :inputs (list temp)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-double-float-instruction
                         :source result-unboxed
                         :destination result))))

(define-builtin sys.int::%%double-float-< ((lhs rhs) :b)
  (cond ((constant-value-p rhs 'double-float)
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :double-float)))
           (emit (make-instance 'unbox-double-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomisd
                                :operands (list lhs-unboxed `(:literal ,(sys.int::%double-float-as-integer (fetch-constant-value rhs))))
                                :inputs (list lhs-unboxed)
                                :outputs '()))))
        (t
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :double-float))
               (rhs-unboxed (make-instance 'virtual-register :kind :double-float)))
           (emit (make-instance 'unbox-double-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'unbox-double-float-instruction
                                :source rhs
                                :destination rhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomisd
                                :operands (list lhs-unboxed rhs-unboxed)
                                :inputs (list lhs-unboxed rhs-unboxed)
                                :outputs '()))))))

;; TODO: This needs to check two conditions (P & NE), which the
;; compiler can't currently do efficiently.
(define-builtin sys.int::%%double-float-= ((lhs rhs) result)
  (cond ((constant-value-p rhs 'double-float)
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :double-float))
               (temp-result1 (make-instance 'virtual-register))
               (temp-result2 (make-instance 'virtual-register)))
           (emit (make-instance 'unbox-double-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomisd
                                :operands (list lhs-unboxed `(:literal ,(sys.int::%double-float-as-integer (fetch-constant-value rhs))))
                                :inputs (list lhs-unboxed)
                                :outputs '()))
           (emit (make-instance 'constant-instruction
                                :destination temp-result1
                                :value t))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64p
                                :result temp-result2
                                :lhs temp-result1
                                :rhs `(:constant nil)))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64ne
                                :result result
                                :lhs temp-result2
                                :rhs `(:constant nil)))))
        (t
         (let ((lhs-unboxed (make-instance 'virtual-register :kind :double-float))
               (rhs-unboxed (make-instance 'virtual-register :kind :double-float))
               (temp-result1 (make-instance 'virtual-register))
               (temp-result2 (make-instance 'virtual-register)))
           (emit (make-instance 'unbox-double-float-instruction
                                :source lhs
                                :destination lhs-unboxed))
           (emit (make-instance 'unbox-double-float-instruction
                                :source rhs
                                :destination rhs-unboxed))
           (emit (make-instance 'x86-instruction
                                :opcode 'lap:ucomisd
                                :operands (list lhs-unboxed rhs-unboxed)
                                :inputs (list lhs-unboxed rhs-unboxed)
                                :outputs '()))
           (emit (make-instance 'constant-instruction
                                :destination temp-result1
                                :value t))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64p
                                :result temp-result2
                                :lhs temp-result1
                                :rhs `(:constant nil)))
           (emit (make-instance 'x86-fake-three-operand-instruction
                                :opcode 'lap:cmov64ne
                                :result result
                                :lhs temp-result2
                                :rhs `(:constant nil)))))))

(define-builtin sys.int::%%truncate-double-float ((value) result)
  (let ((value-unboxed (make-instance 'virtual-register :kind :double-float))
        (result-unboxed (make-instance 'virtual-register :kind :integer)))
    (emit (make-instance 'unbox-double-float-instruction
                         :source value
                         :destination value-unboxed))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:cvttsd2si64
                         :operands (list result-unboxed value-unboxed)
                         :inputs (list value-unboxed)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-fixnum-instruction
                         :source result-unboxed
                         :destination result))))

(macrolet ((frob (name instruction)
             `(define-builtin ,name ((lhs rhs) result)
                (cond ((constant-value-p rhs 'double-float)
                       (let ((lhs-unboxed (make-instance 'virtual-register :kind :double-float))
                             (result-unboxed (make-instance 'virtual-register :kind :double-float)))
                         (emit (make-instance 'unbox-double-float-instruction
                                              :source lhs
                                              :destination lhs-unboxed))
                         (emit (make-instance 'x86-fake-three-operand-instruction
                                              :opcode ',instruction
                                              :result result-unboxed
                                              :lhs lhs-unboxed
                                              :rhs `(:literal ,(sys.int::%double-float-as-integer (fetch-constant-value rhs)))))
                         (emit (make-instance 'box-double-float-instruction
                                              :source result-unboxed
                                              :destination result))))
                      (t
                       (let ((lhs-unboxed (make-instance 'virtual-register :kind :double-float))
                             (rhs-unboxed (make-instance 'virtual-register :kind :double-float))
                             (result-unboxed (make-instance 'virtual-register :kind :double-float)))
                         (emit (make-instance 'unbox-double-float-instruction
                                              :source lhs
                                              :destination lhs-unboxed))
                         (emit (make-instance 'unbox-double-float-instruction
                                              :source rhs
                                              :destination rhs-unboxed))
                         (emit (make-instance 'x86-fake-three-operand-instruction
                                              :opcode ',instruction
                                              :result result-unboxed
                                              :lhs lhs-unboxed
                                              :rhs rhs-unboxed))
                         (emit (make-instance 'box-double-float-instruction
                                              :source result-unboxed
                                              :destination result))))))))
  (frob sys.int::%%double-float-/ lap:divsd)
  (frob sys.int::%%double-float-+ lap:addsd)
  (frob sys.int::%%double-float-- lap:subsd)
  (frob sys.int::%%double-float-* lap:mulsd))

(define-builtin sys.int::%%double-float-sqrt ((value) result)
  (let ((value-unboxed (make-instance 'virtual-register :kind :double-float))
        (result-unboxed (make-instance 'virtual-register :kind :double-float)))
    (emit (make-instance 'unbox-double-float-instruction
                         :source value
                         :destination value-unboxed))
    (emit (make-instance 'x86-instruction
                         :opcode 'lap:sqrtsd
                         :operands (list result-unboxed value-unboxed)
                         :inputs (list value-unboxed)
                         :outputs (list result-unboxed)))
    (emit (make-instance 'box-double-float-instruction
                         :source result-unboxed
                         :destination result))))
