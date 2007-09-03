(declare (standard-bindings))
(declare (extended-bindings))
(declare (not safe))
(define write-byte write-u8)
(define read-byte read-u8)
(define char->ascii char->integer)
(define ascii->char integer->char)
(declare (fixnum))
(include "./srfi-1.scm")
(declare (generic) (mostly-fixnum-flonum))
(include "../common/valk-num.scm")
(include "../common/valk-snd.scm")
(include "../common/valk-seq.scm")
(include "../common/valk-riff.scm")
(include "../common/valk-file.scm")
