(define-module (dom audio)
  #:use-module (hoot ffi)
  #:use-module (support ffi)
  #:export (audio-context-destination
            connect-audio-node
            decode-audio-data
            make-audio-buffer-source-node
            make-audio-context
            start-audio-buffer))

(define-foreign audio-context-destination
  "audio" "destination"
  (ref extern) -> (ref extern))

(define-foreign %connect-audio-node
  "audio" "connect"
  (ref extern) (ref extern) -> none)
(define connect-audio-node (with-unspecified-result %connect-audio-node))

(define-foreign %decode-audio-data
  "audio" "decodeAudioData"
  (ref extern) (ref extern) -> (ref extern))
(define decode-audio-data (with-promise-result %decode-audio-data))

(define-foreign make-audio-buffer-source-node
  "audio" "makeAudioBufferSourceNode"
  (ref extern) (ref extern) -> (ref extern))

(define-foreign make-audio-context
  "audio" "makeAudioContext"
  -> (ref extern))

(define-foreign %start-audio-buffer
  "audio" "startAudioBuffer"
  (ref extern) -> none)
(define start-audio-buffer (with-unspecified-result %start-audio-buffer))
