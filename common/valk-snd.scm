; Some important constants and period/frequency conversions.


;(declare (flonum))

;(declare (standard-bindings))



(define *pi* (* (atan 1) 4))
(define *2pi* (* (atan 1) 8))
(define (freq->period f) (* f *2pi*))
(define (period->freq f) (/ f *2pi*))

(define (constantly x)
  (lambda t
    x))

(define silence (constantly 0))


; Sine wave generator.
; Produces a waveform according to the following function:
; s(t) = A cos ωt + p where ω = 2πf

(define (sine-wave freq ampl . phase)
  (let ((phase (if (null? phase)
		   0
		   (car phase))))
    (lambda (t)
      (* ampl (cos (+ phase (freq->period (* freq t))))))))


; Square wave generator.
;
; Produces a waveform according to the function:
;        | 1 if r is less than d
; s(t) = |
;        | 0 otherwise
;
; where r is where t is in the current period
;       d is the duty cycle
;
(define (square-wave freq ampl . duty)
  (let ((duty (if (null? duty)
		   0.5
		   (car duty))))
    (lambda (t)
      (let* ((t2 (* t freq))
	     (r (- t2 (floor t2))))
	(* ampl
	   (if (< r duty)
	       1.0
	       0.0))))))


(define (envelope-ampl f1 f2)
  (lambda (t)
    (* (f1 t)
       (f2 t))))

; Amplitude changer. Multiply amplitude of output of generator func by factor.

(define (change-ampl f factor)
  (envelope-ampl f (constantly factor)))

; Sample offset generator. Shifts the output of func forward in time by t
; seconds.

(define (sample-offset f offset)
  (lambda (t)
    (if (< t offset)
	0.0
	(f (- t offset)))))

(define (signed->unsigned16 n)
  (if (negative? n)
      (+ 65536 n)
      n))

(define (sound-render-s16vector gen t samplerate)
  (let* (
	 (samples (inexact->exact (floor (* t samplerate))))
	 (v (make-s16vector (* samples))))
    (let loop ((i 0))
      (cond ((>= i samples)
	     v)
	    (else (begin (s16vector-set! v i
					 (max -32768
					      (min 32767
						   (inexact->exact
						    (floor
						     (* (gen (/ i samplerate))
							32768))))))
		       
		       (loop (+ i 1))))))))

(define (sound-render-s16vector-st gen t samplerate)
  (let* (
	 (samples (inexact->exact (floor (* t samplerate))))
	 (s2 (* samples 2))
	 
	 (v (make-s16vector s2)))
    (let loop ((i 0))
      (cond ((>= i samples)
	     v)
	    (else (call-with-values (lambda ()
				    (gen (/ i samplerate)))
		  
		    (lambda (a b)
		      (s16vector-set! v (* i 2)
				      (max -32768
					   (min 32767 (inexact->exact
						       (floor
							(* a 32768))))))
		      (s16vector-set! v (+ (* i 2) 1)
				      (max -32768
					   (min 32767
						(inexact->exact
						 (floor (* b 32768))))))))
		  (loop (+ i 1))
		  )))))

; Mix generator. Mixes the output of two generators together.

(define (mix f1 f2)
  (lambda (t)
    (+ (f1 t)
       (f2 t))))

; Stereo mix generator: same as above but with 2 channels.

(define (stereo-mix f1 f2)
  (lambda (t)
    (call-with-values (lambda ()
			(f1 t))
      (lambda (a b)
	(call-with-values (lambda ()
			    (f2 t))
	  (lambda (c d)
	    (values (+ a c)
		    (+ b d))))))))

(define (stereo left right)
  (lambda (t)
    (values (left t)
	    (right t))))

; Converts mono output to stereo output.

(define (mono->stereo f)
  (let* ((f2 (change-ampl f 0.5)))
    (stereo f2 f2)))

(define (left-channel f)
  (lambda (t)
    (call-with-values (lambda ()
			(f t))
      (lambda (a b)
	a))))

(define (right-channel f)
  (lambda (t)
    (call-with-values (lambda ()
			(f t))
      (lambda (a b)
	b))))

(define (stereo-change-ampl f factor)
  (stereo
   (change-ampl (left-channel f)
		factor)
   (change-ampl (right-channel f)
		factor)))

; Pan generator. Converts a mono signal to stereo; lets you move it left or
; right.
; -1.0 is full left, +1.0 is full right.
(define (pan f factor)
  (let* ((fac2 (* factor 0.5)))
    (stereo
     (change-ampl f
		  (- 0.5 fac2))
     (change-ampl f (+ 0.5 fac2)))))
